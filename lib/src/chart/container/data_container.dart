/// Library of base containers used in the data area of the chart.
///
/// This includes the top level [DataContainer], as well as classes used
///   to present elements inside it, such as [PointContainer]
///

// ui
// import 'dart:ui' as ui show Size;

// this level base libraries or equivalent
import 'package:flutter_charts/src/chart/painter.dart';

import 'package:flutter_charts/src/util/extensions_flutter.dart' show SizeExtension;


// this level chart
import 'package:flutter_charts/src/chart/container/container_common.dart' as container_common show ChartAreaContainer;
import 'package:flutter_charts/src/chart/container/axis_container.dart';

// up level chart
import 'package:flutter_charts/src/chart/options.dart';
import 'package:flutter_charts/src/chart/model/data_model.dart' show DataColumnModel, PointModel;
import 'package:flutter_charts/src/chart/view_model.dart' show ChartViewModel, ClsPointToNullableContainer;
import 'package:flutter_charts/src/chart/model/label_model.dart' show DataRangeLabelInfosGenerator;

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
///     The output values axis and labels are visually represented by [TransposingOutputAxisContainer].
///   - From the input values axis and label, it does include only the axis, but not the labels.
///     The input values labels are visually represented by [TransposingInputAxisContainer].
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
///         - 1.4 Extend the [BarsContainer]  to [MyBarsContainer]  and override [BarsContainer.makeInnerDataColumnPointsBar]
///            to return instance of [MyDataColumnPointsBar]
///         - 1.5 Extend the [DataColumnPointsBar] to [MyDataColumnPointsBar] and override [DataColumnPointsBar.makePointContainer]
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
///         - But we do NOT need to create [MyBarsContainer] and [MyDataColumnPointsBar] 1.3 and 1.4
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
                makeInnerContainerForBothBarsAreasAndInputAxisLine(
                  // Row with columns of positive values
                  positiveBarsContainer: makeInnerBarsContainer(
                    barsAreaSign: Sign.positiveOr0,
                    outerDataContainer: this,
                    constraintsWeight: ConstraintsWeight(weight: chartViewModel.outputLabelsGenerator.dataRangeRatioOfPortionWithSign(Sign.positiveOr0)),
                  ),
                  // X axis line. Could place in Row with main constraints weight=0.0
                  inputAxisLine: TransposingInputAxisLineContainer(
                    chartViewModel: chartViewModel,
                    inputLabelsGenerator: chartViewModel.inputLabelsGenerator,
                    outputLabelsGenerator: chartViewModel.outputLabelsGenerator,
                    constraintsWeight: const ConstraintsWeight(weight: 0.0),
                  ),
                  // Row with columns of negative values
                  negativeBarsContainer: makeInnerBarsContainer(
                    barsAreaSign: Sign.negative,
                    outerDataContainer: this,
                    constraintsWeight: ConstraintsWeight(weight: chartViewModel.outputLabelsGenerator.dataRangeRatioOfPortionWithSign(Sign.negative)),
                  ),
                  outerDataContainer: this,
                ),
              ],
            ),
          ],
        ),
      ),
    ]);
  }

  /// If true, calling [BarsContainer.makeInnerDataColumnPointsBar],
  /// [DataColumnPointsBar.makePointContainer], [DataColumnPointsBar.makePointContainerWithZeroValue]
  /// is forwarded to their equivalents on [DataContainer].
  ///
  /// Motivation: The single motivation is client simplicity of implementing [DataContainer] extensions,
  ///             When set to true on an extension of [DataContainer], such extension must also
  ///             override [BarsContainer.makeInnerDataColumnPointsBar],
  ///             [DataColumnPointsBar.makePointContainer], [DataColumnPointsBar.makePointContainerWithZeroValue],
  ///             returning from them either extension instances of [DataColumnPointsBar],
  ///             [PointContainer], and [PointContainerWithZeroValue] or the default base instances - although at least
  ///             one should return an extension instance for any functional changes compared to default.

  bool isOuterMakingInnerContainers = false;

  /// [DataContainer] client-overridable method hook for extending [PositiveAndNegativeBarsWithInputAxisLineContainer].
  ContainerForBothBarsAreasAndInputAxisLine makeInnerContainerForBothBarsAreasAndInputAxisLine({
    required BarsContainer positiveBarsContainer,
    required TransposingInputAxisLineContainer inputAxisLine,
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

  /// [DataContainer] client-overridable method hook for extending [BarsContainer]. Rare use
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
  }) {
    return BarsContainer(
      chartViewModel: chartViewModel,
      outerDataContainer: outerDataContainer,
      barsAreaSign: barsAreaSign,
      constraintsWeight: constraintsWeight,
      key: key,
    );
  }

  /// [DataContainer] client-overridable method hook for extending [DataColumnPointsBar]. Rare use.
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
  DataColumnPointsBar makeDeepInnerDataColumnPointsBar({
    required DataColumnModel dataColumnModel,
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
    required PointModel pointModel,
  }) {
    throw UnimplementedError('If invoked directly, or isOuterMakingInnerContainers=true, subclass must implement');
  }

  /// Child component maker delegated to outer [DataContainer].
  ///
  /// [BarsContainer] client-overridable method hook for extending [ZeroValueBarPointContainer].
  ///
  /// Likely not needed by any client.
  PointContainer makeDeepInnerPointContainerWithZeroValue({
    required PointModel pointModel,
  }) {
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
  final TransposingInputAxisLineContainer inputAxisLine;
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

/// Build the area showing either positive or negative bars, depending on [barsAreaSign].
///
/// For [ChartViewModel.chartOrientation] = [ChartOrientation.column] a [Row]    of (column) bars is built;
/// for [ChartViewModel.chartOrientation] = [ChartOrientation.row]    a [Column] of (row)    bars is built.
class BarsContainer extends container_common.ChartAreaContainer {

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
          weight: chartViewModel.outputLabelsGenerator.dataRangeRatioOfPortionWithSign(barsAreaSign),
        ),
        mainAxisAlign: Align.start, // default
        // sit positive bars at end (bottom), negative pop to start (top)
        crossAxisAlign: barsAreaSign == Sign.positiveOr0 ? Align.end : Align.start,
        // column orientation, any stacking, any sign: bars of data are in Row main axis,
        // this Row must divide width to all bars evenly
        constraintsDivideMethod: ConstraintsDivideMethod.evenDivision,
        // children are padded bars; each bar created from one [DataColumnModel], contains rectangles or lines
        children: chartViewModel.dataColumnModels
            .map((dataColumnModel) => makeInnerDataColumnPointsBar(
                  dataColumnModel: dataColumnModel,
                  outerDataContainer: outerDataContainer,
                  barsAreaSign: barsAreaSign,
                ))
            .map((dataColumnPointsBar) => Padder(
                  edgePadding: barSidePad,
                  child: dataColumnPointsBar,
                ))
            .toList(),
      )
    ]);
  }

  /// [BarsContainer] client-overridable method hook for extending [DataColumnPointsBar].
  DataColumnPointsBar makeInnerDataColumnPointsBar({
    required DataColumnModel dataColumnModel,
    required DataContainer outerDataContainer,
    required Sign barsAreaSign,
  }) {
    if (outerDataContainer.isOuterMakingInnerContainers) {
      return outerDataContainer.makeDeepInnerDataColumnPointsBar(
        dataColumnModel: dataColumnModel,
        outerBarsContainer: this,
        barsAreaSign: barsAreaSign,
      );
    }
    return DataColumnPointsBar(
      chartViewModel: chartViewModel,
      outerDataContainer: outerDataContainer,
      barsAreaSign: barsAreaSign,
      dataColumnModel: dataColumnModel,
    );
  }

}

