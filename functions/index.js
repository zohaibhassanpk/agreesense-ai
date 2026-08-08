"use strict";

const {setGlobalOptions} = require("firebase-functions/v2");
const {onValueCreated} = require("firebase-functions/v2/database");
const {onSchedule} = require("firebase-functions/v2/scheduler");
const {logger} = require("firebase-functions");
const {initializeApp} = require("firebase-admin/app");
const {getDatabase, ServerValue} = require("firebase-admin/database");
const {getMessaging} = require("firebase-admin/messaging");
const {getAuth} = require("firebase-admin/auth");
const {
  NOTIFICATION_INTERVAL_MS,
  ALERT_RETENTION_HOURS,
  advanceAlertState,
  evaluateReading,
  expiredAlertUpdates,
  isFreshReading,
  popupBody,
  readingTimestamp,
  sanitizeRtdbKey,
  userKeyCandidates,
} = require("./alert_logic");

const DATABASE_URL =
  "https://agrisenseai-app-default-rtdb.asia-southeast1.firebasedatabase.app";
const DATABASE_INSTANCE = "agrisenseai-app-default-rtdb";
const INVALID_TOKEN_CODES = new Set([
  "messaging/registration-token-not-registered",
  "messaging/invalid-registration-token",
]);
const RECIPIENT_CACHE_MS = 5 * 60 * 1000;
const CURRENT_READING_MAX_AGE_MS = NOTIFICATION_INTERVAL_MS + 60 * 1000;
const recipientIdentityCache = new Map();

initializeApp({databaseURL: DATABASE_URL});
setGlobalOptions({region: "asia-southeast1", maxInstances: 20});

exports.sendSensorAlerts = onValueCreated(
  {
    ref: "/users/{sensorUserKey}/farms/{farmKey}/fields/{fieldKey}/history/{historyKey}",
    instance: DATABASE_INSTANCE,
    retry: true,
  },
  async (event) => {
    if (!event.data.exists()) return;

    const storedReading = event.data.val();
    if (
      !storedReading ||
      typeof storedReading !== "object" ||
      Array.isArray(storedReading)
    ) {
      logger.warn("Ignoring an invalid sensor history record", {
        sensorUserKey: event.params.sensorUserKey,
        historyKey: event.params.historyKey,
      });
      return;
    }

    const now = Date.now();
    const readingAt =
      readingTimestamp(storedReading) ||
      historyTimestamp(event.params.historyKey, event.time, now);
    const reading = {...storedReading, updatedAt: readingAt};
    if (!isFreshReading(reading, now, CURRENT_READING_MAX_AGE_MS)) {
      logger.info("Ignoring stale sensor history record", {
        sensorUserKey: event.params.sensorUserKey,
        historyKey: event.params.historyKey,
        readingAt,
      });
      return;
    }

    const database = getDatabase();
    const {sensorUserKey, farmKey, fieldKey, historyKey} = event.params;
    const recipientsSnapshot = await database
      .ref(`notificationRecipients/${sensorUserKey}`)
      .get();
    if (!recipientsSnapshot.exists()) return;

    const jobs = [];
    recipientsSnapshot.forEach((recipientSnapshot) => {
      jobs.push(
        processRecipient({
          database,
          event,
          reading,
          readingAt,
          now,
          sensorUserKey,
          farmKey,
          fieldKey,
          historyKey,
          recipientUid: recipientSnapshot.key,
          recipient: recipientSnapshot.val(),
        }),
      );
    });
    await Promise.all(jobs);
  },
);

exports.checkCurrentSensorAlerts = onSchedule(
  {
    schedule: "every 5 minutes",
    timeZone: "UTC",
    retryCount: 3,
  },
  async (event) => {
    const database = getDatabase();
    const now = Date.now();
    const recipientsRoot = await database.ref("notificationRecipients").get();
    if (!recipientsRoot.exists()) {
      logger.info("Scheduled sensor alert check skipped; no recipients");
      return;
    }

    const sensorJobs = [];
    recipientsRoot.forEach((sensorSnapshot) => {
      sensorJobs.push(
        processSensorUserCurrentReadings({
          database,
          scheduleEvent: event,
          now,
          sensorUserKey: sensorSnapshot.key,
          recipientsSnapshot: sensorSnapshot,
        }),
      );
    });
    await Promise.all(sensorJobs);
  },
);

exports.cleanupExpiredAlerts = onSchedule(
  {
    schedule: "every 15 minutes",
    timeZone: "UTC",
    retryCount: 3,
  },
  async () => {
    const database = getDatabase();
    const alertsReference = database.ref("notificationAlerts");
    const alertsSnapshot = await alertsReference.get();
    if (!alertsSnapshot.exists()) {
      logger.info("Alert cleanup completed", {
        retentionHours: ALERT_RETENTION_HOURS,
        deletedCount: 0,
      });
      return;
    }

    const updates = expiredAlertUpdates(alertsSnapshot.val(), Date.now());
    const deletedCount = Object.keys(updates).length;
    if (deletedCount > 0) {
      await alertsReference.update(updates);
    }
    logger.info("Alert cleanup completed", {
      retentionHours: ALERT_RETENTION_HOURS,
      deletedCount,
    });
  },
);

