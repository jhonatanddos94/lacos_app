import 'package:flutter/material.dart';

import 'package:lacos_app/core/theme/app_radius.dart';

class AppSkeletonBox extends StatelessWidget {
  const AppSkeletonBox({
    required this.height,
    this.width,
    this.borderRadius,
    this.testKey,
    super.key,
  });

  final double height;
  final double? width;
  final BorderRadius? borderRadius;
  final Key? testKey;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final resolvedColor = colorScheme.surfaceContainerHighest;

    return ExcludeSemantics(
      child: Container(
        key: testKey,
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: resolvedColor,
          borderRadius: borderRadius ?? AppRadius.borderSm,
        ),
      ),
    );
  }
}
