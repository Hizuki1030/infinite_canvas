import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'ic_attribute.dart';

class InfiniteCanvasNode<T> {
  InfiniteCanvasNode({
    required this.key,
    required this.size,
    required this.offset,
    required this.child,
    this.groupKey,
    this.attribute,
    this.rotate = 0,
    this.label,
    this.allowResize = false,
    this.allowMove = true,
    this.allowRotate = true,
    this.clipBehavior = Clip.none,
    this.value,
    this.ic_attribute,
  });

  String get id => key.toString();

  final LocalKey key;
  LocalKey? groupKey;

  late Size size;
  late Offset offset;
  Offset dragRectOffset = Offset(0, 0);
  late int rotate = 0;
  String? label;
  String? attribute;
  T? value;
  final Widget child;
  bool allowResize, allowMove, allowRotate;
  final Clip clipBehavior;
  IcAttribute? ic_attribute;

  static const double dragHandleSize = 10;
  static const double borderInset = 2;

  Rect get rect => _getRotatedRect();

  void update({
    Size? size,
    Offset? offset,
    String? label,
    int? rotate,
  }) {
    if (offset != null && allowMove) this.offset = offset;
    if (rotate != null && allowRotate) this.rotate = rotate;
    if (size != null && allowResize) {
      if (size.width < dragHandleSize * 2) {
        size = Size(dragHandleSize * 2, size.height);
      }
      if (size.height < dragHandleSize * 2) {
        size = Size(size.width, dragHandleSize * 2);
      }
      this.size = size;
    }
    if (label != null) this.label = label;
  }

  Rect _getRotatedRect() {
    final double rad = rotate * math.pi / 180;
    final Offset center = offset + Offset(size.width / 2, size.height / 2);

    List<Offset> corners = [
      Offset(-size.width / 2, -size.height / 2),
      Offset(size.width / 2, -size.height / 2),
      Offset(size.width / 2, size.height / 2),
      Offset(-size.width / 2, size.height / 2),
    ];

    List<Offset> rotatedCorners = corners.map((corner) {
      final double xNew = corner.dx * math.cos(rad) - corner.dy * math.sin(rad);
      final double yNew = corner.dx * math.sin(rad) + corner.dy * math.cos(rad);
      return center + Offset(xNew, yNew);
    }).toList();

    double minX = rotatedCorners.map((e) => e.dx).reduce(math.min);
    double maxX = rotatedCorners.map((e) => e.dx).reduce(math.max);
    double minY = rotatedCorners.map((e) => e.dy).reduce(math.min);
    double maxY = rotatedCorners.map((e) => e.dy).reduce(math.max);

    return Rect.fromLTRB(minX, minY, maxX, maxY);
  }
}
