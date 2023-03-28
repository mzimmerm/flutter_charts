import 'dart:ui' as ui show Offset, Paint, Canvas;

import 'package:flutter_charts/src/morphic/ui2d/point.dart';

import 'container_common.dart' as container_common_new;
import '../../morphic/container/container_layouter_base.dart' as container_base;
import '../../morphic/container/chart_support/chart_series_orientation.dart' as chart_orientation;
import '../view_maker.dart' as view_maker;
// import '../container.dart' as container;
import '../model/data_model.dart' as model;
// import '../../util/util_labels.dart' as util_labels;

/// Leaf container manages [lineFrom] and [lineTo] positions and [linePaint] for a line segment.
/// todo-00-last-last-progress IMPLEMENT
class LineSegmentContainer extends container_common_new.ChartAreaContainer
    with container_base.HeightSizerLayouterChild,
      container_base.WidthSizerLayouterChild
{

  LineSegmentContainer({
    required this.chartSeriesOrientation,
    required this.pointFrom,
    required this.pointTo,
    required this.linePaint,
    required view_maker.ChartViewMaker chartViewMaker,
  }) : super(
    chartViewMaker: chartViewMaker
  );

  /// Orientation of the chart bars: horizontal or vertical.
  final chart_orientation.ChartSeriesOrientation chartSeriesOrientation;

  /// Model contains the transformed, non-extrapolated values of the point where the line starts.
  final model.PointModel pointFrom;
  final model.PointModel pointTo;
  final ui.Paint linePaint;

  /// Coordinates of the layed out pixel values.
  // todo-00-last : use PointOffset instead of Offset
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

    // The code here takes care of the pixel positioning aka layout.

    /// Motivation for for lextr-ing Point inputValue and outputValue in context of chart and ChartSeriesOrientation.
    ///   In 'normal' situations, any PointOffset, originally representing data inputValue and outputValue values,
    ///       can live in a LineSegmentContainer which NORMALLY lives within a  MainAndCross (Row, Column) container.
    ///       DURING LAYOUT, THE LineSegmentContainer  WILL CHANGE THE PointOffset POSITION (valuer) BY LEXTR OR USING THE LAYOUTER.
    ///       (the LineSegmentContainer will position the PointOffset in layout_Post_NotLeaf_PositionChildren) ???

    // todo-00-last-last: Replace with Point.lextrInContextOf but KEEP this for reference
    //   create PointOffset from PointModel
    //   set _pixelPointFrom and To
    PointOffset fromPointOffset = pointFrom.pointOffsetWithInputRange(
        dataRangeLabelInfosGenerator: chartViewMaker.xLabelsGenerator,
    );
    PointOffset toPointOffset = pointTo.pointOffsetWithInputRange(
      dataRangeLabelInfosGenerator: chartViewMaker.xLabelsGenerator,
    );
    _pixelPointFrom = fromPointOffset.lextrInContextOf(
        chartSeriesOrientation: chartSeriesOrientation,
        constraintsOnImmediateOwner: constraints, // todo-00-last-last : THIS IS NOT RIGHT !!! NEED THE ROW CONSTRAINT??? MAYBE IT'S RIGHT??? constraintsOnImmediateOwner,
        inputDataRange: chartViewMaker.xLabelsGenerator.dataRange,
        outputDataRange: chartViewMaker.yLabelsGenerator.dataRange,
        heightToLextr: heightToLextr,
        widthToLextr: widthToLextr,
    );
    _pixelPointTo = toPointOffset.lextrInContextOf(
      chartSeriesOrientation: chartSeriesOrientation,
      constraintsOnImmediateOwner: constraints, // todo-00-last-last : THIS IS NOT RIGHT !!! NEED THE ROW CONSTRAINT??? MAYBE IT'S RIGHT??? constraintsOnImmediateOwner,
      inputDataRange: chartViewMaker.xLabelsGenerator.dataRange,
      outputDataRange: chartViewMaker.yLabelsGenerator.dataRange,
      heightToLextr: heightToLextr,
      widthToLextr: widthToLextr,
    );


    layoutSize = constraints.size; // todo-00-last-last : This is likely WRONG - SHOULD BE SOME KIND OF min/max across _pixelPointFrom, _pixelPointTo

    /* KEEP for now
    // layout the [pointFrom] and [pointTo] to pixels, by positioning:
    //   - in the [constraintsSplitAxis],      direction, on the constraints border
    //   - in the [constraintsSplitAxis]-cross direction, by extrapolating their value
    double pixelFromX, pixelFromY, pixelToX, pixelToY;

    // Which labels generator to use for scaling? That depends on which axis is 'input(independent)'
    //   - switch constraints are split along
    //     - horizontal, parent is Row    by definition. We ASSUME dependent axis is Y, use it's extrapolation
    //     - vertical,   parent is Column by definition. We ASSUME dependent axis is X, use it's extrapolation
    util_labels.DataRangeLabelInfosGenerator labelInfosGenerator;

    container_base.LayoutAxis chartPointsMainLayoutAxis = chartSeriesOrientation.mainLayoutAxis;

    switch(chartPointsMainLayoutAxis) {
      case container_base.LayoutAxis.horizontal:
        // Assuming Row, X is constraints.width, Y is extrapolating value to constraints.height
        labelInfosGenerator = chartViewMaker.yLabelsGenerator;
        pixelFromX = 0;
        pixelToX = constraints.width;
        pixelFromY = labelInfosGenerator.lextrValueToPixels(
          value: pointFrom.outputValue,
          axisPixelsMin: 0.0,
          axisPixelsMax: constraints.height,
        );
        pixelToY = labelInfosGenerator.lextrValueToPixels(
          value: pointTo.outputValue,
          axisPixelsMin: 0.0,
          axisPixelsMax: constraints.height,
        );
        break;
      case container_base.LayoutAxis.vertical:
        // Assuming Column, Y is constraints.height, X is extrapolating value to constraints.width
        labelInfosGenerator = chartViewMaker.xLabelsGenerator;
        pixelFromY = 0;
        pixelToY = constraints.height;
        pixelFromX = labelInfosGenerator.lextrValueToPixels(
          value: pointFrom.outputValue,
          axisPixelsMin: 0.0,
          axisPixelsMax: constraints.width,
        );
        pixelToX = labelInfosGenerator.lextrValueToPixels(
          value: pointTo.outputValue,
          axisPixelsMin: 0.0,
          axisPixelsMax: constraints.width,
        );
        break;
    }
    _pixelPointFrom = ui.Offset(pixelFromX, pixelFromY);
    _pixelPointTo = ui.Offset(pixelToX, pixelToY);
    */
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

