"use strict";

const test = require("node:test");
const assert = require("node:assert/strict");
const {
  ALERT_RETENTION_HOURS,
  ALERT_RETENTION_MS,
  DEFAULT_THRESHOLDS,
  NOTIFICATION_INTERVAL_MS,
  advanceAlertState,
  evaluateReading,
  expiredAlertUpdates,
  isFreshReading,
  isExpiredAlert,
  popupBody,
  userKeyCandidates,
} = require("../alert_logic");

test("keeps existing thresholds and five-minute notification interval unchanged", () => {
  assert.equal(NOTIFICATION_INTERVAL_MS, 5 * 60 * 1000);
  assert.deepEqual(DEFAULT_THRESHOLDS, {
    minTemperature: 20,
    maxTemperature: 30,
    minHumidity: 60,
    maxHumidity: 75,
    minMoisture: 60,
    maxMoisture: 85,
    minLight: 45000,
    maxLight: 70000,
  });
});

test("all supported warning alerts contain tobacco-specific farmer action", () => {
  const alerts = [
    evaluateReading({temperatureC: 19}, {}).temperature,
    evaluateReading({temperatureC: 31}, {}).temperature,
    evaluateReading({humidityPercent: 59}, {}).humidity,
    evaluateReading({humidityPercent: 76}, {}).humidity,
    evaluateReading({soilMoisturePercent: 59}, {}).soilMoisture,
    evaluateReading({soilMoisturePercent: 86}, {}).soilMoisture,
    evaluateReading({lightLux: 44000}, {}).lightIntensity,
    evaluateReading({lightLux: 71000, temperatureC: 25}, {}).lightIntensity,
  ];

  for (const alert of alerts) {
    assert.equal(alert.severity, "warning");
    assert.match(alert.detailMessage, /tobacco/i);
    assert.match(alert.recommendedAction, /tobacco/i);
    assert.ok(alert.recommendedAction.length > 40);
  }
});

test("all supported critical alerts contain urgent tobacco-specific action", () => {
  const cases = [
    evaluateReading({temperatureC: 9}, {}).temperature,
    evaluateReading({temperatureC: 37}, {}).temperature,
    evaluateReading({humidityPercent: 39}, {}).humidity,
    evaluateReading({humidityPercent: 86}, {}).humidity,
    evaluateReading({soilMoisturePercent: 49}, {}).soilMoisture,
    evaluateReading({soilMoisturePercent: 91}, {}).soilMoisture,
    evaluateReading({lightLux: 19000}, {}).lightIntensity,
    evaluateReading({lightLux: 91000, temperatureC: 36}, {}).lightIntensity,
  ];

  for (const alert of cases) {
    assert.equal(alert.severity, "critical");
    assert.match(alert.detailMessage, /tobacco/i);
    assert.match(alert.recommendedAction, /tobacco/i);
    assert.match(alert.recommendedAction, /immediately/i);
  }
});

test("popup remains concise and includes an immediate farmer check", () => {
  const alert = evaluateReading({soilMoisturePercent: 49}, {}).soilMoisture;
  const body = popupBody(alert, Date.now());

  assert.equal(body, alert.popupMessage);
  assert.ok(body.length <= 120);
  assert.doesNotMatch(body, /\n/);
  assert.match(body, /inspect/i);
});

test("eight-hour retention keeps newer alerts and expires the boundary", () => {
  const now = 1800000000000;
  assert.equal(ALERT_RETENTION_HOURS, 8);
  assert.equal(
    isExpiredAlert({createdAt: now - ALERT_RETENTION_MS + 1}, now),
    false,
  );
  assert.equal(
    isExpiredAlert({createdAt: now - ALERT_RETENTION_MS}, now),
    true,
  );
  assert.equal(isExpiredAlert({}, now), false);
  assert.equal(isExpiredAlert({createdAt: "invalid"}, now), false);
});

test("cleanup updates only expired alerts across multiple users", () => {
  const now = 1800000000000;
  const updates = expiredAlertUpdates(
    {
      "user-a": {
        expired: {createdAt: now - ALERT_RETENTION_MS},
        recent: {createdAt: now - 1000},
        malformed: {createdAt: "invalid"},
      },
      "user-b": {
        old: {createdAt: (now - ALERT_RETENTION_MS - 1) / 1000},
      },
    },
    now,
  );

  assert.deepEqual(updates, {
    "user-a/expired": null,
    "user-b/old": null,
  });
});

