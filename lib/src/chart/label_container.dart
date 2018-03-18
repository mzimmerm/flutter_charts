import 'package:flutter/widgets.dart' as widgets
    show
        TextStyle,
        TextSpan,
        TextPainter,
        RotatedBox,
        Transform,
        Matrix4,
        Alignment;
import 'package:flutter/material.dart' as material show Colors;

import 'package:vector_math/vector_math.dart' as vector_math
    show Matrix2, Vector2;

import 'dart:ui' as ui
    show TextAlign, TextDirection, Size, Canvas, Offset, Rect;

import 'package:flutter_charts/src/chart/options.dart';

import 'package:flutter_charts/src/chart/container.dart'
    as flutter_charts_container show Container;

import '../util/geometry.dart' as geometry;

/// Provides ability to paint one label anywhere on the chart,
/// in Labels, Axis, Titles, etc.
///
/// Most members are mutable so that clients can experiment with different
/// ways to set text style, until the label fits a predefined allowed size.
///
/// Notes:
///   - Instances manage the text to be presented as label,
///   and create a member [textPainter], instance of [widgets.TextPainter]
///   from the label. The contained [textPainter] is used for all layout
///   and painting.
///   - All methods (and constructor) of this class always call
///   [textPainter.layout] immediately after a change.
///   Consequently,  there is no need to check for
///   a "needs layout" method - the underlying [textPainter]
///   is always layed out, ready to be painted.

class LabelContainer extends flutter_charts_container.Container {
  String _label;
  double _labelMaxWidth;
  double _labelTiltRadians;
  widgets.TextPainter textPainter;
  geometry.PivotRotatedRect _tiltedLabelEnvelope;

  bool _isOverflowingInLabelDirection = true;
  ui.Size _unconstrainedSize;
  ui.Size _constraintSize;

  /// Allows to configure certain sizes, colors, and layout.
  LabelStyle _labelStyle;

  // todo -2 add to signature if boundaries overflown
  ui.TextAlign labelTextAlignOnOverflow = ui.TextAlign.left;

  /// Constructs an instance for a label, it's text style, and label's
  /// maximum width.
  ///
  /// Does not set parent container's [_layoutExpansion] and [_parentContainer].
  /// It is currently assumed clients will not call any methods using them.
  LabelContainer({
    String label,
    double labelMaxWidth,
    double labelTiltRadians,
    LabelStyle labelStyle,
  }) {
    this._label = label;
    this._labelMaxWidth = labelMaxWidth;
    this._labelTiltRadians = labelTiltRadians;
    this._labelStyle = labelStyle;

    var text = new widgets.TextSpan(
      text: label,
      style: _labelStyle.textStyle, // All labels share one style object
    );
    textPainter = new widgets.TextPainter(
      text: text,
      textDirection: _labelStyle.textDirection,
      textAlign: _labelStyle.textAlign,
      // center in available space
      textScaleFactor: _labelStyle.textScaleFactor,
      ellipsis: "...", // forces a single line - without it, wraps at width
    ); //  textScaleFactor does nothing ??

    // Make sure to call layout - this instance is always "clean"
    //   without need to call layout or introducing _isLayoutNeeded
    layout();
  }

  // #####  Implementors of method in superclass [Container].

  /// Implementor of method in superclass [Container].
  void paint(ui.Canvas canvas) {
    this.textPainter.paint(canvas, offset);
  }

