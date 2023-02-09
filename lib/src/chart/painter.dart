import 'dart:ui' as ui;
import 'package:flutter/widgets.dart' as widgets; // note: external package

import 'container.dart' as containers;
import 'bar/chart.dart';
import 'line/chart.dart';

/// Base class of the chart painters; it's core role is to paint the
/// charts (the extensions of [CustomPaint]).
///
/// As this class extends [widgets.CustomPainter], the Flutter framework
/// ensures it's [paint] method is called at some point during the chart widget
/// ([VerticalBarChart], [LineChart], etc, the extensions of [widgets.CustomPaint])
///  is being build.
///
/// This class does the core of painting the chart, in it's core method [paint].
///
/// An extension of flutter's [CustomPainter] which provides the
/// painting of the chart leaf elements - lines, circles, bars - on Canvas.
abstract class FlutterChartPainter extends widgets.CustomPainter {
  /// The anchor holder of the root of the chart container hierarchy, the [chartRootContainer].
  ///
  /// This object is created once per chart, and is NOT recreated on each [FlutterChartPainter.paint] invocation.
  /// That behavior is in contrast to concrete [containers.ChartRootContainer], which is created anew on every
  /// [FlutterChartPainter.paint] invocation.
  containers.ChartAnchor chartAnchor;

  /// Keep track of re-paints
  bool _isFirstPaint = true;

  /// Constructs this chart painter, giving it [chartAnchor], which
  /// holds on [chartData] and other members needed for
  /// the late creation of [containers.ChartAnchor.chartRootContainer].

  FlutterChartPainter({
    required this.chartAnchor,
  }) {
    print('Constructing $runtimeType');
  }


  /// Paints the chart on the passed [canvas], limited to the [size] area.
  ///
  /// This [paint] method is the core method call of painting the chart,
  /// in the sense it is guaranteed to be called by the Flutter framework
  /// (see class comment), hence it provides a "hook" into the chart
  /// being able to paint and draw itself.
  ///
  /// A core role of this [paint] method is to call [chartAnchor.chartRootContainerCreateBuildLayoutPaint],
  /// which creates, builds, lays out and paints the concrete [containers.ChartRootContainer].
  ///
  /// The [chartRootContainer] created in the [chartAnchor.chartRootContainerCreateBuildLayoutPaint]
  /// needs the [size] to provide top size constraints for it's layout.
  @override
  void paint(ui.Canvas canvas, ui.Size size) {
    _debugPrintBegin(size);
    // Applications should handle size=(0,0) which may happen
    //   - just return and wait for re-call with size > (0,0).
    if (size == ui.Size.zero) {
      print(' ### $runtimeType.PAINT: passed size 0 to this CustomPainter! Nothing can be painted here, RETURNING.');
      return;
    }

    chartAnchor.chartRootContainerCreateBuildLayoutPaint(canvas, size);

    _debugPrintEnd();
  }

  void _debugPrintBegin(ui.Size size) {
    print('=================== $runtimeType.PAINT BEGIN BEGIN BEGIN at ${DateTime.now()} =================== ');
    if (_isFirstPaint) {
      print('    invoked === FIRST TIME === with size=$size');
      _isFirstPaint = false;
    } else {
      print('    invoked === SECOND TIME === with size=$size');
    }
  }

  void _debugPrintEnd() {
    // clip canvas to size - this does nothing
    // canvas.clipRect  causes the paint() to be called again. why??
    // canvas.clipRect(ui.Offset.zero & size);
    print('=================== $runtimeType.PAINT END END END at ${DateTime.now()} =================== ');
    print('');
    print('');
  }

  /// Implementing abstract in super.
  ///
  /// Called any time that a new CustomPaint object is created
  /// with a new instance of the custom painter delegate class.
  @override
  bool shouldRepaint(widgets.CustomPainter oldDelegate) {
    print(' ###### $runtimeType.shouldRepaint being CALLED');
    return true;
  }
}
