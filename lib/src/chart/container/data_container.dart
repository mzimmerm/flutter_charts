/// Library of base containers used in the data area of the chart.
///
/// This includes the top level [DataContainer], as well as classes used
///   to present elements inside it, such as [PointContainer]
import 'dart:ui' as ui show Rect, Paint, Canvas, Size;

// this level base libraries or equivalent
import 'package:flutter_charts/src/chart/painter.dart';
import 'package:flutter_charts/src/util/extensions_flutter.dart';

import '../../morphic/container/chart_support/chart_style.dart';
import '../../morphic/container/morphic_dart_enums.dart' show Sign;
import '../../morphic/ui2d/point.dart';
import '../model/label_model.dart';
import 'axis_container.dart';
import 'container_common.dart' as container_common;
import '../../morphic/container/container_layouter_base.dart';
import '../model/data_model.dart' as model;
import '../view_model.dart';
import '../../morphic/container/container_edge_padding.dart';
import '../../morphic/container/layouter_one_dimensional.dart';
import '../options.dart';
import '../../morphic/container/container_key.dart';


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
///         - override [MyDataContainer.isMakeComponentsForwardedToOwner] to true.
///         - 1.5, 1.6 and 1.7 are the same
///
class DataContainer extends container_common.ChartAreaContainer {
  DataContainer({
    required ChartViewModel chartViewModel,
  }) : super(
          chartViewModel: chartViewModel,
        );

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
                    ownerDataContainer: this,
                  ),
                  // X axis line. Could place in Row with main constraints weight=0.0
                  inputAxisLine: TransposingInputAxisLineContainer(
                    chartViewModel: chartViewModel,
                    inputLabelsGenerator: chartViewModel.inputLabelsGenerator,
                    outputLabelsGenerator: chartViewModel.outputLabelsGenerator,
                  ),
                  // Row with columns of negative values
                  negativeBarsContainer: makeInnerBarsContainer(
                    barsAreaSign: Sign.negative,
                    ownerDataContainer: this,
                  ),
                  ownerDataContainer: this,
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

  bool isMakeComponentsForwardedToOwner = false;

  /// [DataContainer] client-overridable method hook for extending [PositiveAndNegativeBarsWithInputAxisLineContainer].
  ContainerForBothBarsAreasAndInputAxisLine makeInnerContainerForBothBarsAreasAndInputAxisLine({
    required BarsContainer positiveBarsContainer,
    required TransposingInputAxisLineContainer inputAxisLine,
    required BarsContainer negativeBarsContainer,
    required DataContainer ownerDataContainer,
    ContainerKey? key,
  }) {
    return ContainerForBothBarsAreasAndInputAxisLine(
      chartViewModel: chartViewModel,
      positiveBarsContainer: positiveBarsContainer,
      inputAxisLine: inputAxisLine,
      negativeBarsContainer: negativeBarsContainer,
      ownerDataContainer: ownerDataContainer,
      key: key,
    );
  }

  /// [DataContainer] client-overridable method hook for extending [BarsContainer].
  BarsContainer makeInnerBarsContainer ({
      required DataContainer ownerDataContainer,
      required Sign barsAreaSign,
      ContainerKey? key,
  }) {
    return BarsContainer(
      chartViewModel: chartViewModel,
      ownerDataContainer: ownerDataContainer,
      barsAreaSign: barsAreaSign,
      key: key,
    );
  }

  /// Child component makers delegated to owner [DataContainer] -----------
  ///
  /// For now, throw [UnimplementedError]. Extensions who want to change something about the chart view elements
  /// should override the view elements returned, then override these methods, and create and return from them
  /// the overridden view elements.
  ///
  DataColumnPointsBar makeDeepInnerDataColumnPointsBar({
    required model.DataColumnModel dataColumnModel,
    // todo-00-done : required DataContainer ownerDataContainer,
    required BarsContainer ownerBarsContainer,
    required Sign barsAreaSign,
  }) {
    throw UnimplementedError('Must be implemented if invoked directly, or if isMakeComponentsForwardedToOwner is true');
  }

  PointContainer makeDeepInnerPointContainer({
    required model.PointModel pointModel,
  }) {
    throw UnimplementedError('Must be implemented if invoked directly, or if isMakeComponentsForwardedToOwner is true');
  }

  /// [BarsContainer] client-overridable method hook for extending [ZeroValueBarPointContainer].
  ///
  /// Likely not needed by any client.
  PointContainer makeDeepInnerPointContainerWithZeroValue({
    required model.PointModel pointModel,
  }) {
    throw UnimplementedError('Must be implemented if invoked directly, or if isMakeComponentsForwardedToOwner is true');
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
    required ChartViewModel chartViewModel,
    required this.positiveBarsContainer,
    required this.inputAxisLine,
    required this.negativeBarsContainer,
    required this.ownerDataContainer,
    ContainerKey? key,
  }) : super(
          chartViewModel: chartViewModel, // KEEP comment - no children to super, added in buildAndReplaceChildren
          key: key,
        );

  final BarsContainer positiveBarsContainer;
  final TransposingInputAxisLineContainer inputAxisLine;
  final BarsContainer negativeBarsContainer;

  /// non-child, kept to establish inner/outer ownership
  final DataContainer ownerDataContainer;

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
    required ChartViewModel chartViewModel,
    required this.ownerDataContainer,
    required this.barsAreaSign,
    ContainerKey? key,
  }) : super(
          chartViewModel: chartViewModel,
          // No children passed, they are created in place
          key: key,
        ) {
    if (barsAreaSign == Sign.any) {
      throw StateError('$runtimeType is designed to hold elements with the same sign.');
    }
  }

  /// The sign of bars for which this container is built.
  final Sign barsAreaSign;
  final DataContainer ownerDataContainer;

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
                  ownerDataContainer: ownerDataContainer,
                  // todo-00 : added and removed : ownerBarsContainer: this,
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
    required model.DataColumnModel dataColumnModel,
    required DataContainer ownerDataContainer,
    required Sign barsAreaSign,
  }) {
    if (ownerDataContainer.isMakeComponentsForwardedToOwner) {
      return ownerDataContainer.makeDeepInnerDataColumnPointsBar(
        dataColumnModel: dataColumnModel,
        // todo-00-done : ownerDataContainer: ownerDataContainer,
        ownerBarsContainer: this,
        barsAreaSign: barsAreaSign,
      );
    }
    return DataColumnPointsBar(
      chartViewModel: chartViewModel,
      ownerDataContainer: ownerDataContainer,
      barsAreaSign: barsAreaSign,
      dataColumnModel: dataColumnModel,
    );
  }

}

