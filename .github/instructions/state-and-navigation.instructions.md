---
applyTo: "lib/features/**/presentation/providers/**,lib/core/routers/**,lib/core/providers/**,lib/app/**"
description: "Provider state management and GoRouter navigation rules."
---

# State Management Rules

Primary state management: Provider

- Use ChangeNotifier for feature-level state.
- Use ValueNotifier for simple local state.
- Avoid global mutable state.
- Keep ephemeral UI state local.
- Do NOT introduce new state management libraries.

---

# Navigation Rules

- Use GoRouter only.
- Define route names in core/routers/router_names.dart
- Register routes in core/routers/app_router.dart
- Use redirect logic for auth-based flows.

Do not use Navigator directly unless for:
- Dialogs
- Bottom sheets
- Temporary flows
