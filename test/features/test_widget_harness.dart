import 'package:agrisenseaiapp/core/config/responsive_config.dart';
import 'package:flutter/material.dart';

Widget buildResponsiveTestApp(Widget child) {
  return MaterialApp(
    home: ResponsiveProvider(child: Scaffold(body: child)),
  );
}
