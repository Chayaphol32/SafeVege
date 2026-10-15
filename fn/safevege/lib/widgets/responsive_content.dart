import 'package:flutter/material.dart';

import '../theme/design_tokens.dart';

/// วิดเจ็ตสำหรับควบคุมความกว้างการแสดงผลให้เหมาะสมกับหน้าจอ (Responsive Container)
class ResponsiveContent extends StatelessWidget {
  const ResponsiveContent({
    super.key,
    required this.child,
    this.maxWidth = AppContentWidth.page,
    this.padding = EdgeInsets.zero,
  });

  final Widget child;
  final double maxWidth;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}
