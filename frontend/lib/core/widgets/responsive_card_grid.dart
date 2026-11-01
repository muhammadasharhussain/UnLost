// lib/core/widgets/responsive_card_grid.dart
//
// Lays vertical cards out in 1 / 2 / 3 columns (breakpoints 600 and 900) and
// makes every card in a row the same height, even when the cards have
// different amounts of content (admin answers, pickup codes and so on).
import 'package:flutter/material.dart';

class ResponsiveCardGrid extends StatelessWidget {
  final List<Widget> children;
  final double spacing;

  const ResponsiveCardGrid({
    super.key,
    required this.children,
    this.spacing = 14,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final cols = w >= 900 ? 3 : (w >= 600 ? 2 : 1);
        final rows = <Widget>[];
        for (var i = 0; i < children.length; i += cols) {
          final cells = <Widget>[];
          for (var c = 0; c < cols; c++) {
            if (c > 0) cells.add(SizedBox(width: spacing));
            final idx = i + c;
            cells.add(Expanded(
              child: idx < children.length ? children[idx] : const SizedBox(),
            ));
          }
          rows.add(IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: cells,
            ),
          ));
          if (i + cols < children.length) rows.add(SizedBox(height: spacing));
        }
        return Column(children: rows);
      },
    );
  }
}
