import 'package:flutter/widgets.dart' as widgets
    show TextStyle, TextSpan, TextPainter;
import 'package:flutter/material.dart' as material show Colors;
import 'dart:ui' as ui show TextAlign, TextDirection, Size;
import 'package:flutter_charts/src/chart/options.dart';

/// Provides ability to paint one label anywhere on the chart,
/// in Labels, Axis, Titles, etc.
///
/// Most members are mutable so that clients can experiment with different
/// ways to set text style, until the label fits a predefined allowed size.
///
/// Note: All methods (and constructor) of this class always calls
///       layout, as a result, [_overflowsMaxWidth] can be always asked,
///       there is no need to check for "needs layout" or similar.
class LabelPainter {
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

  LabelPainter({
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
    ); //  textScaleFactor does nothing ??

    // Make sure to call layout - this instance is always "clean"
    //   without need to call layout or introducing _isLayoutNeeded
    layoutAndCheckOverflow();
  }

  bool applyStyleThenLayoutAndCheckOverflow({LabelStyle labelStyle}) {
    _labelStyle = labelStyle;
    bool doesOverflow = layoutAndCheckOverflow();
    return doesOverflow;
  }

  /// Lays out, for later painting, the member [_label] string
  /// using the member [textPainter].
  ///
  /// For the measured values to correspond the drawn sizes,
  /// all size related styling is included.
  ///
  /// Returns the layed-out member [textPainter]
  /// instance of [widgets.TextPainter],
  /// which can later paint itself (with the [_label]) on `canvas`,
  /// using `textPainter.paint(canvas, offset)`.
  /// todo -2 this needs removed
  widgets.TextPainter layoutTextPainter() {
    textPainter.layout(); // minWidth:100.0, maxWidth: 300.0

    return textPainter;
  }

  /// Lays out the member [_label] text
  /// specifying the maximum allowed width [_labelMaxWidth],
  /// then tests if the label fits the width.
  ///
  /// Returns `true` if label would overflow, `false` otherwise.
  ///
  /// Because the final layout is using
  /// `textPainter.layout(maxWidth: _labelMaxWidth)`,
  /// text overflow if any, will NOT be shown on
  /// the subsequent `textPainter.paint(canvas)` call.
  /// Label text will be croped.
  bool layoutAndCheckOverflow() {
    textPainter.layout();
    _unconstrainedSize = textPainter.size;
    textPainter.layout(maxWidth: _labelMaxWidth);
    _constraintSize = textPainter.size;

    // todo -2 check if constraintSize

    if (_unconstrainedSize.width > _constraintSize.width + 1.0) {
      isOverflowing = true;
    } else {
      isOverflowing = false;
    }

    return isOverflowing;
  }
}

/// Class for value objects which group the text styles that may affect
/// [LabelPainter]'s instances layout.
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
