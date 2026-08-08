# IoT SMART AGRICULTURE MONITORING AND CONTROLLING SYSTEM WITH AI

## Final Year Project Report

**Supervisor**  
Mr. Imran Rasheed

**Submitted by**

| Student | Registration Number |
|---|---|
| Maqsood Ahmad | 22P-WBCS-0924 |
| Zohaib Hassan | 22P-WBCS-0935 |
| Asad Ullah | 22P-WBCS-0943 |

A project report submitted in partial fulfilment of the requirements for the award of the degree of Bachelor of Science in Computer Science.

**Department of Computer Science**  
**University of Engineering & Technology, Peshawar**  
**July 2026**

---

# IoT SMART AGRICULTURE MONITORING AND CONTROLLING SYSTEM WITH AI

**Supervisor**  
Mr. Imran Rasheed

**Submitted by**

| Student | Registration Number |
|---|---|
| Maqsood Ahmad | 22P-WBCS-0924 |
| Zohaib Hassan | 22P-WBCS-0935 |
| Asad Ullah | 22P-WBCS-0943 |

A project report submitted in partial fulfilment of the requirements for the award of the degree of Bachelor of Science in Computer Science.

**Department of Computer Science**  
**University of Engineering & Technology, Peshawar**  
**July 2026**

---

# Project Approval

This is to certify that the project titled **“IoT Smart Agriculture Monitoring and Controlling System with AI”** is approved and recommended as partial fulfilment of the requirements for the award of the degree of Bachelor of Science in Computer Science from the University of Engineering & Technology, Peshawar.

| Role | Name | Signature |
|---|---|---|
| Project Supervisor | Mr. Imran Rasheed | ____________________ |
| Chairperson | ____________________ | ____________________ |

---

# Undertaking

We certify that the project work titled **“IoT Smart Agriculture Monitoring and Controlling System with AI”** is our own work. No portion of this work has been submitted in support of another award or qualification at this institution or elsewhere. Material obtained from other sources has been acknowledged through citations and references.

| Student | Registration Number | Signature |
|---|---|---|
| Maqsood Ahmad | 22P-WBCS-0924 | ____________________ |
| Zohaib Hassan | 22P-WBCS-0935 | ____________________ |
| Asad Ullah | 22P-WBCS-0943 | ____________________ |

---

# Acknowledgements

We are grateful to our supervisor, Mr. Imran Rasheed, for his direction, critical feedback, and encouragement throughout the project. His guidance helped us turn an initially broad idea about smart agriculture into a testable software and IoT architecture.

We also thank the faculty of the Department of Computer Science, University of Engineering & Technology, Peshawar, for the technical foundation provided during our degree. We acknowledge the published work of agricultural researchers and institutions, particularly the Pakistan Tobacco Board and the Food and Agriculture Organization, whose material helped us understand the sensitivity of tobacco to temperature and water conditions. Finally, we thank our families and friends for their patience, moral support, and encouragement during the design, implementation, testing, and documentation of this project.

---

# Abstract

Agricultural decisions are often made from periodic field inspection and personal experience, even though soil and environmental conditions can change between visits. This problem is especially relevant to tobacco cultivation because both moisture deficit and excessive water can affect leaf development and quality. This project presents AgriSenseAI, a mobile and cloud-based monitoring system designed around a low-cost ESP32 sensor node and a Flutter application. The implemented system receives temperature, relative humidity, soil-moisture, and light-intensity readings through Firebase Realtime Database, displays the latest field condition, preserves historical samples for analytics, and supports authenticated remote pump control.

The software uses a layered feature architecture in Flutter, Firebase Authentication for Google sign-in, Firebase Realtime Database for synchronized current and historical records, Firebase Cloud Messaging for remote notification delivery, and Node.js Cloud Functions for server-side threshold evaluation. Farmers can configure normal ranges for each monitored variable. Values outside these ranges produce warning messages, while fixed outer limits produce critical alerts. Alert processing remains available when the mobile application is not open because history-triggered and scheduled Cloud Functions evaluate fresh readings and send notifications through Firebase Cloud Messaging. Stored alert records are retained for eight hours, and repeated notifications are controlled through transactional state and a five-minute interval. The dashboard determines device availability from the age of the latest timestamp rather than trusting a persistent Boolean flag; timestamps supplied in Unix seconds or milliseconds are normalized before the comparison.

Repository-level verification found no static-analysis issues. Fourteen backend tests passed, covering threshold classification, recipient identity, timestamp normalization, repeat scheduling, tobacco-oriented guidance, and alert cleanup. In the Flutter suite, 124 tests passed and four local-monitor tests failed because their simulated 20-second heartbeat exceeds the current 15-second freshness window; this discrepancy is documented rather than hidden. The present prototype therefore demonstrates a working Firebase-centred monitoring, analytics, notification, and control platform. It uses deterministic, agronomy-informed rules rather than a trained machine-learning model; predictive AI, Bluetooth provisioning, multi-field deployment, and field calibration remain future work.

**Keywords:** Internet of Things, smart agriculture, ESP32, Flutter, Firebase Realtime Database, Firebase Cloud Messaging, tobacco monitoring, sensor analytics, threshold alerts.

---

# Table of Contents

1. Introduction  
2. Background and Literature Survey  
3. Requirements  
4. Analysis and Design  
5. Implementation and Testing  
6. Conclusion  
7. Future Recommendations  
Appendix A: Requirements Traceability  
Appendix B: Database and Message Schemas  
Appendix C: Glossary  
References

# List of Figures

1. High-level AgriSenseAI system architecture  
2. End-to-end sensor data flow  
3. Mobile application feature architecture  
4. Device-status state transition  
5. Server-side alert processing sequence  
6. Application startup and authentication flow

# List of Tables

1. Literature comparison and identified gap  
2. Functional requirements  
3. Non-functional requirements  
4. Implemented and deferred scope  
5. Default normal ranges and fixed critical limits  
6. Principal software technologies  
7. Verification results  
8. Requirements traceability matrix

# Abbreviations

| Abbreviation | Meaning |
|---|---|
| AI | Artificial Intelligence |
| API | Application Programming Interface |
| BLE | Bluetooth Low Energy |
| FCM | Firebase Cloud Messaging |
| FYP | Final Year Project |
| IoT | Internet of Things |
| JSON | JavaScript Object Notation |
| MCU | Microcontroller Unit |
| ML | Machine Learning |
| RTDB | Firebase Realtime Database |
| SDK | Software Development Kit |
| UI | User Interface |
| UID | Firebase Authentication User Identifier |

---

# Chapter 1: Introduction

## 1.1 Background

Agriculture depends on decisions that are both local and time-sensitive. A farmer may irrigate, inspect a crop, or operate field equipment based on conditions observed during a visit, but temperature, humidity, soil moisture, and light can change before the next inspection. The Internet of Things offers a practical way to reduce this information gap. Sensors can measure field conditions, a microcontroller can publish the readings, a cloud service can synchronize them, and a mobile application can present the information in a form that supports timely action.

Systematic reviews describe IoT-based agriculture as an interaction between sensing devices, communication networks, data storage, analytics, and user-facing applications [1], [2], [14]. The value of this arrangement is not merely that a number appears on a phone. A useful system must preserve the measurement time, identify stale data, separate abnormal conditions from normal variation, and communicate risk without overwhelming the farmer. Mobile applications are particularly suitable as the final user interface because they can combine remote monitoring, alerts, historical charts, and control functions in a device already familiar to many users [3].

