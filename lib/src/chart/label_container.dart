import 'dart:ui';

import 'package:flutter/widgets.dart' as widgets show TextStyle, TextSpan, TextPainter;
import 'package:flutter_charts/flutter_charts.dart';
import 'package:tuple/tuple.dart' show Tuple2;
import 'package:vector_math/vector_math.dart' as vector_math show Matrix2;
import 'dart:ui' as ui show TextAlign, TextDirection, Canvas, Offset, Size;

import 'container_layouter_base.dart' show BoxContainer, LayoutableBox;
import '../morphic/rendering/constraints.dart' show BoxContainerConstraints;
import '../util/geometry.dart' as geometry;


/// Container of one label anywhere on the chart, in Labels, Axis, Titles, etc.
///
/// The [layoutSize] is exactly that of by the contained
/// layed out [_textPainter] (this [LabelContainerOriginalKeep] has no margins, padding,
/// or additional content in addition to the [_textPainter).
///
/// However, if this object is tilted, as specified by [_labelTiltMatrix], the
/// [layoutSize] is determined by the rotated layed out [_textPainter]. The
/// math and [layoutSize] of this tilt is provided by [_tiltedLabelEnvelope].
///
/// Most members are mutable so that clients can experiment with different
/// ways to set text style, until the label fits a predefined allowed size.
///
/// Notes:
/// - Instances manage the text to be presented as label,
///   and create a member [_textPainter], instance of [widgets.TextPainter]
///   from the label. The contained [_textPainter] is used for all layout
///   and painting.
/// - All methods (and constructor) of this class always call
///   [_textPainter.layout] immediately after a change.
///   Consequently,  there is no need to check for
///   a "needs layout" method - the underlying [_textPainter]
///   is always layed out, ready to be painted.
class LabelContainer extends BoxContainer {
  /// Max width of label (outside constraint).
  ///
  /// Late initialized in layout.
  late final double _labelMaxWidth;
  set labelMaxWidth(double width) {
    _labelMaxWidth = width;
  }

  /// Offset of this [LabelContainerOriginalKeep]'s label, created by the [_textPainter].
  /// 
  Offset offsetOfPotentiallyRotatedLabel = Offset.zero;

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
  Offset get tiltedLabelEnvelopeTopLeft {
    if (_labelTiltMatrix == vector_math.Matrix2.identity()) {
      assert (_tiltedLabelEnvelope.topLeft == Offset.zero);
    }
    return _tiltedLabelEnvelope.topLeft;
  }

  // Allows to configure certain sizes, colors, and layout.
  // final LabelStyle _labelStyle;