/// View for one [model.DataColumnModel], in other words, a bar of [PointContainer]s.
///
/// Each [PointContainer] views one [model.PointModel] in [model.DataColumnModel.pointModelList].
///
/// Each instance is visually presented as a horizontal or vertical bar
/// displaying [PointContainer]s as rectangles or lines.
/// Each rectangle or line represents a data point [model.PointModel].
///
/// See [buildAndReplaceChildren] for how the container is built.
///
class DataColumnPointsBar extends container_common.ChartAreaContainer {

  DataColumnPointsBar({
    required ChartViewModel chartViewModel,
    required this.ownerDataContainer,
    required this.barsAreaSign,
    required this.dataColumnModel,
    ContainerKey? key,
  }) : super(
    chartViewModel: chartViewModel,
    // KEEP comment - no children to super, added in buildAndReplaceChildren
    key: key,
  );

  final model.DataColumnModel dataColumnModel;
  final DataContainer ownerDataContainer;
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
  /// returns function with one free parameter, the [model.PointModel].
  ///
  /// The returned function, when invoked with [model.PointModel] as a parameter,
  /// returns either a [PointContainer] or null using following logic depending by the currier [barsAreaSign] :
  ///   - If the passed [model.PointModel.sign] is the same as [barsAreaSign] a [PointContainer] is returned.
  ///     This [PointContainer] is created by the callback [DataColumnPointsBar.makePointContainer];
  ///     it presents the passed [PointModel].
  ///   - else, null is returned. Caller should respond by
  ///
  /// Encapsulates the logic of creating [PointContainer] from [PointModel] for
  /// all possible values of [ChartViewModel.chartStacking] and [barsAreaSign].
  ClsPointToNullableContainer clsPointToNullableContainerForSign(Sign barsAreaSign) {
    return (model.PointModel pointModelElm) {
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
    required model.PointModel pointModel,
  }) {
    if (ownerDataContainer.isMakeComponentsForwardedToOwner) {
      return ownerDataContainer.makeDeepInnerPointContainer(
        pointModel: pointModel,
      );
    }
    return BarPointContainer(
      pointModel: pointModel,
      chartViewModel: chartViewModel,
      ownerDataColumnPointsBar: this, // todo-00-done : added
    );
  }

