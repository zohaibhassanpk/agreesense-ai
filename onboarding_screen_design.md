# Onboarding Feature - Clean Architecture Implementation

## Design Sources
- APP_DESIGN.html (Onboarding Screen section)
- Design specifications for onboarding flow

## Architecture Overview
The onboarding feature follows **Clean Architecture** with complete separation of concerns:

```
features/splash_onboarding/
├── domain/
│   ├── entities/
│   │   └── onboarding_page.dart
│   └── repositories/
│       └── onboarding_repository.dart (abstract)
├── data/
│   ├── datasources/
│   │   └── onboarding_local_datasource.dart
│   ├── models/
│   │   └── onboarding_page_model.dart
│   └── repositories/
│       └── onboarding_repository_impl.dart
└── presentation/
    ├── providers/
    │   └── onboarding_provider.dart (ChangeNotifier)
    ├── screens/
    │   ├── onboarding_screen.dart
    │   └── splash_screen.dart
    └── widgets/
        ├── onboarding_visual_widgets.dart
        ├── onboarding_control_widgets.dart
        ├── splash_visual_widgets.dart
        └── splash_text_widgets.dart
```

## Domain Layer

### OnboardingPage Entity
- **Purpose**: Pure domain model representing an onboarding page
- **No Flutter imports** - completely framework-agnostic
- **Fields**:
  - `id`: Unique identifier
  - `title`: Page title
  - `description`: Page description
  - `illustrationType`: 'monitor', 'automate', or 'insights'
  - `order`: Display order (0, 1, 2)
  - `ctaLabel`: Call-to-action button text
  - `ctaIcon`: Button icon asset path
  - `showSkip`: Whether to show skip button

### OnboardingRepository (Abstract)
- **Purpose**: Define contract for onboarding data access
- **Methods**:
  - `getAllPages()`: Fetch all onboarding pages
  - `getPageById(id)`: Fetch single page
  - `getTotalPages()`: Get page count

## Data Layer

### OnboardingPageModel
- Extends `OnboardingPage` entity
- Adds JSON serialization (fromJson/toJson)
- Used internally by data layer only

### OnboardingLocalDataSource
- Contains **hardcoded** onboarding data (3 pages)
- Factory pattern implementation: `OnboardingLocalDataSourceImpl`
- Returns Future-based API for consistency with async operations

**Hardcoded Pages**:
1. **Monitor Your Farm** (monitor) - Real-time sensor monitoring
2. **Automate Irrigation** (automate) - Smart irrigation automation
3. **AI Crop Insights** (insights) - Predictive analytics

### OnboardingRepositoryImpl
- Implements `OnboardingRepository` contract
- Delegates to `OnboardingLocalDataSource`
- Single responsibility: data source coordination

## Presentation Layer

### OnboardingProvider (ChangeNotifier)
- **State Management**: Primary Provider for onboarding state
- **Key Properties**:
  - `pages`: List of all OnboardingPage entities
  - `currentPageIndex`: Current page position
  - `currentPage`: Current page object
  - `isLoading`: Loading state
  - `hasNextPage` / `hasPreviousPage`: Navigation helpers
  
- **Methods**:
  - `initialize()`: Load pages from repository
  - `nextPage()` / `previousPage()`: Navigate
  - `goToPage(index)`: Jump to specific page
  - `reset()`: Return to first page

### OnboardingScreen
- **Stateful widget** managing PageController lifecycle
- **Uses Provider** to access and observe OnboardingProvider
- **Key Features**:
  - PageView.builder with dynamic page count
  - Skip button (visible based on page data)
  - Previous/Next navigation via PageController
  - Automatic sync between PageView and Provider state
  - Responsive padding using AppSpacing tokens

