import 'dart:ui' as ui show Offset, Paint, Canvas, Size;
import 'package:flutter_charts/src/chart/container.dart'
    as container show Container, LayoutExpansion;

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
        super(
            layoutExpansion:
                new container.LayoutExpansion.unused());

  // #####  Implementors of method in superclass [Container].

  void paint(ui.Canvas canvas) {
    canvas.drawLine(this.lineFrom, this.lineTo, this.linePaint);
  }

  /// Implementor of method in superclass [Container].
  void layout() {
    throw new StateError("No need to call layout on ${this.runtimeType}.");
  }

  /// Override method in superclass [Container].
  void applyParentOffset(ui.Offset offset) {
    super.applyParentOffset(offset);
    this.lineFrom += offset;
    this.lineTo += offset;
  }

  /// Implementor of method in superclass [Container].
  ui.Size get layoutSize => new ui.Size(
        (lineFrom.dx - lineTo.dx).abs(),
        (lineFrom.dy - lineTo.dy).abs(),
      );
}