test("evaluates fixed critical limits before configured warning limits", () => {
  const results = evaluateReading(
    {
      temperatureC: 40,
      humidityPercent: 70,
      soilMoisturePercent: 65,
      lightLux: 60000,
    },
    {maxTemperature: 45},
  );

  assert.equal(results.temperature.severity, "critical");
  assert.equal(results.temperature.title, "Critical: High Temperature");
  assert.equal(results.humidity, null);
});

test("uses each recipient's configured warning range", () => {
  const results = evaluateReading(
    {temperatureC: 31, humidityPercent: 55, soilMoisturePercent: 70, lightLux: 50000},
    {maxTemperature: 32, minHumidity: 50},
  );

  assert.equal(results.temperature, null);
  assert.equal(results.humidity, null);
});

test("accepts epoch seconds and milliseconds only while fresh", () => {
  const now = 1800000000000;
  assert.equal(isFreshReading({updatedAt: now}, now), true);
  assert.equal(isFreshReading({updatedAt: now / 1000}, now), true);
  assert.equal(isFreshReading({updatedAt: now - 31000}, now), false);
  assert.equal(isFreshReading({}, now), false);
});

test("claims immediately then repeats after five minutes", () => {
  const alert = evaluateReading({temperatureC: 31}, {}).temperature;
  const start = 1800000000000;
  const first = advanceAlertState(null, alert, {
    now: start,
    readingAt: start,
    eventId: "event-1",
  });
  assert.equal(first.action, "claim");
  assert.equal(first.state.nextNotificationAt, start + NOTIFICATION_INTERVAL_MS);

  const waiting = advanceAlertState(first.state, alert, {
    now: start + NOTIFICATION_INTERVAL_MS - 1,
    readingAt: start + 20000,
    eventId: "event-2",
  });
  assert.equal(waiting.action, "wait");

  const claimed = advanceAlertState(waiting.state, alert, {
    now: start + NOTIFICATION_INTERVAL_MS,
    readingAt: start + 30000,
    eventId: "event-3",
  });
  assert.equal(claimed.action, "claim");
  assert.equal(
    claimed.state.nextNotificationAt,
    start + NOTIFICATION_INTERVAL_MS * 2,
  );
});

test("a reading gap starts a new online-session timer", () => {
  const alert = evaluateReading({temperatureC: 31}, {}).temperature;
  const start = 1800000000000;
  const previous = {
    conditionKey: alert.conditionKey,
    conditionStartedAt: start,
    nextNotificationAt: start,
    lastReadingAt: start,
  };
  const resumed = advanceAlertState(previous, alert, {
    now: start + 60000,
    readingAt: start + 60000,
    eventId: "event-2",
  });

  assert.equal(resumed.action, "claim");
  assert.equal(
    resumed.state.nextNotificationAt,
    start + 60000 + NOTIFICATION_INTERVAL_MS,
  );
});

test("normal readings clear the active schedule", () => {
  const transition = advanceAlertState(
    {conditionKey: "warning:test"},
    null,
    {now: 1, readingAt: 1, eventId: "event"},
  );
  assert.deepEqual(transition, {action: "clear", state: null});
});

test("out-of-order readings cannot rewind notification state", () => {
  const alert = evaluateReading({temperatureC: 31}, {}).temperature;
  const transition = advanceAlertState(
    {
      conditionKey: alert.conditionKey,
      nextNotificationAt: 2000,
      lastReadingAt: 1500,
    },
    alert,
    {now: 2000, readingAt: 1400, eventId: "old-event"},
  );

  assert.equal(transition.action, "abort");
  assert.equal(transition.state.lastReadingAt, 1500);
});

test("recipient sensor keys are derived from verified Firebase identities", () => {
  assert.deepEqual(
    userKeyCandidates({
      uid: "firebase-uid",
      email: "Farmer.Name@gmail.com",
      phoneNumber: "+92/3001234567",
    }),
    [
      "farmer_name",
      "firebase-uid",
      "farmer_name@gmail_com",
      "+92_3001234567",
    ],
  );
});
