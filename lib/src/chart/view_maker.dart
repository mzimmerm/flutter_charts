import 'dart:ui' as ui show Canvas, Size;

import 'painter.dart';
import 'package:logger/logger.dart' as logger;

// import 'dart:developer' as dart_developer;

import '../morphic/container/chart_support/chart_orientation.dart';
import '../morphic/container/container_edge_padding.dart';
import '../morphic/container/container_layouter_base.dart' as container_base;
// import '../morphic/container/container_edge_padding.dart';
import '../morphic/container/layouter_one_dimensional.dart';
import '../morphic/container/constraints.dart' as constraints;

// this level or equivalent
import 'model/data_model.dart' as model;
import 'options.dart' as options;
import 'container/data_container.dart' as data_container;
import 'container/container_common.dart' as container_common_new;
import 'container/legend_container.dart' as legend_container;
import 'container/axis_container.dart' as axis_container;
import 'container/root_container.dart' as root_container;
import 'iterative_layout_strategy.dart' as strategy show LabelLayoutStrategy;
import '../util/util_labels.dart' as util_labels;

/// Abstract base class for view makers.
///
/// A view maker is a class that makes (creates, produces, generates) a chart view hierarchy,
/// starting with a concrete [container.ChartRootContainerCL], with the help of [model.ChartModel].
///
/// This base view maker has access to [model.ChartModel]
///
/// This base view maker holds as members:
///   - the model in [chartModel]
///   - the label layout strategy in [xContainerLabelLayoutStrategy]
///   - the definition whether the chart is stacked in [isStacked].
///
/// All the members above are needed to construct the view container hierarchy root, the [chartRootContainer],
/// which is also a late member after it is constructed.
///
/// [ChartViewMaker] is not a [BoxContainer], it provides a 'link' between [FlutterChartPainter]
/// which [paint] method is called by the Flutter framework, and the root of the chart container hierarchy,
/// the [chartRootContainer].
///
/// Core methods of [ChartViewMaker] are
///   - [chartRootContainerCreateBuildLayoutPaint], which should be called in [FlutterChartPainter.paint];
///     this method creates, builds, lays out, and paints
///     the root of the chart container hierarchy, the [chartRootContainer].
///   - abstract [makeViewRoot]; extensions of [ChartViewMaker] (for example, [LineChartViewMaker]) should create
///     and return an instance of the concrete [chartRootContainer] (for example [LineChartRootContainer]).
///   - [container.ChartBehavior.extendAxisToOrigin] is on this Maker,
///     as it controls how views behave (although does not control view making).
abstract class ChartViewMaker extends Object with container_common_new.ChartBehavior {
  ChartViewMaker({
    required this.chartModel,
    required this.chartSeriesOrientation,
    this.isStacked = false,
    this.xContainerLabelLayoutStrategy,
  }) {
    logger.Logger().d('Constructing ChartViewMaker');
    // Copy options also on this [ViewMaker] from Model.options
    chartOptions = chartModel.chartOptions;

    // Create [yLabelsGenerator] which depends on both ChartModel and ChartRootContainer.
    // We can construct the generator here in [ChartViewMaker] constructor or later
    // (e.g. [ChartRootContainer], [YContainer]). But here, in [ChartViewMaker] is the first time we can
    // create the [xLabelsGenerator] and [xLabelsGenerator] instance of [DataRangeLabelInfosGenerator], so do that.
    // todo-0111-refactor : DataRangeLabelInfosGenerator should be moved to the new_model.dart.
    //                         Although not purely a view-independent model, it should ONLY have this one private constructro
    //                         which creates the yLabelsGenerator and xLabelsGenerator. ONLY the class DataRangeLabelInfosGenerator
    //                         should be public, but the constructor of it private to the new_model.
    yLabelsGenerator = util_labels.DataRangeLabelInfosGenerator(
      chartViewMaker: this,
      dataModel: chartModel,
      dataDependency: model.DataDependency.outputData,
      extendAxisToOrigin: extendAxisToOrigin,
      valueToLabel: chartOptions.yContainerOptions.valueToLabel,
      inverseTransform: chartOptions.dataContainerOptions.yInverseTransform,
      userLabels: chartModel.yUserLabels,
      isStacked: isStacked,
      isPixelsAndValuesSameDirection: false,
    );

    // See comment in YContainer constructor
    xLabelsGenerator = util_labels.DataRangeLabelInfosGenerator(
      chartViewMaker: this,
      dataModel: chartModel,
      dataDependency: model.DataDependency.inputData,
      extendAxisToOrigin: extendAxisToOrigin,
      valueToLabel: chartOptions.xContainerOptions.valueToLabel,
      inverseTransform: chartOptions.dataContainerOptions.xInverseTransform,
      userLabels: chartModel.xUserLabels,
      isStacked: isStacked,
      isPixelsAndValuesSameDirection: true,
    );
  }

