import 'package:flutter/widgets.dart' as widgets
    show TextStyle, TextSpan, TextPainter;

import 'package:vector_math/vector_math.dart' as vector_math show Matrix2;

import 'dart:ui' as ui show TextAlign, TextDirection, Size, Canvas, Offset;

import 'package:flutter_charts/src/chart/container_base.dart'
    as container_base show Container;

import 'package:flutter_charts/src/morphic/rendering/constraints.dart' show 
LayoutExpansion;

import '../util/geometry.dart' as geometry;

/// Container of one label anywhere on the chart, in Labels, Axis, Titles, etc.
///
/// The [layoutSize] is exactly that of by the contained
/// layed out [_textPainter] (this [LabelContainer] has no margins, padding,
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
///   - Instances manage the text to be presented as label,
///   and create a member [_textPainter], instance of [widgets.TextPainter]
///   from the label. The contained [_textPainter] is used for all layout
///   and painting.
///   - All methods (and constructor) of this class always call
///   [_textPainter.layout] immediately after a change.
///   Consequently,  there is no need to check for
///   a "needs layout" method - the underlying [_textPainter]
///   is always layed out, ready to be painted.

class LabelContainer extends container_base.Container {

  /// Max width of label (outside constraint)
  final double _labelMaxWidth;

  /// For tilted labels, this is the forward rotation matrix
  /// to apply on both Canvas AND label envelope's topLeft offset's coordinate
  /// (pivoted on origin, once all chart offsets are applied to label).
  /// This is always the inverse of [_labelTiltMatrix].
  final vector_math.Matrix2 _canvasTiltMatrix;

  /// Angle by which label is tilted.
  final vector_math.Matrix2 _labelTiltMatrix;

  /// [TextPainter] wrapped in this label container.
  /// Paints the [_label]. It is the only painted content of this container.
  final widgets.TextPainter _textPainter;

  /// Minimum envelope around the contained label (and hence, this container).
  /// It is created and kept such that the envelope topLeft = (0.0, 0.0),
  /// that is, the envelope is in label container (and textPainter)
  /// local coordinates.
  late geometry.EnvelopedRotatedRect _tiltedLabelEnvelope;
  
  /// Allows to configure certain sizes, colors, and layout.
  final LabelStyle _labelStyle;

  /// Constructs an instance for a label, it's text style, and label's
  /// maximum width.
  ///
  /// Does not set parent container's [_layoutExpansion] and [_chartTopContainer].
  /// It is currently assumed clients will not call any methods using them.
  LabelContainer({
    required String label,
    required double labelMaxWidth,
    required vector_math.Matrix2 labelTiltMatrix,
    required vector_math.Matrix2 canvasTiltMatrix,
    required LabelStyle labelStyle,
  })  : _labelMaxWidth = labelMaxWidth,
        _labelTiltMatrix = labelTiltMatrix,
        _canvasTiltMatrix = canvasTiltMatrix,
        _labelStyle = labelStyle,
        _textPainter = widgets.TextPainter(
          text: widgets.TextSpan(
            text: label,
            style: labelStyle.textStyle, // All labels share one style object
          ),
          textDirection: labelStyle.textDirection,
          textAlign: labelStyle.textAlign,
          // center in available space
          textScaleFactor: labelStyle.textScaleFactor,
          // todo-11 removed, causes lockup: ellipsis: "...", // forces a single line - without it, wraps at width
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
    //   // todo-11 removed, causes lockup: ellipsis: "...", // forces a single line - without it, wraps at width
    // ); //  textScaleFactor does nothing ??

    // Make sure to call layout - this instance is always "clean"
    //   without need to call layout or introducing _isLayoutNeeded
    layout(LayoutExpansion.unused());
  }

  // #####  Implementors of method in superclass [Container].

  /// Implementor of method in superclass [Container].
  @override
  void paint(ui.Canvas canvas) {
    _textPainter.paint(canvas, offset);
  }