  /// [BarsContainer] client-overridable method hook for extending [ZeroValueBarPointContainer].
  ///
  /// Likely not needed by any client.
  PointContainer makePointContainerWithZeroValue({
    required model.PointModel pointModel,
  }) {
    // return BarPointContainer with 0 layoutSize in the value orientation
    if (ownerDataContainer.isMakeComponentsForwardedToOwner) {
      return ownerDataContainer.makeDeepInnerPointContainerWithZeroValue(
        pointModel: pointModel,
      );
    }
    return ZeroValueBarPointContainer(
      pointModel: pointModel,
      chartViewModel: chartViewModel,
      ownerDataColumnPointsBar: this, // todo-00-done : added
    );
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
    required this.pointModel,
    required ChartViewModel chartViewModel,
    required this.ownerDataColumnPointsBar, // todo-00-done added
    // To allow extensions to compose, keep children in signature.
    List<BoxContainer>? children,
    ContainerKey? key,
  }) : super(
    chartViewModel: chartViewModel,
    children: children,
    key: key,
  );

  /// The [PointModel] presented by this container.
  model.PointModel pointModel;

  final DataColumnPointsBar ownerDataColumnPointsBar;
}

/// Container presents it's [pointModel] as a point on a line, or a rectangle in a bar chart.
///
/// See [LegendIndicatorRectContainer] for similar implementation.
///
/// It implements the mixins [WidthSizerLayouterChildMixin] and [HeightSizerLayouterChildMixin]
/// needed to affmap the [pointModel] to a position on the chart.
class BarPointContainer extends PointContainer {

  /// Generate view for this single leaf [PointModel] - a single [BarPointContainer].
  ///
  /// Note: On the leaf, we return single element by agreement, higher ups return lists.
  BarPointContainer({
    required model.PointModel pointModel,
    required ChartViewModel chartViewModel,
    required DataColumnPointsBar ownerDataColumnPointsBar, // todo-00-done added
    List<BoxContainer>? children,
    ContainerKey? key,
  }) : super(
    pointModel: pointModel,
    chartViewModel: chartViewModel,
    ownerDataColumnPointsBar: ownerDataColumnPointsBar, // todo-00-done added
    children: children,
    key: key,
  );

  /// Full [layout] implementation calculates and sets the pixel width and height of the Rectangle
  /// that represents data.
  @override
  void layout() {
    buildAndReplaceChildren();

    DataRangeLabelInfosGenerator inputLabelsGenerator = chartViewModel.inputLabelsGenerator;
    DataRangeLabelInfosGenerator outputLabelsGenerator = chartViewModel.outputLabelsGenerator;

    // Create PointOffset from this [pointModel] by giving it a range,
    // positions the [pointModel] on the x axis on it's label x coordinate.
    // The [pointOffset] can be affmap-ed to it's target value depending on chart direction.
    PointOffset pointOffset = pointModel.asPointOffsetOnInputRange(
      dataRangeLabelInfosGenerator: inputLabelsGenerator,
    );
    PointOffset pixelPointOffset = pointOffset.affmapToPixelsMaybeTransposeInContextOf(
      chartOrientation: chartViewModel.chartOrientation,
      constraintsOnImmediateOwner: constraints,
      inputDataRange: inputLabelsGenerator.dataRange,
      outputDataRange: outputLabelsGenerator.dataRange,
      sizerHeight: sizerHeight,
      sizerWidth: sizerWidth,
    );
    // KEEP generateTestCode(pointOffset, inputLabelsGenerator, outputLabelsGenerator, pixelPointOffset);

    // In the bar container, we only need the [pixelPointOffset.barPointRectSize]
    // which is the [layoutSize] of the rectangle presenting the point.
    // The offset, [pixelPointOffset] is used in line chart.
    //
    // The [layoutSize] is also the size of the rectangle, which, when positioned
    // by the parent layouter, is the pixel-affmap-ed value of the [pointModel]
    // in the main axis direction of the layouter which owns this [BarPointContainer].
    layoutSize = pixelPointOffset.barPointRectSize;
  }

