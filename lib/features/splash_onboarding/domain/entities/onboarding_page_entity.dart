/// Represents a single onboarding page.
class OnboardingPageEntity {
  const OnboardingPageEntity({
    required this.id,
    required this.title,
    required this.description,
    required this.illustrationType,
    required this.order,
    required this.ctaLabel,
    required this.ctaIcon,
    required this.showSkip,
  });

  /// Unique identifier for the onboarding page.
  final String id;

  /// Title displayed on the page.
  final String title;

  /// Description text for the page.
  final String description;

  /// Type of illustration to display (monitor, automate, insights).
  final String illustrationType;

  /// Order of appearance in the onboarding sequence.
  final int order;

  /// Label for the call-to-action button.
  final String ctaLabel;

  /// Icon asset for the call-to-action button.
  final String ctaIcon;

  /// Whether to show the skip button on this page.
  final bool showSkip;
}
