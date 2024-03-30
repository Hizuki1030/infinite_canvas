import 'package:flutter/material.dart';

import '../../domain/model/node.dart';
import '../state/controller.dart';
import 'clipper.dart';
import 'drag_handel.dart';

import 'dart:math' as math;

class NodeRenderer extends StatelessWidget {
  const NodeRenderer({
    super.key,
    required this.node,
    required this.controller,
  });

  final InfiniteCanvasNode node;
  final InfiniteCanvasController controller;

  static const double borderInset = 2;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final fonts = Theme.of(context).textTheme;
    final showHandles = node.allowResize && controller.isSelected(node.key);
    return Transform.rotate(
      alignment: Alignment.topLeft,
      angle: (node.rotate ?? 0) * math.pi / 180, // Convert degrees to radians
      child: SizedBox.fromSize(
        size: node.size,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            if (node.label != null)
              Positioned(
                top: -25,
                left: 0,
                child: Text(
                  node.label!,
                  style: fonts.bodyMedium?.copyWith(
                    color: colors.onSurface,
                    shadows: [
                      Shadow(
                        offset: const Offset(0.8, 0.8),
                        blurRadius: 3,
                        color: colors.surface,
                      ),
                    ],
                  ),
                ),
              ),
            if (controller.isSelected(node.key) || controller.isHovered(node.key))
  Positioned(
    top: node.rect.top - node.offset.dy,
    left: node.rect.left - node.offset.dx,
    child: Container(
      width: node.rect.width,
      height: node.rect.height,
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.5),
        border: Border.all(
          color: Colors.black,
          width: 1,
        ),
      ),
    ),
  ),
            if (controller.isSelected(node.key) ||
                controller.isHovered(node.key))
              Positioned(
                top: -borderInset + node.dragRectOffset.dy,
                left: -borderInset + node.dragRectOffset.dx,
                right: -borderInset - node.dragRectOffset.dx,
                bottom: -borderInset- node.dragRectOffset.dy,
                child: IgnorePointer(
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: controller.isSelected(node.key)
                            ? colors.primary
                            : colors.outline,
                        width: 1,
                      ),
                    ),
                  ),
                ),
              ),
            Positioned.fill(
              key: key,
              child: node.clipBehavior != Clip.none
                  ? ClipRect(
                      clipper: Clipper(node.rect),
                      clipBehavior: node.clipBehavior,
                      child: node.child,
                    )
                  : node.child,
            ),
            if (showHandles) ...[
              // bottom right
              Positioned(
                right: 0,
                bottom: 0,
                child: GestureDetector(
                  onPanUpdate: (details) {
                    if (!controller.mouseDown) return;
                    node.update(size: node.size + details.delta);
                    controller.edit(node);
                  },
                  child: const DragHandel(),
                ),
              ),
              // bottom left
              Positioned(
                left: 0,
                bottom: 0,
                child: GestureDetector(
                  onPanUpdate: (details) {
                    if (!controller.mouseDown) return;
                    node.update(
                      size: node.size +
                          Offset(-details.delta.dx, details.delta.dy),
                      offset: node.offset + Offset(details.delta.dx, 0),
                    );
                    controller.edit(node);
                  },
                  child: const DragHandel(),
                ),
              ),
              // top right
              Positioned(
                right: 0,
                top: 0,
                child: GestureDetector(
                  onPanUpdate: (details) {
                    if (!controller.mouseDown) return;
                    node.update(
                      size: node.size +
                          Offset(details.delta.dx, -details.delta.dy),
                      offset: node.offset + Offset(0, details.delta.dy),
                    );
                    controller.edit(node);
                  },
                  child: const DragHandel(),
                ),
              ),
              // top left
              Positioned(
                left: 0,
                top: 0,
                child: GestureDetector(
                  onPanUpdate: (details) {
                    if (!controller.mouseDown) return;
                    node.update(
                      size: node.size + -details.delta,
                      offset: node.offset + details.delta,
                    );
                    controller.edit(node);
                  },
                  child: const DragHandel(),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
