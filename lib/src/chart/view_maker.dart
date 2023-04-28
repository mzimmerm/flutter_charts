import 'dart:ui' as ui show Canvas, Size;

import 'painter.dart';
import 'package:logger/logger.dart' as logger;

// import 'dart:developer' as dart_developer;

import '../morphic/container/chart_support/chart_style.dart';
import '../morphic/container/morphic_dart_enums.dart';
import '../morphic/container/container_edge_padding.dart';
import '../morphic/container/container_layouter_base.dart' as container_base;
import '../morphic/container/layouter_one_dimensional.dart';
import '../morphic/container/constraints.dart' as constraints;

// this level or equivalent
import 'model/data_model.dart' as model;
import 'options.dart' as options;
import 'container/data_container.dart' as data_container;
import 'container/container_common.dart' as container_common;
import 'container/legend_container.dart' as legend_container;
import 'container/axis_container.dart' as axis_container;
import 'container/root_container.dart' as root_container;
import 'iterative_layout_strategy.dart' as strategy show LabelLayoutStrategy;
import 'model/label_model.dart' as util_labels;

/// Type definition for closures returning a function from model [model.PointModel] 
/// to container [data_container.PointContainer].
typedef ClsPointToNullableContainer = data_container.PointContainer? Function (model.PointModel);

