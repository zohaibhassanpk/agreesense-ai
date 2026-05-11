---
applyTo: "lib/features/**/*.dart"
description: "Feature workflow for building a new feature end-to-end."
---

# Feature Development Workflow

When building a new feature:

1. Analyze provided design screenshot.
2. Cross-check with design.html.
3. Define domain entities.
4. Define repository contract.
5. Implement data layer.
6. Register dependencies in injection_container.
7. Implement provider (ChangeNotifier).
8. Build presentation layer.
9. Connect to router.
10. Test navigation & state.

Follow this order strictly.
