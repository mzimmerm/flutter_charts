import '../chart/container.dart';
import '../chart/model/new_data_model.dart';

import '../chart/options.dart';
import '../morphic/rendering/constraints.dart';

import '../chart/iterative_layout_strategy.dart' as strategy show LabelLayoutStrategy;

import 'dart:ui' as ui show Canvas, Size;

import 'dart:developer' as dart_developer;

/// Base class for classes that hold [chartData], [xContainerLabelLayoutStrategy], [isStacked],
/// members needed for late creation of the root of the chart container hierarchy, the [chartRootContainer].
///
/// [ChartViewMaker] is not a [BoxContainer], it provides a 'link' between [FlutterChartPainter] which [paint] method
/// is called by the Flutter framework, and the root of the chart container hierarchy, the [chartRootContainer].
///
/// Core methods of [ChartViewMaker] are
///   - [chartRootContainerCreateBuildLayoutPaint], which should be called in [FlutterChartPainter.paint];
///     this method creates, builds, lays out, and paints
///     the root of the chart container hierarchy, the [chartRootContainer].
///   - abstract [createRootContainer]; extensions of [ChartViewMaker] (for example, [LineChartViewMaker]) should create
///     and return an instance of the concrete [chartRootContainer] (for example [LineChartRootContainer]).
abstract class ChartViewMaker {

  ChartViewMaker({
    required this.chartData,
    this.isStacked = false,
    this.xContainerLabelLayoutStrategy,
  }) {
    print('Constructing ChartViewMaker');
  }

  /// ChartData to hold on before member [chartRootContainer] is created late.
  ///
  /// After [chartRootContainer] is created and set, This [NewModel] type member [chartData]
  /// should be placed on the member [chartRootContainer.chartViewMaker.chartData].
  // todo-00 : document those, and try make all of them late final.

  NewModel chartData;
  strategy.LabelLayoutStrategy? xContainerLabelLayoutStrategy;
  bool isStacked = false;
  late ChartRootContainer chartRootContainer;
  late final ChartOptions chartOptions;
  // Keep track of first run.
  bool _isFirst = true;

  /// Extensions of this [ChartViewMaker] (for example, [LineChartViewMaker]) should
  /// create and return an instance of the concrete [chartRootContainer]
  /// (for example [LineChartRootContainer]), populated with it's children, but not
  /// children's children. The children's children hierarchy is assumed to
  /// be created in [chartRootContainerCreateBuildLayoutPaint] during
  /// it's call to [ChartRootContainer.layout].
  ///
  /// In the default implementations, the [chartRootContainer]'s children created are
  /// [ChartRootContainer.legendContainer],  [ChartRootContainer.yContainer],
  ///  [ChartRootContainer.xContainer], and  [chartRootContainer.chartViewMaker.chartDataContainer].
  ///
  /// If an extension uses an implementation that does not adhere to the above
  /// description, the [ChartRootContainer.layout] should be overridden.
  ///
  /// Important notes:
  ///   - This controller (ViewMaker) can access both on ChartRootContainer and NewModel.
  //    - NewModel has ChartOptions
  ChartRootContainer createRootContainer({required ChartViewMaker chartViewMaker});

  void chartRootContainerCreateBuildLayoutPaint(ui.Canvas canvas, ui.Size size) {
    // Create the concrete [ChartRootContainer] for this concrete [ChartViewMaker].
    // After this invocation, the created root container is populated with children
    // XContainer, YContainer, DataContainer and LegendContainer. Their children are partly populated,
    // depending on the concrete container. For example YContainer is populated with DataRangeLabelsGenerator.

    String isFirstStr = _debugPrintBegin();

    chartRootContainer = createRootContainer(chartViewMaker: this); // also link from this ViewMaker to ChartRootContainer.

    // Only set `chartData.chartViewMaker = this` ONCE. Reason: member chartData is created ONCE, same as this ANCHOR.
    // To have chartData late final, we have to keep track to only initialize chartData.chartViewMaker = this on first run.
    if (_isFirst) {
      _isFirst = false;
    }

    // e.g. set background: canvas.drawPaint(ui.Paint()..color = material.Colors.green);

    // Apply constraints on root. Layout size and constraint size of the [ChartRootContainer] are the same, and
    // are equal to the full 'size' passed here from the framework via [FlutterChartPainter.paint].
    // This passed 'size' is guaranteed to be the same area on which the painter will paint.

    chartRootContainer.applyParentConstraints(
      chartRootContainer,
      BoxContainerConstraints.insideBox(
        size: ui.Size(
          size.width,
          size.height,
        ),
      ),
    );

    chartRootContainer.layout();

    chartRootContainer.paint(canvas);

    _debugPrintEnd(isFirstStr);
  }

  String _debugPrintBegin() {
    String isFirstStr = _isFirst ? '=== IS FIRST ===' : '=== IS SECOND ===';

    /*
    dart_developer.log(
        '    ========== In $runtimeType.chartRootContainerCreateBuildLayoutPaint BEGIN BEGIN BEGIN, $isFirstStr',
        name: 'charts.debug.log');
    */

    return isFirstStr;
  }

  void _debugPrintEnd(String isFirstStr) {
    /*
    dart_developer.log(
        '    ========== In $runtimeType.chartRootContainerCreateBuildLayoutPaint END END END, $isFirstStr',
        name: 'charts.debug.log');
    */
  }
}
