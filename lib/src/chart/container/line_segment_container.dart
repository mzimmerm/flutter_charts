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

/// Leaf container lays out and draws a line segment between [fromPointOffset] and [toPointOffset] using [linePaint].
///
/// The  [fromPointOffset] and [toPointOffset] are late, and SHOULD be set in the constructor;
/// MUST be set before [layout] is called.
///
/// The nullability of [fromPointOffset] and [toPointOffset] is an awkward lip service to
/// straightforward extensibility of this class where these members can be replaced by [model.PointModel] in extensions,
/// notable the [LineBetweenPointModelsContainer].
class LineBetweenPointOffsetsContainer extends container_common_new.ChartAreaContainer
    with container_base.HeightSizerLayouterChildMixin,
        container_base.WidthSizerLayouterChildMixin {

  LineBetweenPointOffsetsContainer({
    this.fromPointOffset,
    this.toPointOffset,
    required this.chartSeriesOrientation,
    required this.linePaint,
    required view_maker.ChartViewMaker chartViewMaker,
    this.isLextrIntoValueSignPortion = true,
  }) : super(
      chartViewMaker: chartViewMaker
  );

  /// Orientation of the chart bars: horizontal or vertical.
  final chart_orientation.ChartSeriesOrientation chartSeriesOrientation;

  /// Model contains the transformed, non-extrapolated values of the point where the line starts.
  late final PointOffset? fromPointOffset;
  late final PointOffset? toPointOffset;
  final ui.Paint linePaint;

  /// Coordinates of the layed out pixel values.
  ///
  /// NOT final, as offset is manipulated by [applyParentOffset];
  late PointOffset _fromOffsetPixels;
  late PointOffset _toOffsetPixels;

  /// Controls whether layout lextr uses full portion (both positive and negative portion) of lextr-from range,
  /// or just the portion that has the same sign as the point value.
  final bool isLextrIntoValueSignPortion;

  // ##### Full [layout] override.

  /// Overrides [layout] by lextr-transforming the data-valued [PointModel]s [fromPointOffset] and [toPointOffset],
  /// into their pixel equivalents [PointOffset]s [_fromOffsetPixels] and [_toOffsetPixels].
  ///
  /// The
  ///
  /// Ensures the [layoutSize] is set as the maximum value of [_fromOffsetPixels] and [_toOffsetPixels] in the
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

    assert(fromPointOffset != null);
    assert(toPointOffset != null);

    // Code here takes care of the pixel positioning of the points, aka layout.

    // Lextr the pointOffsets to their pixel values using [lextrInContextOf].
    // The method  takes into account chart orientation, which may cause the x and y (input and output) values
    //   to flip (invert) during the lextr.
    // Passing [this.constraints] is correct here, see [layout] documentation.
    _fromOffsetPixels = fromPointOffset!.lextrInContextOf(
      chartSeriesOrientation: chartSeriesOrientation,
      constraintsOnImmediateOwner: constraints,
      inputDataRange: chartViewMaker.xLabelsGenerator.dataRange,
      outputDataRange: chartViewMaker.yLabelsGenerator.dataRange,
      heightToLextr: heightToLextr,
      widthToLextr: widthToLextr,
    );
    _toOffsetPixels = toPointOffset!.lextrInContextOf(
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

  /// Internal calculation of [layoutSize] returns the [ui.Size] of this container.
  ///
  /// The size is already oriented correctly by taking into account the [chart_orientation.ChartSeriesOrientation],
  /// because the underlying [_fromOffsetPixels] and [_toOffsetPixels] have done the same in the [layout] implementation.
  ui.Size get _layoutSize {
    /* KEEP for now
    return ui.Size(
        (_toOffsetPixels.inputValue - _fromOffsetPixels.inputValue ).abs(),
        math.max(_fromOffsetPixels.outputValue, _toOffsetPixels.outputValue),
    );
    */
    return ui.Size(
      (_toOffsetPixels.inputValue - _fromOffsetPixels.inputValue).abs(),
      (_toOffsetPixels.outputValue - _fromOffsetPixels.outputValue).abs(),
    );
  }

  /// Override method in superclass [Container].
  @override
  void applyParentOffset(container_base.LayoutableBox caller, ui.Offset offset) {
    super.applyParentOffset(caller, offset);

    _fromOffsetPixels += offset;
    _toOffsetPixels += offset;
  }

  @override
  void paint(ui.Canvas canvas) {
    canvas.drawLine(_fromOffsetPixels, _toOffsetPixels, linePaint);
  }

  @override
  void buildAndReplaceChildren() {
    buildAndReplaceChildrenDefault();
  }
}

/// Leaf container manages [lineFrom] and [lineTo] positions and [linePaint] for a line segment.
class LineBetweenPointModelsContainer extends LineBetweenPointOffsetsContainer {

  LineBetweenPointModelsContainer({
    required this.fromPointModel,
    required this.toPointModel,
    required chart_orientation.ChartSeriesOrientation chartSeriesOrientation,
    required ui.Paint linePaint,
    required view_maker.ChartViewMaker chartViewMaker,
  }) : super(
    chartSeriesOrientation: chartSeriesOrientation,
      linePaint: linePaint,
      chartViewMaker: chartViewMaker
  );

  /// Model contains the transformed, non-extrapolated values of the point where the line starts.
  ///
  /// This member [fromPointModel] replaces the super [LineBetweenPointOffsetsContainer.fromPointOffset],
  /// in the sense that it yields the super  [LineBetweenPointOffsetsContainer.fromPointOffset]
  /// via this instance getter [fromPointOffset].
  final model.PointModel fromPointModel;
  final model.PointModel toPointModel;

  /// Override of parent from and to offsets. In parent, they are set in constructor,
  /// in this extension, they are pulled from the [model.PointModel] from and to members.
  ///
  /// Pulls the offset (from and toPointOffset) from the [fromPointModel] and [toPointModel].
  /// Both points are on x axis, so xLabelsGenerator is used as input dataRange for both from/to points.
  @override
  PointOffset get fromPointOffset =>
      fromPointModel.pointOffsetWithInputRange(dataRangeLabelInfosGenerator: chartViewMaker.xLabelsGenerator);
  @override
  PointOffset get toPointOffset =>
      toPointModel.pointOffsetWithInputRange(dataRangeLabelInfosGenerator: chartViewMaker.xLabelsGenerator);
}
