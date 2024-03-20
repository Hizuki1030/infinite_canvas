import 'dart:math';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:random_color/random_color.dart';
import 'package:infinite_canvas/infinite_canvas.dart';
import '../../domain/model/edge.dart';
import '../../domain/model/graph.dart';
import '../../domain/model/node.dart';

typedef NodeFormatter = void Function(InfiniteCanvasNode);

/// A controller for the [InfiniteCanvas].
class InfiniteCanvasController extends ChangeNotifier implements Graph {
  InfiniteCanvasController({
    List<InfiniteCanvasNode> nodes = const [],
    List<InfiniteCanvasEdge> edges = const [],
  }) {
    if (nodes.isNotEmpty) {
      this.nodes.addAll(nodes);
    }
    if (edges.isNotEmpty) {
      this.edges.addAll(edges);
    }
  }

  double minScale = 0.4;
  double maxScale = 4;
  final focusNode = FocusNode();
  Size? viewport;

  Size? _gridSize;
  // Public setter for grid size
  set gridSize(Size value) {
    if (value != _gridSize) {
      _gridSize = value;
      notifyListeners();
    }
  }

  @override
  final List<InfiniteCanvasNode> nodes = [];

  @override
  final List<InfiniteCanvasEdge> edges = [];

  final Set<Key> _selected = {};
  List<InfiniteCanvasNode> get selection =>
      nodes.where((e) => _selected.contains(e.key)).toList();
  final Set<Key> _hovered = {};
  List<InfiniteCanvasNode> get hovered =>
      nodes.where((e) => _hovered.contains(e.key)).toList();

  void _cacheSelectedOrigins() {
    // cache selected node origins
    _selectedOrigins.clear();
    for (final key in _selected) {
      final index = nodes.indexWhere((e) => e.key == key);
      if (index == -1) continue;
      final current = nodes[index];
      _selectedOrigins[key] = current.offset;
    }
  }

  void _cacheSelectedOrigin(Key key) {
    final index = nodes.indexWhere((e) => e.key == key);
    if (index == -1) return;
    final current = nodes[index];
    _selectedOrigins[key] = current.offset;
  }

  final Map<Key, Offset> _selectedOrigins = {};

  late final transform = TransformationController();
  Matrix4 get matrix => transform.value;
  Offset mousePosition = Offset.zero;
  Offset? mouseDragStart;
  Offset? marqueeStart, marqueeEnd;
  LocalKey? linkStart;

  void _formatAll() {
    for (InfiniteCanvasNode node in nodes) {
      _formatter!(node);
    }
  }

  bool _formatterHasChanged = false;
  NodeFormatter? _formatter;
  set formatter(NodeFormatter value) {
    _formatterHasChanged = _formatter != value;

    if (_formatterHasChanged == false) return;

    _formatter = value;
    _formatAll();
    notifyListeners();
  }

  Offset? _linkEnd;
  Offset? get linkEnd => _linkEnd;
  set linkEnd(Offset? value) {
    if (value == _linkEnd) return;
    _linkEnd = value;
    notifyListeners();
  }

  bool _mouseDown = false;
  bool get mouseDown => _mouseDown;
  set mouseDown(bool value) {
    if (value == _mouseDown) return;
    _mouseDown = value;
    notifyListeners();
  }

  bool _shiftPressed = false;
  bool get shiftPressed => _shiftPressed;
  set shiftPressed(bool value) {
    if (value == _shiftPressed) return;
    _shiftPressed = value;
    notifyListeners();
  }

  bool _spacePressed = false;
  bool get spacePressed => _spacePressed;
  set spacePressed(bool value) {
    if (value == _spacePressed) return;
    _spacePressed = value;
    notifyListeners();
  }

  bool _controlPressed = false;
  bool get controlPressed => _controlPressed;
  set controlPressed(bool value) {
    if (value == _controlPressed) return;
    _controlPressed = value;
    notifyListeners();
  }

  bool _metaPressed = false;
  bool get metaPressed => _metaPressed;
  set metaPressed(bool value) {
    if (value == _metaPressed) return;
    _metaPressed = value;
    notifyListeners();
  }

  double _scale = 1;
  double get scale => _scale;
  set scale(double value) {
    if (value == _scale) return;
    _scale = value;
    notifyListeners();
  }

  double getScale() {
    final matrix = transform.value;
    final scaleX = matrix.getMaxScaleOnAxis();
    return scaleX;
  }

  Rect getMaxSize() {
    Rect rect = Rect.zero;
    for (final child in nodes) {
      rect = Rect.fromLTRB(
        min(rect.left, child.rect.left),
        min(rect.top, child.rect.top),
        max(rect.right, child.rect.right),
        max(rect.bottom, child.rect.bottom),
      );
    }
    return rect;
  }

  bool isSelected(LocalKey key) => _selected.contains(key);
  bool isHovered(LocalKey key) => _hovered.contains(key);

  bool get hasSelection => _selected.isNotEmpty;

  bool get canvasMoveEnabled => !mouseDown;

  Offset toLocal(Offset global) {
    return transform.toScene(global);
  }

