import 'dart:ui' as ui show Offset, Paint, Canvas;

import 'container_common.dart' as container_common_new;
import '../../morphic/container/container_layouter_base.dart' as container_base;
import '../view_maker.dart' as view_maker;
// import '../container.dart' as container;
import '../model/data_model.dart' as model;
import '../../util/util_labels.dart' as util_labels;

/// Leaf container manages [lineFrom] and [lineTo] positions and [linePaint] for a line segment.
class LineSegmentContainer extends container_common_new.ChartAreaContainer {

  LineSegmentContainer({
    required this.pointFrom,
    required this.pointTo,
    required this.linePaint,
    required this.constraintsSplitAxis,
    required view_maker.ChartViewMaker chartViewMaker,
  }) : super(
    chartViewMaker: chartViewMaker
  );


  /// Model contains the transformed, non-extrapolated values of the point where the line starts.
  final model.PointModel pointFrom;
  final model.PointModel pointTo;
  final ui.Paint linePaint;
  final container_base.LayoutAxis constraintsSplitAxis;

  /// Coordinates of the layed out pixel values.
  late final ui.Offset _pixelPointFrom;
  late final ui.Offset _pixelPointTo;


  // #####  Implementors of method in superclass [BoxContainer].

  /// Implementor of method in superclass [BoxContainer].
  ///
  /// Ensure [layoutSize] is set.
  /// Note that because this leaf container overrides [layout] here,
  /// it does not need to override [layout_Post_Leaf_SetSize_FromInternals].
  @override
  void layout() {
    buildAndReplaceChildren();

    // The switch below takes care of the pixel positioning aka layout.

    // layout the [pointFrom] and [pointTo] to pixels, by positioning:
    //   - in the [constraintsSplitAxis],      direction, on the constraints border
    //   - in the [constraintsSplitAxis]-cross direction, by extrapolating their value
    double pixelFromX, pixelFromY, pixelToX, pixelToY;

    // Which labels generator to use for scaling? That depends on which axis is 'independent'
    //   - switch constraints are split along
    //     - horizontal, parent is Row    by definition. We ASSUME dependent axis is Y, use it's extrapolation
    //     - vertical,   parent is Column by definition. We ASSUME dependent axis is X, use it's extrapolation
    util_labels.DataRangeLabelInfosGenerator labelInfosGenerator;

    switch(constraintsSplitAxis) {
      case container_base.LayoutAxis.horizontal:
        // Assuming Row, X is constraints.width, Y is extrapolating value to constraints.height
        labelInfosGenerator = chartViewMaker.yLabelsGenerator;
        pixelFromX = 0;
        pixelToX = constraints.width;
        pixelFromY = labelInfosGenerator.lextrValueToPixels(
          value: pointFrom.dataValue,
          axisPixelsMin: 0.0,
          axisPixelsMax: constraints.height,
        );
        pixelToY = labelInfosGenerator.lextrValueToPixels(
          value: pointTo.dataValue,
          axisPixelsMin: 0.0,
          axisPixelsMax: constraints.height,
        );
        break;
      case container_base.LayoutAxis.vertical:
      // Assuming Row, Y is constraints.height, X is extrapolating value to constraints.width
        labelInfosGenerator = chartViewMaker.xLabelsGenerator;
        pixelFromY = 0;
        pixelToY = constraints.height;
        pixelFromX = labelInfosGenerator.lextrValueToPixels(
          value: pointFrom.dataValue,
          axisPixelsMin: 0.0,
          axisPixelsMax: constraints.width,
        );
        pixelToX = labelInfosGenerator.lextrValueToPixels(
          value: pointTo.dataValue,
          axisPixelsMin: 0.0,
          axisPixelsMax: constraints.width,
        );
        break;
    }

    _pixelPointFrom = ui.Offset(pixelFromX, pixelFromY);
    _pixelPointTo = ui.Offset(pixelToX, pixelToY);

    layoutSize = constraints.size; // todo-00!! is this right?
  }

  /// Override method in superclass [Container].
  @override
  void applyParentOffset(container_base.LayoutableBox caller, ui.Offset offset) {
    super.applyParentOffset(caller, offset);

    _pixelPointFrom += offset;
    _pixelPointTo += offset;
  }

  @override
  void paint(ui.Canvas canvas) {
    canvas.drawLine(_pixelPointFrom, _pixelPointTo, linePaint);
  }

  @override
  void buildAndReplaceChildren() {
    buildAndReplaceChildrenDefault();
  }
}
