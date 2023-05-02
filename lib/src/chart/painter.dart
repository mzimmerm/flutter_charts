import 'dart:ui' as ui;
import 'dart:developer' as dart_developer;
import 'package:flutter/widgets.dart' as widgets; // note: external package
import 'package:logger/logger.dart' as logger;

// this level or equivalent
import 'chart.dart';

// For comments
import '../chart/view_maker.dart';


/// A not-extended implementation of the chart painter; it's core role is
/// to create, layout, and paint the [FlutterChart] instances (extensions of [CustomPaint]).
///
/// As this class extends [widgets.CustomPainter], the Flutter framework
/// ensures it's [paint] method is invoked at some point after the widget
/// ([BarChart], [LineChart]) was constructed.
/// The construction is performed in main, when the [widgets.runApp] function is being executed.
///
/// Invocation of [paint] of this class does the core of creating, layout, and painting the chart, in
///   ```dart
///   chart.chartViewMaker.chartRootContainerCreateBuildLayoutPaint(canvas, size);
///   ```
/// An extension of flutter's [CustomPainter] which provides the
/// painting of the chart leaf elements - lines, circles, bars - on the [ui.Canvas]
/// passed to [paint].
class FlutterChartPainter extends widgets.CustomPainter {

  /// Keep track of re-paints
  bool _isFirstPaint = true;

  /// Constructs this chart painter.
  FlutterChartPainter() {
    logger.Logger().d('Constructing $runtimeType');
  }

  /// The [FlutterChart] instance (extension of [CustomPaint]) this painter is painting on.
  ///
  /// It will be late initialized in the concrete [FlutterChart] constructor when
  /// this [FlutterChartPainter] is passed to the [FlutterChart] constructor as
  ///    ```dart
  ///      flutterChartPainter.flutterChart = this;
  ///    ```
  /// Then, when this [FlutterChartPainter.paint] is invoked, the [chart] member [FlutterChart.chartViewMaker]
  /// is used to create, layout and paint the chart using
  ///   ```dart
  ///         chart.chartViewMaker.chartRootContainerCreateBuildLayoutPaint(canvas, size);
  ///   ```
  late final FlutterChart chart;

  /// Paints the chart on the passed [canvas], limited to the [size] area.
  ///
  /// This [paint] method is the core that paints the chart,
  /// in the sense it is guaranteed to be called by the Flutter framework
  /// (see class comment), hence it provides a "hook" into the chart
  /// being able to paint and draw itself.
  ///
  /// A core role of this [paint] method is to call [ChartViewMaker.chartRootContainerCreateBuildLayoutPaint],
  /// which creates, builds, lays out and paints the concrete [containers.ChartRootContainer].
  ///
  /// The [chartViewMaker] created in the [ChartViewMaker.chartRootContainerCreateBuildLayoutPaint]
  /// needs the [size] to provide top size constraints for it's layout.
  @override
  void paint(ui.Canvas canvas, ui.Size size) {
    _debugPrintBegin(size);

    // Applications should handle size=(0,0) which may happen
    //   - just return and wait for re-call with size > (0,0).
    if (size == ui.Size.zero) {
      String msg = ' ### Log.Info: $runtimeType. PAINT: passed size 0 to this CustomPainter! '
          'Nothing painted here, RETURNING.';
      print(msg);
      dart_developer.log(msg, name: 'charts.debug.log');
      return;
    }
    print(' ### Log.Info: $runtimeType. FLUTTER_CHART_PAINTER.PAINT: passed size $size');

    // At this point:
    //   - [ViewMaker] has access to [Model] as it was created with [Model] argument.
    //   - On Chart creation, [Model] instance has access to [ChartOptions] directly,
    //     During [ViewMaker] construction, we copy from [Model.ChartOptions] -> [ViewMaker.ChartOptions]
    //   - So here, [Options] are on [Model] and [ViewMaker].
    //   - In the invocation below, when [ViewMaker] creates the [ChartRootContainer] aka View, [ViewMaker]
    //     will also copy [Options] to the [View], so View has access to Options as well.
    if (_isFirstPaint) {
      _isFirstPaint = false;
    }

    chart.chartViewMaker.chartRootContainerCreateBuildLayoutPaint(canvas, size);

    _debugPrintEnd();
  }

  void _debugPrintBegin(ui.Size size) {
    /* KEEP
    var log = logger.Logger();
    log.d('in debug log');

    dart_developer.log(
        '=================== $runtimeType.PAINT BEGIN BEGIN BEGIN at ${DateTime.now()} =================== ',
        name: 'charts.debug.log'
    );
    if (_isFirstPaint) {
      dart_developer.log('    invoked === FIRST TIME === with size=$size', name: 'charts.debug.log');
    } else {
      dart_developer.log('    invoked === SECOND TIME === with size=$size', name: 'charts.debug.log');
    }
    */
  }

  void _debugPrintEnd() {
    /* KEEP
    // clip canvas to size - this does nothing
    // canvas.clipRect  causes the paint() to be called again. why??
    // canvas.clipRect(ui.Offset.zero & size);

    dart_developer.log('=================== $runtimeType.PAINT END END END at ${DateTime.now()} =================== ',
        name: 'charts.debug.log');
    dart_developer.log('', name: 'charts.debug.log');
    dart_developer.log('', name: 'charts.debug.log');
    */
  }

  /// Implementing abstract in super.
  ///
  /// Called any time that a new CustomPaint object is created
  /// with a new instance of the custom painter delegate class.
  @override
  bool shouldRepaint(widgets.CustomPainter oldDelegate) {
    // dart_developer.log(' ###### $runtimeType.shouldRepaint being CALLED', name: 'charts.debug.log');
    return true;
  }
}
