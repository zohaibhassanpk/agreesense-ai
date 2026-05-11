---
applyTo: "lib/**/*.dart,test/**/*.dart,integration_test/**/*.dart"
description: "Effective Dart style, performance, scalability, and logging rules."
---

# Code Style Rules

- Follow Effective Dart.
- Use null safety strictly.
- Avoid `!` unless guaranteed safe.
- Line length: 80 characters max.
- PascalCase → classes
- camelCase → variables & functions
- snake_case → files
- Functions under 20 lines when possible.
- No trailing comments.
- Prefer const constructors.

---

# Performance Rules

- Use ListView.builder for long lists.
- Avoid expensive work inside build().
- Use compute() for heavy parsing.
- Use const whenever possible.

---

# Error Handling Rules

- Use try-catch properly.
- Log structured errors.
- Map API errors to domain errors.
- Show user-friendly error states.

Never fail silently.

---

# Logging Rules

Use: Logger service from core/services/logger_service.dart
Never use print.

---

# Scalability Rules

- Write code ready for dark theme.
- Write code ready for web support.
- Keep feature isolation clean.
- Make components reusable.
