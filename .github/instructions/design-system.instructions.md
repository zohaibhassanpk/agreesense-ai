---
applyTo: "lib/features/**/presentation/**,lib/core/widgets/**,lib/core/theme/**,lib/core/extensions/**"
description: "Design tokens, design reference rules, and UI rules."
---

# Fonts and Assets

**Fonts:** *NEEDS TO BE UPDATE AS PER THIS PROJECT DESIGN*
- Poppins (Regular, Medium, SemiBold)

Font files are stored in:
assets/fonts/

SVG assets are stored in:
assets/

---

# Design Reference Rules (CRITICAL)

In the project root, there is a file:

APP_DESIGN.html

This file contains the complete exported Figma design of the mobile application.

Whenever:
- A screenshot of a design is provided
- A new screen needs to be built
- A UI decision is unclear

You MUST:
1. Refer to APP_DESIGN.html for figma design html code
2. Extract spacing, layout logic, typography, and structure
3. Match the design pixel-accurately
4. Reuse existing theme data/details from core/theme/
5. Reuse the existing widget library from core/widgets/
6. Reuse the existing extensions from core/extensions/
7. Whenever possible, reuse existing components instead of creating new ones.
8. Consult the design for responsive behavior and breakpoints.
9. Must create feature levele widgets that match the design, even if they are
   only used once. This ensures consistency and scalability.
10. Don't need to take too much widgets in the feature level, but if you see a
    widget that can be reused in the future, move it to core/widgets.
11. Always check the design for color usage and never hardcode colors.
12. Must use the existing font styles defined in core/theme/app_text_styles.dart
    and never hardcode font sizes or weights.
13. Must use the existing extensions for spacing and layout defined in
    core/extensions/responsive_extensions.dart to ensure consistent spacing and
    responsive behavior.
14. Always check the design for any specific UI behavior, animations, or
    interactions and implement them according to the design specifications.
15. If you encounter a design element that is not covered by the existing theme
    or widget library, you must first check if it can be implemented by
    composing existing widgets and theme tokens. Only if it cannot be
    implemented by composition should you create a new widget or theme token,
    and even then, you must ensure that it is designed in a way that it can be
    reused in the future.
16. Always use assets/svgs/ for icons and illustrations as specified in the
    design, and never use placeholder icons or hardcoded images.
17. Always ensure that the UI is responsive and adapts to different screen sizes
    as specified in the design, using the responsive configuration defined in
    core/config/responsive_config.dart.
18. Must use the context.theme with the text styles defined in
    core/theme/app_text_styles.dart to ensure consistent typography across the
    app.
19. Always create a .md file in the root of the project, once you done any
    feature design, describing how you implemented the design, which components
    you created, and how you ensured that the implementation matches the design
    specifications. This documentation will serve as a reference for future
    development and help maintain consistency across the app.
20. Always review the design for any specific accessibility considerations, such
    as color contrast, font sizes, and touch target sizes, and ensure that your
    implementation meets these accessibility standards.

Never invent UI styles if they already exist in the design.

---

# UI Rules

- Pixel-perfect implementation.
- Use centralized theme.
- Respect spacing from design.html.
- Avoid magic numbers.
- Use responsive config in core/config.
- Break large build() methods into private widgets.
- Avoid deep widget trees.

---

# core/theme

Contains:
- app_colors
- app_shadows
- app_text_styles
- app_theme
- app_theme_data
- app_border_radius

Rules:
- Never hardcode colors.
- Never hardcode font sizes.
- Always use Theme.of(context)
- Always use centralized tokens.
- Georgia only for headings.
- Inter for body text.
