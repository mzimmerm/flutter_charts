import 'dart:ui' as ui show Canvas, Size;
import 'painter.dart';
import 'package:logger/logger.dart' as logger;

// import 'dart:developer' as dart_developer;

// view_maker imports

// this level or equivalent
import 'container/data_container.dart' as data_container;
import 'container/container_common.dart' as container_common_new;
import 'container/legend_container.dart' as legend_container;
import 'container/axis_container.dart' as axis_container;
import 'container/root_container.dart' as root_container;
import '../morphic/container/container_layouter_base.dart' as container_base;
// import '../morphic/container/container_edge_padding.dart';
import '../morphic/container/layouter_one_dimensional.dart';

import 'model/data_model.dart' as model;
import '../util/util_labels.dart' as util_labels;

import 'options.dart' as options;
import '../morphic/container/constraints.dart' as constraints;

import 'iterative_layout_strategy.dart' as strategy show LabelLayoutStrategy;

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
    // todo-00-last-00-refactor : DataRangeLabelInfosGenerator should be moved to the new_model.dart.
    //                         Although not purely a view-independent model, it should ONLY have this one private constructro
    //                         which creates the yLabelsGenerator and xLabelsGenerator. ONLY the class DataRangeLabelInfosGenerator
    //                         should be public, but the constructor of it private to the new_model.
    yLabelsGenerator = util_labels.DataRangeLabelInfosGenerator(
      chartViewMaker: this,
      dataModel: chartModel,
      dataDependency: model.DataDependency.dependentData,
      extendAxisToOrigin: extendAxisToOrigin,
      valueToLabel: chartOptions.yContainerOptions.valueToLabel,
      inverseTransform: chartOptions.dataContainerOptions.yInverseTransform,
      userLabels: chartModel.yUserLabels,
      isStacked: isStacked,
      isAxisPixelsAndDisplayedValuesInSameDirection: false,
    );

    // See comment in YContainer constructor
    xLabelsGenerator = util_labels.DataRangeLabelInfosGenerator(
      chartViewMaker: this,
      dataModel: chartModel,
      dataDependency: model.DataDependency.independentData,
      extendAxisToOrigin: extendAxisToOrigin,
      valueToLabel: chartOptions.xContainerOptions.valueToLabel,
      inverseTransform: chartOptions.dataContainerOptions.xInverseTransform,
      userLabels: chartModel.xUserLabels,
      isStacked: isStacked,
      isAxisPixelsAndDisplayedValuesInSameDirection: true,
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
  axis_container.XContainer makeViewForDomainAxis() {
    return axis_container.XContainer(
      chartViewMaker: this,
    );
  }

  /// Assumed made from [model.ChartModel] member [model.ChartModel.yUserLabels]
  /// or labels in [container.YContainerCL.labelInfos].
  axis_container.YContainer makeViewForRangeAxis() {
    return axis_container.YContainer(chartViewMaker: this);
  }

  axis_container.YContainer makeViewForYContainerFirst() {
    return axis_container.YContainer(
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
  /// Assumed made from [model.ChartModel.crossPointsModelPositiveList] OR [model.ChartModel.crossPointsModelNegativeList].
  ///
  /// Should be invoked inside [makeViewForDataArea], each child in the returned list
  /// should be made from one element of model [model.ChartModel.crossPointsModelPositiveList] OR
  /// the  [model.ChartModel.crossPointsModelNegativeList],
  /// which are instances of [model.CrossPointsModel].
  ///
  List<data_container.CrossPointsContainer> makeViewsForDataContainer_Bars_As_CrossPointsContainer_List(
    List<model.CrossPointsModel> crossPointsModelList,
    Align columnPointsAlign, // todo-00-last-last : rename to crossPointsAlign
      bool isReversed,
  ) {
    List<data_container.CrossPointsContainer> chartBars = [];
    // Iterate the [chartModel] across series (column wise), create one [CrossPointsContainer] (chartBar)
    //   from each cross-series, add the chartBar to a list of chartBars, which is returned.

    // todo-00-last-last : distinguish chartModel.crossPointsList and chartModel.negativeCrossPointsList
    //                    this should be one method using a param 'positive', 'negative'
    for (model.CrossPointsModel crossPointsModel in crossPointsModelList) {
      // CrossPointsContainer crossPointsContainer =
      chartBars.add(
        data_container.CrossPointsContainer(
          chartViewMaker: this,
          crossPointsModel: crossPointsModel,
          children: [makeViewForDataContainer_BarLayouter(crossPointsModel, columnPointsAlign, isReversed),],
          // Give all view columns the same weight along main axis -
          //   results in same width of each [CrossPointsContainer] as owner will be Row (main axis is horizontal)
          constraintsWeight: const container_base.ConstraintsWeight(weight: 1),
        ),
      );
    }
    return chartBars;
  }

  container_base.BoxContainer makeViewForDataContainer_BarLayouter(
    model.CrossPointsModel crossPointsModel,
    Align columnPointsAlign,
    bool isReversed,
  ) {
    var children =  makeViewsForDataContainer_CrossPointsModel_As_PointContainer_List(crossPointsModel);
    if (isReversed) {
      children = children.reversed.toList(growable: false);
    } else {
      children = children.toList(growable: false);
    }
    return container_base.Column(
      mainAxisAlign: columnPointsAlign,
      children: children,
    );
  }

  /// Generates [PointContainer] view from each [PointModel]
  /// and collects the views in a list of [PointContainer]s which is returned.
  ///
  List<data_container.PointContainer> makeViewsForDataContainer_CrossPointsModel_As_PointContainer_List(
    model.CrossPointsModel crossPointsModel,
  ) {
    List<data_container.PointContainer> pointContainerList = [];

    // Generates [PointContainer] view from each [PointModel]
    // and collect the views in a list which is returned.
    crossPointsModel.applyOnAllElements(
      (model.PointModel pointModelElm, dynamic passedList) {
        passedList.add(makeViewForDataArea_PointModel_As_PointContainer(pointModelElm));
      },
      pointContainerList,
    );

    return pointContainerList;
  }

  /// Generate view for this single leaf [PointModel] - a single [NewHBarPointContainer].
  ///
  /// Note: On the leaf, we return single element by agreement, higher ups return lists.
  data_container.PointContainer makeViewForDataArea_PointModel_As_PointContainer(
    model.PointModel pointModel,
  ) {
    return data_container.HBarPointContainer(
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