  void checkSelection(Offset localPosition, [bool hover = false]) {
    final offset = toLocal(localPosition);
    final selection = <Key>[];
    for (final child in nodes) {
      final rect = child.rect;
      if (rect.contains(offset)) {
        selection.add(child.key);
      }
    }
    if (selection.isNotEmpty) {
      if (shiftPressed) {
        setSelection({selection.last, ..._selected.toSet()}, hover);
      } else {
        setSelection({selection.last}, hover);
      }
    } else {
      deselectAll(hover);
    }
  }

  void checkMarqueeSelection([bool hover = false]) {
    if (marqueeStart == null || marqueeEnd == null) return;
    final selection = <Key>{};
    final rect = Rect.fromPoints(
      toLocal(marqueeStart!),
      toLocal(marqueeEnd!),
    );
    for (final child in nodes) {
      if (rect.overlaps(child.rect)) {
        selection.add(child.key);
      }
    }
    if (selection.isNotEmpty) {
      if (shiftPressed) {
        setSelection(selection.union(_selected.toSet()), hover);
      } else {
        setSelection(selection, hover);
      }
    } else {
      deselectAll(hover);
    }
  }

  InfiniteCanvasNode? getNode(LocalKey? key) {
    if (key == null) return null;
    return nodes.firstWhereOrNull((e) => e.key == key);
  }

  void addLink(LocalKey from, LocalKey to, [String? label]) {
    final edge = InfiniteCanvasEdge(
      from: from,
      to: to,
      label: label,
    );
    edges.add(edge);
    notifyListeners();
  }

  void rotateSelection(int angle) {
    if (_selected.isEmpty) return;

    // 複数のオブジェクトの最大座標と最小座標を算出
    double minX = double.infinity;
    double minY = double.infinity;
    double maxX = double.negativeInfinity;
    double maxY = double.negativeInfinity;
    for (final key in _selected) {
      final node = nodes.firstWhereOrNull((e) => e.key == key);
      if (node != null) {
        final rect = node.rect;
        final offset = node.offset;
        minX = min(minX, rect.left);
        minY = min(minY, rect.top);
        maxX = max(maxX, rect.right);
        maxY = max(maxY, rect.bottom);
      }
    }

// 中心点を算出
  final center = Offset(0,0);
    if (_gridSize != null) {
      final center = Offset(
          (((minX + maxX) / 2) / _gridSize!.width).roundToDouble() * _gridSize!.width,
          (((minY + maxY) / 2) / _gridSize!.height).roundToDouble() * _gridSize!.height);
    }
    // 中心を基準に各オブジェクトを回転
    for (final key in _selected) {
      final index = nodes.indexWhere((e) => e.key == key);
      if (index == -1) continue;
      final current = nodes[index];

      // 回転前の中心位置との差分を計算
      final diff = current.offset - center;

      // 角度をラジアンに変換
      final radians = angle * pi / 180;

      // 回転後の差分を計算
      final rotatedDiff = Offset(
        diff.dx * cos(radians) - diff.dy * sin(radians),
        diff.dx * sin(radians) + diff.dy * cos(radians),
      );

      // 新しい中心位置を計算
      final newOffset = center + rotatedDiff;

      // 新しい位置と角度を設
      final newAngle = (current.rotate ?? 0) + angle;
      current.update(offset: newOffset, rotate: newAngle);

      if (_formatter != null) {
        _formatter!(current);
      }
    }

    notifyListeners();
  }

  void moveSelection(Offset position) {
    Offset delta = mouseDragStart != null
        ? toLocal(position) - toLocal(mouseDragStart!)
        : toLocal(position);
    if (_gridSize != null) {
      delta = Offset(
          (delta.dx / _gridSize!.width).roundToDouble() * _gridSize!.width,
          (delta.dy / _gridSize!.height).roundToDouble() * _gridSize!.height);
    }
    for (final key in _selected) {
      final index = nodes.indexWhere((e) => e.key == key);
      if (index == -1) continue;
      final current = nodes[index];
      final origin = _selectedOrigins[key];
      current.update(offset: origin! + delta);
      if (_formatter != null) {
        _formatter!(current);
      }
    }
    notifyListeners();
  }

  void select(Key key, [bool hover = false]) {
    if (hover) {
      _hovered.add(key);
    } else {
      _selected.add(key);
      _cacheSelectedOrigin(key);
    }

    notifyListeners();
  }

  void setSelection(Set<Key> keys, [bool hover = false]) {
    List<LocalKey> keysIncludeGroup = keys.whereType<LocalKey>().toList();
    List<LocalKey> selectedGroupKeys = [];
    for (final key in keys) {
      for (final node in nodes) {
        if (node.key == key) {
          if (node.groupKey != null) {
            selectedGroupKeys.add(node.groupKey!);
          }
        }
      }
    }
    for (final selectedGroupKey in selectedGroupKeys) {
      for (final node in nodes) {
        if (node.groupKey == selectedGroupKey) {
          node.allowResize = false;
          keysIncludeGroup.add(node.key);
        }
      }
    }
    if (!_controlPressed) {
      if (hover) {
        _hovered.clear();
        _hovered.addAll(keysIncludeGroup);
      } else {
        _selected.clear();
        _selected.addAll(keysIncludeGroup);
        _cacheSelectedOrigins();
      }
    } else {
      if (hover) {
        _hovered.clear();
        _hovered.addAll(keys);
      } else {
        _selected.clear();
        _selected.addAll(keys);
        _cacheSelectedOrigins();
      }
    }

    notifyListeners();
  }