  /// ChartData to hold on before member [chartRootContainer] is created late.
  ///
  /// After [chartRootContainer] is created and set, This [ChartModel] type member [chartModel]
  /// should be placed on the member [chartRootContainer.chartModel].

  /// Model for this chart. Created before chart, set in concrete [ChartViewMaker] in constructor.
  final model.ChartModel chartModel;

  /// Options set from model options in [FlutterChartPainter] constructor from [FlutterChartPainter.chartViewMaker]'s
  /// [ChartViewMaker.chartModel]'s [ChartOptions].
  late final options.ChartOptions chartOptions;

  final ChartSeriesOrientation chartSeriesOrientation;

  final bool isStacked;

  /// The root container (view) is created by this maker [ChartViewMaker]
  /// on every [FlutterChartPainter] paint and repaint.
  ///
  /// While the owner maker survives repaint,
  /// it's member, this [chartRootContainer] is recreated on each repaint in
  /// the following code in [FlutterChartPainter.paint]:
  ///
  /// ```dart
  ///         chartViewMaker.chartRootContainerCreateBuildLayoutPaint(canvas, size);
  /// ```
  ///
  /// Because it can be recreated and re-set in [paint], it is not final;
  ///   it's children, [legendContainer], etc are also not final.
  late root_container.ChartRootContainer chartRootContainer;

  /// The generator and holder of labels in the form of [LabelInfos],
  /// as well as the range of the axis values.
  ///
  /// The [labelsGenerator]'s interval [DataRangeLabelInfosGenerator.dataRange]
  /// is the data range corresponding to the Y axis pixel range kept in [axisPixelsRange].
  ///
  /// Important note: This should NOT be part of model, as different views would have a different instance of it.
  ///                 Reason: Different views may have different labels, esp. on the Y axis.
  late util_labels.DataRangeLabelInfosGenerator yLabelsGenerator;

  late util_labels.DataRangeLabelInfosGenerator xLabelsGenerator;

  /// Layout strategy, necessary to create the concrete view [ChartRootContainer].
  strategy.LabelLayoutStrategy? xContainerLabelLayoutStrategy;

  /// Keep track of first run. As this [ChartViewMaker] survives re-paint (but not first paint),
  /// this can be used to initialize 'late final' members on first paint.
  bool _isFirst = true;