  @override paint(ui.Canvas canvas) {

    ui.Rect rect = offset & layoutSize;

    // Rectangle color should be from pointModel's color.
    ui.Paint paint = ui.Paint();
    paint.color = pointModel.color;

    canvas.drawRect(rect, paint);
  }

  /// Generates code for testing.
  void generateTestCode(
      PointOffset pointOffset,
      DataRangeLabelInfosGenerator inputLabelsGenerator,
      DataRangeLabelInfosGenerator outputLabelsGenerator,
      PointOffset pixelPointOffset,
      ) {
    var pointOffsetStr = '   pointOffset = ${pointOffset.asCodeConstructor()};\n';
    var callStr = '   pixelPointOffset = pointOffset.affmapToPixelsMaybeTransposeInContextOf(\n'
        '       chartOrientation: ChartOrientation.${chartViewModel.chartOrientation.name},\n'
        '       constraintsOnImmediateOwner: ${constraints.asCodeConstructorInsideBox()},\n'
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

/// A zero-height (thus 'invisible') [BarPointContainer] extension.
///
/// Has zero [layoutSize] in the direction of the input data axis. See [layout] for details.
class ZeroValueBarPointContainer extends BarPointContainer {

  ZeroValueBarPointContainer({
    required model.PointModel pointModel,
    required ChartViewModel chartViewModel,
    required DataColumnPointsBar ownerDataColumnPointsBar, // todo-00-done added
   List<BoxContainer>? children,
    ContainerKey? key,
  }) : super(
    pointModel: pointModel,
    chartViewModel: chartViewModel,
    ownerDataColumnPointsBar: ownerDataColumnPointsBar, // todo-00-done added
    children: children,
    key: key,
  );

  /// Layout this container by calling super, then set the [layoutSize] in the value direction
  /// (owner layouter mainAxisDirection) to be zero.
  ///
  /// To be precise, the value direction is defined as input data axis, [ChartOrientation.inputDataAxisOrientation].
  ///
  /// This container is a stand-in for Not-Stacked value point, on the positive or negative side against
  /// where the actual value bar is shown.
  // todo-014-functional : The algorithm is copied from super, just adding the piece of logic setting layoutSize 0.0 in the value direction.
  //                 This is bad for both performance and principle. Find a faster, clearer way - basically we need the logic from super to calculate layoutSize in the cross-value direction,
  //                 maybe not even that.
  @override
  void layout() {
    buildAndReplaceChildren();

    DataRangeLabelInfosGenerator inputLabelsGenerator = chartViewModel.inputLabelsGenerator;
    DataRangeLabelInfosGenerator outputLabelsGenerator = chartViewModel.outputLabelsGenerator;

    // Create PointOffset from this [pointModel] by giving it a range,
    // positions the [pointModel] on the x axis on it's label x coordinate.
    // The [pointOffset] can be affmap-ed to it's target value depending on chart direction.
    PointOffset pointOffset = pointModel.asPointOffsetOnInputRange(
      dataRangeLabelInfosGenerator: inputLabelsGenerator,
    );
    PointOffset pixelPointOffset = pointOffset.affmapToPixelsMaybeTransposeInContextOf(
      chartOrientation: chartViewModel.chartOrientation,
      constraintsOnImmediateOwner: constraints,
      inputDataRange: inputLabelsGenerator.dataRange,
      outputDataRange: outputLabelsGenerator.dataRange,
      sizerHeight: sizerHeight,
      sizerWidth: sizerWidth,
    );

    // Make the layoutSize zero in the direction of the chart orientation
    layoutSize = pixelPointOffset.barPointRectSize.fromMySideAlongPassedAxisOtherSideAlongCrossAxis(
      axis: chartViewModel.chartOrientation.inputDataAxisOrientation,
      other: const ui.Size(0.0, 0.0),
    );
  }

  @override
  paint(ui.Canvas canvas) {
    return;
  }
}
