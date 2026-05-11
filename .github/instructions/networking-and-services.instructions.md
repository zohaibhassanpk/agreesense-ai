---
applyTo: "lib/features/**/data/**,lib/core/services/**"
description: "Service abstractions, networking rules, and auth storage."
---

# core/services

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

# Authentication Rules

- Google Auth via Supabase.
- Securely store tokens using Flutter Secure Storage.
- Never store sensitive data in plain storage.
