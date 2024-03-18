import 'dart:math' as math;
import 'package:flutter/material.dart';

class InfiniteCanvasNode<T> {
  InfiniteCanvasNode({
    required this.key,
    required this.size,
    required this.offset,
    required this.child,
    this.rotate = 0,
    this.label,
    this.allowResize = false,
    this.allowMove = true,
    this.allowRotate = true,
    this.clipBehavior = Clip.none,
    this.value,
  });

  String get id => key.toString();

  final LocalKey key;
  LocalKey? groupKey;

  late Size size;
  late Offset offset;
  late int rotate = 0;
  String? label;
  T? value;
  final Widget child;
  bool allowResize, allowMove, allowRotate;
  final Clip clipBehavior;

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
    Rect rotatedRect;
    if (rotate % 360 == 0) rotate = 0;
    if (rotate == 0) {
      rotatedRect = offset & size;
    } else if (rotate % 270 == 0) {
      rotatedRect = Offset(offset.dx, offset.dy - size.width) &
          Size(size.height, size.width);
    } else if (rotate % 180 == 0) {
      rotatedRect = Offset(offset.dx - size.width, offset.dy - size.height) &
          Size(size.width, size.height);
    } else if (rotate % 90 == 0) {
      rotatedRect = Offset(offset.dx - size.height, offset.dy) &
          Size(size.height, size.width);
    } else {
      rotatedRect = offset & size;
    }
    return rotatedRect;
  }
}
