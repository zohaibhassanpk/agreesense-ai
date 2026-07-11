import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// A reusable class to apply beautiful animated transitions across routes.
class RouteTransitions {
  /// Fade transition
  static CustomTransitionPage<T> fade<T>({
    required Widget child,
    required GoRouterState state,
    Duration duration = const Duration(milliseconds: 400),
  }) {
    return CustomTransitionPage<T>(
      key: state.pageKey,
      child: child,
      transitionDuration: duration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(opacity: animation, child: child);
      },
    );
  }

  /// Slide transition (from right to left)
  static CustomTransitionPage<T> slideFromRight<T>({
    required Widget child,
    required GoRouterState state,
    Duration duration = const Duration(milliseconds: 500),
    Curve curve = Curves.easeInOutCubic,
  }) {
    const begin = Offset(1.0, 0.0);
    const end = Offset.zero;

    var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));

    return CustomTransitionPage<T>(
      key: state.pageKey,
      child: child,
      transitionDuration: duration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return SlideTransition(position: animation.drive(tween), child: child);
      },
    );
  }

  /// Slide transition (from bottom)
  static CustomTransitionPage<T> slideFromBottom<T>({
    required Widget child,
    required GoRouterState state,
    Duration duration = const Duration(milliseconds: 500),
    Curve curve = Curves.fastOutSlowIn,
  }) {
    const begin = Offset(0.0, 1.0);
    const end = Offset.zero;

    var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));

    return CustomTransitionPage<T>(
      key: state.pageKey,
      child: child,
      transitionDuration: duration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return SlideTransition(position: animation.drive(tween), child: child);
      },
    );
  }

  /// Scale transition
  static CustomTransitionPage<T> scale<T>({
    required Widget child,
    required GoRouterState state,
    Duration duration = const Duration(milliseconds: 500),
  }) {
    return CustomTransitionPage<T>(
      key: state.pageKey,
      child: child,
      transitionDuration: duration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return ScaleTransition(
          scale: CurvedAnimation(parent: animation, curve: Curves.easeOutBack),
          child: child,
        );
      },
    );
  }
}
