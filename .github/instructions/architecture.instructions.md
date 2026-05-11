---
applyTo: "lib/**"
description: "Clean Architecture structure, folder layout, DI, and shared layer rules."
---

# Strict Architecture Rules

Project structure:

```
lib/
├── main.dart
├── app/
├── core/
└── features/
```

You must respect this separation at all times.

---

# main.dart Responsibilities

main.dart must ONLY:
- Initialize Flutter bindings
- Configure system UI
- Initialize dependencies
- Initialize Supabase
- Start the app

No business logic.
No UI logic.
No feature logic.

---

# app/ Layer (Application Composition)

## injection_container.dart

- Uses GetIt (DI instance stored in `di`)
- Registers:
    - Services
    - Repositories
    - Providers
    - Feature dependencies

All new feature dependencies MUST be registered here.
Never instantiate services inside UI.

## medichatai_app.dart

- Contains MaterialApp.router
- Sets theme
- Configures GoRouter
- Light theme currently enabled
- Dark theme will be added later (write scalable code)

No business logic here.

---

# core/ Layer (Shared Infrastructure)

Structure:

```
core/
├── config/
├── constants/
├── entities/
├── enums/
├── extensions/
├── providers/
├── routers/
├── services/
├── theme/
├── utils/
└── widgets/
```

Rules:
- Core must remain reusable.
- No feature-specific logic allowed inside core.
- Shared widgets only.
- Shared services only.
- Shared utilities only.

---

## core/services

Includes:
- Dio service
- Network service
- Logger service
- Local storage
- Notification service
- Image picker

Rules:
- Wrap external packages behind service abstractions.
- Never call Dio directly from UI.
- All API calls must go through repository → service.
- Handle interceptors centrally.

---

## core/widgets

Organized into:
- animated
- bottom sheets
- buttons
- cards
- dialogs
- inputs
- loaders
- snackbars
- more/

Reusable only.
If a widget is reused twice → move it to core/widgets.

---

## core/extensions

Includes:
- context extensions
- responsive extensions
- helper extensions
- string extensions
- widget extensions

Use consistently.
Avoid duplicate logic.

---

# features/ Layer (Clean Architecture Per Feature)

Each feature MUST follow:

```
feature_name/
├── data/
├── domain/
└── presentation/
```

## domain/
- Entities
- Repositories
- Use cases

No Flutter imports allowed here.

## data/
- Models
- Repositories
- Data Sources

## presentation/
- Screens
- Providers (ChangeNotifier)
- Widgets

---

# Dependency Injection Rules

- Use GetIt.
- Register everything in injection_container.
- Do not instantiate dependencies manually inside widgets.

---

# Forbidden Practices

- No business logic inside UI.
- No direct API calls inside widgets.
- No feature logic inside core.
- No architecture changes.
- No replacing Provider.
- No random new packages.
