// import 'package:flutter/widgets.dart' as widgets show TextStyle, TextSpan, TextPainter;
// import 'package:flutter_charts/flutter_charts.dart';
// import 'package:tuple/tuple.dart' show Tuple2;
import 'package:vector_math/vector_math.dart' as vector_math show Matrix2;
// import 'dart:ui' as ui show TextAlign, TextDirection, Canvas, Offset, Size;

// this level or equivalent
import 'container.dart' show AxisContainer, PixelRangeProvider;
import '../../chart/container_new/container_common_new.dart' as container_common_new show ChartAreaContainer;
import '../../chart/label_container.dart';
import '../../chart/view_maker.dart' as view_maker;
// import '../../chart/container_layouter_base.dart' show LayoutableBox, BoxLayouter;
import '../../chart/options.dart' show ChartOptions;
// import '../../morphic/rendering/constraints.dart' show BoxContainerConstraints;
// import '../../util/geometry.dart' as geometry;
import '../../util/util_labels.dart' show AxisLabelInfo;

/* No need to extend
class LabelContainerCL extends LabelContainer {

  // Allows to configure certain sizes, colors, and layout.
  // final LabelStyle _labelStyle;

  /// Constructs an instance for a label, it's text style, and label's
  /// maximum width.
  ///
  /// todo-02 : Does not set parent container's [_boxConstraints] and [chartViewMaker].
  /// It is currently assumed clients will not call any methods using them.
  LabelContainerCL({
    required view_maker.ChartViewMaker chartViewMaker,
    required String label,
    required vector_math.Matrix2 labelTiltMatrix,
    required LabelStyle labelStyle,
    // todo-00!!! : Review Labels !!! Take options from chartViewMaker - do this EVERYWHERE - LOOK FOR 'required ChartOptions' AND MORE
    required ChartOptions options,
  })  :
        _options = options,
        _labelTiltMatrix = labelTiltMatrix,
  // _labelStyle = labelStyle,
        _textPainter = widgets.TextPainter(
          text: widgets.TextSpan(
            text: label,
            style: labelStyle.textStyle, // All labels share one style object
          ),
          textDirection: labelStyle.textDirection,
          textAlign: labelStyle.textAlign,
          // center in available space todo-01 textScaleFactor does nothing ??
          textScaleFactor: labelStyle.textScaleFactor,
          // removed, causes lockup: ellipsis: "...", // forces a single line - without it, wraps at width
        ),
        super(
        chartViewMaker: chartViewMaker,
      ) {

  }

  /// Max width of label (outside constraint).
  ///
  /// Late initialized in layout.
  late final double _labelMaxWidth;

  /// Offset of this [LabelContainerOriginalKeep]'s label, created by the [_textPainter].
  ///
  ui.Offset offsetOfPotentiallyRotatedLabel = ui.Offset.zero;

  /// Rotation matrix representing the angle by which the label is tilted.
  ///
  /// Tilting of labels is achieve by applying this [Matrix2] on the
  /// rectangle which surrounds the label text.
  final vector_math.Matrix2 _labelTiltMatrix;

  /// [TextPainter] wrapped in this label container.
  /// Paints the [_label]. It is the only painted content of this container.
  final widgets.TextPainter _textPainter;

  /// Minimum envelope around the contained label (and hence, this container).
  /// It is created and kept such that the envelope topLeft = Offset.zero,
  /// that is, the envelope is in label container (and textPainter)
  /// local coordinates.
  late geometry.EnvelopedRotatedRect _tiltedLabelEnvelope;

  final ChartOptions _options;

  /// Position where paint starts painting the label, expressed
  /// in the coordinate system in which this [_tiltedLabelEnvelope.envelopeRect] topLeft
  /// (NOT the _tiltedLabelEnvelope.topLeft) is at the origin.
  ///
  /// The returned value is the offset (before any rotation!),
  /// needed to reach the point where the text in the [_textPainter]
  /// should start painting the tilted or non-tilted situation.
  /// In the non-tilted situation, the returned value is always Offset.zero.
  ui.Offset get tiltedLabelEnvelopeTopLeft {
    if (_labelTiltMatrix == vector_math.Matrix2.identity()) {
      assert (_tiltedLabelEnvelope.topLeft == ui.Offset.zero);
    }
    return _tiltedLabelEnvelope.topLeft;
  }


  // #####  Implementors of method in superclass [Container].


  @override
  void applyParentOffset(LayoutableBox caller, ui.Offset offset) {
    super.applyParentOffset(caller, offset);

    // Next, _rotateLabelEnvelopeTopLeftToPaintOffset:
    // Transform the point where label painting starts against the tilt of labels.
    // No-op for non-tilted labels, where _labelTiltMatrix is identity,
    //   and  _tiltedLabelEnvelope.topLeft is center = Offset.zero.
    vector_math.Matrix2 canvasTiltMatrix = _labelTiltMatrix.clone();
    canvasTiltMatrix.invert();

    offsetOfPotentiallyRotatedLabel = geometry.transform(
      matrix: canvasTiltMatrix,
      offset: (this.offset),
    );
  }

  /// Implementor of method in superclass [Container].
  @override
  void paint(ui.Canvas canvas) {
    _textPainter.paint(canvas, offsetOfPotentiallyRotatedLabel);
  }

  @override
  void layout_Post_Leaf_SetSize_FromInternals() {
    _layoutLogicToSetMemberMaxSizeForTextLayout();

    // Call manual layout - the returned sizeAndOverflow contains layoutSize in item1
    Tuple2 sizeAndOverflow = _layoutAndCheckOverflowInTextDirection();
    // Set the layout size for parent to know how big this manually layed out label is.
    layoutSize = sizeAndOverflow.item1;
  }

  void _layoutLogicToSetMemberMaxSizeForTextLayout() {
    // todo-00-last-00 : this seems incorrect - used for all labels, yet it acts as legend label!!
    double indicatorSquareSide = _options.legendOptions.legendColorIndicatorWidth;
    double indicatorToLabelPad = _options.legendOptions.legendItemIndicatorToLabelPad;
    double betweenLegendItemsPadding = _options.legendOptions.betweenLegendItemsPadding;

    BoxContainerConstraints boxConstraints = constraints;

    double labelMaxWidth =
        boxConstraints.maxSize.width - (indicatorSquareSide + indicatorToLabelPad + betweenLegendItemsPadding);
    _labelMaxWidth = labelMaxWidth;
    if (allowParentToSkipOnDistressedSize && labelMaxWidth <= 0.0) {
      // todo-01 : fix this as not dealing with width < 0 brings issues further
      applyParentOrderedSkip(parent as BoxLayouter, true);
      layoutSize = ui.Size.zero;
      return;
    }
  }

  // ##### Internal methods

  Tuple2<ui.Size, bool> _layoutAndCheckOverflowInTextDirection() {
    _textPainter.layout();

    bool isOverflowingHorizontally = false;
    _tiltedLabelEnvelope = _createLabelEnvelope();
    ui.Size layoutSize = _tiltedLabelEnvelope.size;

    // todo-00-later : add exception if reached with _labelMaxWidth < 0.0
    if (layoutSize.width > _labelMaxWidth) {
      isOverflowingHorizontally = true;
      _textPainter.layout(maxWidth: _labelMaxWidth);
      _tiltedLabelEnvelope = _createLabelEnvelope();
      layoutSize = _tiltedLabelEnvelope.size;
    }

    return Tuple2(layoutSize, isOverflowingHorizontally);
  }

  /// Creates the envelope rectangle [EnvelopedRotatedRect], which [EnvelopedRotatedRect.topLeft]
  /// is used to position this [LabelContainerOriginalKeep] for painting with or without tilt.
  geometry.EnvelopedRotatedRect _createLabelEnvelope() {
    // Only after layout, we know the envelope of tilted label
    return geometry.EnvelopedRotatedRect.centerRotatedFrom(
      rect: ui.Offset.zero & _textPainter.size, // offset & size => Rect
      rotateMatrix: _labelTiltMatrix,
    );
  }

  @override
  void buildAndReplaceChildren() {
    buildAndReplaceChildrenDefault();
  }
}
*/