/// View for one [DataColumnModel], in other words, a bar of [PointContainer]s.
///
/// Each [PointContainer] views one [PointModel] in [DataColumnModel.pointModelList].
///
/// Each instance is visually presented as a horizontal or vertical bar
/// displaying [PointContainer]s as rectangles or lines.
/// Each rectangle or line represents a data point [PointModel].
///
/// See [buildAndReplaceChildren] for how the container is built.
///
class DataColumnPointsBar extends container_common.ChartAreaContainer {

  DataColumnPointsBar({
    required super.chartViewModel,
    required this.outerDataContainer,
    required this.barsAreaSign,
    required this.dataColumnModel,
    super.key,
  });

  final DataColumnModel dataColumnModel;
  final DataContainer outerDataContainer;
  final Sign barsAreaSign;

  /// Builds a container for one bar with [PointContainer]s.
  ///
  /// For [ChartViewModel.chartOrientation] = [ChartOrientation.column] a [Column] is built;
  /// for [ChartViewModel.chartOrientation] = [ChartOrientation.row]    a [Row] is built.
  @override
  void buildAndReplaceChildren() {

    // Pad around each [PointContainer] before placing it in TransposingRoller
    EdgePadding pointRectSidePad = EdgePadding.TransposingWithSides(
      chartOrientation: chartViewModel.chartOrientation,
      start: 1.0,
      end: 1.0,
    );

    /// todo-00-next : Separate creation of pointContainers in this section up to before padding, from the padding,
    ///                AND MOST IMPORTANT FROM THE WRAPpING IN TransposingRoller.Column . THIS MAY MEAN TO ADD ANOTHER INNER MAKER METHOD.
    ///                THE GOAL IS TO SHARE THE (ARGUABLY DIFFICULT BUT NICELY ABSTRACTED) CREATION OF   List<PointContainer> pointContainers
    ///                with extensions, [BarChartDataColumnPointsBar] and [LineChartDataColumnPointsBar]

    // Creates a list of [PointContainer]s from all points of the passed [dataColumnModel], pads each [PointContainer].
    // The code in [clsPointToNullableContainerForSign] contains logic that processes all combinations of
    // stacked and nonStacked, and positive and negative, distinctly.
    List<PointContainer> pointContainers = dataColumnModel.pointModelList
        // Map applies function converting the [PointModel] to [PointContainer],
        // calling the hook [MyBarChartViewModelPointContainer]
        .map(clsPointToNullableContainerForSign(barsAreaSign))
        // Filters in only non null containers (impl detail of clsPointToNullableContainerForSign)
        .where((containerElm) => containerElm != null)
        .map((containerElm) => containerElm!)
        .toList();

    List<Padder> paddedPointContainers = pointContainers
        .map((pointContainer) => Padder(
              edgePadding: pointRectSidePad,
              child: pointContainer,
            ))
        .toList();

    // todo-00-next : separate this section into it's own overridable method, and inject children, rather
    //                than creating children above.

    TransposingRoller pointContainersLayouter;
    switch (chartViewModel.chartStacking) {
      case ChartStacking.stacked:
        pointContainersLayouter = TransposingRoller.Column(
          chartOrientation: chartViewModel.chartOrientation,
          mainAxisAlign: Align.start, // default
          crossAxisAlign: Align.center, // default
          // For stacked, do NOT put weights, as in main direction, each bar has no limit.
          constraintsDivideMethod: ConstraintsDivideMethod.noDivision, // default
          isMainAxisAlignFlippedOnTranspose: false, // do not flip to Align.end, as children have no weight=no divide
          children: barsAreaSign == Sign.positiveOr0 ? paddedPointContainers.reversed.toList() : paddedPointContainers,
        );
        break;
      case ChartStacking.nonStacked:
        pointContainersLayouter = TransposingRoller.Row(
          chartOrientation: chartViewModel.chartOrientation,
          mainAxisAlign: Align.start, // default
          // column:  sit positive bars at end,   negative bars at start
          // row:     sit positive bars at start, negative bars at end (Transposing will take care of this row flip)
          crossAxisAlign: barsAreaSign == Sign.positiveOr0 ? Align.end : Align.start,
          // For nonStacked leaf rects are in Transposing Row along main axis,
          // this row must divide width to all leaf rects evenly
          constraintsDivideMethod: ConstraintsDivideMethod.evenDivision,
          isMainAxisAlignFlippedOnTranspose: true, // default
          children: paddedPointContainers,
        );
        break;
    }
    // KEEP: Note : if children are passed to super, we need instead: replaceChildrenWith([pointContainersLayouter])
    addChildren([pointContainersLayouter]);
  }

