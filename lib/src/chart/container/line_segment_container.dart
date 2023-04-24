import 'dart:ui' as ui show Size, Offset, Paint, Canvas;


import 'container_common.dart' as container_common;
import '../../morphic/ui2d/point.dart';
import '../../morphic/container/container_layouter_base.dart' as container_base;
import '../../morphic/container/chart_support/chart_orientation.dart' as chart_orientation;
import '../view_maker.dart' as view_maker;
// import '../container.dart' as container;
import '../model/data_model.dart' as model;
// import '../../util/label_model.dart' as util_labels;

/// Leaf container lays out and draws a line segment between [fromPointOffset] and [toPointOffset] using [linePaint].
///
/// The  [fromPointOffset] and [toPointOffset] are late, and SHOULD be set in the constructor;
/// MUST be set before [layout] is called.
///
/// Does NOT define [chart_orientation.ChartOrientation]. Will transform according to member
/// [view_maker.ChartViewMaker.chartOrientation].
///
/// The nullability of [fromPointOffset] and [toPointOffset] is an awkward lip service to
/// straightforward extensibility of this class where these members can be replaced by [model.PointModel] in extensions,
/// notable the [LineBetweenPointModelsContainer].
class LineBetweenPointOffsetsContainer extends container_common.ChartAreaContainer
    with container_base.HeightSizerLayouterChildMixin,
        container_base.WidthSizerLayouterChildMixin {

  /// Constructs container from start and end points, the chart orientation, paint to paint the line,
  /// and a default choice that [layout] assumes to split scaling into positive and negative portion.
  ///
  /// Example:
  /// ```dart
  ///   LineBetweenPointOffsetsContainer( // could also place in Row with main constraints weight=0.0
  ///     chartOrientation: ChartOrientation.column,
  ///     fromPointOffset: const PointOffset(inputValue: 0.0, outputValue: 0.0),
  ///     toPointOffset: PointOffset(inputValue: chartViewMaker.chartModel.dataRangeWhenStringLabels.max, outputValue: 0.0),
  ///     linePaint: chartViewMaker.chartOptions.dataContainerOptions.gridLinesPaint(),
  ///     chartViewMaker: chartViewMaker,
  ///   ),
  /// ```
  LineBetweenPointOffsetsContainer({
    this.fromPointOffset,
    this.toPointOffset,
    required this.linePaint,
    this.isLextrUseSizerInsteadOfConstraint = false,
    required super.chartViewMaker,
    super.constraintsWeight = container_base.ConstraintsWeight.defaultWeight,
  });

  /// Model contains the transformed, non-extrapolated values of the point where the line starts.
  late final PointOffset? fromPointOffset;
  late final PointOffset? toPointOffset;
  final ui.Paint linePaint;

  /// Coordinates of the layed out pixel values.
  ///
  /// NOT final, as offset is manipulated by [applyParentOffset];
  late PointOffset _fromOffsetPixels;
  late PointOffset _toOffsetPixels;

  /// Controls whether layout lextr on points, when setting pixel ranges, uses the full length of sizer
  /// such as [container_base.HeightSizerLayouter] or uses constraints from
  /// the parent Row or Column container.
  ///
  ///   - if false (default): constraints width or height from the parent Row or Column container
  ///     is used to set pixel range.
  ///   - if true           : [container_base.HeightSizerLayouterChildMixin.heightToLextr]
  ///     is used to set pixel range.
  ///
  final bool isLextrUseSizerInsteadOfConstraint;

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
    _fromOffsetPixels = fromPointOffset!.lextrToPixelsMaybeTransposeInContextOf(
      chartOrientation: chartViewMaker.chartOrientation,
      constraintsOnImmediateOwner: constraints,
      inputDataRange: chartViewMaker.inputLabelsGenerator.dataRange,
      outputDataRange: chartViewMaker.outputLabelsGenerator.dataRange,
      heightToLextr: heightToLextr,
      widthToLextr: widthToLextr,
      isLextrUseSizerInsteadOfConstraint: isLextrUseSizerInsteadOfConstraint,
    );
    _toOffsetPixels = toPointOffset!.lextrToPixelsMaybeTransposeInContextOf(
      chartOrientation: chartViewMaker.chartOrientation,
      constraintsOnImmediateOwner: constraints,
      inputDataRange: chartViewMaker.inputLabelsGenerator.dataRange,
      outputDataRange: chartViewMaker.outputLabelsGenerator.dataRange,
      heightToLextr: heightToLextr,
      widthToLextr: widthToLextr,
      isLextrUseSizerInsteadOfConstraint: isLextrUseSizerInsteadOfConstraint,
    );

    // The [layoutSize] is a hard nut. If we restrict our thinking to this [LineSegmentContainer] being a child
    //   of a Non-Stacked [LineChart] with hierarchy-parent being [Column] or [Row] with [mainAxisLayout=matrjoska,end]
    //   all sibling [LineSegmentContainer]s overlap and grow from end. Then the [layoutSize] in the main direction
    //   of parent is the max length in that direction. In the cross-direction, it is the same as constraint size.
    layoutSize = _layoutSize;
  }

  /// Internal calculation of [layoutSize] returns the [ui.Size] of this container.
  ///
  /// The size is already oriented correctly by taking into account the [chart_orientation.ChartOrientation],
  /// because the underlying [_fromOffsetPixels] and [_toOffsetPixels] have done the same in the [layout] implementation.
  ui.Size get _layoutSize {
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
///
/// Does NOT define [chart_orientation.ChartOrientation]. Will transform according to member
/// [view_maker.ChartViewMaker.chartOrientation].
///
class LineBetweenPointModelsContainer extends LineBetweenPointOffsetsContainer {
  LineBetweenPointModelsContainer({
    required this.fromPointModel,
    required this.toPointModel,
    required ui.Paint linePaint,
    required view_maker.ChartViewMaker chartViewMaker,
    container_base.ConstraintsWeight constraintsWeight = container_base.ConstraintsWeight.defaultWeight,
    isLextrUseSizerInsteadOfConstraint = false,
  }) : super(
          linePaint: linePaint,
          chartViewMaker: chartViewMaker,
          constraintsWeight: constraintsWeight,
          isLextrUseSizerInsteadOfConstraint: isLextrUseSizerInsteadOfConstraint,
        );

  /// Model contains the transformed, non-extrapolated values of the point where the line starts.
  ///
  /// This member [fromPointModel] replaces the super [LineBetweenPointOffsetsContainer.fromPointOffset],
  /// in the sense that it yields the super  [LineBetweenPointOffsetsContainer.fromPointOffset]
  /// via this instance getter [fromPointOffset].
  final model.PointModel fromPointModel;
  final model.PointModel toPointModel;

  /// Override of parent from offset, the [fromPointOffset].
  ///
  /// In parent, [fromPointOffset] is set in the constructor; in this extension, if is pulled from
  /// the [model.PointModel]'s [fromPointModel].
  ///
  /// Calculates [fromPointOffset] from the [fromPointModel], using
  ///   - for [PointOffset.inputValue], the data range from the [chartViewMaker.inputLabelsGenerator] and
  ///     [fromPointModel]'s column index.
  ///   - for [PointOffset.outputValue], the [fromPointModel]'s input value [model.PointModel.outputValue] directly.
  ///
  /// Both points are on x axis, so the inputLabelsGenerator is used as input dataRange for both from/to points.
  @override
  PointOffset get fromPointOffset => fromPointModel.asPointOffsetOnInputRange(
        dataRangeLabelInfosGenerator: chartViewMaker.inputLabelsGenerator,
      );

  /// See [fromPointOffset].
  @override
  PointOffset get toPointOffset =>
      toPointModel.asPointOffsetOnInputRange(dataRangeLabelInfosGenerator: chartViewMaker.inputLabelsGenerator);
}
