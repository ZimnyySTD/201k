import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/theme_provider.dart';

class NeumorphicCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double borderRadius;
  final VoidCallback? onTap;
  final bool isPressed;
  final double depth;

  const NeumorphicCard({
    super.key,
    required this.child,
    this.padding,
    this.borderRadius = 20.0,
    this.onTap,
    this.isPressed = false,
    this.depth = 5.0,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: padding ?? const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: theme.surfaceColor,
          borderRadius: BorderRadius.circular(borderRadius),
          boxShadow: isPressed
              ? []
              : [
                  BoxShadow(
                    color: theme.lightShadow,
                    offset: Offset(-depth, -depth),
                    blurRadius: depth * 2,
                  ),
                  BoxShadow(
                    color: theme.darkShadow,
                    offset: Offset(depth, depth),
                    blurRadius: depth * 2,
                  ),
                ],
        ),
        child: child,
      ),
    );
  }
}

class NeumorphicButton extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double size;
  final bool isSelected;
  final Color? color;

  const NeumorphicButton({
    super.key,
    required this.child,
    this.onTap,
    this.size = 52.0,
    this.isSelected = false,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context);
    final bg = color ?? (isSelected ? theme.textColor : theme.surfaceColor);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: bg,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: theme.lightShadow,
              offset: const Offset(-4, -4),
              blurRadius: 8,
            ),
            BoxShadow(
              color: theme.darkShadow,
              offset: const Offset(4, 4),
              blurRadius: 8,
            ),
          ],
        ),
        child: Center(child: child),
      ),
    );
  }
}

class GlassmorphicContainer extends StatelessWidget {
  final Widget child;
  final double blur;
  final double opacity;
  final BorderRadius borderRadius;
  final EdgeInsetsGeometry? padding;

  const GlassmorphicContainer({
    super.key,
    required this.child,
    this.blur = 20.0,
    this.opacity = 0.9,
    this.borderRadius = const BorderRadius.all(Radius.circular(24.0)),
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context);
    return ClipRRect(
      borderRadius: borderRadius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          padding: padding ?? const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: theme.surfaceColor.withAlpha((opacity * 255).toInt()),
            borderRadius: borderRadius,
            border: Border.all(
              color: theme.textColor.withAlpha(20),
              width: 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: theme.darkShadow.withAlpha(40),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}
