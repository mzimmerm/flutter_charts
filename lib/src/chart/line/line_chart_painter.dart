import 'dart:ui' as ui;

import 'dart:math' as math;

import 'package:flutter/widgets.dart' as widgets; // note: external package imp

import 'package:flutter/material.dart' as material;

import 'package:flutter/painting.dart' as painting;

// NO -  need some private import 'package:flutter_charts/flutter_charts.dart' as common;
import 'package:flutter_charts/flutter_charts.dart' as common;
import '../layouters.dart' as layouters; // todo -1 export in lib instead
import '../presenters.dart' as presenters; // todo -1 export in lib instead

class LineChartPainter extends ChartPainter {

  layouters.ChartLayouter _layouter;

  /// Draws the actual data, either as lines with points (line chart),
  /// or bars/columns, stacked or grouped (bar/column charts).
  void drawPresentersColumns(ui.Canvas canvas) {
    this._layouter.pointAndLinePresentersColumns.presentersColumns
        .forEach((presenters.PointAndLinePresentersColumn presentersColumn) {
      presentersColumn.presenters
          .forEach((presenters.PointAndLinePresenter presenter) {
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
}

/// [LineChartPainter] is the core of painting the line chart.
///
/// Extension of [CustomPainter] which provides the painting of
/// chart elemnts - lines, circles, bars - on Canvas.
/// Also encapsulates separate facilities
/// to paint text on [Canvas].
///
/// todo 0 document
///
abstract class ChartPainter extends widgets.CustomPainter {

  /// Layouter provides the auto-layout of chart elements.
  ///
  /// Also currently holds [ChartData] and [ChartOptions].
  layouters.ChartLayouter _layouter;

  /// Constructs this chart painter, giving it [chartData] to paint,
  /// and [chartOptions] which are configurable options that allow to
  /// change some elements of chart's layout, colors, and overall look and feel.

  // todo 0 document - change

  ChartPainter() // note: data should be same for all charts,  options differ
  {
  }

  setLayouter(common.ChartLayouter layouter) {
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

    drawGrid(canvas);
    drawYLabels(canvas);
    drawXLabels(canvas);
    drawLegend(canvas);
    drawPresentersColumns(canvas); // bars (bar chart), lines and points (line)

    // clip canvas to size - this does nothing
    canvas.clipRect(const ui.Offset(0.0, 0.0) & size); // Offset & Size => Rect
  }

  /// abstract in super.
  bool shouldRepaint(widgets.CustomPainter oldDelegate) {
    return true;
  }

  void drawGrid(ui.Canvas canvas) {

    // draw horizontal and vertical grid
    _layouter.horizGridLines.forEach((linePresenter) =>
        canvas.drawLine(linePresenter.from, linePresenter.to, linePresenter.paint)
    );

    _layouter.vertGridLines.forEach((linePresenter) =>
        canvas.drawLine(linePresenter.from, linePresenter.to, linePresenter.paint)
    );
  }

  void drawXLabels(ui.Canvas canvas) {
    // Draw x axis labels on bottom
    for (common.XLayouterOutput xLabel in _layouter.xOutputs) {
      // todo 0 : move / keep label coords in layouter
      var offset = new ui.Offset(xLabel.labelX, _layouter.xLabelsAbsY);

      widgets.TextPainter textPainter = xLabel.painter;
      textPainter.paint(canvas, offset);
    }
  }

  void drawYLabels(ui.Canvas canvas) {
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

  void drawLegend(ui.Canvas canvas) {
    for (common.LegendLayouterOutput legend in _layouter.legendOutputs) {
      legend.labelPainter.paint(canvas, legend.labelOffset);

      canvas.drawRect(legend.indicatorRect, legend.indicatorPaint);
    }
  }

  /// Draws the actual data, either as lines with points (line chart),
  /// or bars/columns, stacked or grouped (bar/column charts).
  void drawPresentersColumns(ui.Canvas canvas);
}

