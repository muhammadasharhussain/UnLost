// lib/core/widgets/app_backdrop.dart
import 'package:flutter/material.dart';
import 'grid_backdrop.dart';

/// Full-screen animated grid backdrop for Unlost.
class AppBackdrop extends StatelessWidget {
  final Widget child;
  const AppBackdrop({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return GridBackdrop(child: child);
  }
}
