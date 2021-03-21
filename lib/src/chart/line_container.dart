import 'dart:ui' as ui show Offset, Paint, Canvas, Size;
import 'package:flutter_charts/src/chart/container_base.dart'
    as container_base show Container;
import 'package:flutter_charts/src/morphic/rendering/constraints.dart'
    show LayoutExpansion;

/// Manages [lineFrom] and [lineTo] positions and [linePaint] for a line segment.
class LineContainer extends container_base.Container {
  ui.Paint linePaint;
  ui.Offset lineFrom;
  ui.Offset lineTo;

  LineContainer({
    required ui.Offset lineFrom,
    required ui.Offset lineTo,
    required ui.Paint linePaint,
  })   : this.linePaint = linePaint,
        this.lineFrom = lineFrom,
        this.lineTo = lineTo,
        super() {
    // todo-00-last-layout-size-add
    // layoutSize = _lineContainerLayoutSize;
  }

  // #####  Implementors of method in superclass [Container].

  void paint(ui.Canvas canvas) {
    canvas.drawLine(this.lineFrom, this.lineTo, this.linePaint);
  }

  /// Implementor of method in superclass [Container].
  void layout(LayoutExpansion parentLayoutExpansion) {
    throw new StateError("No need to call layout on ${this.runtimeType}.");
  }

  /// Override method in superclass [Container].
  void applyParentOffset(ui.Offset offset) {
    super.applyParentOffset(offset);
    this.lineFrom += offset;
    this.lineTo += offset;
    // todo-00-last-layout-size-add : layoutSize = _lineContainerLayoutSize
  }

  // todo-00-last-layout-size : This is not called. Call when we manage line segments like other Containers, and call their layout! 
  ui.Size get _lineContainerLayoutSize => new ui.Size(
    (lineFrom.dx - lineTo.dx).abs(),
    (lineFrom.dy - lineTo.dy).abs(),
  );
}
