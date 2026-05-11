import '../../domain/entities/onboarding_page_entity.dart';

/// Model for onboarding page data.
class OnboardingPageModel extends OnboardingPageEntity {
  const OnboardingPageModel({
    required super.id,
    required super.title,
    required super.description,
    required super.illustrationType,
    required super.order,
    required super.ctaLabel,
    required super.ctaIcon,
    required super.showSkip,
  });

  /// Creates a model from JSON.
  factory OnboardingPageModel.fromJson(Map<String, dynamic> json) {
    return OnboardingPageModel(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      illustrationType: json['illustrationType'] as String,
      order: json['order'] as int,
      ctaLabel: json['ctaLabel'] as String,
      ctaIcon: json['ctaIcon'] as String,
      showSkip: json['showSkip'] as bool,
    );
  }

  /// Converts the model to JSON.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'illustrationType': illustrationType,
      'order': order,
      'ctaLabel': ctaLabel,
      'ctaIcon': ctaIcon,
      'showSkip': showSkip,
    };
  }
}
