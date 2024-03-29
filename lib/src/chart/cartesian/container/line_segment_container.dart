import 'dart:ui' as ui show Size, Offset, Paint, Canvas;

// This level
import 'package:flutter_charts/src/chart/cartesian/container/container_common.dart' as container_common;

import 'package:flutter_charts/src/chart/model/data_model.dart' as model;
import 'package:flutter_charts/src/util/util_flutter.dart' show FromTransposing2DValueRange, To2DPixelRange;

import 'package:flutter_charts/src/morphic/ui2d/point.dart';
import 'package:flutter_charts/src/morphic/container/container_layouter_base.dart' as container_base;
import 'package:flutter_charts/src/morphic/container/chart_support/chart_style.dart' as chart_orientation;



/// Leaf container lays out and draws a line segment between [fromPointOffset] and [toPointOffset] using [linePaint].
///
/// The  [fromPointOffset] and [toPointOffset] are late, and SHOULD be set in the constructor;
/// MUST be set before [layout] is called.
///
/// The line is determined by its end points, [fromPointOffset] and [toPointOffset].
/// When defining these end points, assume that orientation is [ChartOrientation.column].
///
/// At runtime, the orientation [ChartOrientation] is determined by member [chartViewModel]'s
/// [ChartViewModel.chartOrientation]; if orientation is set to [ChartOrientation.row],
/// the line is transformed to their row orientation by affmap-ing the end points [fromPointOffset] and [toPointOffset]
/// using their [PointOffset.affmapBetweenRanges].
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
  ///     toPointOffset: PointOffset(inputValue: chartViewModel.chartModel.dataRangeWhenStringLabels.max, outputValue: 0.0),
  ///     linePaint: chartViewModel.chartOptions.dataContainerOptions.gridLinesPaint(),
  ///     chartViewModel: chartViewModel,
  ///   ),
  /// ```
  LineBetweenPointOffsetsContainer({
    required this.fromPointOffset,
    required this.toPointOffset,
    required this.linePaint,
    required super.chartViewModel,
    super.constraintsWeight,
  });

  /// Model contains the transformed, not-extrapolated values of the point where the line starts.
  final PointOffset fromPointOffset;
  final PointOffset toPointOffset;
  final ui.Paint linePaint;

  /// Coordinates of the layed out pixel values.
  ///
  /// NOT final, as offset is manipulated by [applyParentOffset];
  late PointOffset _fromOffsetPixels;
  late PointOffset _toOffsetPixels;

  /// Controls whether layout affmap on points, when setting pixel ranges, uses the full length of sizer
  /// such as [container_base.HeightSizerLayouter] or uses constraints from
  /// the parent Row or Column container.
  ///
  ///   - if false (default): constraints width or height from the parent Row or Column container
  ///     is used to set pixel range.
  ///   - if true           : [container_base.HeightSizerLayouterChildMixin.sizerHeight]
  ///     is used to set pixel range.
  ///
  // KEEP for now : final bool isAffmapUseSizerInsteadOfConstraint;

  // ##### Full [layout] override.

  /// Overrides [layout] by affmap-transforming the data-valued [PointModel]s [fromPointOffset] and [toPointOffset],
  /// into their pixel equivalents [PointOffset]s [_fromOffsetPixels] and [_toOffsetPixels].
  ///
  /// The
  ///
  /// Ensures the [layoutSize] is set as the maximum value of [_fromOffsetPixels] and [_toOffsetPixels] in the
  /// parent container/layouter main direction, and the [constraints] component in the parent's cross-direction.
  ///
  /// Important notes:
  ///
  ///   - We MUST ASSUME this [LineBetweenPointOffsetsContainer] was placed into a Row or Column without specifying weights on self;
  ///     Such Row or Column layouters pass their full constraints to children (instances of this [LineBetweenPointOffsetsContainer]).
  //      As a consequence, `this.constraints == withinConstraints`!
  ///   - As this leaf container overrides [layout] here, it does not need to
  ///     override [layout_Post_Leaf_SetSize_FromInternals] or any other internal layout methods.
  @override
  void layout() {
    buildAndReplaceChildren();

    // Code here takes care of the pixel positioning of the points, aka layout.

    // Affmap the pointOffsets to their pixel values using [affmapInContextOf].
    // The method  takes into account chart orientation, which may cause the x and y (input and output) values
    //   to flip (invert) during the affmap.
    // Passing [this.constraints] is correct here, see [layout] documentation.
    _fromOffsetPixels = fromPointOffset.affmapBetweenRanges(
      fromTransposing2DValueRange: FromTransposing2DValueRange(
        chartOrientation: chartViewModel.chartOrientation,
        inputDataRange: chartViewModel.inputRangeDescriptor.dataRange,
        outputDataRange: chartViewModel.outputRangeDescriptor.dataRange,
      ),
      to2DPixelRange: To2DPixelRange(
        height: sizerHeight,
        width: sizerWidth,
      ),
      isMoveInCrossDirectionToPixelRangeCenter: false,
      isSetBarPointRectInCrossDirectionToPixelRange: false,
    );
    _toOffsetPixels = toPointOffset.affmapBetweenRanges(
      fromTransposing2DValueRange: FromTransposing2DValueRange(
        chartOrientation: chartViewModel.chartOrientation,
        inputDataRange: chartViewModel.inputRangeDescriptor.dataRange,
        outputDataRange: chartViewModel.outputRangeDescriptor.dataRange,
      ),
      to2DPixelRange: To2DPixelRange(
        height: sizerHeight,
        width: sizerWidth,
      ),
      isMoveInCrossDirectionToPixelRangeCenter: false,
      isSetBarPointRectInCrossDirectionToPixelRange: false,
    );

    // The [layoutSize] is a hard nut. If we restrict our thinking to this [LineSegmentContainer] being a child
    //   of a Not-Stacked [LineChart] with hierarchy-parent being [Column] or [Row] with [mainAxisLayout=matrjoska,end]
    //   all sibling [LineSegmentContainer]s overlap and grow from end. Then the [layoutSize] in the main direction
    //   of parent is the max length in that direction. In the cross-direction, it is the same as constraint size.
    layoutSize = _layoutSize;
  }

  /// Internal calculation of [layoutSize] returns the [ui.Size] of this container.
  ///
  /// The size is already oriented correctly by taking into account the [chart_orientation.ChartOrientation],
  /// because the underlying [_fromOffsetPixels] and [_toOffsetPixels]
  /// have been affmap-ed in the [layout] implementation to the appropriate coordinate system.
  ///
  /// Note: This implementation will always cause length along one direction to be `0`,
  ///       for horizontal or vertical lines.
  ui.Size get _layoutSize {
    return ui.Size(
      (_toOffsetPixels.inputValue - _fromOffsetPixels.inputValue).abs(),
      (_toOffsetPixels.outputValue - _fromOffsetPixels.outputValue).abs(),
    );
  }

  /// Override method in superclass [Container], on every parent move by [offset] does
  /// moves the beginning and end points [_fromOffsetPixels] and [_toOffsetPixels] by the same [offset].
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

