import 'package:flutter/widgets.dart' as widgets show TextSpan, TextPainter;
import 'package:vector_math/vector_math.dart' as vector_math show Matrix2;

// this level or equivalent
import '../morphic/container/label_container.dart';
import 'container/container_common.dart' as container_common_new show ChartAreaContainer;
import 'view_maker.dart' as view_maker;
import 'options.dart' show ChartOptions;
import '../util/util_labels.dart' show AxisLabelInfo;
// import '../util/util_dart.dart' as util_dart;

/// Container of one label anywhere on the chart, in Labels, Axis, Titles, etc.
///
/// The [layoutSize] is exactly that of by the contained
/// layed out [textPainter] (this [LabelContainerOriginalKeep] has no margins, padding,
/// or additional content in addition to the [_textPainter).
///
/// However, if this object is tilted, as specified by [labelTiltMatrix], the
/// [layoutSize] is determined by the rotated layed out [textPainter]. The
/// math and [layoutSize] of this tilt is provided by [_tiltedLabelEnvelope].
///
/// Most members are mutable so that clients can experiment with different
/// ways to set text style, until the label fits a predefined allowed size.
///
/// Notes:
/// - Instances manage the text to be presented as label,
///   and create a member [textPainter], instance of [widgets.TextPainter]
///   from the label. The contained [textPainter] is used for all layout
///   and painting.
/// - All methods (and constructor) of this class always call
///   [textPainter.layout] immediately after a change.
///   Consequently,  there is no need to check for
///   a "needs layout" method - the underlying [textPainter]
///   is always layed out, ready to be painted.
class ChartLabelContainer extends container_common_new.ChartAreaContainer with LabelContainerMixin {

  // Allows to configure certain sizes, colors, and layout.
  // final LabelStyle _labelStyle;

  /// Constructs an instance for a label, it's text style, and label's
  /// maximum width.
  ///
  /// todo-02 : Does not set parent container's [_boxConstraints] and [chartViewMaker].
  /// It is currently assumed clients will not call any methods using them.
  ChartLabelContainer({
    required view_maker.ChartViewMaker chartViewMaker,
    required String label,
    required vector_math.Matrix2 labelTiltMatrix,
    required LabelStyle labelStyle,
  })  : _options = chartViewMaker.chartOptions,
        super(
          chartViewMaker: chartViewMaker,
      ) {
    this.labelTiltMatrix = labelTiltMatrix;
    // _labelStyle = labelStyle,
    textPainter = widgets.TextPainter(
      text: widgets.TextSpan(
        text: label,
        style: labelStyle.textStyle, // All labels share one style object
      ),
      textDirection: labelStyle.textDirection,
      textAlign: labelStyle.textAlign,
      // center in available space todo-01 textScaleFactor does nothing ??
      textScaleFactor: labelStyle.textScaleFactor,
      // removed, causes lockup: ellipsis: "...", // forces a single line - without it, wraps at width
    );
    // var text = new widgets.TextSpan(
    //   text: label,
    //   style: _labelStyle.textStyle, // All labels share one style object
    // );
    // _textPainter = new widgets.TextPainter(
    //   text: text,
    //   textDirection: _labelStyle.textDirection,
    //   textAlign: _labelStyle.textAlign,
    //   // center in available space
    //   textScaleFactor: _labelStyle.textScaleFactor,
    //   // todo-04 add to test - was removed, causes lockup: ellipsis: "...", // forces a single line - without it, wraps at width
    // ); //  textScaleFactor does nothing ??
  }

  final ChartOptions _options;

  @override
  double calcLabelMaxWidthFromLayoutOptionsAndConstraints() {
    // todo-00-last-01 : this seems incorrect - used for all labels, yet it acts as legend label!!
    double indicatorSquareSide = _options.legendOptions.legendColorIndicatorWidth;
    double indicatorToLabelPad = _options.legendOptions.legendItemIndicatorToLabelPad;
    double betweenLegendItemsPadding = _options.legendOptions.betweenLegendItemsPadding;

    // labelMaxWidth from options and constraints on class with this mixin
    return constraints.maxSize.width - (indicatorSquareSide + indicatorToLabelPad + betweenLegendItemsPadding);
  }
}

/// Container of axis label, this subclass of [ChartLabelContainer] also stores
/// this container's center [parentOffsetTick] in parent's coordinates.
///
/// **This violates independence of container parents not needing their contained children.
/// Instances of this class are used in container parent [XContainer] (which is OK),
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
/// Generally, the owner (immediate parent) of this object decides what
/// the [parentOffsetTick]s are:
/// - If owner is a [YContainer], all positions are relative to the top of
///   the container of y labels
/// - If owner is a [XContainer] All positions are relative to the left
///   of the container of x labels
/// - If owner is Area [ChartContainer], all positions are relative
///   to the top of the available [chartArea].
///
abstract class AxisLabelContainer extends ChartLabelContainer {
  AxisLabelContainer({
    required view_maker.ChartViewMaker chartViewMaker,
    required String label,
    required vector_math.Matrix2 labelTiltMatrix,
    required LabelStyle labelStyle,
    required AxisLabelInfo labelInfo,
    required container_common_new.ChartAreaContainer ownerChartAreaContainer,
  })  : _labelInfo = labelInfo,
        _ownerChartAreaContainer = ownerChartAreaContainer,
        super(
          chartViewMaker: chartViewMaker,
          label: label,
          labelTiltMatrix: labelTiltMatrix,
          labelStyle: labelStyle,
        );

  /// The [container_common_new.ChartAreaContainer] on which this [AxisLabelContainer] is shown.
  final container_common_new.ChartAreaContainer _ownerChartAreaContainer;
  container_common_new.ChartAreaContainer get ownerChartAreaContainer => _ownerChartAreaContainer;

  /// Maintains the LabelInfo from which this [ChartLabelContainer] was created,
  /// for use during [layout] of self or parents.
  final AxisLabelInfo _labelInfo;

  /// Getter of [AxisLabelInfo] which created this Y label.
  AxisLabelInfo get labelInfo => _labelInfo;

}

/// Label container for Y labels, which maintain, in addition to
/// the superclass [YLabelContainer] also [AxisLabelInfo] - the object
/// from which each Y label is created.
class YLabelContainer extends AxisLabelContainer {

  YLabelContainer({
    required view_maker.ChartViewMaker chartViewMaker,
    required String label,
    required vector_math.Matrix2 labelTiltMatrix,
    required LabelStyle labelStyle,
    required AxisLabelInfo labelInfo,
    required container_common_new.ChartAreaContainer ownerChartAreaContainer,
  }) : super(
    chartViewMaker: chartViewMaker,
    label:           label,
    labelTiltMatrix: labelTiltMatrix,
    labelStyle:      labelStyle,
    labelInfo:       labelInfo,
    ownerChartAreaContainer: ownerChartAreaContainer,
  );
}

/// [AxisLabelContainer] used in the [XContainer].
class XLabelContainer extends AxisLabelContainer {

  XLabelContainer({
    required view_maker.ChartViewMaker chartViewMaker,
    required String label,
    required vector_math.Matrix2 labelTiltMatrix,
    required LabelStyle labelStyle,
    required AxisLabelInfo labelInfo,
    required container_common_new.ChartAreaContainer ownerChartAreaContainer,
  }) : super(
    chartViewMaker:  chartViewMaker,
    label:           label,
    labelTiltMatrix: labelTiltMatrix,
    labelStyle:      labelStyle,
    labelInfo:       labelInfo,
    ownerChartAreaContainer: ownerChartAreaContainer,
  );
}
