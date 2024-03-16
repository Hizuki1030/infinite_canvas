import 'package:flutter/material.dart';

/// A node in the [InfiniteCanvas].
class InfiniteCanvasNode<T> {
  InfiniteCanvasNode({
    required this.key,
    required this.size,
    required this.offset,
    required this.child,
    this.rotate,
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
  late int? rotate;
  String? label;
  T? value;
  final Widget child;
  bool allowResize, allowMove, allowRotate;
  final Clip clipBehavior;
  Rect get rect => offset & size;
  static const double dragHandleSize = 10;
  static const double borderInset = 2;

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
}