  void chartRootContainerCreateBuildLayoutPaint(ui.Canvas canvas, ui.Size size) {
    // Create the concrete [ChartRootContainer] for this concrete [ChartViewMaker].
    // After this invocation, the created root container is populated with children
    // XContainer, YContainer, DataContainer and LegendContainer. Their children are partly populated,
    // depending on the concrete container. For example YContainer is populated with DataRangeLabelInfosGenerator.

    String isFirstStr = _debugPrintBegin();

    // Create the view [chartRootContainer] and set on member on this maker [ChartViewMaker].
    // This happens even on re-paint, so can be done multiple times after state changes in the + button.
    chartRootContainer = makeViewRoot(chartViewMaker: this); // also link from this ViewMaker to ChartRootContainer.

    // Only set `chartModel.chartViewMaker = this` ONCE. Reason: member chartModel is created ONCE, same as this ANCHOR.
    // To have chartModel late final, we have to keep track to only initialize chartModel.chartViewMaker = this on first run.
    if (_isFirst) {
      _isFirst = false;
    }

    // e.g. set background: canvas.drawPaint(ui.Paint()..color = material.Colors.green);

    // Apply constraints on root. Layout size and constraint size of the [ChartRootContainer] are the same, and
    // are equal to the full 'size' passed here from the framework via [FlutterChartPainter.paint].
    // This passed 'size' is guaranteed to be the same area on which the painter will paint.

    chartRootContainer.applyParentConstraints(
      chartRootContainer,
      constraints.BoxContainerConstraints.insideBox(
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

  /// Should create a concrete instance of [ChartRootContainer], bind it to member [chartRootContainer],
  /// and return it.
  ///
  /// Generally, the created [ChartRootContainer]'s immediate children should also be created and added to it,
  /// but deeper children may or may not be created.
  ///
  /// In the default implementations, the [chartRootContainer]'s children created are
  /// [ChartRootContainer.legendContainer],  [ChartRootContainer.yContainer],
  ///  [ChartRootContainer.xContainer], and  [chartRootContainer.chartModelContainer].
  ///
  /// If an extension uses an implementation that does not adhere to the above
  /// description, the [ChartRootContainer.layout] should be overridden.
  ///
  /// Important notes:
  ///   - This controller (ViewMaker) can access both on ChartRootContainer and ChartModel.
  root_container.ChartRootContainer makeViewRoot({
    required covariant ChartViewMaker chartViewMaker,
  });

  // ##### Methods which create views (containers) for individual chart areas

  /// Assumed made from [model.ChartModel] member [model.ChartModel.xUserLabels]
  /// or [container.YContainerCL.labelInfos].

  /* todo-00-last-done
  axis_container.XContainer makeViewForDomainAxis() {
    return axis_container.XContainer(
      chartViewMaker: this,
    );
  }
  */
  axis_container.TransposingAxisContainer makeViewForDomainAxis() {
    return axis_container.TransposingAxisContainer.Horizontal(
      chartSeriesOrientation: chartSeriesOrientation,
      chartViewMaker: this,
    );
  }

  /// Assumed made from [model.ChartModel] member [model.ChartModel.yUserLabels]
  /// or labels in [container.YContainerCL.labelInfos].
  /*  todo-00-last-done
  axis_container.YContainer makeViewForRangeAxis() {
    return axis_container.YContainer(chartViewMaker: this);
  }
  */
  axis_container.TransposingAxisContainer makeViewForRangeAxis() {
    return axis_container.TransposingAxisContainer.Vertical(
      chartSeriesOrientation: chartSeriesOrientation,
      chartViewMaker: this,
    );
  }

  /* todo-00-last-done
  axis_container.YContainer makeViewForYContainerFirst() {
    return axis_container.YContainer(
      chartViewMaker: this,
    );
  }
  */
  axis_container.TransposingAxisContainer makeViewForYContainerFirst() {
    return axis_container.TransposingAxisContainer.Vertical(
      chartSeriesOrientation: chartSeriesOrientation,
      chartViewMaker: this,
    );
  }

  /// Assumed made from [model.ChartModel] member [model.ChartModel.byRowLegends].
  legend_container.LegendContainer makeViewForLegendContainer() {
    return legend_container.LegendContainer(
      chartViewMaker: this,
    );
  }

  /// Abstract method constructs and returns the concrete [DataContainer] instance,
  /// for the chart type (line, bar) determined by this concrete [ChartRootContainer].
  /// Assumed made from [model.ChartModel.crossPointsModelPositiveList], presents all data in the data area.
  data_container.DataContainer makeViewForDataContainer();

  /// Makes a view showing all bars of data points.
  ///
  /// Assumed to be passed the [model.ChartModel.crossPointsModelPositiveList]
  /// OR [model.ChartModel.crossPointsModelNegativeList].
  ///
  /// Each child in the returned list should be made from one element of the model
  /// [model.ChartModel.crossPointsModelPositiveList] OR the [model.ChartModel.crossPointsModelNegativeList] -
  /// both are instances of [model.CrossPointsModel].
  ///
  List<data_container.CrossPointsContainer> makeViewsForDataContainer_Bars({
    required List<model.CrossPointsModel> crossPointsModelList,
    required Align barsContainerMainAxisAlign,
    required bool isPointsReversed,
  }) {
    List<data_container.CrossPointsContainer> chartBars = [];
    // Iterates the [chartModel] cross-series (column wise) [crossPointsModel],
    //   creates a [CrossPointsContainer] (chartBar) from each cross-series, adds the chartBar
    //   to the [chartBars] list, which is returned.

    for (model.CrossPointsModel crossPointsModel in crossPointsModelList) {
      chartBars.add(
        makeViewForDataContainer_Bar(
          crossPointsModel: crossPointsModel,
          barsContainerMainAxisAlign: barsContainerMainAxisAlign,
          isPointsReversed: isPointsReversed,
        ),
      );
    }
    return chartBars;
  }

  data_container.CrossPointsContainer makeViewForDataContainer_Bar({
    required model.CrossPointsModel crossPointsModel,
    required Align barsContainerMainAxisAlign,
    required bool isPointsReversed,
    }) {
    return data_container.CrossPointsContainer(
        chartViewMaker: this,
        crossPointsModel: crossPointsModel,
        children: [
          makeViewForDataContainer_BarLayouter(
              crossPointsModel: crossPointsModel,
              barsContainerMainAxisAlign: barsContainerMainAxisAlign,
              isPointsReversed: isPointsReversed),
        ],
        // Give all view columns the same weight along main axis -
        //   results in same width of each [CrossPointsContainer] as owner will be Row (main axis is horizontal)
        constraintsWeight: const container_base.ConstraintsWeight(weight: 1),
      );
  }

  container_base.BoxContainer makeViewForDataContainer_BarLayouter({
    required model.CrossPointsModel crossPointsModel,
    required Align barsContainerMainAxisAlign,
    required bool isPointsReversed,
  }) {
    EdgePadding pointRectSidePad;
    switch(chartSeriesOrientation) {
      case ChartSeriesOrientation.column:
        pointRectSidePad = const EdgePadding.withSides(start: 6.0, end: 6.0);
        break;
      case ChartSeriesOrientation.row:
        pointRectSidePad = const EdgePadding.withSides(top: 6.0, bottom: 6.0);
        break;
    }
    // Get point containers, and wrap each in a Padder, narrowing the bars
    var pointContainers = makeViewForDataContainer_CrossPointsModels(
      crossPointsModel: crossPointsModel,
    ).map((pointContainer) =>
        container_base.Padder(
          // todo-01 : Is there an option for sizes? Try to use Aligner instead of Padder, and use gridStepWidthPortionUsedByAtomicPointPresenter to express gap in terms of percentage
          edgePadding: pointRectSidePad,
          child: pointContainer,)
    ).toList();

    if (isPointsReversed) {
      pointContainers = pointContainers.reversed.toList(growable: false);
    } else {
      pointContainers = pointContainers.toList(growable: false);
    }

    return _buildLevel3PointsBarAsRowOrColumn(
      chartSeriesOrientation: chartSeriesOrientation,
      barsContainerMainAxisAlign: barsContainerMainAxisAlign,
      pointContainers: pointContainers,
    );
  }

  // todo-010 :
  //           - WHY IS THIS IN VIEW MAKER, AND SIMILAR CODE also IN data_container.dart?
  //              - this indicates a design issue. Can the row/column switch be ONLY in Container extension OR ViewMaker but NOT IN BOTH?
  //
  container_base.RollingBoxLayouter _buildLevel3PointsBarAsRowOrColumn({
    required ChartSeriesOrientation chartSeriesOrientation,
    required Align barsContainerMainAxisAlign,
    required List<container_base.Padder> pointContainers,
  }) {
    switch (chartSeriesOrientation) {
      case ChartSeriesOrientation.column:
        return container_base.Column(
          // Positive: Both Align.start and end work, . Negative: only Align.start work in column
          mainAxisAlign: barsContainerMainAxisAlign,
          children: pointContainers,
        );
      case ChartSeriesOrientation.row:
        return container_base.Row(
          mainAxisAlign: barsContainerMainAxisAlign, // otherEndAlign(barsContainerMainAxisAlign) already called
          children: pointContainers,
        );
    }
  }
  
  /// Generates [PointContainer] view from each [PointModel]
  /// and collects the views in a list of [PointContainer]s which is returned.
  ///
  List<data_container.PointContainer> makeViewForDataContainer_CrossPointsModels({
    required model.CrossPointsModel crossPointsModel,
  }) {
    List<data_container.PointContainer> pointContainerList = [];

    // Generates [PointContainer] view from each [PointModel]
    // and collect the views in a list which is returned.
    crossPointsModel.applyOnAllElements(
      (model.PointModel pointModelElm, dynamic passedList) {
        passedList.add(makeViewForDataArea_PointModel(
          pointModel: pointModelElm,
        ));
      },
      pointContainerList,
    );

    return pointContainerList;
  }

  /// Generate view for this single leaf [PointModel] - a single [NewVBarPointContainer].
  ///
  /// Note: On the leaf, we return single element by agreement, higher ups return lists.
  data_container.PointContainer makeViewForDataArea_PointModel({
    required model.PointModel pointModel,
  }) {
    return data_container.BarPointContainer(
      pointModel: pointModel,
      chartViewMaker: this,
    );
  }

  String _debugPrintBegin() {
    String isFirstStr = _isFirst ? '=== IS FIRST ===' : '=== IS SECOND ===';

    /* KEEP
    dart_developer.log(
        '    ========== In $runtimeType.chartRootContainerCreateBuildLayoutPaint BEGIN BEGIN BEGIN, $isFirstStr',
        name: 'charts.debug.log');
    */

    return isFirstStr;
  }

  void _debugPrintEnd(String isFirstStr) {
    /* KEEP
    dart_developer.log(
        '    ========== In $runtimeType.chartRootContainerCreateBuildLayoutPaint END END END, $isFirstStr',
        name: 'charts.debug.log');
    */
  }
}
