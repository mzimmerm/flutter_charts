import 'dart:ui' as ui show Offset, Paint, Canvas, Size;
import 'package:flutter_charts/src/chart/container.dart'
    as container show Container;
import 'package:flutter_charts/src/morphic/rendering/constraints.dart'
    show LayoutExpansion;

/// Manages [lineFrom] and [lineTo] positions and [linePaint] for a line segment.
class LineContainer extends container.Container {
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
    // todo-00-last-last-layout-size-add
    // _layoutSize = _lineContainerLayoutSize;
  }

  // #####  Implementors of method in superclass [Container].

  void paint(ui.Canvas canvas) {
    canvas.drawLine(this.lineFrom, this.lineTo, this.linePaint);
  }

  /// Implementor of method in superclass [Container].
  void layout(LayoutExpansion layoutExpansion) {
    throw new StateError("No need to call layout on ${this.runtimeType}.");
  }

  /// Override method in superclass [Container].
  void applyParentOffset(ui.Offset offset) {
    super.applyParentOffset(offset);
    this.lineFrom += offset;
    this.lineTo += offset;
    // todo-00-last-last-layout-size-add : _layoutSize = _lineContainerLayoutSize
  }

  /// Implementor of method in superclass [Container].
  // todo-00-last-last-layout-size-remove : 
  ui.Size get layoutSize => new ui.Size(
        (lineFrom.dx - lineTo.dx).abs(),
        (lineFrom.dy - lineTo.dy).abs(),
      );
  // todo-00-last-last-layout-size-added : 
  ui.Size get _lineContainerLayoutSize => new ui.Size(
    (lineFrom.dx - lineTo.dx).abs(),
    (lineFrom.dy - lineTo.dy).abs(),
  );
}
