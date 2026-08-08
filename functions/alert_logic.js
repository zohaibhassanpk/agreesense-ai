"use strict";

const NOTIFICATION_INTERVAL_MS = 5 * 60 * 1000;
const ONLINE_STALENESS_MS = 30 * 1000;
const ALERT_RETENTION_HOURS = 8;
const ALERT_RETENTION_MS = ALERT_RETENTION_HOURS * 60 * 60 * 1000;

const DEFAULT_THRESHOLDS = Object.freeze({
  minTemperature: 20,
  maxTemperature: 30,
  minHumidity: 60,
  maxHumidity: 75,
  minMoisture: 60,
  maxMoisture: 85,
  minLight: 45000,
  maxLight: 70000,
});

const CRITICAL = Object.freeze({
  temperatureLow: 10,
  temperatureHigh: 36,
  humidityLow: 40,
  humidityHigh: 85,
  moistureLow: 50,
  moistureHigh: 90,
  lightLow: 20000,
  lightHigh: 90000,
  lightHighTemperature: 35,
});

const SENSOR_KEYS = Object.freeze({
  temperature: ["temperatureC", "temperature", "Temperature", "tempC", "temp", "Temp"],
  humidity: ["humidityPercent", "humidity", "Humidity", "humidity_percent"],
  soilMoisture: [
    "soilMoisturePercent",
    "soilMoisture",
    "soil_moisture",
    "SoilMoisture",
    "moisturePercent",
    "moisture",
    "Moisture",
  ],
  lightIntensity: [
    "lightLux",
    "lightIntensity",
    "LightIntensity",
    "light_intensity",
    "lux",
    "Lux",
    "light",
    "Light",
  ],
  updatedAt: ["updatedAt", "timestamp", "Timestamp", "time", "Time", "ts"],
});

function firstNumber(source, keys) {
  if (!source || typeof source !== "object") return undefined;
  for (const key of keys) {
    const value = source[key];
    if (typeof value === "number" && Number.isFinite(value)) return value;
    if (typeof value === "string" && value.trim() !== "") {
      const parsed = Number(value);
      if (Number.isFinite(parsed)) return parsed;
    }
  }
  return undefined;
}

function epochMillis(value) {
  const numeric = typeof value === "number" ? value : Number(value);
  if (!Number.isFinite(numeric) || numeric <= 0) return undefined;
  return numeric < 100000000000 ? Math.trunc(numeric * 1000) : Math.trunc(numeric);
}

function readingTimestamp(reading) {
  return epochMillis(firstNumber(reading, SENSOR_KEYS.updatedAt));
}

function isFreshReading(reading, now = Date.now(), maxAgeMs = ONLINE_STALENESS_MS) {
  const timestamp = readingTimestamp(reading);
  return timestamp !== undefined && Math.abs(now - timestamp) <= maxAgeMs;
}

function normalizedThresholds(raw) {
  const thresholds = {...DEFAULT_THRESHOLDS};
  if (!raw || typeof raw !== "object") return thresholds;
  for (const key of Object.keys(thresholds)) {
    const candidate = Number(raw[key]);
    if (Number.isFinite(candidate)) thresholds[key] = candidate;
  }
  return thresholds;
}

