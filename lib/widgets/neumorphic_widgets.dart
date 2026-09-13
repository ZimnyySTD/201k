import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'theme_provider.dart';

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
    this.borderRadius = 18.0,
    this.onTap,
    this.isPressed = false,
    this.depth = 6.0,
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
    final bg = color ?? (isSelected ? theme.accentColor : theme.surfaceColor);

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
    this.opacity = 0.25,
    this.borderRadius = const BorderRadius.all(Radius.circular(24.0)),
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: borderRadius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          padding: padding ?? const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: Colors.white.withAlpha((opacity * 255).toInt()),
            borderRadius: borderRadius,
            border: Border.all(
              color: Colors.white.withAlpha(50),
              width: 1.5,
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}