The project focuses on tobacco fields in Khyber Pakhtunkhwa. Tobacco has crop-stage-dependent water needs. The Food and Agriculture Organization notes that both water deficit during important growth stages and excessive irrigation can reduce leaf quality, while prolonged waterlogging may severely damage plants [4]. A Pakistan Tobacco Board research plan similarly describes tobacco as sensitive to very high temperature and emphasizes deliberate irrigation scheduling rather than continuous watering [5]. These observations support a monitoring-and-advisory design: the system should make changing conditions visible, warn when a configured range is crossed, and keep the farmer responsible for the final agronomic decision.

AgriSenseAI was therefore developed as an IoT monitoring and controlling prototype. An ESP32-side data producer writes sensor samples to Firebase. The Flutter mobile application authenticates the user, listens to the latest record, visualizes historical records, manages alert thresholds, displays warning and critical events, and writes a pump command to an authenticated database path. Cloud Functions evaluate readings independently of the application process and use FCM for remote delivery.

The title retains “with AI” because that is the approved FYP title and the architecture is intended to accept a future predictive component. The implemented decision support is currently rule-based. It does not train, evaluate, or deploy a machine-learning model, and this report does not describe threshold comparisons as artificial intelligence. This distinction is important for technical accuracy.

## 1.2 Problem Statement

Small agricultural deployments need timely field information but face cost, connectivity, usability, and reliability constraints. Manual inspection provides only a snapshot and may miss a developing moisture or heat problem. A simple cloud dashboard, however, can also be misleading if it presents an old measurement as current, sends duplicate notifications for the same persistent condition, exposes one farmer’s data to another, or stops monitoring as soon as the mobile application is closed.

The specific problem addressed in this project is the absence of a single low-cost application that can:

- present current tobacco-field readings with an explicit indication of freshness;
- organize historical readings into understandable day, week, and month views;
- permit farmer-adjustable warning ranges while preserving fixed critical boundaries;
- deliver threshold alerts when the application is backgrounded or terminated normally;
- associate cloud access and pump commands with an authenticated identity; and
- remain modular enough for later sensor, crop, and predictive-model extensions.

## 1.3 Research Questions

This project is guided by the following questions:

1. How can an ESP32, a real-time cloud database, and a Flutter application be integrated into a responsive monitoring system for a tobacco field?
2. How can the application distinguish a genuinely offline sensor node from delayed initialization or an old cached value?
3. How can warning and critical conditions be evaluated and delivered when the mobile application is not running in the foreground?
4. How can historical readings be transformed into useful mobile analytics without assuming that every sensor value is present?
5. How can user identity, configurable thresholds, alert history, and remote pump state be organized without tightly coupling the presentation layer to Firebase?

## 1.4 Objectives

The principal objective is to design and implement a working prototype for real-time tobacco-field monitoring and remote interaction. The supporting objectives are:

- to integrate temperature, humidity, soil-moisture, and light-intensity readings produced by an ESP32-side sensor system;
- to store a current snapshot and timestamped history in Firebase Realtime Database;
- to implement authenticated Google sign-in and session-aware navigation;
- to display live readings, a clear device-status state, and rule-based smart actions;
- to calculate day, week, and month analytics from historical records;
- to support configurable minimum and maximum normal ranges;
- to classify outer-range measurements as warning or critical events;
- to deliver alerts through a backend path that does not depend on the Flutter process remaining open;
- to synchronize a pump-control Boolean through an authenticated RTDB path; and
- to verify the design with static analysis and automated tests.

## 1.5 Scope

The implemented scope includes a Flutter mobile application, Firebase Authentication, Firebase Realtime Database integration, live and historical sensor presentation, device freshness calculation, threshold configuration, server-side notification processing, FCM registration and delivery, eight-hour alert history, and remote pump-state synchronization. Tobacco is the selected crop, and the current schema represents one farm and field per resolved sensor account.

The current repository does not contain ESP32 firmware, Bluetooth pairing, Wi-Fi provisioning UI, a trained AI/ML model, disease detection, multilingual resources, or a production-scale multi-farm administration portal. Earlier proposal and design documents discuss several of these features. They are treated as deferred work, not as implemented results.

## 1.6 Contributions

The project makes the following engineering contributions:

1. A repository-pattern Flutter application that separates entities, data models, data sources, repositories, providers, and widgets by feature.
2. A freshness-based device-status model with `unknown`, `loading`, `online`, `offline`, and `error` states, avoiding a false offline state during startup.
3. Timestamp normalization that accepts Unix seconds and Unix milliseconds before device-age comparison.
4. One configurable threshold profile shared by the mobile settings interface and server-side alert registration.
5. A backend notification workflow with authenticated recipients, transactional repeat state, invalid-token cleanup, and eight-hour alert retention.
6. Historical analytics that tolerate missing fields and update from RTDB streams.
7. An explicit separation between what is implemented, what is only proposed, and what requires field validation.

## 1.7 Thesis Organization

Chapter 2 explains the technologies and reviews related work. Chapter 3 converts the project scope into functional and non-functional requirements. Chapter 4 describes the architecture, data model, status calculation, alert design, and security decisions. Chapter 5 presents the implementation and the actual verification results. Chapter 6 concludes the work, and Chapter 7 gives technically realistic future recommendations. The appendices provide traceability, schemas, and terminology.

---

# Chapter 2: Background and Literature Survey

## 2.1 Introduction

AgriSenseAI combines embedded sensing, cloud synchronization, mobile software, and event-driven backend logic. This chapter establishes the concepts needed to understand those components and compares the project with relevant agricultural IoT literature.

## 2.2 IoT Architecture for Agriculture

A common agricultural IoT architecture contains a perception layer, a communication layer, a processing or cloud layer, and an application layer [1], [2]. The perception layer measures physical variables. The communication layer moves those readings through Wi-Fi, cellular, LoRa, BLE, or another protocol. The processing layer stores, aggregates, or evaluates data. The application layer exposes results to a farmer, operator, or researcher.

AgriSenseAI follows this general model. Environmental and soil sensors form the perception layer. The ESP32 is the field controller and Wi-Fi endpoint. Firebase provides synchronized storage and server-side events. Flutter provides the user interface. This separation is useful because no single component is required to perform every responsibility: the ESP32 publishes measurements, RTDB distributes them, Cloud Functions evaluate durable alert logic, and the phone focuses on interaction and visualization.

## 2.3 ESP32 and Field Sensors

The ESP32 is appropriate for low-cost IoT prototyping because it combines a microcontroller with Wi-Fi and Bluetooth capabilities. In the present system it is treated as the producer of JSON-compatible sensor readings. Four logical measurements are consumed by the application: air temperature in degrees Celsius, relative humidity in percent, soil moisture in percent, and light intensity in lux. Each record also requires a timestamp.

Low-cost sensors introduce limitations that software cannot remove. Soil probes may respond to soil composition and placement; light sensors require correct units and exposure; temperature and humidity sensors can be affected by direct radiation and enclosure design. The checked-in sample contains light values around 90 lux, while the configured agricultural normal range starts at 45,000 lux. That difference may indicate indoor testing, unit conversion, sensor selection, or calibration. Consequently, the system reports the measurement but cannot claim agronomic accuracy without calibration against reference instruments.

