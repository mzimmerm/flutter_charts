import 'dart:ui' as ui;

import 'package:flutter/widgets.dart' as widgets; // note: external package

import 'package:flutter_charts/flutter_charts.dart' as common;
import 'container.dart' as containers;

import 'package:flutter_charts/src/chart/presenter.dart' as presenters;

/// [ChartPainter] does the core of painting the chart,
/// in it's core method [paint].
///
/// Extensions should implement method [drawPresentersColumns],
/// which paints each column with the data representing elements -
/// lines, or rectangles.
///
/// An extension of flutter's [CustomPainter] which provides the
/// painting of the chart leaf elements - lines, circles, bars - on Canvas.
abstract class ChartPainter extends widgets.CustomPainter {
  /// Container provides the auto-layout of chart elements.
  ///
  /// Also currently holds [ChartData] and [ChartOptions].
  containers.ChartContainer container;

  /// Constructs this chart painter, giving it [chartData] to paint,
  /// and [chartOptions] which are configurable options that allow to
  /// change some elements of chart's layout, colors, and overall look and feel.

  // note: data should be same for all charts,  options differ
  ChartPainter();

  setContainer(common.ChartContainer container) {
    this.container = container;
  }

  /// Paints the chart area - the legend in [drawLegend],
  /// the grid in [drawGrid], the x/y labels in [drawXLabels] and [drawYLabels],
  /// and the data values, column by column, in [drawPresentersColumns].
  ///
  /// Starts with a call to [ChartContainer.layout], then painting
  /// according to the calculated layout positions.
  void paint(ui.Canvas canvas, ui.Size size) {

    // Applications should handle size=(0,0) which may happen
    //   - just return and wait for re-call with size > (0,0).
    if (size == ui.Size.zero) {
      print(" ### Size: paint(): passed size 0!");
      return;
    }

    // set background: canvas.drawPaint(new ui.Paint()..color = material.Colors.green);

    container.chartArea = size;
    container.layout();

    drawGrid(canvas);
    drawYLabels(canvas);
    drawXLabels(canvas);
    drawLegend(canvas);
    drawPresentersColumns(canvas); // bars (bar chart), lines and points (line)

    // clip canvas to size - this does nothing
    // todo-1: THIS canvas.clipRect VVVV CAUSES THE PAINT() TO BE CALLED AGAIN. WHY??
    // canvas.clipRect(const ui.Offset(0.0, 0.0) & size); // Offset & Size => Rect
  }

  /// Implementing abstract in super.
  ///
  /// Called any time that a new CustomPaint object is created
  /// with a new instance of the custom painter delegate class.
  bool shouldRepaint(widgets.CustomPainter oldDelegate) {
    return true;
  }

  void drawGrid(ui.Canvas canvas) {
    // draw horizontal and vertical grid
    container.dataContainer.paint(canvas);
  }

  void drawXLabels(ui.Canvas canvas) {
    // Draw x axis labels
    container.xContainer.paint(canvas);
  }

  void drawYLabels(ui.Canvas canvas) {
    // Draw y axis labels
    container.yContainer.paint(canvas);
  }

  void drawLegend(ui.Canvas canvas) {
    container.legendContainer.paint(canvas);
  }

  /// Optionally paint series in reverse order (first to last vs last to first)
  ///
  /// See [ChartOptions.firstDataRowPaintedFirst].
  List<presenters.Presenter> optionalPaintOrderReverse(
      List<presenters.Presenter> presenters) {
    var options = this.container.options;
    if (options.firstDataRowPaintedFirst) {
      presenters = presenters.reversed.toList();
    }
    return presenters;
  }

  /// Draws the actual data, either as lines with points (line chart),
  /// or bars/columns, stacked or grouped (bar/column charts).
  void drawPresentersColumns(ui.Canvas canvas);
}
