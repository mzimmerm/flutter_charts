import 'dart:ui' as ui;

import 'package:flutter/widgets.dart' as widgets; // note: external package
import 'package:flutter_charts/src/chart/bar/chart.dart';
import 'package:flutter_charts/src/chart/line/chart.dart';

import 'container.dart' as containers;

import 'package:flutter_charts/src/chart/presenter.dart' as presenters;

// todo-00-last-last-document-better around how this is only used to be called [paint] from there, everything are containers.
/// [ChartPainter] does the core of painting the chart,
/// in it's core method [paint()].
///
/// Extensions should implement method [drawPresentersColumns()],
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

  /// Constructor ensures the [ChartPainter] is initialized with
  /// the [ChartContainer]
  ChartPainter({
    required containers.ChartContainer chartContainer,
  }) : container = chartContainer;

  /// Paints the chart on the passed [canvas], limited to the [size] area.
  /// 
  /// This [paint()] method is the core method call of painting the chart. 
  /// 
  /// As this class extends [widgets.CustomPainter], the Flutter framework
  /// ensures this method is called at some point during the chart widget 
  /// (the [VerticalBarChart], [LineChart], etc 
  /// - the extensions of [widgets.CustomPaint]) - is being build. 
  /// 
  /// In detail, it paints all elements of the chart - the legend in [drawLegend],
  /// the grid in [drawGrid], the x/y labels in [drawXLabels] and [drawYLabels],
  /// and the data values, column by column, in [drawDataPresentersColumns].
  ///
  /// Before the actual canvas painting, 
  /// the operation with a call to [ChartContainer.painterLayout], then paints 
  /// the lines, rectangles and circles of the child [containers.Container]s,
  /// according to their calculated layout positions.
  void paint(ui.Canvas canvas, ui.Size size) {
    // Applications should handle size=(0,0) which may happen
    //   - just return and wait for re-call with size > (0,0).
    if (size == ui.Size.zero) {
      print(" ### Size: paint(): passed size 0!");
      return;
    }

    // set background: canvas.drawPaint(new ui.Paint()..color = material.Colors.green);


    // todo-00-last-last-all-containers added block:
    // Once we know the size, let the container manage it's size. 
    // This is the layout size (??)
    container.chartArea = size;

    // todo-00-last-last-all-containers container.painterLayout(size);
    container.painterLayout();

    drawGrid(canvas);
    drawYLabels(canvas);
    drawXLabels(canvas);
    drawLegend(canvas);
    // todo-00-last-last-all-containers
    // removed drawDataPresentersColumns(canvas); // bars (bar chart), lines and points (line chart)
    drawData(canvas); // bars (bar chart), lines and points (line chart)

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

// todo-00-last-last-all-containers : moved from here to LineChartDataContainer 
/*

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
*/

  // todo-00-last-last-last-remove

  /// Draws the actual data, either as lines with points (line chart),
  /// or bars/columns, stacked or grouped (bar/column charts).
// todo-00-last-last-all-containers-moved void drawDataPresentersColumns(ui.Canvas canvas);

// todo-00-last-last-all-containers-added

void drawData(ui.Canvas canvas) {
  container.dataContainer.paint(canvas);
}

}
