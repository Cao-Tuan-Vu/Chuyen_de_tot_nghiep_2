import 'package:flutter/material.dart';

/// Widget Card tùy chỉnh với styling đẹp
class StyledCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final Color? color;

  const StyledCard({
    super.key,
    required this.child,
    this.margin,
    this.onTap,
    this.color,
  }) : super();

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: margin,
      elevation: 2,
      color: color ?? Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: onTap != null
        ? InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: child,
          )
        : child,
    );
  }
}

