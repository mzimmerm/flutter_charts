import 'dart:ui' as ui show Offset, Paint, Canvas;
import 'container_layouter_base.dart' show BoxContainer, LayoutableBox;
import '../morphic/rendering/constraints.dart' show BoxContainerConstraints;

/// Manages [lineFrom] and [lineTo] positions and [linePaint] for a line segment.
class LineContainer extends BoxContainer {
  ui.Paint linePaint;
  ui.Offset lineFrom;
  ui.Offset lineTo;
  // todo-00-last-last : added
  /// With manual layout, holds on to the layout value of horizontal or vertical lines,
  /// between the lifecycle events of [LineContainer]
  /// creation in parent [buildAndAddChildrenLateDuringParentLayout]
  /// and it's layout in parent [newCoreLayout].
  ///
  /// ONLY used on horizontal xLineContainer or vertical yLineContainer, maintains the
  /// coordinate that remains the same: y on xLineContainer, x on yLineContainer.
  ///
  double layoutValue;

  LineContainer({
    required this.lineFrom,
    required this.lineTo,
    required this.linePaint,
    BoxContainer? parent,
    this.layoutValue = 0.0,
  }) {
    this.parent = parent;
  }

  // #####  Implementors of method in superclass [Container].

  @override
  void paint(ui.Canvas canvas) {
    canvas.drawLine(lineFrom, lineTo, linePaint);
  }

  /// Implementor of method in superclass [Container].
  @override
  void layout(BoxContainerConstraints boxConstraints) {
    throw StateError('No need to call layout on $runtimeType, extension of LineContainer.');
  }

  /// Override method in superclass [Container].
  @override
  void applyParentOffset(LayoutableBox caller, ui.Offset offset) {
    super.applyParentOffset(caller, offset);
    lineFrom += offset;
    lineTo += offset;
    // todo-01-morph-layout-size-add : layoutSize = _lineContainerLayoutSize
  }

  // todo-01-morph : This is not called. Call when we manage line segments like other Containers, and call their layout!
/*
  ui.Size get _lineContainerLayoutSize => ui.Size(
        (lineFrom.dx - lineTo.dx).abs(),
        (lineFrom.dy - lineTo.dy).abs(),
      );
*/
}
