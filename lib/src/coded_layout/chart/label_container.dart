import 'package:vector_math/vector_math.dart' as vector_math show Matrix2;

// this level or equivalent
import 'container.dart' show PixelRangeProvider;
import '../../chart/container/container_common.dart' as container_common show ChartAreaContainer;
import '../../morphic/container/label_container.dart';
import '../../chart/chart_label_container.dart';
import '../../chart/view_model.dart' as view_model;
import '../../chart/model/label_model.dart' show AxisLabelInfo;

/// Extension of [AxisLabelContainer] for legacy manual layout axis labels container,
/// with added behavior needed for manual layout:
///   1. overrides method [layout_Post_Leaf_SetSize_FromInternals] to use the
///      (ownerChartAreaContainer as PixelRangeProvider).axisPixelsRange to lextr label data values to pixels
///   2. has member parentOffsetTick to keep location (from build to manual layout?).
///
///  Legacy label containers [InputLabelContainerCL] and [OutputLabelContainerCL] should extend this
///
class AxisLabelContainerCL extends AxisLabelContainer {
  AxisLabelContainerCL({
    required view_model.ChartViewModel chartViewModel,
    required String label,
    required vector_math.Matrix2 labelTiltMatrix,
    required LabelStyle labelStyle,
    required AxisLabelInfo labelInfo,
    required container_common.ChartAreaContainer ownerChartAreaContainer,
  })  : _labelInfo = labelInfo,
        _ownerChartAreaContainer = ownerChartAreaContainer,
        super(
          chartViewModel: chartViewModel,
          label: label,
          labelTiltMatrix: labelTiltMatrix,
          labelStyle: labelStyle,
        );

  /// The [container_common.ChartAreaContainer] on which this [AxisLabelContainer] is shown.
  final container_common.ChartAreaContainer _ownerChartAreaContainer;
  container_common.ChartAreaContainer get ownerChartAreaContainer => _ownerChartAreaContainer;

  /// Maintains the LabelInfo from which this [ChartLabelContainer] was created,
  /// for use during [layout] of self or parents.
  final AxisLabelInfo _labelInfo;

  /// Getter of [AxisLabelInfo] which created this Y label.
  AxisLabelInfo get labelInfo => _labelInfo;


  /// [parentOffsetTick] is the UI pixel coordinate of the "axis tick mark", which represent the
  /// X or Y data value.
  ///
  /// In more detail, it is the numerical value of a label, transformed, then extrapolated to axis pixels length,
  /// so its value is in pixels relative to the immediate container - the [VerticalAxisContainer] or [HorizontalAxisContainer]
  ///
  /// It's value is not affected by call to [applyParentOffset].
  /// It is calculated during parent's [VerticalAxisContainer] [layout] method,
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
  ///     (currently, xTickX is from x value data position, not from generated labels by [DataRangeLabelInfosGenerator]).
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
  /// Uses the [VerticalAxisContainerCL.labelsGenerator] instance of [DataRangeLabelInfosGenerator] to
  /// lextr the [labelInfo] value [AxisLabelInfo.outputValue] and places the result on [parentOffsetTick].
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
    // so we can calculate this label pixel position IN THE HorizontalAxisContainer / VerticalAxisContainer
    // and place it on [parentOffsetTick]
    var labelsGenerator = ownerChartAreaContainer.chartViewModel.outputLabelsGenerator;

    parentOffsetTick = labelsGenerator.lextrValueToPixels(
      value: labelInfo.outputValue.toDouble(),
      axisPixelsMin: (ownerChartAreaContainer as PixelRangeProvider).axisPixelsRange.min,
      axisPixelsMax: (ownerChartAreaContainer as PixelRangeProvider).axisPixelsRange.max,
    );

    super.layout_Post_Leaf_SetSize_FromInternals();
  }
}
