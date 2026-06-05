import 'package:flutter/widgets.dart';

class PopIcon {
  final String asset;
  final Offset start;
  final Offset end;
  final double size;
  final Interval interval;

  const PopIcon({
    required this.asset,
    required this.start,
    required this.end,
    required this.size,
    required this.interval,
  });
}
