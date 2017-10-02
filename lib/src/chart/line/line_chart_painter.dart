import 'dart:ui' as ui;

import 'dart:math' as math;

import 'package:flutter/widgets.dart' as widgets; // note: external package imp

import 'package:flutter/material.dart' as material;

import 'package:flutter/painting.dart' as painting;

// NO -  need some private import 'package:flutter_charts/flutter_charts.dart' as common;
import 'package:flutter_charts/flutter_charts.dart' as common;
import '../elements_layouters.dart' as layouters;

/// [LineChartPainter] is the core of painting the line chart.
///
/// Extension of [CustomPainter] which provides the painting of
/// chart elemnts - lines, circles, bars - on Canvas.
/// Also encapsulates separate facilities
/// to paint text on [Canvas].
///
class LineChartPainter extends widgets.CustomPainter {

  /// Layouter provides the auto-layout of chart elements.
  ///
  /// Also currently holds [ChartData] and [ChartOptions].
  layouters.SimpleChartLayouter _layouter;

  /// Constructs this chart painter, giving it [chartData] to paint,
  /// and [chartOptions] which are configurable options that allow to
  /// change some elements of chart's layout, colors, and overall look and feel.

  // todo 0 document - change

 LineChartPainter() // note: data should be same for all charts,  options differ
  {
  }

  setLayouter(common.SimpleChartLayouter layouter) {
   _layouter = layouter;
  }
  /// todo 00 document
  /// This is sort of like constructor in the sense all initialization
  ///   of sizes based on changed data is done here.
  void paint(ui.Canvas canvas, ui.Size size) {
    print(" ### Size: paint(): passed size = ${size}");

    // Applications should handle size=(0,0) which may happen
    //   - just return and wait for re-call with size > (0,0).
    if (size == ui.Size.zero) {
      print(" ### Size: paint(): passed size 0!");
      return;
    }

    _layouter.chartArea = size;
    _layouter.layout(); // todo 0 pass size to layout

    drawGrid(canvas, size); // todo 0 do we need both args?
    drawYLabels(size, canvas);
    drawXLabels(size, canvas);
    drawLegend(size, canvas);
    drawPresentersColumns(canvas); // bars (bar chart), lines and points (line)

    // clip canvas to size - this does nothing
    canvas.clipRect(const ui.Offset(0.0, 0.0) & size); // Offset & Size => Rect
  }

  /// abstract in super.
  bool shouldRepaint(widgets.CustomPainter oldDelegate) {
    return true;
  }

  void drawGrid(ui.Canvas canvas, ui.Size gridSize) {

    // draw horizontal and vertical grid
    _layouter.horizGridLines.forEach((linePresenter) =>
        canvas.drawLine(linePresenter.from, linePresenter.to, linePresenter.paint)
    );

    _layouter.vertGridLines.forEach((linePresenter) =>
        canvas.drawLine(linePresenter.from, linePresenter.to, linePresenter.paint)
    );
  }

  /// Draws the actual data, either as lines with points (line chart),
  /// or bars/columns, stacked or grouped (bar/column charts).
  void drawPresentersColumns(ui.Canvas canvas) {
   this._layouter.presentersColumns.presentersColumns
       .forEach((common.PointAndLinePresentersColumn presentersColumn) {
     presentersColumn.presenters
         .forEach((common.PointAndLinePresenter presenter) {
       canvas.drawLine(
           presenter.linePresenter.from,
         presenter.linePresenter.to,
         presenter.linePresenter.paint,
       );
       canvas.drawCircle(
           presenter.point,
           presenter.outerRadius,
           presenter.outerPaint);
       canvas.drawCircle(
           presenter.point,
           presenter.innerRadius,
           presenter.innerPaint);
     });
   });
  }
  void drawXLabels(ui.Size size, ui.Canvas canvas) {
    // Draw x axis labels on bottom
    for (common.XLayouterOutput xLabel in _layouter.xOutputs) {
      // todo 0 : move / keep label coords in layouter
      var offset = new ui.Offset(xLabel.labelX, _layouter.xLabelsAbsY);

      widgets.TextPainter textPainter = xLabel.painter;
      textPainter.paint(canvas, offset);
    }
  }

  void drawYLabels(ui.Size size, ui.Canvas canvas) {
    // Draw y axis labels on the left
    for (common.YLayouterOutput yLabel in _layouter.yOutputs) {
      // todo 0 : move / keep label coords in layouter
      var offset = new ui.Offset(
        _layouter.yLabelsAbsX,
        yLabel.labelY,
      );
      widgets.TextPainter textPainter = yLabel.painter;
      textPainter.paint(canvas, offset);
    }
  }

  void drawLegend(ui.Size size, ui.Canvas canvas) {
    for (common.LegendLayouterOutput legend in _layouter.legendOutputs) {
      legend.labelPainter.paint(canvas, legend.labelOffset);

      canvas.drawRect(legend.indicatorRect, legend.indicatorPaint);
    }
  }
}

