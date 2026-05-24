import 'package:flutter/material.dart';

/// Wraps child with MediaQuery-aware responsive padding and safe area.
/// Use around the main content of each screen for consistent responsive layout.
class ResponsiveWrapper extends StatelessWidget {
  final Widget child;
  final bool useSafeArea;
  final double horizontalPaddingPercent;
  final double verticalPaddingPercent;

  const ResponsiveWrapper({
    super.key,
    required this.child,
    this.useSafeArea = true,
    this.horizontalPaddingPercent = 0.000,
    this.verticalPaddingPercent = 0.00,
  });
  // orienration can be handled by adjusting the padding percentages based on MediaQuery orientation if needed.


  // This widget calculates padding based on screen size and applies it to the child.

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final horizontalPadding = size.width * horizontalPaddingPercent;
    final verticalPadding = size.height * verticalPaddingPercent;

    

    Widget content = Padding(
      padding: EdgeInsets.symmetric(
        horizontal: horizontalPadding.clamp(0.0, 0.0),
        vertical: verticalPadding.clamp(0.0, 0.0),
      ),
      child: child,
    );

    if (useSafeArea) {
      content = SafeArea(child: content);
    }

    return content;
  }

}
