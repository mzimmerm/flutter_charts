import 'package:flutter/widgets.dart' as widgets
    show TextStyle, TextSpan, TextPainter;
import 'package:flutter/material.dart' as material show Colors;
import 'dart:ui' as ui show TextAlign, TextDirection, Size, Canvas;
import 'package:flutter_charts/src/chart/options.dart';
import 'package:flutter_charts/src/chart/container.dart'
    as flutter_charts_container show Container;

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
  widgets.TextPainter textPainter;
  bool isOverflowing = true;
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
    LabelStyle labelStyle,
  }) {
    this._label = label;
    this._labelMaxWidth = labelMaxWidth;
    this._labelStyle = labelStyle;

    var text = new widgets.TextSpan(
      text: label,
      style: _labelStyle.textStyle, // All labels share one style object
    );
    textPainter = new widgets.TextPainter(
      text: text,
      textDirection: _labelStyle.textDirection,
      textAlign: _labelStyle.textAlign, // center in available space
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
    // todo -3 consider option: layoutSimple();
    // todo -3 consider option:  layoutAndCheckOverflow();
    layoutAndCheckOverflow();
  }

  // ##### Internal methods

  /// Lays out for later painting, the member [_label] text
  /// specifying the maximum allowed width [_labelMaxWidth],
  /// then tests if the label fits the width.
  ///
  /// Returns `true` if label would overflow, `false` otherwise.
  ///
  /// Implementation and Behaviour:
  ///   - Because the underlying [textPainter] is always
  ///     - created using [widgets.TextPainter.ellipses]
  ///     - and layed out using `textPainter.layout(maxWidth:)`
  ///   the subsequent `textPainter.paint(canvas)` call paints the label
  ///   **as always cropped to it's allocated size [_labelMaxWidth]**.
  ///   - [isOverflowing] can be asked but this is information only.
  bool layoutAndCheckOverflow() {
    textPainter.layout();
    _unconstrainedSize = textPainter.size;
    textPainter.layout(maxWidth: _labelMaxWidth);
    _constraintSize = textPainter.size;

    // todo -3 change 1.0 pixels for epsilon
    if (_unconstrainedSize.width > _constraintSize.width + 1.0) {
      isOverflowing = true;
    } else {
      isOverflowing = false;
    }

    return isOverflowing;
  }

  // todo -4
  bool applyStyleThenLayoutAndCheckOverflow({LabelStyle labelStyle}) {
    _labelStyle = labelStyle;
    bool doesOverflow = layoutAndCheckOverflow();
    return doesOverflow;
  }


  void layoutSimple() {
    textPainter.layout();
    _unconstrainedSize = textPainter.size;
  }

  /// Implementor of method in superclass [Container].
  ui.Size get layoutSize =>
      _constraintSize != null ? _constraintSize : _unconstrainedSize;
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