async function processSensorUserCurrentReadings({
  database,
  scheduleEvent,
  now,
  sensorUserKey,
  recipientsSnapshot,
}) {
  const readings = await loadCurrentReadings(database, sensorUserKey, now);
  if (readings.length === 0) {
    logger.info("Scheduled sensor alert check found no current readings", {
      sensorUserKey,
    });
    return;
  }

  const jobs = [];
  recipientsSnapshot.forEach((recipientSnapshot) => {
    for (const reading of readings) {
      jobs.push(
        processRecipient({
          database,
          sourceEventId: `schedule_${scheduleEvent.id}_${reading.farmKey}_${reading.fieldKey}`,
          reading: reading.reading,
          readingAt: reading.readingAt,
          now,
          sensorUserKey,
          farmKey: reading.farmKey,
          fieldKey: reading.fieldKey,
          historyKey: "current",
          recipientUid: recipientSnapshot.key,
          recipient: recipientSnapshot.val(),
          source: "scheduled_current",
        }),
      );
    }
  });
  await Promise.all(jobs);
}

async function loadCurrentReadings(database, sensorUserKey, now) {
  const farmsSnapshot = await database
    .ref(`users/${sensorUserKey}/farms`)
    .get();
  const readings = [];
  if (!farmsSnapshot.exists()) return readings;

  farmsSnapshot.forEach((farmSnapshot) => {
    const fieldsSnapshot = farmSnapshot.child("fields");
    fieldsSnapshot.forEach((fieldSnapshot) => {
      const current = fieldSnapshot.child("current").val();
      if (!current || typeof current !== "object" || Array.isArray(current)) {
        return;
      }
      const readingAt = readingTimestamp(current);
      if (
        readingAt === undefined ||
        !isFreshReading(current, now, CURRENT_READING_MAX_AGE_MS)
      ) {
        logger.info("Skipping stale current sensor reading", {
          sensorUserKey,
          farmKey: farmSnapshot.key,
          fieldKey: fieldSnapshot.key,
          readingAt,
        });
        return;
      }
      readings.push({
        farmKey: farmSnapshot.key,
        fieldKey: fieldSnapshot.key,
        readingAt,
        reading: {...current, updatedAt: readingAt},
      });
    });
  });
  return readings;
}

async function processRecipient({
  database,
  event,
  sourceEventId,
  reading,
  readingAt,
  now,
  sensorUserKey,
  farmKey,
  fieldKey,
  historyKey,
  recipientUid,
  recipient,
  source = "history_created",
}) {
  if (!recipient || recipient.enabled !== true) {
    return;
  }

  if (!(await recipientCanReceive(sensorUserKey, recipientUid))) {
    logger.warn("Ignoring a recipient linked to another sensor account", {
      sensorUserKey,
      recipientUid,
    });
    return;
  }

  const tokenEntries = extractTokens(recipient.tokens);
  if (tokenEntries.length === 0) return;

  const eventId = sourceEventId || event.id;
  const results = evaluateReading(reading, recipient.thresholds);
  const metricJobs = Object.entries(results).map(async ([metric, alert]) => {
    if (alert === undefined) return;

    const stateReference = database.ref(
      `notificationAlertStates/${sensorUserKey}/${recipientUid}/${farmKey}/${fieldKey}/${metric}`,
    );
    let transition;
    const state = await stateReference.transaction(
      (current) => {
        transition = advanceAlertState(current, alert, {
          now,
          readingAt,
          eventId,
        });
        return transition.action === "abort" ? undefined : transition.state;
      },
      undefined,
      false,
    );
    if (!state.committed || !transition || transition.action !== "claim") {
      return;
    }

    const alertId = sanitizeRtdbKey(`${eventId}_${metric}`);

    try {
      await persistAlert({
        database,
        alert,
        alertId,
        eventId,
        readingAt,
        sensorUserKey,
        farmKey,
        fieldKey,
        historyKey,
        recipientUid,
        source,
      });
      await sendAlert({
        database,
        tokenEntries,
        alert,
        readingAt,
        sensorUserKey,
        farmKey,
        fieldKey,
        recipientUid,
      });
      logger.info("Sensor threshold notification generated", {
        sensorUserKey,
        recipientUid,
        farmKey,
        fieldKey,
        metric,
        severity: alert.severity,
        source,
      });
    } catch (error) {
      // Keep the canonical in-app alert, but release this event's delivery so
      // a retried invocation can attempt the popup again.
      await stateReference.transaction((current) => {
        if (!current || current.claimedEventId !== eventId) return undefined;
        const nextState = {...current};
        delete nextState.claimedEventId;
        delete nextState.claimedAt;
        nextState.nextNotificationAt = now;
        return nextState;
      });
      throw error;
    }
  });

  await Promise.all(metricJobs);
}

