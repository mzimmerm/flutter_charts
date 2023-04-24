import 'dart:ui' as ui show Canvas, Size;

import 'painter.dart';
import 'package:logger/logger.dart' as logger;

// import 'dart:developer' as dart_developer;

import '../morphic/container/chart_support/chart_orientation.dart';
import '../morphic/container/container_edge_padding.dart';
import '../morphic/container/container_layouter_base.dart' as container_base;
import '../morphic/container/container_layouter_base_dart_support.dart';
// import '../morphic/container/container_edge_padding.dart';
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
import '../util/util_labels.dart' as util_labels;

/// Abstract base class for view makers.
///
/// A view maker is a class that makes (creates, produces, generates) a chart view hierarchy,
/// starting with a concrete [container.ChartRootContainerCL], with the help of [model.ChartModel].
///
/// This base view maker has access to [model.ChartModel]
///
/// This base view maker holds as members:
///   - the model in [chartModel]. It's member [model.ChartModel.chartOptions] provides access to [options.ChartOptions]
///   - the chart orientation in [chartSeriesOrientation]
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
    required this.chartSeriesOrientation,
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
    // todo-010-refactoring : DataRangeLabelInfosGenerator should be moved to the new_model.dart.
    //                         Although not purely a view-independent model, it should ONLY have this one private constructro
    //                         which creates the outputLabelsGenerator and inputLabelsGenerator. ONLY the class DataRangeLabelInfosGenerator
    //                         should be public, but the constructor of it private to the new_model.
    outputLabelsGenerator = util_labels.DataRangeLabelInfosGenerator(
      chartViewMaker: this,
      dataModel: chartModel,
      dataDependency: DataDependency.outputData,
      extendAxisToOrigin: extendAxisToOrigin,
      valueToLabel: options.outputValueToLabel,
      inverseTransform: chartOptions.dataContainerOptions.yInverseTransform,
      userLabels: chartModel.yUserLabels,
      isStacked: isStacked,
    );

    // See comment in VerticalAxisContainer constructor
    inputLabelsGenerator = util_labels.DataRangeLabelInfosGenerator(
      chartViewMaker: this,
      dataModel: chartModel,
      dataDependency: DataDependency.inputData,
      extendAxisToOrigin: extendAxisToOrigin,
      valueToLabel: options.inputValueToLabel,
      inverseTransform: chartOptions.dataContainerOptions.xInverseTransform,
      userLabels: chartModel.xUserLabels,
      isStacked: isStacked,
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

  final ChartStackingEnum chartStacking;

  bool get isStacked => chartStacking == ChartStackingEnum.stacked;

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

  /// Assumed made from [model.ChartModel] member [model.ChartModel.xUserLabels]
  /// or [container.VerticalAxisContainerCL.labelInfos].

  axis_container.TransposingAxisContainer makeViewForHorizontalAxis() {
    return axis_container.TransposingAxisContainer.Horizontal(
      chartViewMaker: this,
    );
  }

  /// Assumed made from [model.ChartModel] member [model.ChartModel.yUserLabels]
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
  // todo-010-next : 1) Reduce number of methods - merge the container-producing methods. 2) Review if the PointContainers, CrossSeriesContainers etc are needed and maybe rethink. 3) Change return values of methods
  List<container_base.Padder> makeViewsForDataContainer_Bars({
    required List<model.CrossPointsModel> crossPointsModels,
    required model.Sign barsAreaSign,
  }) {
    List<container_base.Padder> chartBars = [];
    // Iterates the [chartModel] cross-series (column wise) [crossPointsModel],
    //   creates a [CrossPointsContainer] (chartBar) from each cross-series, adds the chartBar
    //   to the [chartBars] list, which is returned.

    for (model.CrossPointsModel crossPointsModel in crossPointsModels) {

      data_container.CrossPointsContainer oneBar = makeViewForDataContainer_EachBar(
        crossPointsModel: crossPointsModel,
        barsAreaSign: barsAreaSign,
      );

      EdgePadding pointRectSidePad = EdgePadding.TransposingWithSides(
        chartSeriesOrientation: chartSeriesOrientation,
        start: 5.0,
        end: 5.0,
      );
      container_base.Padder oneBarPadded = container_base.Padder(
        edgePadding: pointRectSidePad,
        child: oneBar,
        // Give all padded [CrossPointsContainer] which will be wrapped in columns the same weight along main axis.
        constraintsWeight: const container_base.ConstraintsWeight(weight: 1),
      );

      chartBars.add(oneBarPadded);
    }
    return chartBars;
  }

  data_container.CrossPointsContainer makeViewForDataContainer_EachBar({
    required model.CrossPointsModel crossPointsModel,
    required model.Sign barsAreaSign,
    }) {
    return data_container.CrossPointsContainer(
        chartViewMaker: this,
        crossPointsModel: crossPointsModel,
        children: [
          makeViewForDataContainer_EachBarLayouter(
              crossPointsModel: crossPointsModel,
              barsAreaSign: barsAreaSign),
        ],
      );
  }

  // todo-00-next : Rename EachBar to EachCrossSeriesBar; Rename Bar CrossSeriesBar, Bars to CrossSeriesBars
  container_base.RollingBoxLayouter makeViewForDataContainer_EachBarLayouter({
    required model.CrossPointsModel crossPointsModel,
    required model.Sign barsAreaSign,
  }) {
    EdgePadding pointRectSidePad = EdgePadding.TransposingWithSides(
      chartSeriesOrientation: chartSeriesOrientation,
      start: 1.0,
      end: 1.0,
    );
    // Get point containers, and wrap each in a Padder, narrowing the bars
    var pointContainers = makeViewForDataContainer_CrossPointsModel(
      crossPointsModel: crossPointsModel,
      barsAreaSign: barsAreaSign,
    ).map((pointContainer) =>
        container_base.Padder(
          edgePadding: pointRectSidePad,
          child: pointContainer,
          constraintsWeight: const container_base.ConstraintsWeight(weight: 1),
        ),
    ).toList();

    return _buildLevel3PointsBarAsTransposingColumn(
      childrenPointContainers: pointContainers,
      barsAreaSign: barsAreaSign,
    );
  }

  // todo-010
  //           - WHY IS THIS  data_container building code IN VIEW MAKER,
  //             AND SIMILAR CODE building data_container also IN data_container.dart?
  //              - this indicates a design issue.
  //              - CAN THE data_container building code be ONLY in Container extension OR ViewMaker but NOT IN BOTH?
  //              - SIMILAR FOR AXIS_CONTAINER
  //
  // todo-010-next : get rid of this method, merge it.
  container_base.RollingBoxLayouter _buildLevel3PointsBarAsTransposingColumn({
    required List<container_base.Padder> childrenPointContainers,
    required model.Sign barsAreaSign,
  }) {

    switch(chartStacking) {
      // column, stacked only, positive: revert order so that first cross-series is at end (bottom)
      case ChartStackingEnum.stacked:
        switch(barsAreaSign) {
          case model.Sign.positiveOr0:
            childrenPointContainers = childrenPointContainers.reversed.toList(growable: false);
            break;
          case model.Sign.negative:
            // todo-00-last-done : childrenPointContainers = childrenPointContainers.toList(growable: false);
            break;
          case model.Sign.any:
            throw StateError('Invalid "any" sign for data container bars.');
        }        break;
      case ChartStackingEnum.nonStacked:
        // logic on this is in-place on crossAxisAlign
        break;
    }

    switch(chartStacking) {
      case ChartStackingEnum.stacked:
        return container_base.TransposingRoller.Column(
          chartSeriesOrientation: chartSeriesOrientation,
          // Positive: Both Align.start and end work, . Negative: only Align.start work in column
          mainAxisAlign: Align.start, // default
          isMainAxisAlignFlippedOnTranspose: false, // but do not flip to Align.end, as children have no weight=no divide
          children: childrenPointContainers,
        );
      case ChartStackingEnum.nonStacked:
        return container_base.TransposingRoller.Row(
          chartSeriesOrientation: chartSeriesOrientation,
          // Positive: Both Align.start and end work, . Negative: only Align.start work in column
          mainAxisAlign: Align.start, // default
          // column:  sit positive bars at end,   negative bars at start
          // row:     sit positive bars at start, negative bars at end (Transposing will take care of this row flip)
          crossAxisAlign: barsAreaSign == model.Sign.positiveOr0 ? Align.end : Align.start,
          // isMainAxisAlignFlippedOnTranspose: false, // but do not flip to Align.end, as children have no weight=no divide todo-010-next review
          children: childrenPointContainers,
        );
    }

  }

  /// Generates [PointContainer] view from each [PointModel]
  /// and collects the views in a list of [PointContainer]s which is returned.
  ///
  /// The logic contains stacking switch that processes stacked and nonStacked distinctly.
  /// See the code comments for [ChartStackingEnum.stacked] and [ChartStackingEnum.nonStacked].
  List<data_container.PointContainer> makeViewForDataContainer_CrossPointsModel({
    required model.CrossPointsModel crossPointsModel,
    required model.Sign barsAreaSign,
  }) {
    List<data_container.PointContainer> pointContainerList = [];
    data_container.PointContainer pointContainer;

    // Generates [PointContainer] view from each [PointModel]
    // and collect the views in a list which is returned.
    crossPointsModel.applyOnAllElements(
      (model.PointModel pointModelElm, dynamic passedList) {
        switch (chartStacking) {
          case ChartStackingEnum.stacked:
            // Stacked:
            //   Note: this [makeViewForDataContainer_CrossPointsModel] is called each for positive and negative;
            //   Creates a point container from point [pointModelElm] and adds the container to result,
            //     only for points [pointModelElm] which point sign and stack sign being built are the same.
            if (barsAreaSign == pointModelElm.sign) {
              passedList.add(makeViewForDataArea_PointModel(
                pointModel: pointModelElm,
              ));
            }
            break;
          case ChartStackingEnum.nonStacked:
            // Non-Stacked:
            //   For points [pointModelElm] with the same sign as the stack sign being built,
            //     creates a regular point container from point [pointModelElm] and adds the container to result,
            //     as in the [ChartStackingEnum.stacked] branch above.
            //   For points [pointModelElm] with opposite sign to the stack being built,
            //     create a 'ZeroValue' container which has 0 length (along main direction).
            //     This ensures the returned list of PointContainers is the same size for positive and negative, so
            //     their places for positive and negative are alternating.

            if (barsAreaSign == pointModelElm.sign) {
              passedList.add(makeViewForDataArea_PointModel(
                pointModel: pointModelElm,
              ));
            } else {
              passedList.add(makeViewForDataArea_PointModelWithZeroValue(
                pointModel: pointModelElm,
              ));
            }
            break;
        }
      },
      pointContainerList,
    );

    return pointContainerList;
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