  /// Implementor of method in superclass [Container].
  void layout() {
    _layoutAndCheckOverflowInTextDirection();
    // Only after layout, we know the envelope of tilted label
    // todo -12 : it is now questionable if the PivotRotatedRect should be Rect
    // todo -12 : it seems more natural to make it Offset (and assume it starts at origin, then no moving around needed
    _tiltedLabelEnvelope = new geometry.PivotRotatedRect.centerPivotedFrom(
      rect: offset & textPainter.size, // offset & size => Rect
      radians: this._labelTiltRadians,
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
  ///   - Because the underlying [textPainter] is always
  ///     - created using [widgets.TextPainter.ellipses]
  ///     - and layed out using `textPainter.layout(maxWidth:)`
  ///   the subsequent `textPainter.paint(canvas)` call paints the label
  ///   **as always cropped to it's allocated size [_labelMaxWidth]**.
  ///   - [_isOverflowingInLabelDirection] can be asked but this is information only.
  bool _layoutAndCheckOverflowInTextDirection() {
    textPainter.layout();
    _unconstrainedSize = textPainter.size;
    textPainter.layout(maxWidth: _labelMaxWidth);
    _constraintSize = textPainter.size;

    // todo -3 change 1.0 pixels for epsilon or maybe just remove
    if (_unconstrainedSize.width > _constraintSize.width + 1.0) {
      _isOverflowingInLabelDirection = true;
    } else {
      _isOverflowingInLabelDirection = false;
    }

    return _isOverflowingInLabelDirection;
  }

  // todo -4
  bool applyStyleThenLayoutAndCheckOverflow({LabelStyle labelStyle}) {
    _labelStyle = labelStyle;
    bool doesOverflow = _layoutAndCheckOverflowInTextDirection();
    return doesOverflow;
  }

  void layoutSimple() {
    textPainter.layout();
    _unconstrainedSize = textPainter.size;
  }

  /// Implementor of method in superclass [Container].
  ui.Size get layoutSize =>
      _constraintSize != null ? _constraintSize : _unconstrainedSize;

  /// Answers if container overflows is't allocated size
  /// defined in [labelMaxWidth].
  ///
  /// Allows parent containers to set some overflow affecting
  /// member, and re-layout
  bool get isOverflowinWidth =>
      _isOverflowingInLabelDirection; // todo -10 change to Mixin

// todo -10 change to Mixin: void setOverflowAffectingParameter();

}

/// Class for value objects which group the text styles that may affect
/// [LabelContainer]'s instances layout.
class LabelStyle {
  widgets.TextStyle textStyle;
  ui.TextDirection textDirection;
  ui.TextAlign textAlign;
  double textScaleFactor;

  LabelStyle({
    widgets.TextStyle this.textStyle,
    ui.TextDirection this.textDirection,
    ui.TextAlign this.textAlign,
    double this.textScaleFactor,
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
  double parentOffsetTick;

  AxisLabelContainer({
    String label,
    double labelMaxWidth,
    double labelTiltRadians,
    LabelStyle labelStyle,
  })
      : super(
          label: label,
          labelMaxWidth: labelMaxWidth,
          labelTiltRadians: labelTiltRadians,
          labelStyle: labelStyle,
        );

  void applyParentOffset(ui.Offset offset) {
    super.applyParentOffset(offset);
  }

  // todo -6 todo -1 document, and likely move up to a class named RotatedContainer or similar
  void tiltLabels() {
    // todo -12: This must be rotating by inverse of angle
    // old: rotated PI/2 COUNTERCLOCK WISE (for canvas rotate + PI/2, always clockwise)
    // KEEP: for PI/2: _offset = new ui.Offset(_offset.dy, -1.0 * _offset.dx);
    // new: rotated PI/2 CLOCK WISE        (for canvas rotate - PI/2, always clockwise)
    // KEEP: for PI/2: _offset = new ui.Offset(-1.0 * _offset.dy, _offset.dx);
    /*
    applyParentOffset(new ui.Offset(
        offset.dx, - offset.dy)); // rotated PI/2 COUNTERCLOCK WISE
//    offset.dy, -1.0 * offset.dx)); // rotated PI/2 COUNTERCLOCK WISE
   */

    // KEEP, works: offset = new ui.Offset( offset.dy, -1.0 * offset.dx);

    /* todo -12
    offset = geometry.rotateOffset(
      offset: offset,
      rotatorMatrix: _labelTiltMatrix);
      */
    offset = new ui.Offset( offset.dy, -1.0 * offset.dx);
  }
}
