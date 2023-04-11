import 'dart:ui' as ui show Offset, Paint, Canvas;

// this level

import '../../morphic/container/container_layouter_base.dart' show LayoutableBox;
import '../../chart/container/container_common.dart' as container_common_new show ChartAreaContainer;
import '../../chart/view_maker.dart';


/// Manages [lineFrom] and [lineTo] positions and [linePaint] for a line segment.
class LineContainerCL extends container_common_new.ChartAreaContainer {
  /// Points from which line starts and ends. NOT added to children ATM.
  ui.Offset lineFrom;
  ui.Offset lineTo;
  ui.Paint linePaint;

  // todo-02-full-autolayout : manualLayedOutFromX and friends ADDED TEMPORARILY to be set during construction
  //                         : of [LineContainer] in [GridLinesContainer.buildAndReplaceChildren]
  //                         : where these layout values are calculated, held on,
  //                         : and used later in self [layout], to set [lineFrom] and [lineTo]
  //                         : THIS IS TEMPORARY FOR MANUAL LAYOUT TO SHUFFLE VALUES FROM PARENT LAYOUT
  //                         : (GridLinesContainer, something else??) TO LineContainer.layout()
  /// With manual layout, holds on to the layout value of horizontal or vertical lines,
  /// between the lifecycle events of [LineContainerCL]
  /// creation in parent [buildAndReplaceChildren]
  /// and it's layout in parent [layout].
  ///
  /// ONLY used on horizontal xLineContainer or vertical yLineContainer, maintains the
  /// coordinate that remains the same: y on xLineContainer, x on yLineContainer.
  ///
  double manualLayedOutFromX;
  double manualLayedOutFromY;
  double manualLayedOutToX;
  double manualLayedOutToY;

  LineContainerCL({
    required ChartViewMaker chartViewMaker,
    required this.lineFrom,
    required this.lineTo,
    required this.linePaint,
    this.manualLayedOutFromX = 0.0,
    this.manualLayedOutFromY = 0.0,
    this.manualLayedOutToX = 0.0,
    this.manualLayedOutToY = 0.0,
  }) : super(
          chartViewMaker: chartViewMaker,
        );

  // #####  Implementors of method in superclass [Container].

  /// Implementor of method in superclass [Container].
  ///
  /// Ensure [layoutSize] is set.
  /// Note that because this leaf container overrides [layout] here,
  /// it does not need to override [layout_Post_Leaf_SetSize_FromInternals].
  @override
  void layout() {
    buildAndReplaceChildren();
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

  @override
  void buildAndReplaceChildren() {
    buildAndReplaceChildrenDefault();
  }
}