/* KEEP todo-02-design : this is currently not used. What was the intent???

/// Leaf container manages [lineFrom] and [lineTo] positions and [linePaint] for a line segment.
///
/// Does NOT define [chart_orientation.ChartOrientation]. Will transform according to member
/// [view_model.ChartViewModel.chartOrientation].
///
class LineBetweenPointModelsContainer extends LineBetweenPointOffsetsContainer {
  LineBetweenPointModelsContainer({
    required this.fromPointModel,
    required this.toPointModel,
    required ui.Paint linePaint,
    required view_model.ChartViewModel chartViewModel,
    container_base.ConstraintsWeight constraintsWeight = container_base.ConstraintsWeight.defaultWeight,
  }) : super(
          linePaint: linePaint,
          chartViewModel: chartViewModel,
          constraintsWeight: constraintsWeight,
        );

  /// Model contains the transformed, not-extrapolated values of the point where the line starts.
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
  ///   - for [PointOffset.inputValue], the data range from the [chartViewModel.inputRangeDescriptor] and
  ///     [fromPointModel]'s column index.
  ///   - for [PointOffset.outputValue], the [fromPointModel]'s input value [model.PointModel.outputValue] directly.
  ///
  /// Both points are on x axis, so the inputRangeDescriptor is used as input dataRange for both from/to points.
  @override
  PointOffset get fromPointOffset => fromPointModel.toPointOffsetOnInputRange(
        inputDataRangeTicksAndLabelsDescriptor: chartViewModel.inputRangeDescriptor,
      );

  /// See [fromPointOffset].
  @override
  PointOffset get toPointOffset =>
      toPointModel.toPointOffsetOnInputRange(inputDataRangeTicksAndLabelsDescriptor: chartViewModel.inputRangeDescriptor);
}
*/