## 2.4 Firebase Realtime Database

Firebase Realtime Database is a cloud-hosted NoSQL database in which clients listen to paths and receive snapshots when data changes. Firebase recommends listeners for data that should remain current and a one-time `get()` when a single snapshot is needed [6]. Its mobile SDK can persist synchronized data locally, making previously loaded data available across temporary interruptions and application restarts [7].

These properties match the project’s need for current and historical data, but they also create a design obligation: cached data must not automatically be treated as fresh. AgriSenseAI compares the stored reading timestamp with the current time. The current node supports the dashboard, while the history node supports analytics and backend event processing. Listeners are attached to the narrowest relevant path rather than to the database root.

## 2.5 Flutter Mobile Architecture

Flutter supports a single Dart codebase for multiple mobile platforms. The project uses Provider for presentation state, GetIt for dependency injection, and GoRouter for navigation. Its feature structure resembles clean architecture: domain entities and repository interfaces do not directly depend on screen widgets, while Firebase-specific mapping remains in data sources. Flutter’s architecture guidance recommends repositories as the source of truth for distinct data types [8], a principle followed for Home, Analytics, Alerts, Settings, Authentication, Profile, and Onboarding.

## 2.6 Notifications Beyond the Application Process

A foreground database listener cannot guarantee an alert after the operating system terminates the application process. Cloud Functions can react to RTDB creation or update events without a client being open [9]. FCM then carries the notification to registered devices. Firebase documents different foreground, background, and terminated states and notes that the user must grant permission and open the app at least once for registration; platform force-stop behaviour is outside application control [10].

AgriSenseAI therefore evaluates remote alerts in Cloud Functions. The mobile application registers a token and its threshold preferences, but the event is generated on the backend. Foreground messages are displayed through the local-notification plugin for consistent UI behaviour. A scheduled function covers continuing conditions, and another scheduled function deletes expired alerts.

## 2.7 Tobacco Monitoring Context

Tobacco irrigation cannot be reduced to “more water is better.” FAO material describes changing water demand across crop stages, damage from waterlogging, and possible benefits of moderate deficit during early root development [4]. Pakistan Tobacco Board material reports an optimum germination temperature near 28°C, germination over a wider range, and wilting risk above approximately 35°C [5]. These sources justify monitoring and caution, but they do not justify a universal automatic irrigation command. Soil type, crop stage, weather, variety, sensor placement, and local expert advice still matter.

For that reason, AgriSenseAI uses thresholds as an advisory layer. Messages tell the user to inspect the field and verify the sensor before following an approved irrigation or crop-management plan. The application includes manual pump control, but threshold evaluation does not automatically energize the pump.

## 2.8 Related Work

Pathmudi et al. reviewed sensors, controllers, communication standards, data storage, and analytics across sustainable agricultural IoT systems [1]. Their work shows that the technological value lies in the complete pipeline rather than in a sensor alone. Quy et al. organized smart-agriculture systems around devices, communication, storage, and data processes, while also identifying connectivity, security, and scalability as continuing challenges [2].

Mendes et al. reviewed smartphone applications for precision agriculture and found that mobile tools can centralize monitoring, alerts, and field tasks, but usefulness is limited when essential actions depend on unavailable connectivity [3]. Vallejo-Gómez et al. found that embedded systems, IoT, fuzzy logic, and machine learning are recurring technologies in smart irrigation. They also emphasized that data-intensive models require a sufficiently large and robust dataset [11]. This observation supports the decision not to claim an ML result from the project’s small prototype dataset.

A tobacco-specific system by Liana, Al Rasyid, and Setiawardhana combined temperature, moisture, pH, Firebase, and Mamdani fuzzy logic for drip irrigation. Their experimental system reported lower water consumption than manual watering [12]. It demonstrates the potential of crop-specific control but differs from AgriSenseAI in its control algorithm and deployment context. AgriSenseAI emphasizes authenticated mobile monitoring, configurable alerts, historical analytics, and backend delivery; it has not yet performed a comparative water-use experiment.

An IITM low-cost monitoring study reported strong correlation between its soil-moisture profile and gravimetric observations and presented a pipeline from field sensing to a mobile data server [13]. Its calibration-focused result highlights an important gap in this FYP: software correctness has been tested, but the physical sensor package still requires controlled calibration and field evaluation.

## 2.9 Literature Comparison and Gap Analysis

| Work | Main contribution | Limitation relative to this project | Relevance |
|---|---|---|---|
| Pathmudi et al. [1] | Systematic review of IoT components for sustainable agriculture | Review rather than an end-user implementation | Supports layered IoT architecture |
| Quy et al. [2] | Architecture, applications, and challenges across smart agriculture | Broad domain; not tobacco- or application-specific | Supports device–network–cloud–application separation |
| Mendes et al. [3] | Review of agricultural smartphone applications | Does not provide this project’s sensor/backend implementation | Supports farmer-facing mobile access |
| Vallejo-Gómez et al. [11] | Review of IoT and intelligent irrigation methods | Focuses irrigation literature rather than secure FCM workflow | Supports monitoring and cautions about ML data needs |
| Liana et al. [12] | Tobacco-specific fuzzy irrigation with Firebase | Different hardware/control stack and regional experiment | Closest tobacco IoT comparison |
| Deshpande et al. [13] | Low-cost soil monitoring with field calibration | Raspberry Pi-based and fewer application functions | Establishes importance of sensor validation |

The identified gap is not the absence of all smart-agriculture systems. Many prototypes already monitor moisture and temperature. The practical gap addressed here is the combination of tobacco-oriented messaging, explicit device freshness, authenticated Flutter presentation, current/history separation, configurable ranges, server-generated push alerts, bounded alert history, and transparent handling of missing data in one student-scale architecture. The project does not close the separate research gaps of calibrated field accuracy or learned prediction; those require additional experiments and data.

## 2.10 Chapter Summary

Agricultural IoT research supports layered sensor-to-application systems and demonstrates the value of mobile monitoring. It also shows that connectivity, calibration, secure access, alert reliability, and sufficient training data remain significant. AgriSenseAI adopts established architectural patterns while concentrating its contribution on a coherent, testable Firebase and Flutter implementation for tobacco monitoring.

---

# Chapter 3: Requirements

## 3.1 Introduction

The original project SRS defined a broad offline-and-online agricultural platform [15]. During implementation, the project converged on a Firebase-first prototype. This chapter records the requirements of the implemented baseline and identifies proposal items that remain deferred. This prevents a planned feature from being mistaken for a tested feature.

## 3.2 Stakeholders and User Characteristics

The primary user is a tobacco farmer or field operator with basic smartphone experience. The user needs a small number of clearly labelled screens, visible units, readable alerts, and straightforward control feedback. The project supervisor and evaluators are academic stakeholders concerned with correctness, scope, and evidence. Developers and administrators maintain Firebase configuration, deploy backend functions, manage device-to-account provisioning, and diagnose sensor or notification failures.

## 3.3 Functional Requirements