  /// Constructs an instance for a label, it's text style, and label's
  /// maximum width.
  ///
  /// todo-01 : Does not set parent container's [_boxConstraints] and [chartRootContainer].
  /// It is currently assumed clients will not call any methods using them.
  LabelContainer({
    required String label,
    required vector_math.Matrix2 labelTiltMatrix,
    required LabelStyle labelStyle,
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
          // center in available space
          textScaleFactor: labelStyle.textScaleFactor,
          // removed, causes lockup: ellipsis: "...", // forces a single line - without it, wraps at width
        ),
  //  textScaleFactor does nothing ??
        super() {
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
    //   // todo-02 add to test - was removed, causes lockup: ellipsis: "...", // forces a single line - without it, wraps at width
    // ); //  textScaleFactor does nothing ??
  }

  // #####  Implementors of method in superclass [Container].

  /// Calls super method, then adds the passed [offset] to the locally-kept slot
  /// [offsetOfPotentiallyRotatedLabel].
  /// 
  /// In more details:  After calling super, rotate the point at which label will start painting -
  /// the [offset] + [_tiltedLabelEnvelope.topLeft] - by the tilt angle against the 
  /// tilt (this angle is represented by [_labelTiltMatrix] inverse).
  /// 
  /// In *non-tilted labels*, the [_tiltedLabelEnvelope] was created as
  /// ```dart
  ///   ui.Offset.zero & _textPainter.size, // offset & size => Rect
  /// ```
  /// so the [_tiltedLabelEnvelope.topLeft] is always origin ([0.0, 0.0]).
  /// In addition, the [_labelTiltMatrix] is identity, so this method will set 
  /// ```dart
  ///   offsetOfPotentiallyRotatedLabel = offset
  /// ```
  /// to the value of [offset] (large, after all parent offsets applied).
  /// 
  /// In the *tilted labels*, the [_tiltedLabelEnvelope.topLeft] 
  /// is a small value below origin such as [0.0, 30.0], 
  /// and [offset] is also large, after all parent offsets applied. In this situation,
  /// the non-zero  [_tiltedLabelEnvelope.topLeft] represent the needed slight 'shift down'
  /// of the original [offset] at which to start painting, as the tilted labels take up a bigger rectangle.
  /// 
  // todo-01-morph : this implementation only works for tilting in [XContainer] because first call to it is 
  //                 made in [XContainer.layout], after label container is created, as 
  //                    `xLabelContainer.applyParentOffset(this, labelLeftTop + xLabelContainer.tiltedLabelEnvelopeTopLeft)`.
  //                 In this first call(s), the result of offsetOfPotentiallyRotatedLabel is the rotated
  //                    value, which is OVERWRITTEN by the last call described below; 
  //                    also, the accumulated non-rotated this.offset is kept on super slot
  //                    This is what we want - we want to keep the non-rotated this.offset on super slot,
  //                    and only do the rotation on the last call (last before paint)
  //                 The last call is made in [ChartRootContainer.layout] inside
  //                     `xContainer.applyParentOffset(this, xContainerOffset)` as
  //                 as
  //                    for (AxisLabelContainer xLabelContainer in _xLabelContainers) {
  //                      xLabelContainer.applyParentOffset(this, offset);
  //                    }
  //                 which calculates and stores the rotated value of the accumulated non-rotated this.offset 
  //                 into offsetOfPotentiallyRotatedLabel; which value is used by paint. 
  @override
  void applyParentOffset(LayoutableBox caller, ui.Offset offset) {
    super.applyParentOffset(caller, offset);

    // todo-01-morph : This should be part of new method 'findPosition' in the layout process
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

  /// This override is essentially semi-manual layout for it's class [LabelContainer],
  ///   which allows to calculate several layout related values.
  ///
  /// First, it calculates and sets the [_labelMaxWidth] member,
  ///   in [_layoutLogicToSetMemberMaxSizeForTextLayout]. See [_layoutLogicToSetMemberMaxSizeForTextLayout] for details.
  ///
  /// Second, it calls [_textPainter.layout] in [_layoutLogicToSetMemberMaxSizeForTextLayout],
  ///   which obtains the size of [_textPainter]. The resulting [layoutSize] of this [LabelContainer]
  ///   is set from the bounding rectangle of potentially rotated [_textPainter].
  ///   
  /// Note: On this leaf, instead of overriding this internal method, we could override [newCoreLayout]
  ///        witch exactly same code, and things would work, except missing check if 
  ///        layout size is within constraints.
  @override
  post_Leaf_SetSize_FromInternals() {
    _layoutLogicToSetMemberMaxSizeForTextLayout();

    // Call manual layout - the returned sizeAndOverflow contains layoutSize in item1
    Tuple2 sizeAndOverflow = _layoutAndCheckOverflowInTextDirection();
    // Set the layout size for parent to know how big this manually layed out label is.
    layoutSize = sizeAndOverflow.item1;
  }

  ///  Calculated and sets [_labelMaxWidth] used to layout [_textPainter.layout].
  ///
  ///   [layoutableBoxParentSandbox.constraints] is needed to have been
  ///   set on this object by parent in layout (before this [newCoreLayout] is called,
  ///   parent would have pushed constraints.
  void _layoutLogicToSetMemberMaxSizeForTextLayout() {
    double indicatorSquareSide = _options.legendOptions.legendColorIndicatorWidth;
    double indicatorToLabelPad = _options.legendOptions.legendItemIndicatorToLabelPad;
    double betweenLegendItemsPadding = _options.legendOptions.betweenLegendItemsPadding;

    BoxContainerConstraints boxConstraints = constraints;

    double labelMaxWidth =
        boxConstraints.maxSize.width - (indicatorSquareSide + indicatorToLabelPad + betweenLegendItemsPadding);
    _labelMaxWidth = labelMaxWidth;
    if (allowParentToSkipOnDistressedSize && labelMaxWidth <= 0.0) {
      applyParentOrderedSkip(this, true);
      layoutSize = ui.Size.zero;
      return;
    }
  }

  // ##### Internal methods

  /// Lays out for later painting, the member [_label] text
  /// specifying the maximum allowed width [_labelMaxWidth],
  /// then tests if the label fits the width.
  ///
  /// Returns `true` if label would overflow in the direction of text,
  /// `false` otherwise.
  ///
  /// The direction of text is important,  we check for overflow in letters'
  /// horizontal (length) direction, which is normally along horizontal direction.
  /// But note that canvas can be rotated, so we may be checking along
  /// vertical direction in that case.
  ///
  /// Implementation and Behaviour:
  /// - Because the underlying [_textPainter] is always
  ///   - created using [widgets.TextPainter.ellipses]
  ///   - and layed out using `textPainter.layout(maxWidth:)`
  ///     the subsequent `textPainter.paint(canvas)` call paints the label
  ///     **as always cropped to it's allocated size [_labelMaxWidth]**.
  /// - [_isOverflowingInLabelDirection] can be asked but this is information only.
  Tuple2<Size, bool> _layoutAndCheckOverflowInTextDirection() {
    _textPainter.layout();

    bool isOverflowingHorizontally = false;
    _tiltedLabelEnvelope = _createLabelEnvelope();
    Size layoutSize = _tiltedLabelEnvelope.size;

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

}

/// Class for value objects which group the text styles that may affect
/// [LabelContainerOriginalKeep]'s instances layout.
class LabelStyle {
  widgets.TextStyle textStyle;
  ui.TextDirection textDirection;
  ui.TextAlign textAlign;
  double textScaleFactor;

  LabelStyle({
    required this.textStyle,
    required this.textDirection,
    required this.textAlign,
    required this.textScaleFactor,
  });
}

/// Container of axis label, this subclass of [LabelContainer] also stores
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
class AxisLabelContainer extends LabelContainer {
  /// UI coordinate of the "axis tick mark", which represent the
  /// X or Y data value.
  ///
  /// [parentOffsetTick]'s value is not affected by call to [applyParentOffset].
  /// It is calculated during parent's [YContainer] [layout] method,
  /// as a result, it remains positioned in the [YContainer]'s coordinates.
  /// Any objects using [parentOffsetTick] as it's end point
  /// (for example grid line's end point), should apply
  /// the parent offset to themselves. The reason for this behavior is for
  /// the [parentOffsetTick]'s value to live after [YContainer]'s layout,
  /// so the  [parentOffsetTick]'s value can be used in the
  /// grid layout, without reversing any offsets.
  ///
  /// Also the X or Y offset of the X or Y label middle point
  /// (before label's parent offset).
  ///
  /// Also the "tick dash" for the label center on the X or Y axis.
  ///
  /// First "tick dash" is on the first label, last on the last label,
  /// but both x and y label containers can be skipped
  /// (tick dashes should not?).
  ///
  // todo-03 how is this used?
  double parentOffsetTick = 0.0;

  AxisLabelContainer({
    required String label,
    required vector_math.Matrix2 labelTiltMatrix,
    required LabelStyle labelStyle,
    required ChartOptions options,
    required BoxContainer parent,
  }) : super(
          label: label,
          labelTiltMatrix: labelTiltMatrix,
          labelStyle: labelStyle,
           options: options,
        ) {
    this.parent = parent;
  }
}

// todo-00-last-last added
/// Label container for Y labels, which maintain, in addition to
/// the superclass [YAxisLabelContainer] also [LabelInfo] - the object
/// from which each Y label is created.
class YAxisLabelContainer extends AxisLabelContainer {

  /// Maintains the LabelInfo from which this [LabelContainer] was created,
  /// for use during [newCoreLayout] of self or parents.
  final LabelInfo _labelInfo;

  /// Getter of [LabelInfo] which created this Y label.
  LabelInfo get labelInfo => _labelInfo;

  YAxisLabelContainer({
    required String label,
    required vector_math.Matrix2 labelTiltMatrix,
    required LabelStyle labelStyle,
    required ChartOptions options,
    required BoxContainer parent,
    required LabelInfo labelInfo, // todo-00-last-last added
  }) : _labelInfo = labelInfo, super(
    label:           label,
    labelTiltMatrix: labelTiltMatrix,
    labelStyle:      labelStyle,
    options:         options,
    parent:          parent,
  );
}
