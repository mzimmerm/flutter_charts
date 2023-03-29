import 'dart:ui' as ui show Size, Offset, Paint, Canvas;
import 'dart:math' as math show max;

import 'package:flutter_charts/src/morphic/ui2d/point.dart';

import 'container_common.dart' as container_common_new;
import '../../morphic/container/container_layouter_base.dart' as container_base;
import '../../morphic/container/chart_support/chart_series_orientation.dart' as chart_orientation;
import '../view_maker.dart' as view_maker;
// import '../container.dart' as container;
import '../model/data_model.dart' as model;
// import '../../util/util_labels.dart' as util_labels;

/// Leaf container manages [lineFrom] and [lineTo] positions and [linePaint] for a line segment.
class LineBetweenPointModelsContainer extends container_common_new.ChartAreaContainer
    with container_base.HeightSizerLayouterChildMixin,
      container_base.WidthSizerLayouterChildMixin
{

  LineBetweenPointModelsContainer({
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
  late final PointOffset _pixelPointFrom;
  late final PointOffset _pixelPointTo;


  // #####  Implementors of method in superclass [BoxContainer].

  /// Overrides [layout] by lextr-transforming the data-valued [PointModel]s [pointFrom] and [pointTo],
  /// into their pixel equivalents [PointOffset]s [_pixelPointFrom] and [_pixelPointTo].
  ///
  /// The
  ///
  /// Ensures the [layoutSize] is set as the maximum value of [_pixelPointFrom] and [_pixelPointTo] in the
  /// parent layouter main direction, and the [constraints] component in the parent layouter cross-direction.
  ///
  /// Important notes:
  ///
  ///   - We MUST ASSUME this [LineBetweenPointModelsContainer] was placed into a Row or Column without specifying weights on self;
  ///     Such Row or Column layouters pass their full constraints to children (instances of this [LineBetweenPointModelsContainer]).
  //      As a consequence, `this.constraints == constraintsOnImmediateOwner`!
  ///   - As this leaf container overrides [layout] here, it does not need to
  ///     override [layout_Post_Leaf_SetSize_FromInternals] or any other internal layout methods.
  @override
  void layout() {
    buildAndReplaceChildren();

    // Code here takes care of the pixel positioning of the points, aka layout.

    // Pull the offset (from and toPointOffset) from the [pointFrom] and [pointTo]. The points are both on x axis
    //   so far, so xLabelsGenerator is user as full inputRange for both from/to points.
    // Just after, we lextr the pointOffsets to their pixel values.
    PointOffset fromPointOffset = pointFrom.pointOffsetWithInputRange(
        dataRangeLabelInfosGenerator: chartViewMaker.xLabelsGenerator,
    );
    PointOffset toPointOffset = pointTo.pointOffsetWithInputRange(
      dataRangeLabelInfosGenerator: chartViewMaker.xLabelsGenerator,
    );

    // Lextr the pointOffsets to their pixel values using [lextrInContextOf].
    // The method  takes into account chart orientation, which may cause the x and y (input and output) values
    //   to flip (invert) during the lextr.
    // Passing [this.constraints] is correct here, see [layout] documentation.
    _pixelPointFrom = fromPointOffset.lextrInContextOf(
        chartSeriesOrientation: chartSeriesOrientation,
        constraintsOnImmediateOwner: constraints,
        inputDataRange: chartViewMaker.xLabelsGenerator.dataRange,
        outputDataRange: chartViewMaker.yLabelsGenerator.dataRange,
        heightToLextr: heightToLextr,
        widthToLextr: widthToLextr,
    );
    _pixelPointTo = toPointOffset.lextrInContextOf(
      chartSeriesOrientation: chartSeriesOrientation,
      constraintsOnImmediateOwner: constraints,
      inputDataRange: chartViewMaker.xLabelsGenerator.dataRange,
      outputDataRange: chartViewMaker.yLabelsGenerator.dataRange,
      heightToLextr: heightToLextr,
      widthToLextr: widthToLextr,
    );

    // The [layoutSize] is a hard nut. If we restrict our thinking to this [LineSegmentContainer] being a child
    //   of a non-stacked [LineChart] with hierarchy-parent being [Column] or [Row] with [mainAxisLayout=matrjoska,end]
    //   all sibling [LineSegmentContainer]s overlap and grow from end. Then the [layoutSize] in the main direction
    //   of parent is the max length in that direction. In the cross-direction, it is the same as constraint size.
    layoutSize = _layoutSize;

  }

  ui.Size get _layoutSize {
    switch(chartSeriesOrientation) {
      case chart_orientation.ChartSeriesOrientation.column:
        return ui.Size(constraints.width, math.max(_pixelPointFrom.outputValue, _pixelPointTo.outputValue));
      case chart_orientation.ChartSeriesOrientation.row:
        return ui.Size(math.max(_pixelPointFrom.inputValue, _pixelPointTo.inputValue), constraints.height);
    }
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