/// Extension of [AxisLabelContainer] for legacy manual layout axis labels container,
/// with added behavior needed for manual layout:
///   1. overrides method [layout_Post_Leaf_SetSize_FromInternals] to use the
///      (ownerChartAreaContainer as PixelRangeProvider).axisPixelsRange to lextr label data values to pixels
///   2. has member parentOffsetTick to keep location (from build to manual layout?).
///
///  Legacy label containers [XLabelContainerCL] and [YLabelContainerCL] should extend this
///
abstract class AxisLabelContainerCL extends AxisLabelContainer {
  AxisLabelContainerCL({
    required view_maker.ChartViewMaker chartViewMaker,
    required String label,
    required vector_math.Matrix2 labelTiltMatrix,
    required LabelStyle labelStyle,
    required ChartOptions options,
    required AxisLabelInfo labelInfo,
    required container_common_new.ChartAreaContainer ownerChartAreaContainer,
  }) : super(
        chartViewMaker: chartViewMaker,
        label: label,
        labelTiltMatrix: labelTiltMatrix,
        labelStyle: labelStyle,
        options: options,
        labelInfo: labelInfo,
        ownerChartAreaContainer: ownerChartAreaContainer,
      );

  /// [parentOffsetTick] is the UI pixel coordinate of the "axis tick mark", which represent the
  /// X or Y data value.
  ///
  /// In more detail, it is the numerical value of a label, transformed, then extrapolated to axis pixels length,
  /// so its value is in pixels relative to the immediate container - the [YContainer] or [XContainer]
  ///
  /// It's value is not affected by call to [applyParentOffset].
  /// It is calculated during parent's [YContainer] [layout] method,
  /// as a result, it remains positioned in the [AxisContainer]'s coordinates.
  /// Any objects using [parentOffsetTick] as it's end point
  /// (for example grid line's end point), should apply
  /// the parent offset to themselves. The reason for this behavior is for
  /// the [parentOffsetTick]'s value to live after [AxisContainer]'s layout,
  /// so the  [parentOffsetTick]'s value can be used in the
  /// grid layout, without reversing any offsets.
  ///
  /// [parentOffsetTick]  has multiple other roles:
  ///   - The X or Y offset of the X or Y label middle point
  ///     (before label's parent offset), which becomes [yTickY] but NOT [xTickX]
  ///     (currently, xTickX is from x value data position, not from generated labels by [DataRangeLabelInfosGenerator]).
  ///     ```dart
  ///        double yTickY = yLabelContainer.parentOffsetTick;
  ///        double labelTopY = yTickY - yLabelContainer.layoutSize.height / 2;
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
  /// Uses the [YContainerCL.labelsGenerator] instance of [DataRangeLabelInfosGenerator] to
  /// lextr the [labelInfo] value [AxisLabelInfo.dataValue] and places the result on [parentOffsetTick].
  ///
  /// Must ONLY be invoked after container layout when the axis pixels range (axisPixelsRange)
  /// is determined.
  ///
  /// Note: Invoked on BOTH [XLabelContainerCL] and [YLabelContainerCL], but only relevant on [YLabelContainerCL].
  ///       On [XLabelContainerCL] it could be skipped, the layout code in [XContainerCL.layout]
  ///       ```dart
  ///           xLabelContainer.parentOffsetTick = xTickX;
  ///        ```
  ///        overrides this.
  @override
  void layout_Post_Leaf_SetSize_FromInternals() {
    // We now know how long the Y axis is in pixels,
    // so we can calculate this label pixel position IN THE XContainer / YContainer
    // and place it on [parentOffsetTick]
    var labelsGenerator = ownerChartAreaContainer.chartViewMaker.yLabelsGenerator;
    assert (chartViewMaker.isUseOldDataContainer == true);

    parentOffsetTick = labelsGenerator.lextrValueToPixels(
      value: labelInfo.dataValue.toDouble(),
      axisPixelsMin: (ownerChartAreaContainer as PixelRangeProvider).axisPixelsRange.min,
      axisPixelsMax: (ownerChartAreaContainer as PixelRangeProvider).axisPixelsRange.max,
    );

    super.layout_Post_Leaf_SetSize_FromInternals();
  }
}

