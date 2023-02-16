import 'dart:ui' as ui;
import 'dart:developer' as dart_developer;
import 'package:flutter/widgets.dart' as widgets; // note: external package
// import 'package:logger/logger.dart' as logger;

// this level or equivalent
import 'container.dart' as containers;
import 'view_maker.dart' as view_maker;


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
  /// The maker (generator) of the root of the chart view (container) hierarchy, the [ChartRootContainer].
  ///
  /// This object is created once per chart, on the FIRST invocation OF  [FlutterChartPainter.paint] ,
  /// BUT it is NOT recreated on each repaint - the follow up repaint [FlutterChartPainter.paint] invocation.
  /// That behavior is in contrast to concrete view, the [containers.ChartRootContainer], which is created anew on every
  /// [FlutterChartPainter.paint] invocation, including the repaint invocation
  /// .
  view_maker.ChartViewMaker chartViewMaker;

  /// Keep track of re-paints
  bool _isFirstPaint = true;

  /// Constructs this chart painter, giving it [chartViewMaker], which
  /// holds on [chartData] and other members needed for
  /// the late creation of [containers.ChartViewMaker.chartViewMakerOnChartArea].

  FlutterChartPainter({
    required this.chartViewMaker,
  }) {
    // Copy options also on ViewMaker from Model.options
    chartViewMaker.chartOptions = chartViewMaker.chartData.chartOptions;
    print('Constructing $runtimeType');
  }


  /// Paints the chart on the passed [canvas], limited to the [size] area.
  ///
  /// This [paint] method is the core method call of painting the chart,
  /// in the sense it is guaranteed to be called by the Flutter framework
  /// (see class comment), hence it provides a "hook" into the chart
  /// being able to paint and draw itself.
  ///
  /// A core role of this [paint] method is to call [chartViewMaker.chartRootContainerCreateBuildLayoutPaint],
  /// which creates, builds, lays out and paints the concrete [containers.ChartRootContainer].
  ///
  /// The [chartViewMakerOnChartArea] created in the [chartViewMaker.chartRootContainerCreateBuildLayoutPaint]
  /// needs the [size] to provide top size constraints for it's layout.
  @override
  void paint(ui.Canvas canvas, ui.Size size) {
    _debugPrintBegin(size);

    // Applications should handle size=(0,0) which may happen
    //   - just return and wait for re-call with size > (0,0).
    if (size == ui.Size.zero) {
      String msg = ' ### $runtimeType. PAINT: passed size 0 to this CustomPainter! Nothing painted here, RETURNING.';
      print(msg);
      dart_developer.log(msg, name: 'charts.debug.log');
      return;
    }

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

    chartViewMaker.chartRootContainerCreateBuildLayoutPaint(canvas, size);

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
    dart_developer.log(' ###### $runtimeType.shouldRepaint being CALLED', name: 'charts.debug.log');
    return true;
  }
}
