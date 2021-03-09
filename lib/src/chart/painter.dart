import 'dart:ui' as ui;

import 'package:flutter/widgets.dart' as widgets; // note: external package
import 'package:flutter_charts/src/chart/bar/chart.dart';
import 'package:flutter_charts/src/chart/line/chart.dart';

import 'container.dart' as containers;

import 'package:flutter_charts/src/chart/presenter.dart' as presenters;

/// Base class of the chart painters; it's core role is to paint the 
/// charts (the extensions of [CustomPaint]).
/// 
/// As this class extends [widgets.CustomPainter], the Flutter framework
/// ensures it's [paint()] method is called at some point during the chart widget
/// ([VerticalBarChart], [LineChart], etc, the extensions of [widgets.CustomPaint])
///  is being build.
///
/// This class does the core of painting the chart, in it's core method [paint()].
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
  /// This [paint()] method is the core method call of painting the chart,
  /// in the sense it is guaranteed to be called by the Flutter framework
  /// (see class comment), hence it provides a "hook" into the chart
  /// being able to paint and draw itself.
  ///
  /// In detail, it paints all elements of the chart - the legend in [_paintLegend],
  /// the grid in [drawGrid], the x/y labels in [_paintXLabels] and [_paintYLabels],
  /// and the data values, column by column, in [drawDataPresentersColumns].
  ///
  /// Before the actual canvas painting,
  /// the operation with a call to [ChartContainer.layout()], then paints
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

    // Once we know the size, let the container manage it's size.
    // This is the layout size (??)
    container.chartArea = size;

    // Layout the whole chart container - provides all positions to paint and draw
    // all chart elements.
    container.layout();

    _paintYLabels(canvas);
    _paintXLabels(canvas);
    _paintLegend(canvas);
    // removed drawDataPresentersColumns(canvas); // bars (bar chart), lines and points (line chart)
    // Grid, then data area - bars (bar chart), lines and points (line chart).
    _paintGridAndData(canvas); 

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

  /// Draws the X labels area of the chart. 
  void _paintXLabels(ui.Canvas canvas) {
    // Draw x axis labels
    container.xContainer.paint(canvas);
  }

  /// Draws the Y labels area of the chart.
  void _paintYLabels(ui.Canvas canvas) {
    // Draw y axis labels
    container.yContainer.paint(canvas);
  }

  /// Draws the legend area of the chart.
  void _paintLegend(ui.Canvas canvas) {
    container.legendContainer.paint(canvas);
  }

  /// Draws the grid and data areas of the chart.
  void _paintGridAndData(ui.Canvas canvas) {
    container.dataContainer.paint(canvas);
  }
}