| ID | Requirement | Current status |
|---|---|---|
| FR-01 | The system shall authenticate a user through Google and Firebase Authentication. | Implemented |
| FR-02 | The application shall restore the authenticated session and route signed-in users past the login screen. | Implemented |
| FR-03 | The ESP32-side producer shall publish temperature, humidity, soil moisture, light, and a timestamp to the agreed RTDB schema. | Schema consumed; firmware outside repository |
| FR-04 | The application shall read the existing current snapshot and then listen for subsequent changes. | Implemented |
| FR-05 | Before a valid timestamp is available, the UI shall show a checking state rather than Offline. | Implemented |
| FR-06 | A reading no older than the configured 15-second timeout shall be Online; an older valid reading shall be Offline. | Implemented |
| FR-07 | Unix-second and Unix-millisecond timestamps shall be normalized before comparison. | Implemented |
| FR-08 | The dashboard shall show the four sensor values with units and status colours. | Implemented |
| FR-09 | The application shall generate deterministic smart-action text from the latest readings and configured ranges. | Implemented |
| FR-10 | The user shall view historical values over day, week, and month ranges. | Implemented |
| FR-11 | Analytics shall tolerate missing values without failing the whole dashboard. | Implemented |
| FR-12 | The user shall configure minimum and maximum normal ranges for all four measurements. | Implemented |
| FR-13 | The backend shall classify configured-range deviations as warnings and fixed-envelope deviations as critical events. | Implemented |
| FR-14 | Remote alerts shall work without relying on an open Flutter screen. | Implemented through Cloud Functions and FCM |
| FR-15 | Persistent abnormal conditions shall be eligible for a repeat alert every five minutes while fresh data continues. | Implemented |
| FR-16 | Alert records older than eight hours shall be excluded and deleted by scheduled cleanup. | Implemented |
| FR-17 | Alerts shall be filterable by All, Critical, and Warning. | Implemented |
| FR-18 | The user shall be able to write and observe pump state through an authenticated path. | Implemented |
| FR-19 | The application shall provide onboarding, profile, settings, and sign-out flows. | Implemented |
| FR-20 | The mobile application shall pair and synchronize directly over BLE. | Deferred |
| FR-21 | A trained AI/ML model shall produce predictive crop recommendations. | Deferred |

## 3.4 Non-Functional Requirements

| ID | Requirement | Design response |
|---|---|---|
| NFR-01 | Usability | Responsive cards, plain labels, units, severity filters, and explicit loading/error states |
| NFR-02 | Reliability | RTDB listeners, one-time current read, last-good analytics preservation, scheduled backend checks |
| NFR-03 | Security | Firebase Authentication, UID-scoped rules, recipient identity verification, authenticated pump path |
| NFR-04 | Maintainability | Feature modules, repository interfaces, dependency injection, shared threshold service |
| NFR-05 | Performance | Narrow RTDB listeners, cached recipient identity, bounded local alert list, queried history window |
| NFR-06 | Scalability | User/farm/field hierarchy and server-side token batching, with current single-field provisioning limitation |
| NFR-07 | Data integrity | Timestamped history, seconds/milliseconds normalization, stale and out-of-order protection |
| NFR-08 | Safety | Advisory recommendations; no automatic threshold-to-pump activation |
| NFR-09 | Portability | Flutter Android/iOS project structure, subject to platform notification configuration |
| NFR-10 | Testability | Injectable services, fakes, unit/integration/widget tests, pure JavaScript alert logic |

## 3.5 Use Cases

### 3.5.1 Sign in and restore a session

The user opens the application. Firebase initializes before dependent services. The authentication provider observes Firebase Auth state. A new user sees onboarding and Google sign-in; an authenticated user is redirected to the main navigation area after the splash screen.

### 3.5.2 Monitor the field

After authentication resolves, the Home data source derives candidate sensor-account keys from the verified user identity. It restores a locally cached last status, performs a one-time read of the current node, attaches one live listener, and calculates status from `updatedAt`. The dashboard shows the latest values and rule-based guidance.

### 3.5.3 Review analytics

The user opens Analytics and chooses Day, Week, or Month. Historical samples are streamed from the history node. Values are bucketed and averaged; missing fields are skipped. The user sees combined metric lines and summary values.

### 3.5.4 Change alert ranges

The user adjusts minimum and maximum values in Settings. The shared threshold service validates order and presentation bounds, saves committed values in secure local storage, and the push service synchronizes the ranges to the user’s notification registration.

### 3.5.5 Receive and review an alert

When a fresh history record is created, a Cloud Function evaluates it for each authenticated recipient associated with that sensor account. A claimed alert is saved under the recipient UID and sent through FCM. The Alerts screen merges remote and local records, removes expired entries, groups them by date, and applies the selected severity filter.

### 3.5.6 Control the pump

An online user opens Pump Control and chooses On or Off. The provider updates the UI optimistically and writes the Boolean to the UID-scoped control path. A live listener confirms changes. If the write fails, the provider rolls back to the latest Firebase value and presents an error.

## 3.6 Implemented and Deferred Scope

| Area | Implemented baseline | Deferred extension |
|---|---|---|
| Communication | ESP32-to-RTDB schema over an external Wi-Fi producer | BLE sync and in-app Wi-Fi provisioning |
| Decision support | Configurable deterministic ranges and fixed critical limits | Trained predictive model and validated crop-stage recommendations |
| Deployment | One resolved sensor account, farm, and field | Device enrollment and multi-farm administration |
| Language | English interface | Urdu and Pashto localization |
| Sensors | Temperature, humidity, soil moisture, light | pH, EC, NPK, rainfall, and calibrated weather station |
| Automation | Manual authenticated pump command | Closed-loop irrigation with safety interlocks |
| Evaluation | Automated software verification and sample RTDB data | Seasonal field trial, farmer study, and calibrated hardware experiment |

## 3.7 Constraints and Assumptions

The system assumes that the ESP32-side producer writes a valid timestamp and uses the configured field path. The 15-second online timeout only makes sense when the actual write interval is at most 15 seconds; a slower firmware cadence will correctly appear stale under this policy. Remote notifications require Firebase deployment, a valid FCM token, user permission, and platform setup. iOS requires an APNs key. Android force-stop and iOS swipe-away behaviour can suspend delivery until the application is reopened [10]. Cloud Functions deployment also requires the appropriate Firebase billing plan.

The system assumes thresholds have been reviewed for the actual field and sensor units. Default ranges are software defaults, not a substitute for agronomic advice or hardware calibration.

---

# Chapter 4: Analysis and Design

## 4.1 Architectural Overview

The architecture deliberately separates the device data path, application path, and server notification path.

```text
Field sensors
     |
     v
ESP32 sensor node ---- Wi-Fi/HTTPS ----> Firebase Realtime Database
                                             | current snapshot
                                             | timestamped history
                    +------------------------+------------------------+
                    |                                                 |
                    v                                                 v
             Flutter mobile app                               Cloud Functions
      Home / Analytics / Settings / Alerts           evaluate / schedule / clean up
                    |                                                 |
                    +---- authenticated pump write                    v
                                                              Firebase Cloud Messaging
                                                                       |
                                                                       v
                                                              Farmer's mobile device
```

**Figure 1: High-level AgriSenseAI system architecture**

