/// Library of base containers used in the data area of the chart.
///
/// This includes the top level [DataContainer], as well as classes used
///   to present elements inside it, such as [PointContainer]
///

// ui
// import 'dart:ui' as ui show Size;

// this level base libraries or equivalent

import 'dart:ui' as ui show Canvas, Size;

import 'package:flutter_charts/src/chart/chart_type/bar/container/data_container.dart';
import 'package:flutter_charts/src/chart/chart_type/line/container/data_container.dart';
import 'package:flutter_charts/src/chart/painter.dart';

import 'package:flutter_charts/src/util/extensions_flutter.dart' show SizeExtension;


// this level chart
import 'package:flutter_charts/src/chart/container/container_common.dart' as container_common show ChartAreaContainer;
import 'package:flutter_charts/src/chart/container/axis_and_grid_container.dart';

// up and down levels
import 'package:flutter_charts/src/chart/options.dart';
import 'package:flutter_charts/src/chart/view_model/view_model.dart' show ChartViewModel, ClsPointToNullableContainer, PointsBarModel, BasePointModel;
import 'package:flutter_charts/src/chart/view_model/label_model.dart' show DataRangeTicksAndLabelsDescriptor;
import 'package:flutter_charts/src/util/util_flutter.dart' show  To2DPixelRange;

// morphic
import 'package:flutter_charts/src/morphic/container/chart_support/chart_style.dart' show ChartOrientation, ChartStacking;
import 'package:flutter_charts/src/morphic/container/morphic_dart_enums.dart' show Sign;
import 'package:flutter_charts/src/morphic/container/container_layouter_base.dart';
import 'package:flutter_charts/src/morphic/container/container_edge_padding.dart';
import 'package:flutter_charts/src/morphic/container/layouter_one_dimensional.dart';
import 'package:flutter_charts/src/morphic/container/container_key.dart' show ContainerKey;
import 'package:flutter_charts/src/morphic/ui2d/point.dart' show PointOffset;

/// Container for data on the chart.
///
/// It only includes the visual widgets representing data: bars on a bar chart, lines on a line chart.
///
/// To be precise, it also does include the input values axis, in detail:
///   - It does NOT include: neither the output values axis nor the output values labels.
///     The output values axis and labels are visually represented by [TransposingOutputAxisOrGrid].
///   - From the input values axis and label, it does include only the axis, but not the labels.
///     The input values labels are visually represented by [TransposingInputAxisOrGrid].
///
/// Important note about override:
///   1. Extensibility:  Consider a client that needs to place a value into each data rectangle on a bar chart.
///     This requires
///     - implementing [BarPointContainer] as [MyBarPointContainer]
///        - overriding the [buildAndReplaceChildren] method (if [MyBarPointContainer] is composed
///          of [BarPointContainer] and say a new [BarPointLabel] which are placed in a stack)
///        - OR
///        - overriding the [layout] method and [paint] method (if [MyBarPointContainer] also extends [BarPointContainer]
///          and uses the [paint] method to paint the values.
///     - However, creating the [MyBarPointContainer] is not sufficient, we also need to 'deliver' it
///       to the chart at the place where [BarPointContainer] is created.
///       Such 'delivery of [MyBarPointContainer] instances to their places' is possible in one of two methods:
///       1. Gradual override of all classes under [DataContainer]
///         - 1.1 Extend the [ChartRootContainer] to [MyBarChartRootContainer]
///         - 1.2 Extend the [SwitchBarChartViewModel] to [MyBarChartViewModel] and override [ChartViewModel.makeChartRootContainer]
///             to return [MyBarChartRootContainer].
///         - 1.3 Extend the [DataContainer]  to [MyDataContainer]  and override [DataContainer.makeInnerBarsContainer]
///             to return instance of [MyBarsContainer]
///         - 1.4 Extend the [BarsContainer]  to [MyBarsContainer]  and override [BarsContainer.makeInnerPointContainersBar]
///            to return instance of [MyPointContainersBar]
///         - 1.5 Extend the [PointContainersBar] to [MyPointContainersBar] and override [PointContainersBar.makePointContainer]
///             to return instance of [MyBarPointContainer]
///         - 1.6 In [MyBarChartViewModel] override [makeChartRootContainer], create and return [MyBarChartRootContainer]
///           instance, pass to it's dataContainer parameter argument
///           ```dart
///              dataContainer: BarChartDataContainer(chartViewModel: this),
///           ```
///         - 1.7 Pass [MyBarChartViewModel] (instead of [ChartViewModel]) into concrete [FlutterChartPainter]
///           instance (example of concrete [FlutterChartPainter] is [BarChartPainter])
///
///       2. Easier override provided by [MyBarChartViewModel] methods pulled up to [DataContainer]:
///         - 1.1, 1.2 are the same.
///         - But we do NOT need to create [MyBarsContainer] and [MyPointContainersBar] 1.3 and 1.4
///         - override [MyDataContainer.isOuterMakingInnerContainers] to true.
///         - 1.5, 1.6 and 1.7 are the same
///
abstract class DataContainer extends container_common.ChartAreaContainer {
  DataContainer({
    required super.chartViewModel,
  });