function sanitizeRtdbKey(raw) {
  return String(raw || "").replace(/[.#$/\[\]]/g, "_");
}

function userKeyCandidates({uid, email, phoneNumber}) {
  const candidates = new Set();
  const add = (raw) => {
    const value = String(raw || "").trim();
    if (value === "") return;
    const key = sanitizeRtdbKey(value);
    if (key !== "") candidates.add(key);
  };
  const normalizedEmail = String(email || "").trim().toLowerCase();
  if (normalizedEmail !== "") add(normalizedEmail.split("@")[0]);
  add(uid);
  add(normalizedEmail);
  add(phoneNumber);
  return [...candidates];
}

function fmt(value) {
  const rounded = Math.round(value * 10) / 10;
  return Number.isInteger(rounded) ? String(rounded) : rounded.toFixed(1);
}

function makeAlert({
  metric,
  metricLabel,
  value,
  unit,
  severity,
  title,
  detailMessage,
  recommendedAction,
  popupMessage,
}) {
  return {
    metric,
    metricLabel,
    value,
    unit,
    severity,
    title,
    detailMessage,
    recommendedAction,
    popupMessage,
    conditionKey: `${severity}:${title}`,
  };
}

function temperatureAlert(value, thresholds) {
  const shown = fmt(value);
  if (value < CRITICAL.temperatureLow) {
    return makeAlert({
      metric: "temperature",
      metricLabel: "Temperature",
      value,
      unit: "\u00B0C",
      severity: "critical",
      title: "Critical: Low Temperature",
      detailMessage: `Tobacco field temperature is ${shown}\u00B0C, below the critical limit of ${CRITICAL.temperatureLow}\u00B0C. Severe cold can injure transplants, stop leaf growth, and delay maturity.`,
      recommendedAction: "Inspect tobacco plants immediately for cold injury and transplant shock. Confirm the sensor reading and current growth stage before following the approved cold-protection plan.",
      popupMessage: "Tobacco temperature is critically low. Confirm the sensor and inspect plants for cold injury now.",
    });
  }
  if (value > CRITICAL.temperatureHigh) {
    return makeAlert({
      metric: "temperature",
      metricLabel: "Temperature",
      value,
      unit: "\u00B0C",
      severity: "critical",
      title: "Critical: High Temperature",
      detailMessage: `Tobacco field temperature is ${shown}\u00B0C, above the critical limit of ${CRITICAL.temperatureHigh}\u00B0C. Severe heat can cause rapid water loss, wilting, leaf scorch, and poorer leaf quality.`,
      recommendedAction: "Inspect tobacco plants immediately for wilting or scorch. Check root-zone moisture and confirm that the sensor is not falsely heated by direct exposure before following the approved heat and irrigation plan.",
      popupMessage: "Critical tobacco heat stress risk. Check wilting, root-zone moisture, and sensor exposure immediately.",
    });
  }
  if (value < thresholds.minTemperature) {
    return makeAlert({
      metric: "temperature",
      metricLabel: "Temperature",
      value,
      unit: "\u00B0C",
      severity: "warning",
      title: "Warning: Low Temperature",
      detailMessage: `Tobacco field temperature is ${shown}\u00B0C, below the configured minimum of ${fmt(thresholds.minTemperature)}\u00B0C. Continued cool conditions may slow leaf growth and maturity.`,
      recommendedAction: "Check the tobacco growth stage, inspect young plants for cold stress, and verify the sensor reading before applying the approved cold-weather crop plan.",
      popupMessage: "Tobacco temperature is low. Verify the sensor and inspect young plants for cold stress.",
    });
  }
  if (value > thresholds.maxTemperature) {
    return makeAlert({
      metric: "temperature",
      metricLabel: "Temperature",
      value,
      unit: "\u00B0C",
      severity: "warning",
      title: "Warning: High Temperature",
      detailMessage: `Tobacco field temperature is ${shown}\u00B0C, above the configured maximum of ${fmt(thresholds.maxTemperature)}\u00B0C. Continued heat may increase moisture loss, wilting, and leaf-quality stress.`,
      recommendedAction: "Inspect leaves for early wilting, check root-zone moisture, and confirm sensor exposure before following the approved tobacco heat and irrigation plan for the current growth stage.",
      popupMessage: "Tobacco temperature is high. Check leaf wilting, root-zone moisture, and sensor exposure.",
    });
  }
  return null;
}

function humidityAlert(value, thresholds) {
  const shown = fmt(value);
  if (value < CRITICAL.humidityLow) {
    return makeAlert({
      metric: "humidity",
      metricLabel: "Humidity",
      value,
      unit: "%",
      severity: "critical",
      title: "Critical: Low Humidity",
      detailMessage: `Humidity around the tobacco crop is ${shown}%, below the critical limit of ${CRITICAL.humidityLow}%. Very dry air can accelerate leaf water loss, wilting, and transplant stress.`,
      recommendedAction: "Inspect tobacco leaves immediately for wilting and check root-zone moisture. Confirm the humidity sensor has normal airflow before following the approved irrigation plan for the current growth stage and soil.",
      popupMessage: "Tobacco humidity is critically low. Check wilting, root-zone moisture, and the sensor immediately.",
    });
  }
  if (value > CRITICAL.humidityHigh) {
    return makeAlert({
      metric: "humidity",
      metricLabel: "Humidity",
      value,
      unit: "%",
      severity: "critical",
      title: "Critical: High Humidity",
      detailMessage: `Humidity around the tobacco crop is ${shown}%, above the critical limit of ${CRITICAL.humidityHigh}%. Prolonged humid, wet foliage can strongly favor damaging tobacco leaf diseases.`,
      recommendedAction: "Inspect tobacco leaves immediately for wetness and early disease symptoms. Check airflow and the sensor before improving ventilation where possible, and avoid unnecessary overhead watering.",
      popupMessage: "Critical humidity around tobacco may favor leaf disease. Inspect leaf wetness and airflow immediately.",
    });
  }
  if (value < thresholds.minHumidity) {
    return makeAlert({
      metric: "humidity",
      metricLabel: "Humidity",
      value,
      unit: "%",
      severity: "warning",
      title: "Warning: Low Humidity",
      detailMessage: `Humidity around the tobacco crop is ${shown}%, below the configured minimum of ${fmt(thresholds.minHumidity)}%. Dry air may increase leaf water loss and moisture stress.`,
      recommendedAction: "Check tobacco leaves for early wilting, inspect root-zone moisture, and verify sensor airflow before following the approved irrigation plan for the crop stage and soil condition.",
      popupMessage: "Humidity around tobacco is low. Check leaf condition, root-zone moisture, and sensor airflow.",
    });
  }
  if (value > thresholds.maxHumidity) {
    return makeAlert({
      metric: "humidity",
      metricLabel: "Humidity",
      value,
      unit: "%",
      severity: "warning",
      title: "Warning: High Humidity",
      detailMessage: `Humidity around the tobacco crop is ${shown}%, above the configured maximum of ${fmt(thresholds.maxHumidity)}%. Persistent humidity and leaf wetness can favor tobacco leaf disease.`,
      recommendedAction: "Inspect leaves for moisture and early spots, check canopy airflow and the sensor, and avoid unnecessary overhead watering before following the approved tobacco disease-management plan.",
      popupMessage: "Humidity around tobacco is high. Check leaf wetness, early disease signs, and airflow.",
    });
  }
  return null;
}

function moistureAlert(value, thresholds) {
  const shown = fmt(value);
  if (value < CRITICAL.moistureLow) {
    return makeAlert({
      metric: "soilMoisture",
      metricLabel: "Soil Moisture",
      value,
      unit: "%",
      severity: "critical",
      title: "Critical: Low Soil Moisture",
      detailMessage: `Tobacco root-zone moisture is ${shown}%, below the critical limit of ${CRITICAL.moistureLow}%. Severe shortage can cause wilting, restrict nutrient uptake, delay maturity, and reduce leaf quality.`,
      recommendedAction: "Inspect the tobacco root zone and plants immediately for wilting. Check the sensor and irrigation system, then restore moisture according to the approved tobacco irrigation plan while avoiding sudden over-irrigation.",
      popupMessage: "Tobacco root-zone moisture is critically low. Inspect plants and the irrigation system immediately.",
    });
  }
  if (value > CRITICAL.moistureHigh) {
    return makeAlert({
      metric: "soilMoisture",
      metricLabel: "Soil Moisture",
      value,
      unit: "%",
      severity: "critical",
      title: "Critical: High Soil Moisture",
      detailMessage: `Tobacco root-zone moisture is ${shown}%, above the critical limit of ${CRITICAL.moistureHigh}%. Saturated soil can deprive roots of oxygen, damage roots, and increase tobacco disease risk.`,
      recommendedAction: "Stop unnecessary irrigation and inspect standing water, field drainage, roots, and the sensor immediately. Improve safe drainage where possible and monitor tobacco for yellowing or wilting.",
      popupMessage: "Critical excess moisture around tobacco roots. Stop unnecessary irrigation and inspect drainage now.",
    });
  }
  if (value < thresholds.minMoisture) {
    return makeAlert({
      metric: "soilMoisture",
      metricLabel: "Soil Moisture",
      value,
      unit: "%",
      severity: "warning",
      title: "Warning: Low Soil Moisture",
      detailMessage: `Tobacco root-zone moisture is ${shown}%, below the configured minimum of ${fmt(thresholds.minMoisture)}%. Continued moisture stress may cause wilting, weak growth, and poorer leaf quality.`,
      recommendedAction: "Inspect the tobacco root zone, leaves, sensor, and irrigation system. Apply water only according to the approved tobacco irrigation plan for the current growth stage, soil, and recent weather.",
      popupMessage: "Tobacco root-zone moisture is low. Check plants, the sensor, and irrigation before watering.",
    });
  }
  if (value > thresholds.maxMoisture) {
    return makeAlert({
      metric: "soilMoisture",
      metricLabel: "Soil Moisture",
      value,
      unit: "%",
      severity: "warning",
      title: "Warning: High Soil Moisture",
      detailMessage: `Tobacco root-zone moisture is ${shown}%, above the configured maximum of ${fmt(thresholds.maxMoisture)}%. Prolonged wet soil may restrict root development and favor root disease.`,
      recommendedAction: "Pause additional irrigation and inspect field drainage, standing water, and the sensor. Check tobacco roots and lower leaves for stress before following the approved drainage and disease-management plan.",
      popupMessage: "Tobacco root-zone moisture is high. Pause irrigation and inspect drainage and standing water.",
    });
  }
  return null;
}

function lightAlert(value, temperature, thresholds) {
  const shown = fmt(value);
  if (value < CRITICAL.lightLow) {
    return makeAlert({
      metric: "lightIntensity",
      metricLabel: "Light Intensity",
      value,
      unit: " lux",
      severity: "critical",
      title: "Critical: Low Light Intensity",
      detailMessage: `Light around the tobacco crop is ${shown} lux, below the critical limit of ${CRITICAL.lightLow} lux. Prolonged severe shade can restrict photosynthesis, leaf expansion, and timely maturity.`,
      recommendedAction: "Inspect the tobacco canopy immediately for abnormal shading and verify that the light sensor is clean and unobstructed. Check current weather and growth stage before following the approved canopy-management plan.",
      popupMessage: "Light around tobacco is critically low. Check shading, weather, and sensor obstruction immediately.",
    });
  }
  if (
    value > CRITICAL.lightHigh &&
    temperature !== undefined &&
    temperature > CRITICAL.lightHighTemperature
  ) {
    return makeAlert({
      metric: "lightIntensity",
      metricLabel: "Light Intensity",
      value,
      unit: " lux",
      severity: "critical",
      title: "Critical: High Light & Heat",
      detailMessage: `Light around the tobacco crop is ${shown} lux while temperature exceeds ${CRITICAL.lightHighTemperature}\u00B0C. Combined intense sun and heat can drive rapid moisture loss, wilting, and leaf scorch.`,
      recommendedAction: "Inspect tobacco leaves immediately for wilting or sunscald. Check root-zone moisture, temperature, and both sensors before following the approved heat and irrigation plan for the current growth stage.",
      popupMessage: "Critical sun and heat stress risk for tobacco. Check wilting, scorch, moisture, and sensors now.",
    });
  }
  if (value < thresholds.minLight) {
    return makeAlert({
      metric: "lightIntensity",
      metricLabel: "Light Intensity",
      value,
      unit: " lux",
      severity: "warning",
      title: "Warning: Low Light Intensity",
      detailMessage: `Light around the tobacco crop is ${shown} lux, below the configured minimum of ${fmt(thresholds.minLight)} lux. Persistent low light may slow leaf growth and maturity.`,
      recommendedAction: "Check current cloud conditions, canopy shading, and whether the light sensor is clean and unobstructed before following the approved tobacco canopy-management plan.",
      popupMessage: "Light around tobacco is low. Check weather, canopy shading, and sensor obstruction.",
    });
  }
  if (value > thresholds.maxLight) {
    return makeAlert({
      metric: "lightIntensity",
      metricLabel: "Light Intensity",
      value,
      unit: " lux",
      severity: "warning",
      title: "Warning: High Light Intensity",
      detailMessage: `Light around the tobacco crop is ${shown} lux, above the configured maximum of ${fmt(thresholds.maxLight)} lux. Intense exposure can increase leaf heating and moisture loss.`,
      recommendedAction: "Inspect tobacco leaves for early scorch or wilting, check root-zone moisture and temperature, and verify direct sensor exposure before following the approved heat-management plan.",
      popupMessage: "Light around tobacco is high. Check leaf scorch, wilting, root-zone moisture, and sensor exposure.",
    });
  }
  return null;
}

/// Returns `undefined` for a missing metric, `null` for a normal metric, and
/// an alert object for a warning/critical metric.
function evaluateReading(reading, rawThresholds) {
  const thresholds = normalizedThresholds(rawThresholds);
  const temperature = firstNumber(reading, SENSOR_KEYS.temperature);
  const humidity = firstNumber(reading, SENSOR_KEYS.humidity);
  const moisture = firstNumber(reading, SENSOR_KEYS.soilMoisture);
  const light = firstNumber(reading, SENSOR_KEYS.lightIntensity);

  return {
    temperature:
      temperature === undefined ? undefined : temperatureAlert(temperature, thresholds),
    humidity: humidity === undefined ? undefined : humidityAlert(humidity, thresholds),
    soilMoisture:
      moisture === undefined ? undefined : moistureAlert(moisture, thresholds),
    lightIntensity:
      light === undefined ? undefined : lightAlert(light, temperature, thresholds),
  };
}

function popupBody(alert, now) {
  void now;
  return alert.popupMessage;
}

function alertCreatedAtMillis(alert) {
  return epochMillis(alert && alert.createdAt);
}

function isExpiredAlert(alert, now = Date.now()) {
  const createdAt = alertCreatedAtMillis(alert);
  return createdAt !== undefined && now - createdAt >= ALERT_RETENTION_MS;
}

function expiredAlertUpdates(rawAlerts, now = Date.now()) {
  if (!rawAlerts || typeof rawAlerts !== "object" || Array.isArray(rawAlerts)) {
    return {};
  }
  const updates = {};
  for (const [uid, userAlerts] of Object.entries(rawAlerts)) {
    if (!userAlerts || typeof userAlerts !== "object" || Array.isArray(userAlerts)) {
      continue;
    }
    for (const [alertId, alert] of Object.entries(userAlerts)) {
      if (isExpiredAlert(alert, now)) {
        updates[`${uid}/${alertId}`] = null;
      }
    }
  }
  return updates;
}

/// Pure state transition used inside an RTDB transaction.
function advanceAlertState(current, alert, {now, readingAt, eventId}) {
  if (alert === null) return {action: "clear", state: null};
  if (alert === undefined) return {action: "skip", state: current};

  const previous = current && typeof current === "object" ? current : null;
  if (
    previous &&
    Number.isFinite(Number(previous.lastReadingAt)) &&
    readingAt < Number(previous.lastReadingAt)
  ) {
    return {action: "abort", state: previous};
  }
  const readingGap = previous && Number.isFinite(Number(previous.lastReadingAt))
    ? Math.abs(readingAt - Number(previous.lastReadingAt))
    : Number.POSITIVE_INFINITY;
  const conditionChanged = !previous || previous.conditionKey !== alert.conditionKey;
  if (conditionChanged || readingGap > ONLINE_STALENESS_MS) {
    return {
      action: "claim",
      state: {
        conditionKey: alert.conditionKey,
        conditionStartedAt: now,
        nextNotificationAt: now + NOTIFICATION_INTERVAL_MS,
        lastReadingAt: readingAt,
        claimedEventId: eventId,
        claimedAt: now,
      },
    };
  }

  if (previous.claimedEventId === eventId) {
    return {action: "abort", state: previous};
  }

  if (now < Number(previous.nextNotificationAt || now + NOTIFICATION_INTERVAL_MS)) {
    return {
      action: "wait",
      state: {...previous, lastReadingAt: readingAt},
    };
  }

  return {
    action: "claim",
    state: {
      ...previous,
      nextNotificationAt: now + NOTIFICATION_INTERVAL_MS,
      lastReadingAt: readingAt,
      claimedEventId: eventId,
      claimedAt: now,
    },
  };
}

module.exports = {
  ALERT_RETENTION_HOURS,
  ALERT_RETENTION_MS,
  CRITICAL,
  DEFAULT_THRESHOLDS,
  NOTIFICATION_INTERVAL_MS,
  ONLINE_STALENESS_MS,
  advanceAlertState,
  evaluateReading,
  expiredAlertUpdates,
  isFreshReading,
  isExpiredAlert,
  popupBody,
  readingTimestamp,
  sanitizeRtdbKey,
  userKeyCandidates,
};