The Flutter side is divided into core services and feature modules. Core services own authentication, RTDB access, local secure storage, notifications, network state, logging, and threshold settings. Each main feature follows an entity → model → data source → repository → provider → screen/widget direction. Dependency registration is centralized through GetIt.

```text
Presentation: Screen + Widgets <---- Provider
                                      |
Domain:                         Repository interface + Entities
                                      |
Data:                         Repository implementation
                               /                       \
                      Remote data source          Local data source
                               |                       |
                      Firebase services         Secure/local fixtures
```

**Figure 2: Mobile feature architecture**

## 4.2 Data Model

The primary sensor hierarchy is:

```text
users/{sensorUserKey}/farms/{farmKey}/fields/{fieldKey}/
    current/
        temperatureC
        humidityPercent
        soilMoisturePercent
        lightLux
        updatedAt
    history/{epochMilliseconds}/
        temperatureC
        humidityPercent
        soilMoisturePercent
        lightLux
        timestamp
```

The current node minimizes dashboard reads. History stores immutable time-series samples and is the event source for alert creation. Separating them avoids scanning history merely to render the latest card.

Notification registrations use `notificationRecipients/{sensorUserKey}/{uid}`. The record includes an enabled flag, the eight configured thresholds, and one or more platform tokens. Server-produced alerts use `notificationAlerts/{uid}/{alertId}`. Per-metric transactional state is held below `notificationAlertStates` to prevent duplicate claims and track the next eligible notification time.

Pump state uses `users/{auth.uid}/device/controls/pumpStatus`. This is intentionally keyed by authenticated UID even when legacy sensor telemetry is resolved through the local part of an email address.

## 4.3 Identity and Access Design

Google sign-in returns an identity that Firebase Authentication converts into an authenticated session. The application observes auth-state changes instead of storing a parallel login Boolean as the authority. Candidate sensor keys are generated from the email local part, UID, sanitized full email, and phone number. The current implementation checks only identity-derived candidates; it does not silently fall back to another user’s field.

RTDB rules allow a user to read and write their UID branch, register notification preferences only for their UID, and read server-written alerts only under their UID. Client writes to `notificationAlerts` are denied. The Cloud Function further retrieves the Firebase Auth record and confirms that the sensor account key is one of the verified identity-derived candidates before sending an alert. This is defence in depth, although a production device-link table would be more flexible than identity-derived mapping.

## 4.4 Device-Status Design

The hardware’s `deviceOnline` Boolean is not accepted as the final truth because a device that loses power cannot write `false`. Instead, the application uses the latest valid timestamp.

Let `t_now` be the current time in milliseconds and `t_reading` be the normalized reading timestamp. With timeout `T = 15,000 ms`:

```text
age = t_now - t_reading

0 <= age <= T  => Online
age > T         => Offline
no valid value  => Unknown/Loading or Error, not Offline
```

A small future-clock tolerance handles limited clock skew. Numeric timestamps below `100000000000` are treated as Unix seconds and multiplied by 1,000; larger values are treated as milliseconds.

```text
App start -> Unknown -> Loading -> Online
                         |          |
                         |          +-- age exceeds 15 s --> Offline
                         |
                         +-- valid old timestamp ----------> Offline
                         +-- Firebase failure -------------> Error
```

**Figure 3: Device-status state transition**

The startup sequence restores the last valid status from secure storage, validates its timestamp, performs a one-time current read, and then attaches the live listener. A cached Online value is never shown after it has aged past the timeout. A ten-second refresh timer re-evaluates age even when Firebase emits no new event. Authentication changes cancel old subscriptions and bind a new user exactly once.

## 4.5 Threshold and Advisory Design

The system uses configurable normal ranges inside fixed critical envelopes.

| Metric | Default normal range | Fixed critical low | Fixed critical high |
|---|---:|---:|---:|
| Temperature | 20–30°C | below 10°C | above 36°C |
| Relative humidity | 60–75% | below 40% | above 85% |
| Soil moisture | 60–85% | below 50% | above 90% |
| Light intensity | 45,000–70,000 lux | below 20,000 lux | above 90,000 lux with temperature above 35°C |

Critical limits are evaluated before user-configured warning limits. A value within the configured range is normal. A value outside that range but inside the critical envelope is a warning. A value beyond the outer envelope is critical. The high-light critical condition also checks temperature, reducing the chance that light alone is described as combined light-and-heat stress.

Every alert contains the sensor name, current value, severity, threshold, detailed explanation, timestamp, and an action that asks the farmer to inspect the crop and verify the reading. This wording is deliberately advisory. It avoids presenting a generic threshold as a guaranteed agronomic diagnosis.

## 4.6 Alert Processing Design

```text
ESP32 creates history record
        |
        v
RTDB onValueCreated function validates record freshness
        |
        v
Load enabled recipients and verify Firebase identity
        |
        v
Evaluate four metrics against recipient thresholds
        |
        v
Transaction claims per-user/per-field/per-metric event
        |
        +---- no claim / normal / stale ----> stop
        |
        v
Persist alert -> send FCM multicast -> remove invalid tokens
```

**Figure 4: Server-side alert processing sequence**

The history trigger handles new readings immediately. A scheduled function runs every five minutes and inspects fresh current records so a condition can repeat while it remains active. State transactions protect against concurrent duplicate delivery, reject out-of-order readings, and record the next eligible time. FCM batches are limited to 500 tokens. A cleanup function runs every 15 minutes and removes alert records at or beyond the eight-hour retention boundary.

The client registers tokens after notification permission and authentication are available. It debounces threshold synchronization for 500 milliseconds so a slider does not write every intermediate frame. Foreground FCM messages are displayed through the local plugin and recorded in the local alert store. The Alerts data source then deduplicates local and remote representations.

## 4.7 Analytics Design

Analytics listens only to history. Day uses a rolling 24-hour window, Week aligns buckets with calendar days, and Month shows samples from the available current year. Each metric is extracted independently so a missing light value does not discard temperature from the same sample. Empty or one-point series are converted into safe chart inputs. Average cards show `--` when no value exists.

The combined chart normalizes each metric to preserve visibility even when one unit, such as lux, has a much larger numeric scale than percentages or degrees. A separate rounded light-axis maximum is calculated for readable labelling. The provider keeps the last good dashboard if a later stream error occurs, while a first-load error produces a retryable state.

## 4.8 Pump-Control Design

Pump control is manual. The provider first updates the visible state so the interaction feels immediate, then performs the Firebase write. The live database stream remains authoritative. If the write throws an exception, the provider restores the last confirmed value. The button is disabled when the sensor device is not Online, reducing the likelihood that a user sends a command while field telemetry is stale. This is a UI safety measure, not proof that the physical relay acted; hardware feedback would be required for closed-loop confirmation.

## 4.9 Startup Flow

```text
Process starts
  -> initialize Flutter binding
  -> initialize Firebase
  -> register FCM background handler
  -> register dependencies
  -> load stored thresholds and alerts
  -> initialize notification presentation
  -> start FCM registration service
  -> run application
  -> resolve Firebase Authentication state
  -> route to onboarding/authentication or main navigation
  -> bind feature streams for authenticated user
```

**Figure 5: Application startup and authentication flow**

Ordering matters. Firebase-dependent services are not started before Firebase initialization, and user-specific paths are not built before the auth session resolves.

## 4.10 Design Limitations

