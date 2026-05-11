import 'package:flutter/material.dart';

class AppBackButton extends StatelessWidget {
  final VoidCallback? onBackPressed;
  const AppBackButton({super.key, this.onBackPressed});

  @override
  Widget build(BuildContext context) {
    return Text('Back Button');

    /// Adjust it as per project need.
  }
}
