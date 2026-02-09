import 'package:flutter/material.dart';
import 'package:sixam_mart/util/dimensions.dart';

/// ⚡ TASK 1: Extracted flattened module content to reduce nesting
class FlattenedModuleContent extends StatelessWidget {
  final Widget moduleWidget;

  const FlattenedModuleContent({
    super.key,
    required this.moduleWidget,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: Dimensions.webMaxWidth,
        child: moduleWidget,
      ),
    );
  }
}