  /// Function closure, when called with argument [barsAreaSign],
  /// returns function with one free parameter, the [PointModel].
  ///
  /// The returned function, when invoked with [PointModel] as a parameter,
  /// returns either a [PointContainer] or null using following logic depending by the currier [barsAreaSign] :
  ///   - If the passed [PointModel.sign] is the same as [barsAreaSign] a [PointContainer] is returned.
  ///     This [PointContainer] is created by the callback [DataColumnPointsBar.makePointContainer];
  ///     it presents the passed [PointModel].
  ///   - else, null is returned. Caller should respond by
  ///
  /// Encapsulates the logic of creating [PointContainer] from [PointModel] for
  /// all possible values of [ChartViewModel.chartStacking] and [barsAreaSign].
  ClsPointToNullableContainer clsPointToNullableContainerForSign(Sign barsAreaSign) {
    return (PointModel pointModelElm) {
      PointContainer? pointContainer;
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
            //   creates a 'ZeroValue' [pointContainer] which has 0 length (along main direction).
            //   This ensures the returned list of PointContainers is the same size for positive and negative, so
            //   their places for positive and negative alternate. Caller adds the [pointContainer] to result list.
            pointContainer = makePointContainerWithZeroValue(
              pointModel: pointModelElm,
            );
          }
          break;
      }
      return pointContainer;
    };
  }

  /// [BarsContainer] client-overridable method hook for extending [PointContainer].
  PointContainer makePointContainer({
    required PointModel pointModel,
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

  /// [BarsContainer] client-overridable method hook for extending [ZeroValueBarPointContainer].
  ///
  /// Likely not needed by any client.
  PointContainer makePointContainerWithZeroValue({
    required PointModel pointModel,
  }) {
    // return BarPointContainer with 0 layoutSize in the value orientation
    if (outerDataContainer.isOuterMakingInnerContainers) {
      return outerDataContainer.makeDeepInnerPointContainerWithZeroValue(
        pointModel: pointModel,
      );
    }
    throw UnimplementedError('$runtimeType.makePointContainerWithZeroValue: '
        'The value of outerDataContainer.isOuterMakingInnerContainers '
        'is false, this method must be overridden in a subclass.');
  }

}

/// Abstract container is a view for it's [pointModel];
/// implementations represent the point model on a line, or as a rectangle in a bar chart.
///
/// Important note: To enable extensibility, two things are being done here:
///   - extends `with WidthSizerLayouterChildMixin, HeightSizerLayouterChildMixin`,
///     for extensions to not have to worry about sizing
///   - signature includes `List<BoxContainer>? children`, to allow extensions to compose from other [BoxContainer]s.
///
abstract class PointContainer extends container_common.ChartAreaContainer  with WidthSizerLayouterChildMixin, HeightSizerLayouterChildMixin {

  PointContainer({
    required super.chartViewModel,
    required this.pointModel,
    required this.outerDataColumnPointsBar,
    // To allow extensions to compose, keep children in signature.
    super.children,
    super.key,
  });

  /// The [PointModel] presented by this container.
  PointModel pointModel;

  final DataColumnPointsBar outerDataColumnPointsBar;

  /// Calculates the [offset] and [layoutSize] of this container to represent the position of
  /// [pointModel] on the chart, for any [ChartOrientation] and [ChartStacking].
  ///
  /// Intended to be invoked during [PointContainer.layout] of this [PointContainer] class or subclasses.
  ///
  /// Transforms (transposes and affmap-s) this [PointModel] to it's [PointOffset] position,
  /// determined by its [PointModel.outputValue].
  ///
  /// Motivation and implementation:
  ///
  ///   1. As this method should be invoked during [PointContainer.layout] by a container (and also owner) layouter
  ///      [outerDataColumnPointsBar] (which creates a [Row] or a [Column] parent layouter for this instance),
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
      inputDataRangeLabelInfosGenerator: chartViewModel.inputLabelsGenerator,
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
      DataRangeLabelInfosGenerator inputLabelsGenerator,
      DataRangeLabelInfosGenerator outputLabelsGenerator,
      PointOffset pixelPointOffset,
      ) {
    var pointOffsetStr = '   pointOffset = ${pointOffset.asCodeConstructor()};\n';
    var callStr = '   pixelPointOffset = pointOffset.affmapToPixelsMaybeTransposeInContextOf(\n'
        '       chartOrientation: ChartOrientation.${chartViewModel.chartOrientation.name},\n'
        '       withinConstraints: ${constraints.asCodeConstructorInsideBox()},\n'
        '       inputDataRange: ${inputLabelsGenerator.dataRange.asCodeConstructor()},\n'
        '       outputDataRange: ${outputLabelsGenerator.dataRange.asCodeConstructor()},\n'
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

