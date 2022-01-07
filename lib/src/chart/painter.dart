import 'dart:ui' as ui;

import 'package:flutter/widgets.dart' as widgets; // note: external package
import 'package:flutter_charts/src/chart/bar/chart.dart';
import 'package:flutter_charts/src/chart/line/chart.dart';

import 'container.dart' as containers;

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
  containers.ChartTopContainer chartTopContainer;

  /// Constructs this chart painter, giving it [chartData] to paint,
  /// and [chartOptions] which are configurable options that allow to
  /// change some elements of chart's layout, colors, and overall look and feel.

  /// Constructor ensures the [ChartPainter] is initialized with
  /// the [ChartContainer]
  ChartPainter({
    required this.chartTopContainer,
  });

  /// Paints the chart on the passed [canvas], limited to the [size] area.
  ///
  /// This [paint()] method is the core method call of painting the chart,
  /// in the sense it is guaranteed to be called by the Flutter framework
  /// (see class comment), hence it provides a "hook" into the chart
  /// being able to paint and draw itself.
  ///
  /// The substantial role is to pass the [size] provided by the framework layout
  /// to [chartTopContainer.chartArea]. The container needs this information for layout,
  /// see [containers.ChartContainer.layout()].
  ///
  /// Once the above role is done, it delegates all painting to canvas to the
  /// [containers.ChartContainer.paint()] (see).
  @override
  void paint(ui.Canvas canvas, ui.Size size) {
    // Applications should handle size=(0,0) which may happen
    //   - just return and wait for re-call with size > (0,0).
    if (size == ui.Size.zero) {
      print(' ### Size: paint(): passed size 0!');
      return;
    }

    // set background: canvas.drawPaint(ui.Paint()..color = material.Colors.green);

    // Once we know the size, let the container manage it's size.
    // This is the layout size. Once done, we can delegate painting
    // to canvas to the [ChartContainer].
    chartTopContainer.chartArea = size;

    // Layout the whole chart container - provides all positions to paint and draw
    // all chart elements.
    chartTopContainer.paint(canvas);

    // clip canvas to size - this does nothing
    // todo-1: THIS canvas.clipRect VVVV CAUSES THE PAINT() TO BE CALLED AGAIN. WHY??
    // canvas.clipRect(const ui.Offset(0.0, 0.0) & size); // Offset & Size => Rect
  }

  /// Implementing abstract in super.
  ///
  /// Called any time that a new CustomPaint object is created
  /// with a new instance of the custom painter delegate class.
  @override
  bool shouldRepaint(widgets.CustomPainter oldDelegate) {
    return true;
  }
}