  /// Implementor of method in superclass [Container].
  @override
  void layout(LayoutExpansion parentLayoutExpansion) {
    // todo-00-last : cannot set _layoutExpansion here, as it is private in another src file
    // it does not appear needed.
    _layoutAndCheckOverflowInTextDirection();
    _tiltedLabelEnvelope = _createLabelEnvelope();
  }

  geometry.EnvelopedRotatedRect _createLabelEnvelope() {
    assert(offset == ui.Offset.zero);
    // Only after layout, we know the envelope of tilted label
    return geometry.EnvelopedRotatedRect.centerRotatedFrom(
      rect: offset & _textPainter.size, // offset & size => Rect
      rotateMatrix: _labelTiltMatrix,
    );
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
  ///   - Because the underlying [_textPainter] is always
  ///     - created using [widgets.TextPainter.ellipses]
  ///     - and layed out using `textPainter.layout(maxWidth:)`
  ///   the subsequent `textPainter.paint(canvas)` call paints the label
  ///   **as always cropped to it's allocated size [_labelMaxWidth]**.
  ///   - [_isOverflowingInLabelDirection] can be asked but this is information only.
  bool _layoutAndCheckOverflowInTextDirection() {
    _textPainter.layout();

    bool isOverflowingHorizontally = false;
    _tiltedLabelEnvelope = _createLabelEnvelope();
    layoutSize = _tiltedLabelEnvelope.size;

    if (layoutSize.width > _labelMaxWidth) {
      isOverflowingHorizontally = true;
      _textPainter.layout(maxWidth: _labelMaxWidth);
      _tiltedLabelEnvelope = _createLabelEnvelope();
      layoutSize = _tiltedLabelEnvelope.size;
    }
    
    return isOverflowingHorizontally;
  }

}

/// Class for value objects which group the text styles that may affect
/// [LabelContainer]'s instances layout.
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

/// Subclass of [LabelContainer] is extended with member [parentOffsetTick],
/// which maintains the container's center position in
/// immediate parent's coordinates.
///
/// **This violates independence of parents not knowing
/// and not needing their children;
/// here, when used in parent [XContainer], the parent is storing
/// some of it's properties on children.**
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
///   - If owner is a [YContainer], all positions are relative to the top of
///     the container of y labels
///   - If owner is a [XContainer] All positions are relative to the left
///     of the container of x labels
///   - If owner is Area [ChartContainer], all positions are relative
///     to the top of the available [chartArea].
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
  double parentOffsetTick = 0.0;

  AxisLabelContainer(
      {required String label,
      required double labelMaxWidth,
      required vector_math.Matrix2 labelTiltMatrix,
      required vector_math.Matrix2 canvasTiltMatrix,
      required LabelStyle labelStyle,
  })
      : super(
          label: label,
          labelMaxWidth: labelMaxWidth,
          labelTiltMatrix: labelTiltMatrix,
          canvasTiltMatrix: canvasTiltMatrix,
          labelStyle: labelStyle,
        );

/* todo-00-new this is just calling super, so not needed, todo-00-remove
  @override
  void applyParentOffset(ui.Offset offset) {
    super.applyParentOffset(offset);
  }
*/

  /// Rotate this label around origin along with Canvas, to achieve label tilt.
  ///
  /// Must be called only in paint()
  void rotateLabelWithCanvas() {
    // In paint(), this label's offset is now the "absolute" offset in the chart
    // The point in the tilted rectangle, where [TextPainter] should start
    // painting the label is always topLeft in the envelope.
    // The envelope is kept at (0,0), so find the full offset of
    // the [_tiltedLabelEnvelope.topLeft] in the "absolute" coordinates,
    // then rotate the result with Canvas.

    offset = geometry.transform(
      matrix: _canvasTiltMatrix,
      offset: (offset + _tiltedLabelEnvelope.topLeft),
    );
  }
}