  @override
  void buildAndReplaceChildren() {
    var padGroup = ChartPaddingGroup(fromChartOptions: chartViewModel.chartOptions);

    // Generate list of containers, each container represents one bar (chartViewModel defines if horizontal or vertical)
    // This is the entry point where this container's [chartViewModel] starts to generate this container (view).
    addChildren([
      // Pad DataContainer on top and bottom from options. Children are height and width sizers
      Padder(
        edgePadding: EdgePadding.withSides(
          top: padGroup.heightPadTopOfYAndData(),
          bottom: padGroup.heightPadBottomOfYAndData(),
        ),
        child: HeightSizerLayouter(
          children: [
            WidthSizerLayouter(
              children: [
                // Wrapper StackLayouter for [TransposingGrid] which underlays the core of [DataContainer]:
                // The containers that show positive and negative bars or lines.
                TransposingStackLayouter(
                  children: [
                    TransposingCrossGrid(
                      chartViewModel: chartViewModel,
                    ),

                    makeInnerContainerForBothBarsAreasAndInputAxisLine(
                      // Row with columns of positive values
                      positiveBarsContainer: makeInnerBarsContainer(
                        barsAreaSign: Sign.positiveOr0,
                        outerDataContainer: this,
                        constraintsWeight: ConstraintsWeight(
                            weight:
                                chartViewModel.outputRangeDescriptor.dataRangeRatioOfPortionWithSign(Sign.positiveOr0)),
                      ),
                      // X axis line. Could place in Row with main constraints weight=0.0
                      inputAxisLine: TransposingInputAxisLine(
                        chartViewModel: chartViewModel,
                        inputRangeDescriptor: chartViewModel.inputRangeDescriptor,
                        outputRangeDescriptor: chartViewModel.outputRangeDescriptor,
                        // ConstraintsWeight.weight 0 ensures the parent layouter divides all weight
                        //   between positive and negative sections.
                        constraintsWeight: const ConstraintsWeight(weight: 0.0),
                      ),
                      // Row with columns of negative values
                      negativeBarsContainer: makeInnerBarsContainer(
                        barsAreaSign: Sign.negative,
                        outerDataContainer: this,
                        constraintsWeight: ConstraintsWeight(
                            weight:
                                chartViewModel.outputRangeDescriptor.dataRangeRatioOfPortionWithSign(Sign.negative)),
                      ),
                      outerDataContainer: this,
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    ]);
  }

  /// If true, calling [BarsContainer.makeInnerPointContainersBar],
  /// [PointContainersBar.makePointContainer], [PointContainersBar.makePointContainerWithFiller]
  /// is forwarded to their equivalents on [DataContainer].
  ///
  /// Motivation: The single motivation is client simplicity of implementing [DataContainer] extensions,
  ///             When set to true on an extension of [DataContainer], such extension must also
  ///             override [BarsContainer.makeInnerPointContainersBar],
  ///             [PointContainersBar.makePointContainer], [PointContainersBar.makePointContainerWithFiller],
  ///             returning from them either extension instances of [PointContainersBar],
  ///             [PointContainer], and [PointContainerWithFiller] or the default base instances - although at least
  ///             one should return an extension instance for any functional changes compared to default.

  bool isOuterMakingInnerContainers = false;

  /// [DataContainer] client-overridable method hook for extending [PositiveAndNegativeBarsWithInputAxisLineContainer].
  ContainerForBothBarsAreasAndInputAxisLine makeInnerContainerForBothBarsAreasAndInputAxisLine({
    required BarsContainer positiveBarsContainer,
    required TransposingInputAxisLine inputAxisLine,
    required BarsContainer negativeBarsContainer,
    required DataContainer outerDataContainer,
    ContainerKey? key,
  }) {
    return ContainerForBothBarsAreasAndInputAxisLine(
      chartViewModel: chartViewModel,
      positiveBarsContainer: positiveBarsContainer,
      inputAxisLine: inputAxisLine,
      negativeBarsContainer: negativeBarsContainer,
      outerDataContainer: outerDataContainer,
      key: key,
    );
  }

  /// Abstract [DataContainer] client-overridable method hook for extending [BarsContainer].
  ///
  /// Client-overridable, but rare use by client except direct extensions
  /// [LineChartDataContainer] and [BarChartDataContainer].
  ///
  /// One of child component maker delegates to outer [DataContainer].
  ///
  /// Client can provide their own subclass of [BarsContainer], return an instance from this method,
  /// and this new instance will be placed inside the [DataContainer.buildAndReplaceChildren]
  /// instead of the base instance.
  ///
  /// The reason for the word 'makeInner' is: The created [BarsContainer] is 'inner' to the [DataContainer] instance,
  /// (in other words, has a reference back to it's outer (owner) [DataContainer] instance).
  /// The 'inner' instances, can be created from their 'outer' instances, without the need to extend all intermediate
  /// classes used deep in the [DataContainer].
  ///
  /// In this base [DataContainer], the returned [BarsContainer] becomes a 'child of
  /// a child': specifically, a child of this [DataContainer]'s child [ContainerForBothBarsAreasAndInputAxisLine].
  /// (It is given a name [ContainerForBothBarsAreasAndInputAxisLine.positiveBarsContainer]
  /// or [ContainerForBothBarsAreasAndInputAxisLine.positiveBarsContainer].)
  /// See code in [DataContainer.buildAndReplaceChildren].
  ///
  /// The reason for the above inconsistency (something named inner is child of a child, rather than immediate child),
  /// is no named instance holds on the [ContainerForBothBarsAreasAndInputAxisLine] instance in [DataContainer].
  /// We could change that later.
  BarsContainer makeInnerBarsContainer ({
      required DataContainer outerDataContainer,
      required Sign barsAreaSign,
      required ConstraintsWeight constraintsWeight,
    ContainerKey? key,
  });

  /// [DataContainer] client-overridable method hook for extending [PointContainersBar]. Rare use.
  ///
  /// One of child component maker delegates to outer [DataContainer].
  ///
  /// Client can provide their own subclass of [BarsContainer], return an instance from this method,
  /// and this new instance will be placed inside the [DataContainer.buildAndReplaceChildren]
  /// instead of the base instance.
  ///
  /// For now, throw [UnimplementedError]. Extensions who want to change something about the chart view elements
  /// should override the view elements returned, then override these methods, and create and return from them
  /// the overridden view elements.
  ///
  PointContainersBar makeDeepInnerPointContainersBar({
    required PointsBarModel pointsBarModel,
    required BarsContainer outerBarsContainer,
    required Sign barsAreaSign,
  }) {
    throw UnimplementedError('If invoked directly, or isOuterMakingInnerContainers=true, subclass must implement');
  }

  /// [DataContainer] client-overridable method hook for extending [PointContainer]. Frequent use by clients.
  ///
  /// One of child component maker delegates to outer [DataContainer].
  ///
  /// Client can provide their own subclass of [PointContainer], return an instance from this method,
  /// and this new instance will be placed inside the [DataContainer.buildAndReplaceChildren]
  /// instead of the base instance.
  ///
  /// See discussion in [makeInnerBarsContainer] for 'inner' and 'outer' naming conventions.
  PointContainer makeDeepInnerPointContainer({
    required BasePointModel pointModel,
  }) {
    throw UnimplementedError('If invoked directly, or isOuterMakingInnerContainers=true, subclass must implement');
  }

  /// Child component maker delegated to outer [DataContainer].
  ///
  /// [BarsContainer] client-overridable method hook for extending [FillerBarPointContainer].
  ///
  /// Likely not needed by any client.
  BasePointContainer makeDeepInnerPointContainerWithFiller() {
    throw UnimplementedError('If invoked directly, or isOuterMakingInnerContainers=true, subclass must implement');
  }
}

/// Builds a container for positive and negative chart data areas;
///   positive and negative areas are separated by an axis line.
///
/// This container is on the top of data container hierarchy.
///
/// It accepts it's child containers in order of display (which could be reversed for row orientation
///   - [positiveBarsContainer] The area with positive bars
///   - [inputAxisLine]  Axis line separating positive and negative areas
///   - [negativeBarsContainer] The area with negative bars
///
/// For [ChartViewModel.chartOrientation] = [ChartOrientation.column] a [Column] is built;
/// for [ChartViewModel.chartOrientation] = [ChartOrientation.row]    a [Row] is built.
class ContainerForBothBarsAreasAndInputAxisLine extends container_common.ChartAreaContainer {
  ContainerForBothBarsAreasAndInputAxisLine({
    required super.chartViewModel,
    required this.positiveBarsContainer,
    required this.inputAxisLine,
    required this.negativeBarsContainer,
    required this.outerDataContainer,
    super.key,
    // KEEP comment - no children to super, added in buildAndReplaceChildren
  });

  final BarsContainer positiveBarsContainer;
  final TransposingInputAxisLine inputAxisLine;
  final BarsContainer negativeBarsContainer;

  /// non-child, kept to establish inner/outer relationship
  final DataContainer outerDataContainer;

  @override
  void buildAndReplaceChildren() {
    replaceChildrenWith([
      TransposingRoller.Column(
        chartOrientation: chartViewModel.chartOrientation,
        mainAxisAlign: Align.start, // default
        children: [
          positiveBarsContainer,
          inputAxisLine,
          negativeBarsContainer,
        ],
      )
    ]);
  }
}

/// Abstract container of either positive or negative bars, depending on [barsAreaSign].
///
/// Extensions should override [makeInnerPointContainersBar].
///
/// For [ChartViewModel.chartOrientation] = [ChartOrientation.column] a [Row]    of (column) bars is built;
/// for [ChartViewModel.chartOrientation] = [ChartOrientation.row]    a [Column] of (row)    bars is built.
abstract class BarsContainer extends container_common.ChartAreaContainer {

  BarsContainer({
    required super.chartViewModel,
    required this.outerDataContainer,
    required this.barsAreaSign,
    required super.constraintsWeight,
    super.key,
  }) {
    if (barsAreaSign == Sign.any) {
      throw StateError('$runtimeType is designed to hold elements with the same sign.');
    }
  }

  /// The sign of bars for which this container is built.
  final Sign barsAreaSign;
  final DataContainer outerDataContainer;

  @override
  void buildAndReplaceChildren() {
    EdgePadding barSidePad = EdgePadding.TransposingWithSides(
      chartOrientation: chartViewModel.chartOrientation,
      start: 5.0,
      end: 5.0,
    );

    // Row with positive or negative Column-bars, depending on [barsAreaSign].
    // As there are two of these rows in a parent Column, each Row is:
    //   - weighted by the ratio of positive / negative range taken up depending on sign
    //   - cross-aligned to top or bottom depending on sign.
    replaceChildrenWith([
      TransposingRoller.Row(
        chartOrientation: chartViewModel.chartOrientation,
        constraintsWeight: ConstraintsWeight(
          weight: chartViewModel.outputRangeDescriptor.dataRangeRatioOfPortionWithSign(barsAreaSign),
        ),
        mainAxisAlign: Align.start, // default
        // sit positive bars at end (bottom), negative pop to start (top)
        crossAxisAlign: barsAreaSign == Sign.positiveOr0 ? Align.end : Align.start,
        // column orientation, any stacking, any sign: bars of data are in Row main axis,
        // this Row must divide width to all bars evenly
        constraintsDivideMethod: ConstraintsDivideMethod.evenDivision,
        // children are padded bars; each bar created from one [PointsBarModel], contains rectangles or lines
        children: chartViewModel.pointsBarModels
            .map((pointsBarModel) => makeInnerPointContainersBar(
                  pointsBarModel: pointsBarModel,
                  outerDataContainer: outerDataContainer,
                  barsAreaSign: barsAreaSign,
                ))
            .map((pointContainersBar) => Padder(
                  edgePadding: barSidePad,
                  child: pointContainersBar,
                ))
            .toList(),
      )
    ]);
  }

  /// Abstract client-overridable method hook for extending [PointContainersBar].
  PointContainersBar makeInnerPointContainersBar({
    required PointsBarModel pointsBarModel,
    required DataContainer outerDataContainer,
    required Sign barsAreaSign,
  });

}

/// View for one [PointsBarModel], in other words, a bar of [PointContainer]s.
///
/// Each [PointContainer] views one [PointModel] in [PointsBarModel.pointModelList].
///
/// Each instance is visually presented as a horizontal or vertical bar
/// displaying [PointContainer]s as rectangles or lines.
/// Each rectangle or line represents a data point [PointModel].
///
/// See [buildAndReplaceChildren] for how the container is built.
///
abstract class PointContainersBar extends container_common.ChartAreaContainer {

  PointContainersBar({
    required super.chartViewModel,
    required this.outerDataContainer,
    required this.barsAreaSign,
    required this.pointsBarModel,
    super.key,
  });

  final PointsBarModel pointsBarModel;
  final DataContainer outerDataContainer;
  final Sign barsAreaSign;

  /// Builds a container for one bar with [PointContainer]s.
  ///
  /// Fully implemented in this base class, by providing client-overridable hooks.
  ///
  /// The hooks called in this base implementation (in order):
  ///
  ///   - [makePointContainerListForSign] creates the list of [PointContainer]s from all [PointModel] instances
  ///     in [pointsBarModel]s [PointsBarModel.pointModelList].
  ///   - [makePointContainersLayouter] wraps the above created point containers as children of a layouter;
  ///     the returned layouter instance is determined by the extension:
  ///       - The bar chart,  the [BarChartPointContainersBar]  returns the [TransposingRoller.Column]
  ///       - The line chart, the [LineChartPointContainersBar] returns the [TransposingStackLayouter.Column].
  ///   - [addChildren] adds the above created layouter as a single child of this [PointContainersBar].
  @override
  void buildAndReplaceChildren() {

    // Create list of PointContainers given [this.barsAreaSign].
    // Extensions may override [makePointContainerListForSign] by invoking this base,
    // then wrap (e.g. in Padder) each [PointContainer] in the result
    List<BoxContainer> pointContainerList = makePointContainerListForSign();

    // Call the overridable method that creates the list of [PointContainer]s,
    // each representing one [PointModel]l
    BoxContainer pointContainersLayouter = makePointContainersLayouter(pointContainerList: pointContainerList);

    // KEEP: Note : if children are passed to super, we need instead: replaceChildrenWith([])
    addChildren([pointContainersLayouter]);
  }

  /// Abstract method; extensions should make and return a layouter for the
  /// passed [pointContainerList] as children.
  ///
  /// Example: The extensions-returned layouter may be [TransposingRoller.Column] for bar chart
  /// or [TransposingStackLayouter] for line chart.
  ///
  BoxContainer makePointContainersLayouter({
    required List<BoxContainer> pointContainerList,
  });

  /// Returns a list of [PointContainer]s from all points of the [pointsBarModel]
  /// of this [PointContainersBar] instance that have the member sign [barsAreaSign].
  ///
  /// Invoked in [PointContainersBar.buildAndReplaceChildren] method, where it's result members are
  /// placed as children of the layouter created by [makePointContainersLayouter]
  ///
  /// Can be also overridden by extensions that need to manipulate the result (e.g. wrap each member in [Padder]).
  ///
  /// It merely forwards its work to the closure [clsPointToNullableContainerForSign] with the intended sign.
  ///
  /// Note: [makePointContainersLayouter] may create [TransposingRoller.Column] for bar chart
  /// or [TransposingStackLayouter] for line chart.
  ///
  List<BoxContainer> makePointContainerListForSign() {

    List<BoxContainer> pointContainers = pointsBarModel.pointModelList
        // Map applies function converting the [PointModel] to [PointContainer],
        // calling the hook [MyBarChartViewModelPointContainer]
        .map(clsPointToNullableContainerForSign(barsAreaSign))
        // Filters in only non null containers (impl detail of clsPointToNullableContainerForSign)
        .where((containerElm) => containerElm != null)
        .map((containerElm) => containerElm!)
        .toList();
    return pointContainers;
  }

  /// Function closure, when called with argument [barsAreaSign],
  /// returns function with one free parameter, the [PointModel].
  ///
  /// Contains logic that processes all combinations of
  /// stacked and nonStacked, and positive and negative, distinctly.
  ///
  /// The returned function, when invoked with [PointModel] as a parameter,
  /// returns either a [PointContainer] or null using following logic depending by the currier [barsAreaSign] :
  ///   - If the passed [PointModel.sign] is the same as [barsAreaSign] a [PointContainer] is returned.
  ///     This [PointContainer] is created by the callback [PointContainersBar.makePointContainer];
  ///     it presents the passed [PointModel].
  ///   - else, null is returned. Caller should respond by
  ///
  /// Encapsulates the logic of creating [PointContainer] from [PointModel] for
  /// all possible values of [ChartViewModel.chartStacking] and [barsAreaSign].
  ClsPointToNullableContainer clsPointToNullableContainerForSign(Sign barsAreaSign) {
    return (BasePointModel pointModelElm) {
      BasePointContainer? pointContainer;
      switch (chartViewModel.chartStacking) {
        case ChartStacking.stacked:
          if (barsAreaSign == pointModelElm.sign) {
            // Note: this [MyBarChartViewModelPointContainer] is called (all the way from top) once for positive, once for negative;
            // For [pointModelElm] with the same sign as the stack sign being built,
            //   creates a [pointContainer] from the [pointModelElm]. Caller adds the [pointContainer] to result list.
            pointContainer = makePointContainer(
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
            //   creates a [pointContainer] from the [pointModelElm]. Caller adds the [pointContainer] to result list.
            pointContainer = makePointContainer(
              pointModel: pointModelElm,
            );
          } else {
            // For points [pointModelElm] with opposite sign to the stack being built,
            //   creates a 'Filler' [pointContainer] which has 0 length (along main direction).
            //   This ensures the returned list of PointContainers is the same size for positive and negative, so
            //   their places for positive and negative alternate.
            // Caller adds the [pointContainer] to result list; layouter presents it with 0 length in cross direction.
            pointContainer = makePointContainerWithFiller();
          }
          break;
      }
      return pointContainer;
    };
  }

  /// [BarsContainer] client-overridable method hook for extending [PointContainer].
  PointContainer makePointContainer({
    required BasePointModel pointModel,
  }) {
    if (outerDataContainer.isOuterMakingInnerContainers) {
      return outerDataContainer.makeDeepInnerPointContainer(
        pointModel: pointModel,
      );
    }
    throw UnimplementedError('$runtimeType.makePointContainer: '
        'The value of outerDataContainer.isOuterMakingInnerContainers '
        'is false, this method must be overridden in a subclass.');
  }

  /// [BarsContainer] client-overridable method hook for extending [FillerBarPointContainer].
  ///
  /// Likely not needed by any client.
  BasePointContainer makePointContainerWithFiller() {
    // return BarPointContainer with 0 layoutSize in the value orientation
    if (outerDataContainer.isOuterMakingInnerContainers) {
      return outerDataContainer.makeDeepInnerPointContainerWithFiller();
    }
    throw UnimplementedError('$runtimeType.makePointContainerWithFiller: '
        'The value of outerDataContainer.isOuterMakingInnerContainers '
        'is false, this method must be overridden in a subclass.');
  }

}

/// The base class of containers which present a single point in chart's [PointModel].
///
/// Extensions may present a point as a rectangle in a bar chart, or a dot and line in a line chart.
///
/// - [chartViewModel] is needed in constructor to pass to super ChartAreaContainer
/// - [pointModel] kept as a member is the point presented by this container.
/// - Note: This base class is NOT connected to any column - it does NOT hold an outer member representing a column (bar).
///         Such connection is in concrete extension [PointContainer] , see [PointContainer.outerPointContainersBar],
///         but NOT in the filler extension [FillerPointContainer].
abstract class BasePointContainer extends container_common.ChartAreaContainer
    with WidthSizerLayouterChildMixin, HeightSizerLayouterChildMixin {

  BasePointContainer({
    required super.chartViewModel,
    required this.pointModel,
    // To allow extensions to compose, keep children in signature.
    super.children,
    super.key,
  }) {
    // Model can find the view which displays the model
    pointModel.pointContainer = this;
  }

  /// The concrete [BasePointModel] presented by this container.
  final BasePointModel pointModel;

  ///
  late final PointOffset pixelPointOffset;
}

/// Abstract container is a view for it's [pointModel];
/// implementations represent the point model on a line, or as a rectangle in a bar chart.
///
/// Important note: To enable extensibility, two things are being done here:
///   - extends `with WidthSizerLayouterChildMixin, HeightSizerLayouterChildMixin`,
///     for extensions to not have to worry about sizing
///   - signature includes `List<BoxContainer>? children`, to allow extensions to compose from other [BoxContainer]s.
///
abstract class PointContainer extends BasePointContainer {

  PointContainer({
    required super.chartViewModel,
    required super.pointModel,
    required this.outerPointContainersBar,
    // To allow extensions to compose, keep children in signature.
    super.children,
    super.key,
  }) {
    // Model can find the view which displays the model
    pointModel.pointContainer = this;
  }

  final PointContainersBar outerPointContainersBar;

  /// Performs the core work of layout of this [PointContainer] by calculating a [PointOffset], containing data
  /// about the position where this [PointContainer] representing the [pointModel] should be placed on the chart.
  ///
  /// Intended to be called from concrete [PointContainer]'s extension's [layout] method.
  ///
  /// The returned [PointOffset] contains the core data about [offset] in parent and [layoutSize] of this container
  /// for any [ChartOrientation] and [ChartStacking].
  ///
  /// Intended to be invoked during [PointContainer.layout] of this [PointContainer] class or subclasses.
  ///
  /// Transforms (transposes and affmap-s) this [PointModel] to it's [PointOffset] position,
  /// determined by its [PointModel.outputValue].
  ///
  /// Motivation and implementation:
  ///
  ///   1. As this method should be invoked during [PointContainer.layout] by a container (and also owner) layouter
  ///      [outerPointContainersBar] (which creates a [Row] or a [Column] parent layouter for this instance),
  ///      this code is always running as a container-child of a [Column] or a [Row].
  ///   2. Terminology: Below, we use the term 'container-parent bar' for the owner [Row] or [Column]
  ///      of this [PointContainer].
  ///   3. The intent of this method is to position this container (set [offset]) to represent
  ///      its [pointModel]'s position RELATIVE to (inside of) its container-parent bar mentioned above.
  ///   4. The positioning mentioned in item 3. is implemented by affmap-ing the [pointModel]'s values
  ///      to a new transformed position relative to this [PointContainer]'s container-parent bar pixel coordinates.
  ///   5. Note: This implementation uses affmap because if allows to transfer a position between two coordinate systems
  ///      with different origins, in any [ChartOrientation] and [ChartStacking] situation.
  ///   6. To use affmap on a point, we need to know the 'from range' and the 'to range'. Several important facts
  ///      regarding the 'from range' and 'to range':
  ///      - Because the 'to range' is always given by [constraints] of the container-parent bar mentioned
  ///        in items 1. and 2., this method does ALWAYS MUST AFFMAP TO THE [constraints] of the container-parent bar
  ///        NOT TO THE FULL [sizerHeight] or [sizerWidth].
  ///      - Further, the container-parent bar's [constraints] ALWAYS represents either positive or negative value,
  ///        this method must SEPARATELY AFFMAP the positive or negative 'from range'
  ///        to the container-parent bar's [constraints]. The [constraints] are sized as follows:
  ///        - in the layouter Main direction,  length is the dataRange of positive values (the positive portion of data range)
  ///        - in the layouter Cross direction, length is the width of the bar
  ///   7. So the affmap ranges are:
  ///      - fromInputRange:  the positive or negative portion of dataRange (Sign of the PointModel.inputValue)
  ///      - fromOutputRange: as above, Sign of PointModel.outputValue
  ///      - pixelRange:      height = constraints height, width = constraints width.
  ///                         constraints are those given to 'container-parent bar'. They are sized in both directions
  ///   8. After affmap, the code makes two changes to the transferred pixelPointOffset:
  ///     - 8.1: repositions the PointOffset, in the cross direction, in the middle of the constraint,
  ///            see [affmapBetweenRanges]
  ///     - 8.2: sets the [PointOffset.barPointRectSize], see [affmapBetweenRanges]
  ///
  PointOffset layoutUsingPointModelAffmapToPixels() {

    PointOffset pointOffset = pointModel.toPointOffsetOnInputRange(
      inputDataRangeTicksAndLabelsDescriptor: chartViewModel.inputRangeDescriptor,
    );

    To2DPixelRange to2DPixelRange = To2DPixelRange(
      width: constraints.size.width,
      height: constraints.size.height,
    );

    // Affmap the [pointOffset] corresponding to [pointModel] between affmap ranges - see item 7.
    PointOffset pixelPointOffset = pointOffset.affmapBetweenRanges(
      fromTransposing2DValueRange: chartViewModel.fromTransposing2DValueRange.subsetForSignOfPointOffsetBeforeAffmap(
        pointOffset: pointOffset,
      ),
      to2DPixelRange: to2DPixelRange,
      isMoveInCrossDirectionToPixelRangeCenter: true,
      isSetBarPointRectInCrossDirectionToPixelRange: true,
    );

    return pixelPointOffset;
  }

  /// Generates code for testing.
  // todo-020 : fix this after changes in API of this class
  void generateTestCode(
      PointOffset pointOffset,
      DataRangeTicksAndLabelsDescriptor inputRangeDescriptor,
      DataRangeTicksAndLabelsDescriptor outputRangeDescriptor,
      PointOffset pixelPointOffset,
      ) {
    var pointOffsetStr = '   pointOffset = ${pointOffset.asCodeConstructor()};\n';
    var callStr = '   pixelPointOffset = pointOffset.affmapToPixelsMaybeTransposeInContextOf(\n'
        '       chartOrientation: ChartOrientation.${chartViewModel.chartOrientation.name},\n'
        '       withinConstraints: ${constraints.asCodeConstructorInsideBox()},\n'
        '       inputDataRange: ${inputRangeDescriptor.dataRange.asCodeConstructor()},\n'
        '       outputDataRange: ${outputRangeDescriptor.dataRange.asCodeConstructor()},\n'
        '       sizerHeight: $sizerHeight,\n'
        '       sizerWidth: $sizerWidth,\n'
        '       //  isAffmapUseSizerInsteadOfConstraint: false,\n'
        '     );\n';
    // var pixelPointOffsetStr = '   pixelPointOffset = ${pixelPointOffset.asCodeConstructor()};\n';
    // var pixelPointOffsetLayoutSizeStr = '   pixelPointOffsetLayoutSize = ${pixelPointOffset.barPointRectSize.asCodeConstructor()};\n';
    var assertOffsetSame = '   assertOffsetResultsSame(pixelPointOffset, ${pixelPointOffset.asCodeConstructor()});\n';
    var assertSizeSame =   '   assertSizeResultsSame(pixelPointOffset.barPointRectSize, ${pixelPointOffset.barPointRectSize.asCodeConstructor()});\n';

    print(' $pointOffsetStr $callStr $assertOffsetSame $assertSizeSame\n\n');
  }

}

/// Filler container for charts is zero-height (thus 'invisible'),
/// and does not need any underlying [pointModel].
///
/// This container is a stand-in for value point in any chart (line, bar), any orientation and stacking-only,
/// placed on the positive or negative side against the non-zero opposite-sign value bar is shown. See drawing below.
///
/// It's parent container is assumed to be [MainAndCrossAxisBoxLayouter], hence we use the term 'main' and 'cross' axis
/// below.
///
/// It's [layoutSize] in the main direction is always 0, in the cross-direction is the parent's
/// [MainAndCrossAxisBoxLayouter.constraints] size.
///
/// See [layout] for details.
///
/// Motivation: - Used in bar chart, if data contain both positive and negative values to display the
///               'filler' rectangles shown on the opposite side of rectangles that have a value.
///             - Example on vertical bar chart nonStacking:
///               - Assume data contains points with values 1 and -1 in that order.
///                 Then the rectangles shown in the chart are:
///                 - On the positive side, 2 rectangles are shown:
///                   - A rectangle with height corresponding to value 1; this rectangle is [paint]ed by
///                     a [PointContainer] extension, the [BarPointContainer].
///                   - A zero-height rectangle (to fill in the horizontal space against the negative -1 rectangle);
///                     this rectangle is [paint]ed by instances of this [FillerFillerPointContainer],
///                     is invisible due to height 0, but fills in the horizontal width which is the same as
///                     the -1 rectangle.
///                 - On the negative side, 2 rectangles are shown, analogs to the positive side.
///
/// |------------|
/// |            |   filler rect
/// ---------------------------------  <--- axis
///  filler rect    |            |
///                 |------------|
///
class FillerPointContainer extends BasePointContainer {

  FillerPointContainer({
    required super.chartViewModel,
    required super.pointModel,
    super.children,
    super.key,
  });

  /// Sets the [layoutSize] in the value direction
  /// (parent container/layouter mainAxisDirection) to be zero.
  @override
  void layout() {
    buildAndReplaceChildren();

    // Make the layoutSize zero in the direction of the chart orientation
    layoutSize = constraints.size.fromMySideAlongPassedAxisOtherSideAlongCrossAxis(
      axis: chartViewModel.chartOrientation.inputDataAxisOrientation,
      other: const ui.Size(0.0, 0.0),
    );
  }

  @override
  paint(ui.Canvas canvas) {
    return;
  }

}