function historyTimestamp(historyKey, eventTime, fallback) {
  const fromKey = readingTimestamp({updatedAt: historyKey});
  if (fromKey !== undefined) return fromKey;
  const fromEvent = Date.parse(eventTime || "");
  return Number.isFinite(fromEvent) ? fromEvent : fallback;
}

async function persistAlert({
  database,
  alert,
  alertId,
  eventId,
  readingAt,
  sensorUserKey,
  farmKey,
  fieldKey,
  historyKey,
  recipientUid,
  source,
}) {
  await database.ref(`notificationAlerts/${recipientUid}/${alertId}`).set({
    eventId,
    title: alert.title,
    message: alert.detailMessage,
    recommendedAction: alert.recommendedAction,
    popupBody: popupBody(alert, readingAt),
    severity: alert.severity,
    metric: alert.metric,
    sensorName: alert.metricLabel,
    value: alert.value,
    currentValue: alert.value,
    unit: alert.unit,
    notificationType: alert.severity,
    timestamp: readingAt,
    sensorUserKey,
    farmKey,
    fieldKey,
    historyKey,
    source,
    createdAt: ServerValue.TIMESTAMP,
  });
}

async function recipientCanReceive(sensorUserKey, recipientUid) {
  const now = Date.now();
  let cached = recipientIdentityCache.get(recipientUid);
  if (!cached || cached.expiresAt <= now) {
    try {
      const user = await getAuth().getUser(recipientUid);
      cached = {
        candidates: userKeyCandidates({
          uid: user.uid,
          email: user.email,
          phoneNumber: user.phoneNumber,
        }),
        expiresAt: now + RECIPIENT_CACHE_MS,
      };
      recipientIdentityCache.set(recipientUid, cached);
    } catch (error) {
      logger.error("Could not verify a notification recipient", {
        recipientUid,
        error,
      });
      return false;
    }
  }
  return cached.candidates.includes(sensorUserKey);
}

function extractTokens(rawTokens) {
  if (!rawTokens || typeof rawTokens !== "object") return [];
  return Object.entries(rawTokens)
    .map(([key, value]) => ({key, token: value && value.token}))
    .filter(({token}) => typeof token === "string" && token.length > 20);
}

async function sendAlert({
  database,
  tokenEntries,
  alert,
  readingAt,
  sensorUserKey,
  farmKey,
  fieldKey,
  recipientUid,
}) {
  // The Admin SDK supports at most 500 registration tokens per multicast.
  for (let offset = 0; offset < tokenEntries.length; offset += 500) {
    const chunk = tokenEntries.slice(offset, offset + 500);
    const response = await getMessaging().sendEachForMulticast({
      tokens: chunk.map(({token}) => token),
      notification: {
        title: alert.title,
        body: popupBody(alert, readingAt),
      },
      data: {
        type: "sensor_alert",
        metric: alert.metric,
        severity: alert.severity,
        title: alert.title,
        body: popupBody(alert, readingAt),
        detailMessage: alert.detailMessage,
        recommendedAction: alert.recommendedAction,
        timestamp: String(readingAt),
        createdAt: String(Date.now()),
        sensorUserKey,
        farmKey,
        fieldKey,
      },
      android: {
        priority: "high",
        notification: {
          channelId: "high_importance_channel",
          icon: "ic_stat_notification",
          sound: "default",
          priority: "high",
        },
      },
      apns: {
        headers: {"apns-priority": "10", "apns-push-type": "alert"},
        payload: {aps: {sound: "default"}},
      },
    });

    const removals = [];
    response.responses.forEach((result, index) => {
      if (result.success || !INVALID_TOKEN_CODES.has(result.error?.code)) return;
      const tokenKey = chunk[index].key;
      removals.push(
        database
          .ref(
            `notificationRecipients/${sensorUserKey}/${recipientUid}/tokens/${tokenKey}`,
          )
          .remove(),
      );
    });
    try {
      await Promise.all(removals);
    } catch (error) {
      // The popup has already been accepted by FCM. Token cleanup must not
      // cause the history event to be retried and delivered a second time.
      logger.warn("Could not remove invalid notification tokens", {
        sensorUserKey,
        recipientUid,
        metric: alert.metric,
        error,
      });
    }

    logger.info("Sensor alert FCM delivery completed", {
      sensorUserKey,
      recipientUid,
      metric: alert.metric,
      successCount: response.successCount,
      failureCount: response.failureCount,
    });
  }
}