/// Abstract base class for view makers.
///
/// A view maker is a class that makes (creates, produces, generates) a chart view hierarchy,
/// starting with a concrete [container.ChartRootContainerCL], with the help of [model.ChartModel].
///
/// This base view maker has access to [model.ChartModel]
///
/// This base view maker holds as members:
///   - the model in [chartModel]. It's member [model.ChartModel.chartOptions] provides access to [options.ChartOptions]
///   - the chart orientation in [chartOrientation]
///   - the definition whether the chart is stacked in [chartStacking].
///   - the label layout strategy in [inputLabelLayoutStrategy]
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
abstract class ChartViewMaker extends Object with container_common.ChartBehavior {
  ChartViewMaker({
    required this.chartModel,
    required this.chartOrientation,
    required this.chartStacking,
    this.inputLabelLayoutStrategy,
  }) {
    logger.Logger().d('Constructing ChartViewMaker');
    // Copy options also on this [ViewMaker] from Model.options
    chartOptions = chartModel.chartOptions;

    // Create [outputLabelsGenerator] which depends on both ChartModel and ChartRootContainer.
    // We can construct the generator here in [ChartViewMaker] constructor or later
    // (e.g. [ChartRootContainer], [VerticalAxisContainer]). But here, in [ChartViewMaker] is the first time we can
    // create the [inputLabelsGenerator] and [inputLabelsGenerator] instance of [DataRangeLabelInfosGenerator], so do that.
    outputLabelsGenerator = util_labels.DataRangeLabelInfosGenerator(
      chartOrientation: chartOrientation,
      chartStacking: chartStacking,
      dataModel: chartModel,
      dataDependency: DataDependency.outputData,
      extendAxisToOrigin: extendAxisToOrigin,
      valueToLabel: options.outputValueToLabel,
      inverseTransform: chartOptions.dataContainerOptions.yInverseTransform,
      userLabels: chartModel.outputUserLabels,
    );

    // See comment in VerticalAxisContainer constructor
    inputLabelsGenerator = util_labels.DataRangeLabelInfosGenerator(
      chartOrientation: chartOrientation,
      chartStacking: chartStacking,
      dataModel: chartModel,
      dataDependency: DataDependency.inputData,
      extendAxisToOrigin: extendAxisToOrigin,
      valueToLabel: options.inputValueToLabel,
      inverseTransform: chartOptions.dataContainerOptions.xInverseTransform,
      userLabels: chartModel.inputUserLabels,
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

  final ChartOrientation chartOrientation;

  final ChartStacking chartStacking;

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
  late util_labels.DataRangeLabelInfosGenerator outputLabelsGenerator;

  late util_labels.DataRangeLabelInfosGenerator inputLabelsGenerator;

  /// Layout strategy, necessary to create the concrete view [ChartRootContainer].
  strategy.LabelLayoutStrategy? inputLabelLayoutStrategy;

  /// Keep track of first run. As this [ChartViewMaker] survives re-paint (but not first paint),
  /// this can be used to initialize 'late final' members on first paint.
  bool _isFirst = true;

  void chartRootContainerCreateBuildLayoutPaint(ui.Canvas canvas, ui.Size size) {
    // Create the concrete [ChartRootContainer] for this concrete [ChartViewMaker].
    // After this invocation, the created root container is populated with children
    // HorizontalAxisContainer, VerticalAxisContainer, DataContainer and LegendContainer. Their children are partly populated,
    // depending on the concrete container. For example VerticalAxisContainer is populated with DataRangeLabelInfosGenerator.

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
  /// [ChartRootContainer.legendContainer],  [ChartRootContainer.verticalAxisContainer],
  ///  [ChartRootContainer.horizontalAxisContainer], and  [chartRootContainer.chartModelContainer].
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

  /// Assumed made from [model.ChartModel] member [model.ChartModel.inputUserLabels]
  /// or [container.VerticalAxisContainerCL.labelInfos].

  axis_container.TransposingAxisContainer makeViewForHorizontalAxis() {
    return axis_container.TransposingAxisContainer.Horizontal(
      chartViewMaker: this,
    );
  }

  /// Assumed made from [model.ChartModel] member [model.ChartModel.outputUserLabels]
  /// or labels in [container.VerticalAxisContainerCL.labelInfos].
  axis_container.TransposingAxisContainer makeViewForVerticalAxis() {
    return axis_container.TransposingAxisContainer.Vertical(
      chartViewMaker: this,
    );
  }

  axis_container.TransposingAxisContainer makeViewForVerticalAxisContainerFirst() {
    return axis_container.TransposingAxisContainer.Vertical(
      chartViewMaker: this,
    );
  }

  /// Makes view for legends in [model.ChartModel.byRowLegends].
  legend_container.LegendContainer makeViewForLegendContainer() {
    return legend_container.LegendContainer(
      chartViewMaker: this,
    );
  }

  /// Abstract method makes view for all data in [model.ChartModel.valuesColumns].
  /// The returned view presents all data in the data area.
  /// The chart type (line, bar) is determined by a concrete [ChartRootContainer].
  data_container.DataContainer makeViewForDataContainer();

  /// Makes a view showing all bars of data points.
  ///
  /// Each child in the returned list should be made from one positive or negative element of the model
  /// [model.ChartModel.crossPointsModelList].

  // todo-010      : 1) Reduce number of methods - merge the container-producing methods.
  //                 2) Review if the PointContainers, CrossSeriesContainers etc are needed and maybe rethink.
  //                 3) Change return values of methods
  //                 4!!) Pull Pad-creation outside of the methods where possible.
  //                 5) Review use and naming of _buildLevelYYY methods.
  //                 6) WHY DOES VIEW_MAKER EXIST??????? THERE IS SIMILAR CODE IN DATA_CONTAINER AND VIEW_MAKER
  //                    - CAN THE data_container building code be ONLY in Container extension OR ViewMaker but NOT IN BOTH?
  //                    - SIMILAR FOR AXIS_CONTAINER

  List<container_base.Padder> makeViewsForDataContainer_CrossPointsModels({
    required List<model.CrossPointsModel> crossPointsModels,
    required Sign barsAreaSign,
  }) {
    List<container_base.Padder> chartBars = [];
    // Iterates the [chartModel] cross-series (column wise) [crossPointsModel],
    //   creates a [CrossPointsContainer] (chartBar) from each cross-series, adds the chartBar
    //   to the [chartBars] list, which is returned.

    for (model.CrossPointsModel crossPointsModel in crossPointsModels) {

      data_container.CrossPointsContainer oneBar = makeViewForDataContainer_EachCrossPointsModel(
        crossPointsModel: crossPointsModel,
        barsAreaSign: barsAreaSign,
      );

      EdgePadding barSidePad = EdgePadding.TransposingWithSides(
        chartOrientation: chartOrientation,
        start: 5.0,
        end: 5.0,
      );

      // Pad around each [PointContainer]. Parent layouter must enforce even weights along main axis on all.
      container_base.Padder oneBarPadded = container_base.Padder(
        edgePadding: barSidePad,
        child: oneBar,
      );

      chartBars.add(oneBarPadded);
    }

    return chartBars;
  }

  /// Makes view for one [model.CrossPointsModel],
  /// presenting one bar (stacked or nonStacked) of data values (positive or negative).
  ///
  /// Controlled by two overridable hooks: [_buildLevel3PointsBarAsTransposingColumn]
  /// and [makeViewForDataArea_PointModel].
  ///
  data_container.CrossPointsContainer makeViewForDataContainer_EachCrossPointsModel({
    required model.CrossPointsModel crossPointsModel,
    required Sign barsAreaSign,
  }) {
    EdgePadding pointRectSidePad = EdgePadding.TransposingWithSides(
      chartOrientation: chartOrientation,
      start: 1.0,
      end: 1.0,
    );
    return data_container.CrossPointsContainer(
      chartViewMaker: this,
      crossPointsModel: crossPointsModel,
      children: [
        _buildLevel3PointsBarAsTransposingColumn(
          pointContainers:
              // Creates a list of padded [PointContainer]s from all points of the passed [crossPointsModel].
              // The code in [clsPointToNullableContainerForSign] contains logic that processes all combinations of
              // stacked and nonStacked, and positive and negative, distinctly.
              crossPointsModel
                  .crossPointsAllElements
                  // Map applies function converting [PointModel] to [PointContainer],
                  // calling the hook [makeViewForDataArea_PointModel]
                  .map(clsPointToNullableContainerForSign(barsAreaSign))
                  // Filters in only non null containers (impl detail of clsPointToNullableContainerForSign)
                  .where((containerElm) => containerElm != null)
                  .map((containerElm) => containerElm!)
                  // Pad around each [PointContainer].
                  // Only for nonStacked, parent layouter must enforce even weights along main axis on all.
                  // For stacked, we must NOT put weights, as in main direction, each bar has no limit.
                  .map((pointContainer) => container_base.Padder(
                        edgePadding: pointRectSidePad,
                        child: pointContainer,
                      ))
                  .toList(),
          barsAreaSign: barsAreaSign,
        )
      ],
    );
  }

  container_base.RollingBoxLayouter _buildLevel3PointsBarAsTransposingColumn({
    required List<container_base.Padder> pointContainers,
    required Sign barsAreaSign,
  }) {

    switch(chartStacking) {
      case ChartStacking.stacked:
        return container_base.TransposingRoller.Column(
          chartOrientation: chartOrientation,
          mainAxisAlign: Align.start, // default
          crossAxisAlign: Align.center, // default
          constraintsDivideMethod: ConstraintsDivideMethod.noDivision, // default
          isMainAxisAlignFlippedOnTranspose: false, // but do not flip to Align.end, as children have no weight=no divide
          children: barsAreaSign == Sign.positiveOr0 ? pointContainers.reversed.toList() : pointContainers,
        );
      case ChartStacking.nonStacked:
        return container_base.TransposingRoller.Row(
          chartOrientation: chartOrientation,
          mainAxisAlign: Align.start, // default
          // column:  sit positive bars at end,   negative bars at start
          // row:     sit positive bars at start, negative bars at end (Transposing will take care of this row flip)
          crossAxisAlign: barsAreaSign == Sign.positiveOr0 ? Align.end : Align.start,
          // nonStacked column orientation, leaf rects are in Row along main axis,
          // this Row must divide width to all leaf rects evenly
          constraintsDivideMethod: ConstraintsDivideMethod.evenDivision,
          isMainAxisAlignFlippedOnTranspose: true, // default
          children: pointContainers,
        );
    }

  }

  /// Function closure, when called with argument [barsAreaSign],
  /// returns [PointContainer] yielding function with one free parameter, the [PointModel].
  /// 
  /// Encapsulates the logic of creating [PointContainer] from [PointModel] for 
  /// all possible values of [chartStacking] and [barsAreaSign].
  ClsPointToNullableContainer clsPointToNullableContainerForSign(Sign barsAreaSign) {
    return (model.PointModel pointModelElm) {
      data_container.PointContainer? pointContainer;
      switch (chartStacking) {
        case ChartStacking.stacked:
          if (barsAreaSign == pointModelElm.sign) {
            // Note: this [makeViewForDataContainer_CrossPointsModel] is called each for positive and negative;
            // For points [pointModelElm] with the same sign as the stack sign being built,
            //   creates a point container from the [pointModelElm]. Caller must add the container to result list.
            pointContainer = makeViewForDataArea_PointModel(
              pointModel: pointModelElm,
            );
          } else {
            // For points [pointModelElm] with opposite sign to the stack being built,
            // return null PointContainer. Caller must SKIP this null, so no container will be added to result list.
          }
          break;
        case ChartStacking.nonStacked:
          if (barsAreaSign == pointModelElm.sign) {
            // For points [pointModelElm] with the same sign as the stack sign being built,
            //   creates a point container from the [pointModelElm]. Caller must add the container to result list.
            pointContainer = makeViewForDataArea_PointModel(
              pointModel: pointModelElm,
            );
          } else {
            // For points [pointModelElm] with opposite sign to the stack being built,
            //   creates a 'ZeroValue' container which has 0 length (along main direction).
            //   This ensures the returned list of PointContainers is the same size for positive and negative, so
            //   their places for positive and negative are alternating. Caller must add the container to result list.
            pointContainer = makeViewForDataArea_PointModelWithZeroValue(
              pointModel: pointModelElm,
            );
          }
          break;
      }
      return pointContainer;
    };
  }

  /// Generate view for this single leaf [PointModel] - a single [BarPointContainer].
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

  data_container.PointContainer makeViewForDataArea_PointModelWithZeroValue({
    required model.PointModel pointModel,
  }) {
    // return BarPointContainer with 0 layoutSize in the value orientation
    return data_container.ZeroValueBarPointContainer(
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
