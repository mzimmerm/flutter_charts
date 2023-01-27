import 'dart:ui' as ui show Offset, Paint, Canvas;
import 'container_layouter_base.dart' show BoxContainer, LayoutableBox;

/// Manages [lineFrom] and [lineTo] positions and [linePaint] for a line segment.
class LineContainer extends BoxContainer {
  /// Points from which line starts and ends. NOT added to children ATM.
  ui.Offset lineFrom;
  ui.Offset lineTo;
  ui.Paint linePaint;

  // todo-01-full-autolayout : manualLayedOutFromX and friends ADDED TEMPORARILY to be set during construction
  //                         : of [LineContainer] in [GridLinesContainer.buildAndAddChildren_DuringParentLayout]
  //                         : where these layout values are calculated, held on,
  //                         : and used later in self [layout], to set [lineFrom] and [lineTo]
  //                         : THIS IS TEMPORARY FOR MANUAL LAYOUT TO SHUFFLE VALUES FROM PARENT LAYOUT
  //                         : (GridLinesContainer, something else??) TO LineContainer.layout()
  /// With manual layout, holds on to the layout value of horizontal or vertical lines,
  /// between the lifecycle events of [LineContainer]
  /// creation in parent [buildAndAddChildren_DuringParentLayout]
  /// and it's layout in parent [layout].
  ///
  /// ONLY used on horizontal xLineContainer or vertical yLineContainer, maintains the
  /// coordinate that remains the same: y on xLineContainer, x on yLineContainer.
  ///
  double manualLayedOutFromX;
  double manualLayedOutFromY;
  double manualLayedOutToX;
  double manualLayedOutToY;

  LineContainer({
    required this.lineFrom,
    required this.lineTo,
    required this.linePaint,
    this.manualLayedOutFromX = 0.0,
    this.manualLayedOutFromY = 0.0,
    this.manualLayedOutToX = 0.0,
    this.manualLayedOutToY = 0.0,
  });

  // #####  Implementors of method in superclass [Container].

  /// Implementor of method in superclass [Container].
  ///
  /// Ensure [layoutSize] is set.
  /// Note that because this leaf container overrides [layout] here,
  /// it does not need to override [post_Leaf_SetSize_FromInternals].
  @override
  void layout() {
    // Use the coordinates manually layed out during creation in [GridLinesContainer] by
    lineFrom = ui.Offset(manualLayedOutFromX, manualLayedOutFromY);
    lineTo = ui.Offset(manualLayedOutToX, manualLayedOutToY);

    layoutSize = constraints.size;
  }

  /// Override method in superclass [Container].
  @override
  void applyParentOffset(LayoutableBox caller, ui.Offset offset) {
    super.applyParentOffset(caller, offset);
    lineFrom += offset;
    lineTo += offset;
  }

  @override
  void paint(ui.Canvas canvas) {
    canvas.drawLine(lineFrom, lineTo, linePaint);
  }
}
