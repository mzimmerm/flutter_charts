import 'dart:ui' as ui show Offset, Paint, Canvas, Size;
import 'package:flutter_charts/src/chart/container_base.dart' as container_base show Container;
import 'package:flutter_charts/src/morphic/rendering/constraints.dart' show LayoutExpansion;

/// Manages [lineFrom] and [lineTo] positions and [linePaint] for a line segment.
class LineContainer extends container_base.Container {
  ui.Paint linePaint;
  ui.Offset lineFrom;
  ui.Offset lineTo;

  LineContainer({
    required this.lineFrom,
    required this.lineTo,
    required this.linePaint,
  }) {
    // todo-13-layout-size-add
    // layoutSize = _lineContainerLayoutSize;
  }

  // #####  Implementors of method in superclass [Container].

  @override
  void paint(ui.Canvas canvas) {
    canvas.drawLine(lineFrom, lineTo, linePaint);
  }

  /// Implementor of method in superclass [Container].
  @override
  void layout(LayoutExpansion parentLayoutExpansion) {
    throw StateError('No need to call layout on $runtimeType.');
  }

  /// Override method in superclass [Container].
  @override
  void applyParentOffset(ui.Offset offset) {
    super.applyParentOffset(offset);
    lineFrom += offset;
    lineTo += offset;
    // todo-13-layout-size-add : layoutSize = _lineContainerLayoutSize
  }

  // todo-13layout-size : This is not called. Call when we manage line segments like other Containers, and call their layout!
  ui.Size get _lineContainerLayoutSize => ui.Size(
        (lineFrom.dx - lineTo.dx).abs(),
        (lineFrom.dy - lineTo.dy).abs(),
      );
}
