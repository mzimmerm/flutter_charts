import 'package:vector_math/vector_math.dart' as vector_math show Matrix2;

// this level or equivalent
import 'package:flutter_charts/src/coded_layout/chart/container.dart' show PixelRangeProvider;

import 'package:flutter_charts/src/chart/cartesian/container/container_common.dart' as container_common show ChartAreaContainer;
import 'package:flutter_charts/src/morphic/container/label_container.dart';
import 'package:flutter_charts/src/chart/chart_label_container.dart';
import 'package:flutter_charts/src/chart/view_model/view_model.dart' as view_model;
import 'package:flutter_charts/src/chart/view_model/label_model.dart' show AxisLabelInfo;

/// Extension of [AxisLabelContainer] for legacy manual layout axis labels container,
/// with added behavior needed for manual layout:
///   1. overrides method [layout_Post_Leaf_SetSize_FromInternals] to use the
///      (outerChartAreaContainer as PixelRangeProvider).axisPixelsRange to affmap label data values to pixels
///   2. has member parentOffsetTick to keep location (from build to manual layout?).
///
///  Legacy label containers [InputLabelContainerCL] and [OutputLabelContainerCL] should extend this
///
///
/// This subclass of [ChartLabelContainer] also stores this container's center [parentOffsetTick]
/// in parent's coordinates.
///
/// **This violates independence of container parents not needing their contained children.
/// Instances of this class are used in container parent [HorizontalAxisContainer] (which is OK),
/// but the parent is storing some of it's properties on children (which is not OK,
/// effectively, this class uses it's children as sandboxes).**
///
/// [parentOffsetTick] can be thought of as position of the "tick" showing
/// the label's value on axis - the immediate parent
/// decides whether this position represents X or Y.
///
/// Can be used by clients to create, layout, and center labels on X and Y axis,
/// and the label's graph "ticks".
///
/// Generally, the immediate parent container (parent) of this object decides what
/// the [parentOffsetTick]s are:
/// - If the parent is a [OutputAxisContainer], all positions are relative to the top of
///   the container of y labels
/// - If parent is a [HorizontalAxisContainer] all positions are relative to the left
///   of the container of x labels
/// - If parent is Area [ChartContainer], all positions are relative
///   to the top of the available [chartArea].
///
class AxisLabelContainerCL extends AxisLabelContainer {
  AxisLabelContainerCL({
    required view_model.ChartViewModel chartViewModel,
    required String label,
    required vector_math.Matrix2 labelTiltMatrix,
    required LabelStyle labelStyle,
    required AxisLabelInfo labelInfo,
    required container_common.ChartAreaContainer outerChartAreaContainer,
  })  : _labelInfo = labelInfo,
        _outerChartAreaContainer = outerChartAreaContainer,
        super(
          chartViewModel: chartViewModel,
          label: label,
          labelTiltMatrix: labelTiltMatrix,
          labelStyle: labelStyle,
        );

  /// The [container_common.ChartAreaContainer] on which this [AxisLabelContainer] is shown.
  final container_common.ChartAreaContainer _outerChartAreaContainer;
  container_common.ChartAreaContainer get outerChartAreaContainer => _outerChartAreaContainer;

  /// Maintains the LabelInfo from which this [ChartLabelContainer] was created,
  /// for use during [layout] of self or parents.
  final AxisLabelInfo _labelInfo;

  /// Getter of [AxisLabelInfo] which created this Y label.
  AxisLabelInfo get labelInfo => _labelInfo;


  /// [parentOffsetTick] is the UI pixel coordinate of the "axis tick mark", which represent the
  /// X or Y data value.
  ///
  /// In more detail, it is the numerical value of a label, transformed, then extrapolated to axis pixels length,
  /// so its value is in pixels relative to the immediate container - the [OutputAxisContainer] or [HorizontalAxisContainer]
  ///
  /// It's value is not affected by call to [applyParentOffset].
  /// It is calculated during parent's [OutputAxisContainer] [layout] method,
  /// as a result, it remains positioned in the [AxisContainerCL]'s coordinates.
  /// Any objects using [parentOffsetTick] as it's end point
  /// (for example grid line's end point), should apply
  /// the parent offset to themselves. The reason for this behavior is for
  /// the [parentOffsetTick]'s value to live after [AxisContainerCL]'s layout,
  /// so the  [parentOffsetTick]'s value can be used in the
  /// grid layout, without reversing any offsets.
  ///
  /// [parentOffsetTick]  has multiple other roles:
  ///   - The X or Y offset of the X or Y label middle point
  ///     (before label's parent offset), which becomes [yTickY] but NOT [xTickX]
  ///     (currently, xTickX is from x value data position, not from generated labels by [DataRangeTicksAndLabelsDescriptor]).
  ///     ```dart
  ///        double yTickY = outputLabelContainer.parentOffsetTick;
  ///        double labelTopY = yTickY - outputLabelContainer.layoutSize.height / 2;
  ///     ```
  ///   - The "tick dash" for the label center on the X or Y axis.
  ///     First "tick dash" is on the first label, last on the last label,
  ///     but both x and y label containers can be skipped.
  ///
  /// Must NOT be used in new auto-layout
  double parentOffsetTick = 0.0;

  /// Overridden from [AxisLabelContainer.layout_Post_Leaf_SetSize_FromInternals]
  /// added logic to set pixels. Used on legacy X and Y axis labels.
  ///
  /// Uses the [OutputAxisContainerCL.rangeDescriptor] instance of [DataRangeTicksAndLabelsDescriptor] to
  /// affmap the [labelInfo] value [AxisLabelInfo.centerTickValue] and places the result on [parentOffsetTick].
  ///
  /// Must ONLY be invoked after container layout when the axis pixels range (axisPixelsRange)
  /// is determined.
  ///
  /// Note: Invoked on BOTH [InputLabelContainerCL] and [OutputLabelContainerCL], but only relevant on [OutputLabelContainerCL].
  ///       On [InputLabelContainerCL] it could be skipped, the layout code in [HorizontalAxisContainerCL.layout]
  ///       ```dart
  ///           inputLabelContainer.parentOffsetTick = xTickX;
  ///        ```
  ///        overrides this.
  @override
  void layout_Post_Leaf_SetSize_FromInternals() {
    // We now know how long the Y axis is in pixels,
    // so we can calculate this label pixel position IN THE HorizontalAxisContainer / OutputAxisContainer
    // and place it on [parentOffsetTick]
    var rangeDescriptor = outerChartAreaContainer.chartViewModel.outputRangeDescriptor;

    parentOffsetTick = rangeDescriptor.affmapValueToPixels(
      value: labelInfo.centerTickValue.toDouble(),
      axisPixelsMin: (outerChartAreaContainer as PixelRangeProvider).axisPixelsRange.min,
      axisPixelsMax: (outerChartAreaContainer as PixelRangeProvider).axisPixelsRange.max,
    );

    super.layout_Post_Leaf_SetSize_FromInternals();
  }
}
