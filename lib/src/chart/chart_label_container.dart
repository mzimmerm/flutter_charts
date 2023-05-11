import 'package:flutter/widgets.dart' as widgets show TextSpan, TextPainter;
import 'package:flutter_charts/src/morphic/container/container_layouter_base.dart';
import 'package:vector_math/vector_math.dart' as vector_math show Matrix2;

// this level or equivalent
import '../morphic/container/label_container.dart';
import 'container/container_common.dart' as container_common show ChartAreaContainer;
import 'view_model.dart' as view_model;
import 'options.dart' show ChartOptions;

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
class ChartLabelContainer extends container_common.ChartAreaContainer with TiltableLabelContainerMixin {

  // Allows to configure certain sizes, colors, and layout.
  // final LabelStyle _labelStyle;

  /// Constructs an instance for a label, it's text style, and label's
  /// maximum width.
  ///
  /// Note: Does not set parent container's [_boxConstraints] and [chartViewModel].
  ///       It is currently assumed clients will not call any methods using those members.
  ChartLabelContainer({
    required view_model.ChartViewModel chartViewModel,
    required String label,
    required vector_math.Matrix2 labelTiltMatrix,
    required LabelStyle labelStyle,
  })  :
        super(
          chartViewModel: chartViewModel,
      ) {
    this.labelTiltMatrix = labelTiltMatrix;
    textPainter = widgets.TextPainter(
      text: widgets.TextSpan(
        text: label,
        style: labelStyle.textStyle, // All labels share one style object
      ),
      textDirection: labelStyle.textDirection,
      textAlign: labelStyle.textAlign,
      // center in available space todo-02 textScaleFactor does nothing ??
      textScaleFactor: labelStyle.textScaleFactor,
      // removed, causes lockup: ellipsis: "...", // forces a single line - without it, wraps at width
    );

    // _labelStyle = labelStyle,
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

  @override
  double calcLabelMaxWidthFromLayoutOptionsAndConstraints() {
    // todo-013 : this seems incorrect - used for all labels, yet it acts as legend label!!
    //            used only to get label max size in rotated labels.
    ChartOptions options = chartViewModel.chartOptions;
    double indicatorSquareSide = options.legendOptions.legendColorIndicatorWidth;
    double indicatorToLabelPad = options.legendOptions.legendItemIndicatorToLabelPad;
    double betweenLegendItemsPadding = options.legendOptions.betweenLegendItemsPadding;

    // labelMaxWidth from options and constraints on class with this mixin
    return constraints.maxSize.width - (indicatorSquareSide + indicatorToLabelPad + betweenLegendItemsPadding);
  }
}

/// Container of an axis label, a marker extension of [ChartLabelContainer] with no additional operations to it's
/// superclass.
///
/// Should be used for axis labels, and layed out with any standard layouters,
/// most likely an extension of the [ExternalTicksBoxLayouter].
///
class AxisLabelContainer extends ChartLabelContainer {
  AxisLabelContainer({
    required view_model.ChartViewModel chartViewModel,
    required String label,
    required vector_math.Matrix2 labelTiltMatrix,
    required LabelStyle labelStyle,
  }) : super(
          chartViewModel: chartViewModel,
          label: label,
          labelTiltMatrix: labelTiltMatrix,
          labelStyle: labelStyle,
        );
}