The database rules reveal a transitional identity model: sensor data may be stored below an email-derived key, whereas general user controls use UID. Production deployment should replace this with an explicit server-managed device link. Threshold values are not crop-stage-aware. RTDB is suitable for the prototype, but long-term high-frequency history may require retention, aggregation, pagination, or a time-series store. Scheduled Cloud Functions and FCM are not hard real-time systems; delivery depends on cloud scheduling, network state, platform policy, and device permission.

---

# Chapter 5: Implementation and Testing

## 5.1 Development Environment and Technologies

| Component | Technology and role |
|---|---|
| Mobile framework | Flutter with Dart 3.11 environment |
| State management | Provider/ChangeNotifier |
| Dependency injection | GetIt |
| Navigation | GoRouter |
| Authentication | Firebase Authentication and Google Sign-In |
| Live storage | Firebase Realtime Database |
| Push delivery | Firebase Cloud Messaging |
| Backend | Firebase Cloud Functions v2, Node.js 20 |
| Local persistence | Flutter Secure Storage and RTDB disk persistence |
| Notifications | Flutter Local Notifications |
| Connectivity and background support | Connectivity Plus, Workmanager, platform permissions |
| Testing | Flutter Test, Integration Test package, Node built-in test runner |

The repository contains 191 Dart source files and approximately 15,782 lines under `lib`. Feature modules include Alerts, Analytics, Authentication, Home, Navigation, Profile, Settings, and Splash/Onboarding. The test tree contains 42 Dart files and approximately 3,717 lines. These counts describe the inspected repository state and exclude generated build and dependency directories.

## 5.2 Mobile Initialization

The entry point awaits Firebase initialization before dependency registration. It registers the top-level FCM background handler, loads persisted thresholds before notification services use them, restores the local alert cache, initializes foreground notification presentation, requests notification permission, and starts push registration. The application then creates one router connected to the authentication session provider.

## 5.3 Home Dashboard Implementation

The Home remote data source coordinates current readings and pump state through a broadcast stream. When a user becomes available, it increments a binding generation, cancels old subscriptions, restores validated cached status, resolves the sensor key, starts the pump listener, reads the existing current value once, and then starts the current listener. Generation checks prevent a slow operation for an old account from binding after the user changes.

The mapped dashboard contains greeting text, field name, connection status, smart action, four sensor cards, pump state, and device-status enum. Values are rounded consistently before display and advisory comparison. The provider subscribes once, cancels the subscription on disposal, preserves the Firebase-confirmed pump state during optimistic updates, and guards asynchronous callbacks after disposal.

## 5.4 Analytics Implementation

The Analytics data source requests only history records and rebuilds the selected periods whenever the RTDB query changes. Metric specifications centralize extraction labels, units, colours, and average labels. Bucket-building functions sort samples, ignore null values, and generate safe points. Presentation widgets provide range tabs, a combined line chart, and average cards.

## 5.5 Settings and Local Persistence

`ThresholdSettingsService` is the in-memory authority for the eight range values. It loads and saves through `LocalStorageService`, normalizes reversed ranges, clamps values to presentation bounds, and notifies listeners. Slider movement updates memory without persistent writes; release commits the range. Settings also controls the push-enabled preference and can clear local settings and alert data without deleting authentication state.

## 5.6 Backend Implementation

The Node.js backend exposes three functions:

1. `sendSensorAlerts`, an RTDB history-creation trigger;
2. `checkCurrentSensorAlerts`, a five-minute scheduled condition check; and
3. `cleanupExpiredAlerts`, a fifteen-minute scheduled retention task.

Pure functions in `alert_logic.js` parse aliases, normalize timestamps, evaluate thresholds, build tobacco-specific messages, advance notification state, and calculate cleanup updates. Keeping this logic independent of the Firebase SDK makes it directly testable. Cloud resources are configured for the `asia-southeast1` region to align with the RTDB instance.

## 5.7 Testing Strategy

The repository uses several testing levels:

- unit tests for constants, timestamp freshness, threshold services, repositories, providers, and pure backend logic;
- widget tests for visible content, tab selection, buttons, filters, charts, and cards;
- integration-style tests for feature flows using fake repositories and data sources; and
- static analysis using the Dart analyzer and project lint rules.

Tests avoid toggling the real pump. Firebase-facing behaviour is represented through interfaces and fakes where a real backend is not appropriate.

## 5.8 Verification Results

The following commands were executed against the inspected working tree on 14 July 2026.

| Verification | Result | Interpretation |
|---|---:|---|
| Direct Dart static analysis | **Passed: no issues found** | Source satisfies configured analyzer/lint checks |
| Node backend test suite | **14 passed, 0 failed** | Pure alert and retention logic passed |
| Full Flutter test suite | **124 passed, 4 failed** | Most application tests passed; local monitor fixture mismatch remains |

The backend tests verify that warning and critical alerts contain tobacco-oriented action, critical limits take precedence over configured warning limits, individual recipient ranges are used, timestamps in seconds and milliseconds are accepted only while fresh, repeated claims occur after five minutes, normal readings clear state, out-of-order readings do not rewind state, recipient keys derive from verified identities, and eight-hour cleanup removes only expired records.

The four Flutter failures are all in `sensor_alert_monitor_test.dart`. The test helper emits a simulated heartbeat every 20 seconds, while the current application freshness constant is 15 seconds. Each simulated emission is consequently interpreted as the start of a new online session, resetting the five-minute local notification schedule. The expected alerts are therefore not produced. This is a test-fixture inconsistency with the current timeout, not evidence that the passing Cloud Function classification tests failed. Nevertheless, the suite is not fully green and must not be reported as such. The fixture cadence should be brought below the configured timeout or parameterized in a later maintenance task, followed by a complete rerun.

## 5.9 Requirement Validation

Authentication, current reading mapping, freshness boundaries, timestamp unit normalization, pump rollback, live analytics updates, alert grouping, retention, threshold persistence, onboarding controls, and presentation widgets have automated coverage in the current test tree. Backend delivery to real devices, physical pump actuation, sensor calibration, radio reliability, and farmer usability require deployment or field experiments and cannot be proven by repository tests.

## 5.10 Discussion

The implementation demonstrates that a serverless backend can keep alert decisions independent of the mobile lifecycle. It also demonstrates why timestamp freshness must be explicit: a Boolean written during the last successful device cycle can remain `true` indefinitely. The use of `unknown` and `loading` states avoids turning initialization latency into a false Offline message.

The architecture is more mature than a simple sensor dashboard, but its evidence is uneven. Software structure and deterministic alert logic are well represented by automated tests. Agronomic validity is less certain because the repository contains only a minimal sample history and no calibration report. The light-unit discrepancy is particularly important. A responsible interpretation is that the prototype can carry and classify data correctly when the data and thresholds use the same verified units; it has not yet proven that the physical measurement represents field illuminance accurately.

The test failure also exposes a configuration dependency: heartbeat cadence and freshness timeout cannot be chosen independently. If the ESP32 writes every 20 or 30 seconds while the application declares data stale after 15 seconds, the device will spend most of its time Offline. The production timeout should exceed the measured normal write interval plus reasonable network jitter, and the same value should be shared by firmware documentation, Flutter tests, and backend policy.

---

# Chapter 6: Conclusion

