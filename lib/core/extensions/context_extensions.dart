import 'package:flutter/material.dart';

extension ContextExtensions on BuildContext {
  // Theme
  ThemeData get theme => Theme.of(this);
  TextTheme get textTheme => Theme.of(this).textTheme;
  ColorScheme get colorScheme => Theme.of(this).colorScheme;

  // Keyboard
  void hideKeyboard() => FocusScope.of(this).unfocus();
  bool get isKeyboardVisible => MediaQuery.of(this).viewInsets.bottom > 0;

  // Focus
  void requestFocus(FocusNode node) => FocusScope.of(this).requestFocus(node);
  void unfocus() => FocusScope.of(this).unfocus();
}