/// Label container for Y labels, which maintain, in addition to
/// the superclass [YLabelContainer] also [AxisLabelInfo] - the object
/// from which each Y label is created.
class YLabelContainerCL extends AxisLabelContainerCL {

  YLabelContainerCL({
    required view_maker.ChartViewMaker chartViewMaker,
    required String label,
    required vector_math.Matrix2 labelTiltMatrix,
    required LabelStyle labelStyle,
    required ChartOptions options,
    required AxisLabelInfo labelInfo,
    required AxisContainer ownerChartAreaContainer,
  }) : super(
    chartViewMaker: chartViewMaker,
    label:           label,
    labelTiltMatrix: labelTiltMatrix,
    labelStyle:      labelStyle,
    options:         options,
    labelInfo:       labelInfo,
    ownerChartAreaContainer: ownerChartAreaContainer,
  );
}

/// [AxisLabelContainer] used in the [XContainer].
class XLabelContainerCL extends AxisLabelContainerCL {

  XLabelContainerCL({
    required view_maker.ChartViewMaker chartViewMaker,
    required String label,
    required vector_math.Matrix2 labelTiltMatrix,
    required LabelStyle labelStyle,
    required ChartOptions options,
    required AxisLabelInfo labelInfo,
    required container_common_new.ChartAreaContainer ownerChartAreaContainer,
  }) : super(
    chartViewMaker:  chartViewMaker,
    label:           label,
    labelTiltMatrix: labelTiltMatrix,
    labelStyle:      labelStyle,
    options:         options,
    labelInfo:       labelInfo,
    ownerChartAreaContainer: ownerChartAreaContainer,
  );
}