AgriSenseAI was developed to make changing tobacco-field conditions visible through a low-cost IoT and mobile architecture. The implemented prototype connects an ESP32-oriented RTDB schema with an authenticated Flutter application. It displays current temperature, humidity, soil-moisture, and light readings; derives device availability from timestamp freshness; organizes history into multiple analytics ranges; synchronizes pump commands; persists user-selected threshold ranges; and delivers server-generated warning and critical notifications.

The project’s most important architectural result is the separation of responsibilities. Firebase initialization and authentication precede user-bound data access. The Home screen does not equate missing startup data with Offline. Historical analytics are isolated from the current snapshot. Cloud Functions, rather than a foreground widget, own remote threshold evaluation. Recipient identity is checked before delivery, transactional state restricts duplicates, and scheduled cleanup bounds alert storage. These decisions make the system more dependable than a client-only demonstration.

The work also establishes clear limits. No trained AI model is implemented, BLE provisioning is absent, device linking is still identity-derived, and agronomic accuracy has not been established through a seasonal field trial. Static analysis and all 14 backend tests pass. The Flutter suite has 124 passing tests and four known failures caused by an outdated simulated heartbeat interval relative to the current freshness constant. This report presents that result transparently.

The research questions can therefore be answered as follows. First, an ESP32-to-RTDB-to-Flutter pipeline can provide responsive field monitoring when records have a stable schema and timestamp. Second, device availability is more accurately represented by a multi-state freshness calculation than by a stored Boolean. Third, notifications that must work without an open application require backend evaluation and push delivery. Fourth, historical charts can remain robust by processing each metric independently and defining empty-data behaviour. Finally, modular repositories and shared services allow authentication, storage, settings, alerts, and presentation to evolve without placing Firebase code directly in every widget.

The present outcome is a functional software prototype and a defensible foundation for field research. Its next stage should prioritize measurement quality and real deployment evidence before adding a more complex predictive label.

---

# Chapter 7: Future Recommendations

## 7.1 Hardware Calibration and Field Trial

The highest-priority next step is not a new screen. Each sensor should be calibrated against an appropriate reference instrument across the expected field range. The team should record sensor model, placement depth, enclosure, sampling interval, conversion formula, raw value, reference value, temperature, soil type, and calibration date. Soil moisture should be compared with a suitable gravimetric or calibrated volumetric method. Light readings must be confirmed in lux, and the apparent mismatch in current sample data must be resolved.

A field trial should then cover multiple tobacco growth stages and weather conditions. Useful measures include missing-sample rate, end-to-end latency, notification delay, false-warning rate, device uptime, power consumption, pump-command acknowledgement, and farmer comprehension. Agronomic outcomes such as water use or leaf quality should only be claimed after a controlled comparison.

## 7.2 Firmware and Timeout Contract

The ESP32 firmware should be versioned with the application repository or referenced as a separate controlled repository. A written contract should define keys, units, timestamp source, current/history write order, retry behaviour, pump acknowledgement, and heartbeat cadence. The device timeout should be configured from observed cadence and network jitter. Tests, backend logic, and user documentation should use the same policy.

## 7.3 Explicit Device Enrollment

Identity-derived sensor keys are suitable for the prototype but not ideal for a general product. A privileged enrollment workflow should create a device record, bind a hardware identifier to an owner UID, and authorize selected farms and fields. Security rules and Cloud Functions should read this relationship instead of inferring ownership from email text. Ownership transfer and revoked access should be supported.

## 7.4 Offline Provisioning and BLE

The proposal’s BLE mode should be implemented only after a protocol is specified. The protocol should cover service and characteristic UUIDs, pairing, packet format, sequence numbers, checksums, retry, stored-reading pagination, time synchronization, and Wi-Fi credential provisioning. Offline recommendations can reuse the same rule definitions, but conflicts between locally changed settings and cloud settings need a synchronization policy.

## 7.5 Crop-Stage-Aware Recommendations

Static thresholds are simple and explainable, but tobacco water requirements change by stage [4]. A future rule engine should include transplant date or stage, soil class, recent rainfall, and sensor calibration. Threshold sources should be reviewed by an agronomist and stored with version, provenance, and effective date. Manual overrides should remain visible and auditable.

## 7.6 Responsible AI Extension

A predictive model should be added only after defining a measurable target and collecting enough representative labelled data. Possible targets include short-term soil-moisture forecasting, anomaly detection, or irrigation-need classification. The dataset should be split by time or field to avoid leakage. Baselines such as persistence, linear regression, and decision trees should be compared with more complex models using appropriate metrics. Model uncertainty, drift, and failure cases should be shown to the user. Until those steps are complete, the application should continue to call its output rule-based guidance rather than AI prediction.

## 7.7 Notification and Data Operations

Production monitoring should record function execution failures, FCM delivery outcomes, invalid-token rates, and cleanup counts. Retry policies need budget limits. Alert records should support acknowledgement and perhaps a longer aggregated audit history even if pop-up records expire after eight hours. High-frequency history should eventually be downsampled into hourly or daily summaries to control database cost.

## 7.8 Security and Privacy Review

Before wider deployment, rules should be tested with the Firebase Emulator Suite. App Check can reduce unauthorized client traffic. Secrets and signing material must remain outside source control. Data retention, account deletion, device transfer, audit logging, and least-privilege administration should be documented. A privacy notice should explain what field and device information is stored.

## 7.9 Usability and Localization

The interface should be evaluated with actual farmers using task-based observation rather than developer opinion alone. The study should measure whether users understand units, Online/Offline status, warning versus critical severity, and the difference between advice and automatic action. Urdu and Pashto localization should include agronomic review, not only literal translation. Accessibility testing should cover text scale, colour contrast, and non-colour severity cues.

## 7.10 Complete Verification

The four failing local-monitor tests should be corrected by aligning their simulated heartbeat with the 15-second contract or by injecting the timeout. The full suite should then run cleanly. Additional emulator tests should cover RTDB rules, function triggers, multi-user isolation, token removal, duplicate events, and database disconnects. Device tests should cover background, normal termination, Android force-stop limitations, iOS delivery, and denied notification permission.

---

# Appendix A: Requirements Traceability Matrix

| Requirement | Principal implementation evidence | Verification evidence |
|---|---|---|
| FR-01–02 Authentication/session | Auth remote data source, auth provider, auth session provider, router | Auth unit/integration/widget tests; splash/onboarding tests |
| FR-04–07 Current read/status | Sensor database service, Home remote data source, status enum/constants | Timestamp and freshness tests; Home provider/widget tests |
| FR-08–09 Dashboard/guidance | Home models, mapper, smart-action builder, widgets | Home data, provider, integration, and widget tests |
| FR-10–11 Analytics | Historical database interface, Analytics remote data source/provider | Analytics unit, integration, and widget tests |
| FR-12 Threshold settings | Threshold settings service, secure local storage, Settings provider | Threshold service and Settings tests |
| FR-13–16 Remote alerts/retention | Cloud Functions trigger, scheduler, pure alert logic | 14 passing Node tests; alert retention Dart tests |
| FR-17 Alert review | Alerts store/live data source/provider/widgets | Alert data/domain/integration/widget tests |
| FR-18 Pump control | UID path, Home provider optimistic update and rollback | Home provider tests |
| FR-19 Supporting screens | Onboarding, navigation, profile, settings features | Corresponding feature tests |
| FR-20 BLE | No current implementation | Deferred |
| FR-21 ML model | No dataset/training/inference implementation | Deferred |