### Visual Widgets (Presentation/widgets)
- **OnboardingPageContent**: Title + description + illustration
- **OnboardingIllustration**: Routes to variant-specific illustrations
- **_MonitorIllustration**: Rotated info cards (temperature, humidity)
- **_AutomationIllustration**: Shine icon with checkmark badge
- **_InsightsIllustration**: Icon with "Maximize Yield" pill
- **Supporting**: _IllustrationShell, _SoftCircle, _InfoCard, _IconCard, _BadgeCircle, _InsightPill

### Control Widgets (Presentation/widgets)
- **OnboardingSkipButton**: Conditional skip button
- **OnboardingPagerIndicator**: Dot indicators for pages
- **OnboardingPrimaryButton**: CTA button with icon

## Dependency Injection (GetIt)

Registered in `app/injection_container.dart`:

```dart
// Local datasource (Lazy singleton)
di.registerLazySingleton<OnboardingLocalDataSource>(
  () => OnboardingLocalDataSourceImpl(),
);

// Repository (Lazy singleton)
di.registerLazySingleton<OnboardingRepository>(
  () => OnboardingRepositoryImpl(localDataSource: di()),
);

// Provider (Factory - new instance per use)
di.registerFactory<OnboardingProvider>(
  () => OnboardingProvider(repository: di()),
);
```

## State Management Flow

```
User Action
    ↓
OnboardingScreen (UI)
    ↓
OnboardingProvider.nextPage() / goToPage()
    ↓
Provider notifies listeners
    ↓
Consumer<OnboardingProvider> rebuilds
    ↓
UI updates (text, illustration, buttons)
```

## Design Fidelity

### Colors
- All from AppColors (primary green, accent blue/yellow, surface)
- No hardcoded colors
- Soft circles use color.withOpacity() for backgrounds

### Typography
- Title: displaySmall (darkGreen)
- Description: bodyMedium (textSecondary)
- Labels: labelMedium (varied colors)
- All from context.textTheme via AppTextStyles

### Spacing & Layout
- All measurements from AppSpacing tokens
- Responsive via .w, .h, .r extensions
- BorderRadius from AppBorderRadius
- Consistent shadows (0.04-0.16 opacity)

### Responsive Design
- PageView with proper height calculations
- Padding scales with AppSpacing
- SafeArea respects device notches
- Responsive config applied from core/config

### Assets
- SVG icons from assets/svgs/
- ColorFilter for icon tinting
- Flutter_svg for rendering

## Code Quality

- ✅ **No hardcoded values**: All spacing, colors, typography centralized
- ✅ **Clean Architecture**: Strict domain/data/presentation separation
- ✅ **Dependency Injection**: GetIt for all dependencies
- ✅ **State Management**: Provider pattern with ChangeNotifier
- ✅ **Const constructors**: Used throughout for performance
- ✅ **Error handling**: Graceful null checks and empty states
- ✅ **Documentation**: Dartdoc comments on public APIs
- ✅ **Accessibility**: Proper color contrast, touch targets, font sizes

## Integration Points

### Router (GoRouter)
- OnboardingScreen registered in app_router.dart
- Navigation to auth screen on completion or skip
- Route names in core/routers/router_names.dart

### Theming
- Uses ThemeData from app_theme_data.dart
- Light theme enabled (dark theme ready)
- Scalable for future theme support

## UI Fidelity Updates (May 2026)

- Adjusted onboarding screen padding to match p-6 (skip), p-8/pt-4 (content), and pb-10 (footer) from APP_DESIGN.html.
- Updated illustration layouts to mirror the two-card grid, badge offset, and soft-circle scales from the design export.
- Tuned icon sizes using AppSpacing-derived values (text-3xl, text-4xl, text-5xl equivalents) with no hardcoded numbers.
- Refined the insights pill to use a plain icon + text (no background chip) with gap-3 spacing.
- Aligned CTA button height and icon size to match the py-4 and text-lg proportions.
- Set AppTextStyles.displaySmall to 24.sp to match the design's text-2xl heading size.

## Future Enhancements

- Add animations between pages (optional)
- Persist onboarding completion state
- Add analytics tracking
- Support for remote onboarding data
- Localization for multi-language support
