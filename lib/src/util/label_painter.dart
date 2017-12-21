import 'package:flutter/widgets.dart' as widgets
    show TextStyle, TextSpan, TextPainter;
import 'package:flutter/material.dart' as material show Colors;
import 'dart:ui' as ui
    show TextAlign, TextDirection;
import 'package:flutter_charts/src/chart/options.dart';

/// Provides ability to paint individual elements
/// of the chart: Labels, Axis, Titles.
///
class LabelPainter {
  String _label;
  double _labelMaxWidth;
  /// Options allow to configure certain sizes, colors, and layout.
  ChartOptions _options;// todo -2 remove
  widgets.TextStyle _labelTextStyle;
  ui.TextDirection _labelTextDirection;
  ui.TextAlign _labelTextAlign;
  // todo--1 add to signature if boundaries overflown
  ui.TextAlign _labelTextAlignOnOverflow = ui.TextAlign.left;
  double _labelTextScaleFactor;
  bool isTooBig = true; // transient layout helper

  LabelPainter({
    String label,
    double labelMaxWidth,
    ChartOptions options, // todo -2 remove
    widgets.TextStyle labelTextStyle,
    ui.TextDirection labelTextDirection,
    ui.TextAlign labelTextAlign,
    double labelTextScaleFactor,
  }) {
    _label = label;
    _labelMaxWidth = labelMaxWidth;
    _options = options; // todo -2 not needed

    _labelTextStyle = labelTextStyle;
    _labelTextDirection = labelTextDirection;
    _labelTextAlign = labelTextAlign;
    _labelTextScaleFactor = labelTextScaleFactor;
  }

  /// Paints the passed string using a [widgets.TextPainter].
  ///
  /// For the passed string , obtains a new TextPainter that can be used
  /// both for measuring and drawing.
  ///
  /// For the measured values to correspond the drawn sizes,
  /// all size related styling is included.
  ///
  /// Returns a layed-out `textPainter` instance of [widgets.TextPainter],
  /// which can paint itself on `canvas`, with top-left position at `offset`,
  /// using `textPainter.paint(canvas, offset)`.
  widgets.TextPainter textPainterForLabel() {
    var text = new widgets.TextSpan(
      text: _label,
      style: _labelTextStyle, // All labels share one style object
    );
    var textPainter = new widgets.TextPainter(
      text: text,
      textDirection: _labelTextDirection,
      textAlign: _labelTextAlign, // center text in available space
      textScaleFactor: _labelTextScaleFactor,
    ); //  textScaleFactor does nothing ??

    textPainter.layout(); // minWidth:100.0, maxWidth: 300.0

    return textPainter;
  }
}