# Appendix B: Database and Message Schemas

## B.1 Current reading example

```json
{
  "temperatureC": 34.0,
  "humidityPercent": 65.8,
  "soilMoisturePercent": 0.0,
  "lightLux": 91.67,
  "updatedAt": 1783771022000
}
```

## B.2 History record example

```json
{
  "temperatureC": 33.9,
  "humidityPercent": 65.6,
  "soilMoisturePercent": 0.0,
  "lightLux": 93.33,
  "timestamp": 1783770391000
}
```

## B.3 Notification registration

```text
notificationRecipients/{sensorUserKey}/{uid}/
    enabled: Boolean
    updatedAt: epoch milliseconds
    thresholds:
        minTemperature, maxTemperature
        minHumidity, maxHumidity
        minMoisture, maxMoisture
        minLight, maxLight
    tokens/{sanitizedToken}/:
        token, platform, updatedAt
```

## B.4 Stored alert

```text
notificationAlerts/{uid}/{alertId}/
    eventId, title, message, recommendedAction
    severity, metric, sensorName
    value, unit, timestamp
    sensorUserKey, farmKey, fieldKey
    source, createdAt
```

# Appendix C: Glossary

| Term | Definition |
|---|---|
| Current snapshot | Latest known sensor record optimized for dashboard display |
| Historical sample | Timestamped record retained for analytics and backend events |
| Fresh reading | Valid timestamp whose age is within the configured device timeout |
| Warning | Measurement outside a user-configured normal range but inside the fixed critical envelope |
| Critical | Measurement beyond a fixed outer safety boundary |
| Sensor user key | RTDB path segment identifying the account under which hardware publishes data |
| Recipient UID | Firebase Authentication UID authorized to receive a notification |
| Rule-based guidance | Deterministic message produced from explicit comparisons, not a trained model |
| FCM token | Installation-specific identifier used by Firebase Cloud Messaging |
| Stale data | Valid old data that must not be presented as a live device state |

---

# References

[1] V. R. Pathmudi, N. Khatri, S. Kumar, A. S. H. Abdul-Qawy, and A. K. Vyas, “A systematic review of IoT technologies and their constituents for smart and sustainable agriculture applications,” *Scientific African*, vol. 19, e01577, 2023, doi: [10.1016/j.sciaf.2023.e01577](https://doi.org/10.1016/j.sciaf.2023.e01577).

[2] V. K. Quy, N. V. Hau, D. V. Anh, N. M. Quy, N. T. Ban, S. Lanza, G. Randazzo, and A. Muzirafuti, “IoT-enabled smart agriculture: Architecture, applications, and challenges,” *Applied Sciences*, vol. 12, no. 7, p. 3396, 2022, doi: [10.3390/app12073396](https://doi.org/10.3390/app12073396).

[3] J. Mendes, T. M. Pinho, F. Neves dos Santos, J. J. Sousa, E. Peres, J. Boaventura-Cunha, M. Cunha, and R. Morais, “Smartphone applications targeting precision agriculture practices—A systematic review,” *Agronomy*, vol. 10, no. 6, p. 855, 2020, doi: [10.3390/agronomy10060855](https://doi.org/10.3390/agronomy10060855).

[4] Food and Agriculture Organization of the United Nations, “Tobacco: Crop water information,” FAO Land & Water. [Online]. Available: [https://www.fao.org/land-water/databases-and-software/crop-information/tobacco/](https://www.fao.org/land-water/databases-and-software/crop-information/tobacco/). Accessed: Jul. 14, 2026.

[5] Pakistan Tobacco Board, *Research & Development Plan 2021–22*. Peshawar, Pakistan: Pakistan Tobacco Board, 2021, pp. 30–31. [Online]. Available: [PTB research plan](https://ptb.gov.pk/sites/default/files/2022-08/Research%20%26%20Development%20Plan%202021-22%2830-11-21%29%20%281%29.pdf).

[6] Google, “Read and write data on Flutter,” *Firebase Realtime Database Documentation*. [Online]. Available: [https://firebase.google.com/docs/database/flutter/read-and-write](https://firebase.google.com/docs/database/flutter/read-and-write). Accessed: Jul. 14, 2026.

[7] Google, “Enabling offline capabilities on Flutter,” *Firebase Realtime Database Documentation*. [Online]. Available: [https://firebase.google.com/docs/database/flutter/offline-capabilities](https://firebase.google.com/docs/database/flutter/offline-capabilities). Accessed: Jul. 14, 2026.

[8] Google, “Guide to app architecture,” *Flutter Documentation*. [Online]. Available: [https://docs.flutter.dev/app-architecture/guide](https://docs.flutter.dev/app-architecture/guide). Accessed: Jul. 14, 2026.

[9] Google, “Realtime Database triggers,” *Cloud Functions for Firebase Documentation*. [Online]. Available: [https://firebase.google.com/docs/functions/database-events](https://firebase.google.com/docs/functions/database-events). Accessed: Jul. 14, 2026.

[10] Google, “Receive messages in a Flutter app,” *Firebase Cloud Messaging Documentation*. [Online]. Available: [https://firebase.google.com/docs/cloud-messaging/flutter/receive-messages](https://firebase.google.com/docs/cloud-messaging/flutter/receive-messages). Accessed: Jul. 14, 2026.

[11] D. Vallejo-Gómez, M. Osorio, and C. A. Hincapié, “Smart irrigation systems in agriculture: A systematic review,” *Agronomy*, vol. 13, no. 2, p. 342, 2023, doi: [10.3390/agronomy13020342](https://doi.org/10.3390/agronomy13020342).

[12] P. Liana, M. U. H. Al Rasyid, and Setiawardhana, “Development of IoT-based drip irrigation system for tobacco crops using fuzzy logic: A case study in Indonesian agriculture,” *CommIT Journal*, vol. 19, no. 2, pp. 249–265, 2025, doi: [10.21512/commit.v19i2.13060](https://doi.org/10.21512/commit.v19i2.13060).

[13] P. K. Rajani, G. Deshpande, M. Goswami, J. Kolhe, V. Khandagale, M. Mujumdar, and B. B. Singh, “IoT-based low-cost soil moisture and soil temperature monitoring system,” *International Journal of Electrical and Electronics Engineering*, vol. 10, no. 10, pp. 66–74, 2023, doi: [10.14445/23488379/IJEEE-V10I10P108](https://doi.org/10.14445/23488379/IJEEE-V10I10P108).

[14] M. Farooq, S. Riaz, A. Abid, K. Abid, and M. A. Naeem, “A survey on the role of IoT in agriculture for the implementation of smart farming,” *IEEE Access*, vol. 7, pp. 156237–156271, 2019, doi: [10.1109/ACCESS.2019.2949703](https://doi.org/10.1109/ACCESS.2019.2949703).

[15] AgriSenseAI Project Team, *Software Requirements Specification for IoT Smart Agriculture Monitoring and Controlling System with AI*, version 1.0, Department of Computer Science, University of Engineering & Technology, Peshawar, Nov. 2025.