  void deselect(Key key, [bool hover = false]) {
    if (hover) {
      _hovered.remove(key);
    } else {
      _selected.remove(key);
      _selectedOrigins.remove(key);
    }
    notifyListeners();
  }

  void deselectAll([bool hover = false]) {
    if (hover) {
      _hovered.clear();
    } else {
      _selected.clear();
      _selectedOrigins.clear();
    }
    notifyListeners();
  }

  void add(InfiniteCanvasNode child) {
    if (_formatter != null) {
      _formatter!(child);
    }
    nodes.add(child);
    notifyListeners();
  }

  void edit(InfiniteCanvasNode child) {
    if (_selected.length == 1) {
      final idx = nodes.indexWhere((e) => e.key == _selected.first);
      nodes[idx] = child;
      notifyListeners();
    }
  }

  void remove(Key key) {
    nodes.removeWhere((e) => e.key == key);
    _selected.remove(key);
    _selectedOrigins.remove(key);
    notifyListeners();
  }

  void bringToFront() {
    final selection = _selected.toList();
    for (final key in selection) {
      final index = nodes.indexWhere((e) => e.key == key);
      if (index == -1) continue;
      final current = nodes[index];
      nodes.removeAt(index);
      nodes.add(current);
    }
    notifyListeners();
  }

  void sendBackward() {
    final selection = _selected.toList();
    if (selection.length == 1) {
      final key = selection.first;
      final index = nodes.indexWhere((e) => e.key == key);
      if (index == -1) return;
      if (index == 0) return;
      final current = nodes[index];
      nodes.removeAt(index);
      nodes.insert(index - 1, current);
      notifyListeners();
    }
  }

  void sendForward() {
    final selection = _selected.toList();
    if (selection.length == 1) {
      final key = selection.first;
      final index = nodes.indexWhere((e) => e.key == key);
      if (index == -1) return;
      if (index == nodes.length - 1) return;
      final current = nodes[index];
      nodes.removeAt(index);
      nodes.insert(index + 1, current);
      notifyListeners();
    }
  }

  void sendToBack() {
    final selection = _selected.toList();
    for (final key in selection) {
      final index = nodes.indexWhere((e) => e.key == key);
      if (index == -1) continue;
      final current = nodes[index];
      nodes.removeAt(index);
      nodes.insert(0, current);
    }
    notifyListeners();
  }

  void deleteSelection() {
    final selection = _selected.toList();
    for (final key in selection) {
      final index = nodes.indexWhere((e) => e.key == key);
      if (index == -1) continue;
      nodes.removeAt(index);
      _selectedOrigins.remove(key);
    }
    // Delete related connections
    edges.removeWhere(
      (e) => selection.contains(e.from) || selection.contains(e.to),
    );
    notifyListeners();
  }

  void selectAll() {
    _selected.clear();
    _selected.addAll(nodes.map((e) => e.key).toList());
    _cacheSelectedOrigins();
    notifyListeners();
  }

  void zoom(double delta) {
    final matrix = transform.value.clone();
    final local = toLocal(mousePosition);
    matrix.translate(local.dx, local.dy);
    matrix.scale(delta, delta);
    matrix.translate(-local.dx, -local.dy);
    transform.value = matrix;
    notifyListeners();
  }

  void zoomIn() => zoom(1.1);
  void zoomOut() => zoom(0.9);
  void zoomReset() => transform.value = Matrix4.identity();

  void pan(Offset delta) {
    final matrix = transform.value.clone();
    matrix.translate(delta.dx, delta.dy);
    transform.value = matrix;
    notifyListeners();
  }

  void panUp() => pan(const Offset(0, -10));
  void panDown() => pan(const Offset(0, 10));
  void panLeft() => pan(const Offset(-10, 0));
  void panRight() => pan(const Offset(10, 0));

  Offset getOffset() {
    final matrix = transform.value.clone();
    matrix.invert();
    final result = matrix.getTranslation();
    return Offset(result.x, result.y);
  }

  Rect getRect(BoxConstraints constraints) {
    final offset = getOffset();
    final scale = matrix.getMaxScaleOnAxis();
    final size = constraints.biggest;
    return offset & size / scale;
  }
}

class InlineCustomPainter extends CustomPainter {
  const InlineCustomPainter({
    required this.brush,
    required this.builder,
    this.isAntiAlias = true,
  });
  final Paint brush;
  final bool isAntiAlias;
  final void Function(Paint paint, Canvas canvas, Rect rect) builder;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    brush.isAntiAlias = isAntiAlias;
    canvas.save();
    builder(brush, canvas, rect);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
