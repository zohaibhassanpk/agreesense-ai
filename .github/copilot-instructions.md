# AI Rules for AgriSenseAI App

You are an expert Flutter and Dart Engineer working on the AgriSenseAI mobile
application.

Your goal is to build a scalable, production-grade, agricultural sensor ai app,
following Clean Architecture, modern Flutter best practices, and strict
separation of concerns.

This project is already structured. You must respect the structure and extend
it, never break it.

---

# How These Rules Are Organized

This file contains the universal non-negotiable rules plus an index. Detailed
rules are split across scoped files under `.github/instructions/`. Each file has
an `applyTo` glob and is auto-loaded when you edit matching paths.

| File | Auto-loads when editing | Covers |
|---|---|---|
| `instructions/architecture.instructions.md` | `lib/**` | Clean Architecture, folder structure, DI rules |
| `instructions/design-system.instructions.md` | `lib/features/**/presentation/**`, `lib/core/widgets/**`, `lib/core/theme/**`, `lib/core/extensions/**` | Design tokens, UI rules, design reference rules |
| `instructions/code-quality.instructions.md` | `lib/**/*.dart`, `test/**/*.dart`, `integration_test/**/*.dart` | Code style, performance, scalability, logging |
| `instructions/feature-workflow.instructions.md` | `lib/features/**/*.dart` | Feature workflow steps |
| `instructions/state-and-navigation.instructions.md` | `lib/features/**/presentation/providers/**`, `lib/core/routers/**`, `lib/core/providers/**`, `lib/app/**` | Provider rules, GoRouter navigation |
| `instructions/networking-and-services.instructions.md` | `lib/features/**/data/**`, `lib/core/services/**` | Services, networking, auth rules |
| `instructions/testing.instructions.md` | `test/**`, `integration_test/**` | Testing rules |

---

# Project Overview

**App Name:** AgriSenseAI
**Platform:** Flutter (Android & iOS)
**Architecture:** Clean Architecture (Feature-based)
**State Management:** Provider
**Dependency Injection:** GetIt
**Navigation:** GoRouter
**Backend:** Firebase (Auth, Firestore, Storage)
**Push Notifications:** Firebase Push Notifications
**Local Storage:** Flutter Secure Storage
**Image Handling:** Image Picker
**SVG Rendering:** flutter_svg
**Testing:** Unit, Widget, and Integration Tests
**CI/CD:** GitHub Actions

**Fonts:** *NEEDS TO BE UPDATE AS PER THIS PROJECT DESIGN*
- Poppins (Regular, Medium, SemiBold)

Font files are stored in:
assets/fonts/

SVG assets are stored in:
assets/

Design reference: `APP_DESIGN.html` in the project root.

---

# Non-Negotiable Rules (always apply)

- Follow Clean Architecture: `lib/` splits into `main.dart`, `app/`, `core/`,
  and `features/`. No cross-feature internals.
- Register every dependency in `app/injection_container.dart` via GetIt.
  Never instantiate services inside UI.
- Use GoRouter only. Define route names in `core/routers/router_names.dart`
  and register routes in `core/routers/app_router.dart`.
- No hardcoded values: colors, font sizes, weights, radii, shadows, asset
  paths, or magic numbers in widgets.
- Use theme tokens, responsive extensions, and `core/widgets/` first.
- Icons and illustrations must come from `assets/svgs/` via `AppAssets.*`.
- State management: Provider / ChangeNotifier only.
- Write code testable by design and keep domain unit-testable.
- Use Logger service; never use `print`.
- No business logic inside UI. No direct API calls inside widgets.
- No feature logic inside core. No architecture changes. No random packages.

---

# Final Instruction

You are writing production-ready, scalable, maintainable code for a real mobile
app product.

Follow Clean Architecture strictly. Respect the existing structure and
`APP_DESIGN.html`.
