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
class LabelPainter {
  String label;
  double labelMaxWidth;
  widgets.TextPainter textPainter;
  bool _overflowsMaxWidth = true; // transient layout helper
  ui.Size _unconstrainedSize;
  ui.Size _constraintSize;

  bool _needLayout; // todo -3 use same name as in layouters.

  /// Allows to configure certain sizes, colors, and layout.
  LabelTextModifier _labelTextModifier;
  // todo -2 add to signature if boundaries overflown
  ui.TextAlign labelTextAlignOnOverflow = ui.TextAlign.left;

  LabelPainter({
    String label,
    double labelMaxWidth,
    LabelTextModifier labelTextModifier,
  }) {
    label = label;
    labelMaxWidth = labelMaxWidth;
    _needLayout = true;
    _labelTextModifier = labelTextModifier;

    var text = new widgets.TextSpan(
      text: label,
      style: _labelTextModifier
          .labelTextStyle, // All labels share one style object
    );
    textPainter = new widgets.TextPainter(
      text: text,
      textDirection: _labelTextModifier.labelTextDirection,
      textAlign:
          _labelTextModifier.labelTextAlign, // center text in available space
      textScaleFactor: _labelTextModifier.labelTextScaleFactor,
    ); //  textScaleFactor does nothing ??
  }

  void modifyTextStyle({LabelTextModifier labelTextModifier}) {
    _needLayout = true;
    _labelTextModifier = labelTextModifier;
  }

  /// Lays out, for later painting, the member [label] string
  /// using the member [textPainter].
  ///
  /// For the measured values to correspond the drawn sizes,
  /// all size related styling is included.
  ///
  /// Returns the layed-out member [textPainter]
  /// instance of [widgets.TextPainter],
  /// which can later paint itself (with the [label]) on `canvas`,
  /// using `textPainter.paint(canvas, offset)`.
  widgets.TextPainter layoutTextPainter() {
    textPainter.layout(); // minWidth:100.0, maxWidth: 300.0

    return textPainter;
  }

  /// Lays out the member label [_label] text
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
  bool doesLayoutToMaxWidthOverflow() {
    textPainter.layout();
    _unconstrainedSize = textPainter.size;
    textPainter.layout(maxWidth: labelMaxWidth);
    _constraintSize = textPainter.size;

    // todo -2 check if constraintSize

    if (_unconstrainedSize.width > _constraintSize.width + 1.0) {
      _overflowsMaxWidth = true;
    } else {
      _overflowsMaxWidth = false;
    }

    return _overflowsMaxWidth;
  }
}

/// Value class grouping text styles that may change
/// [LabelPainter] and affect it's layout.
class LabelTextModifier {
  widgets.TextStyle labelTextStyle;
  ui.TextDirection labelTextDirection;
  ui.TextAlign labelTextAlign;
  double labelTextScaleFactor;

  LabelTextModifier({
    widgets.TextStyle this.labelTextStyle,
    ui.TextDirection this.labelTextDirection,
    ui.TextAlign this.labelTextAlign,
    double this.labelTextScaleFactor,
  });
}
