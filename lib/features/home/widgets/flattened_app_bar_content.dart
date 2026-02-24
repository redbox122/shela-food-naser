import 'package:flutter/material.dart';
import 'package:sixam_mart/util/dimensions.dart';

/// ⚡ TASK 1: Extracted flattened app bar content to reduce nesting
class FlattenedAppBarContent extends StatelessWidget {
  final Widget searchWidget;
  final Widget addressWidget;

  const FlattenedAppBarContent({
    super.key,
    required this.searchWidget,
    required this.addressWidget,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
          child: searchWidget,
        ),
        const SizedBox(height: 4),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 5),
          child: addressWidget,
        ),
      ],
    );
  }
}

