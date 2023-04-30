/// Library of base containers used in the data area of the chart.
///
/// This includes the top level [DataContainer], as well as classes used
///   to present elements inside it, such as [PointContainer]
import 'dart:ui' as ui show Rect, Paint, Canvas, Size;

// this level base libraries or equivalent
import 'package:flutter_charts/flutter_charts.dart';
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
import '../view_maker.dart';
import '../../morphic/container/container_edge_padding.dart';
import '../../morphic/container/layouter_one_dimensional.dart';
import '../options.dart';
import '../../morphic/container/container_key.dart';

// todo-010-documentation finish

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
///       to the chart at the place where [BarPointContainer] is created. This is possible by the following:
///       - Extend the [ChartViewMaker] to [MyChartViewMaker] and override [ChartViewMaker.makeViewForDataContainer]
///       - Extend the [DataContainer]  to [MyDataContainer]  and override [DataContainer.remakeBarsContainer].
///       - Extend the [BarsContainer]  to [MyBarsContainer]  and override [BarsContainer.remakeCrossPointsBar]
///       - Extend the [CrossPointsBar] to [MyCrossPointsBar] and override [CrossPointsBar.remakePointContainer]
///       - from [MyCrossPointsBar.remakePointContainer] return instance of [MyBarPointContainer]
///       - from [MyBarsContainer.remakeCrossPointsBar] return instance of [MyCrossPointsBar]
///       - from [MyDataContainer.remakeBarsContainer] return instance of [MyBarsContainer]
///       - from [MyChartViewMaker.makeViewForDataContainer] return instance of [MyDataContainer]
///       - Pass [MyChartViewMaker] (instead of [ChartViewMaker] into [FlutterChartPainter] such as [BarChartPainter]
///
class DataContainer extends container_common.ChartAreaContainer {
  DataContainer({
    required ChartViewMaker chartViewMaker,
  }) : super(
          chartViewMaker: chartViewMaker,
        );

  @override
  void buildAndReplaceChildren() {
    var padGroup = ChartPaddingGroup(fromChartOptions: chartViewMaker.chartOptions);

    // Generate list of containers, each container represents one bar (chartViewMaker defines if horizontal or vertical)
    // This is the entry point where this container's [chartViewMaker] starts to generate this container (view).
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
                remakePositiveAndNegativeBarsWithInputAxisLineContainer(
                  // Row with columns of positive values
                  positiveBarsContainer: remakeBarsContainer(
                    barsAreaSign: Sign.positiveOr0,
                  ),
                  // X axis line. Could place in Row with main constraints weight=0.0
                  inputAxisLine: TransposingInputAxisLineContainer(
                    chartViewMaker: chartViewMaker,
                    inputLabelsGenerator: chartViewMaker.inputLabelsGenerator,
                    outputLabelsGenerator: chartViewMaker.outputLabelsGenerator,
                  ),
                  // Row with columns of negative values
                  negativeBarsContainer: remakeBarsContainer(
                    barsAreaSign: Sign.negative,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ]);
  }

  /// [DataContainer] client-overridable method hook for extending [PositiveAndNegativeBarsWithInputAxisLineContainer].
  PositiveAndNegativeBarsWithInputAxisLineContainer remakePositiveAndNegativeBarsWithInputAxisLineContainer({
    required BarsContainer positiveBarsContainer,
    required TransposingInputAxisLineContainer inputAxisLine,
    required BarsContainer negativeBarsContainer,
    ContainerKey? key,
  }) {
    return PositiveAndNegativeBarsWithInputAxisLineContainer(
      chartViewMaker: chartViewMaker,
      positiveBarsContainer: positiveBarsContainer,
      inputAxisLine: inputAxisLine,
      negativeBarsContainer: negativeBarsContainer,
      key: key,
    );
  }

  /// [DataContainer] client-overridable method hook for extending [BarsContainer].
  BarsContainer remakeBarsContainer ({
      required Sign barsAreaSign,
      ContainerKey? key,
  }) {
    return BarsContainer(
      chartViewMaker: chartViewMaker,
      barsAreaSign: barsAreaSign,
      key: key,
    );
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
/// For [ChartViewMaker.chartOrientation] = [ChartOrientation.column] a [Column] is built;
/// for [ChartViewMaker.chartOrientation] = [ChartOrientation.row]    a [Row] is built.
class PositiveAndNegativeBarsWithInputAxisLineContainer extends container_common.ChartAreaContainer {
  PositiveAndNegativeBarsWithInputAxisLineContainer({
    required ChartViewMaker chartViewMaker,
    required this.positiveBarsContainer,
    required this.inputAxisLine,
    required this.negativeBarsContainer,
    ContainerKey? key,
  }) : super(
          chartViewMaker: chartViewMaker, // KEEP comment - no children to super, added in buildAndReplaceChildren
          key: key,
        );

  final BarsContainer positiveBarsContainer;
  final TransposingInputAxisLineContainer inputAxisLine;
  final BarsContainer negativeBarsContainer;

  @override
  void buildAndReplaceChildren() {
    replaceChildrenWith([
      TransposingRoller.Column(
        chartOrientation: chartViewMaker.chartOrientation,
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
/// For [ChartViewMaker.chartOrientation] = [ChartOrientation.column] a [Row]    of (column) bars is built;
/// for [ChartViewMaker.chartOrientation] = [ChartOrientation.row]    a [Column] of (row)    bars is built.
class BarsContainer extends container_common.ChartAreaContainer {

  BarsContainer({
    required ChartViewMaker chartViewMaker,
    required this.barsAreaSign,
    ContainerKey? key,
  }) : super(
          chartViewMaker: chartViewMaker,
          // KEEP - no children passed, they are created in place
          key: key,
        ) {
    if (barsAreaSign == Sign.any) {
      throw StateError('$runtimeType is designed to hold elements with the same sign.');
    }
  }

  /// The sign of bars for which this container is built.
  final Sign barsAreaSign;

  @override
  void buildAndReplaceChildren() {
    EdgePadding barSidePad = EdgePadding.TransposingWithSides(
      chartOrientation: chartViewMaker.chartOrientation,
      start: 5.0,
      end: 5.0,
    );

    // Row with positive or negative Column-bars, depending on [barsAreaSign].
    // As there are two of these rows in a parent Column, each Row is:
    //   - weighted by the ratio of positive / negative range taken up depending on sign
    //   - cross-aligned to top or bottom depending on sign.
    replaceChildrenWith([
      TransposingRoller.Row(
        chartOrientation: chartViewMaker.chartOrientation,
        constraintsWeight: ConstraintsWeight(
          weight: chartViewMaker.outputLabelsGenerator.dataRangeRatioOfPortionWithSign(barsAreaSign),
        ),
        mainAxisAlign: Align.start, // default
        // sit positive bars at end (bottom), negative pop to start (top)
        crossAxisAlign: barsAreaSign == Sign.positiveOr0 ? Align.end : Align.start,
        // column orientation, any stacking, any sign: bars of data are in Row main axis,
        // this Row must divide width to all bars evenly
        constraintsDivideMethod: ConstraintsDivideMethod.evenDivision,
        // children are padded bars; each bar created from one [CrossPointsModel], contains rectangles or lines
        children: chartViewMaker.chartModel.crossPointsModelList
            .map((crossPointsModel) => remakeCrossPointsBar(
                  crossPointsModel: crossPointsModel,
                  barsAreaSign: barsAreaSign,
                ))
            .map((crossPointsBar) => Padder(
                  edgePadding: barSidePad,
                  child: crossPointsBar,
                ))
            .toList(),
      )
    ]);
  }

  /// [BarsContainer] client-overridable method hook for extending [CrossPointsBar].
  CrossPointsBar remakeCrossPointsBar({
    required model.CrossPointsModel crossPointsModel,
    required Sign barsAreaSign,
  }) {
    return CrossPointsBar(
      chartViewMaker: chartViewMaker,
      barsAreaSign: barsAreaSign,
      crossPointsModel: crossPointsModel,
    );
  }

}

/// View for one [model.CrossPointsModel], in other words, a bar of [PointContainer]s.
///
/// Each [PointContainer] views one [model.PointModel] in [model.CrossPointsModel.pointModelList].
///
/// Visually presented as a horizontal or vertical bar with rectangles or lines representing data points.
///
/// See [buildAndReplaceChildren] for how the container is built.
///
class CrossPointsBar extends container_common.ChartAreaContainer {

  CrossPointsBar({
    required ChartViewMaker chartViewMaker,
    required this.barsAreaSign,
    required this.crossPointsModel,
    ContainerKey? key,
  }) : super(
    chartViewMaker: chartViewMaker,
    // KEEP comment - no children to super, added in buildAndReplaceChildren
    key: key,
  );

  final model.CrossPointsModel crossPointsModel;
  final Sign barsAreaSign;

  /// Builds a container for one bar with [PointContainer]s.
  ///
  /// For [ChartViewMaker.chartOrientation] = [ChartOrientation.column] a [Column] is built;
  /// for [ChartViewMaker.chartOrientation] = [ChartOrientation.row]    a [Row] is built.
  @override
  void buildAndReplaceChildren() {

    // Pad around each [PointContainer] before placing it in TransposingRoller
    EdgePadding pointRectSidePad = EdgePadding.TransposingWithSides(
      chartOrientation: chartViewMaker.chartOrientation,
      start: 1.0,
      end: 1.0,
    );
    // Creates a list of [PointContainer]s from all points of the passed [crossPointsModel], pads each [PointContainer].
    // The code in [clsPointToNullableContainerForSign] contains logic that processes all combinations of
    // stacked and nonStacked, and positive and negative, distinctly.
    List<PointContainer> pointContainers = crossPointsModel.pointModelList
    // Map applies function converting [PointModel] to [PointContainer],
    // calling the hook [remakePointContainer]
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
    switch (chartViewMaker.chartStacking) {
      case ChartStacking.stacked:
        pointContainersLayouter = TransposingRoller.Column(
          chartOrientation: chartViewMaker.chartOrientation,
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
          chartOrientation: chartViewMaker.chartOrientation,
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
  /// returns [PointContainer] yielding function with one free parameter, the [PointModel].
  ///
  /// Encapsulates the logic of creating [PointContainer] from [PointModel] for
  /// all possible values of [ChartViewMaker.chartStacking] and [barsAreaSign].
  ClsPointToNullableContainer clsPointToNullableContainerForSign(Sign barsAreaSign) {
    return (model.PointModel pointModelElm) {
      PointContainer? pointContainer;
      switch (chartViewMaker.chartStacking) {
        case ChartStacking.stacked:
          if (barsAreaSign == pointModelElm.sign) {
            // Note: this [remakePointContainer] is called (all the way from top) once for positive, once for negative;
            // For [pointModelElm] with the same sign as the stack sign being built,
            //   creates a [pointContainer] from the [pointModelElm]. Caller adds the [pointContainer] to result list.
            pointContainer = remakePointContainer(
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
            pointContainer = remakePointContainer(
              pointModel: pointModelElm,
            );
          } else {
            // For points [pointModelElm] with opposite sign to the stack being built,
            //   creates a 'ZeroValue' [pointContainer] which has 0 length (along main direction).
            //   This ensures the returned list of PointContainers is the same size for positive and negative, so
            //   their places for positive and negative alternate. Caller adds the [pointContainer] to result list.
            pointContainer = remakePointContainerWithZeroValue(
              pointModel: pointModelElm,
            );
          }
          break;
      }
      return pointContainer;
    };
  }

  /// [BarsContainer] client-overridable method hook for extending [PointContainer].
  PointContainer remakePointContainer({
    required model.PointModel pointModel,
  }) {
    return BarPointContainer(
      pointModel: pointModel,
      chartViewMaker: chartViewMaker,
    );
  }

  /// [BarsContainer] client-overridable method hook for extending [ZeroValueBarPointContainer].
  ///
  /// Likely not needed by any client.
  PointContainer remakePointContainerWithZeroValue({
    required model.PointModel pointModel,
  }) {
    // return BarPointContainer with 0 layoutSize in the value orientation
    return ZeroValueBarPointContainer(
      pointModel: pointModel,
      chartViewMaker: chartViewMaker,
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
    required ChartViewMaker chartViewMaker,
    // To allow extensions to compose, keep children in signature.
    List<BoxContainer>? children,
    ContainerKey? key,
  }) : super(
    chartViewMaker: chartViewMaker,
    children: children,
    key: key,
  );

  /// The [PointModel] presented by this container.
  model.PointModel pointModel;
}

/// Container presents it's [pointModel] as a point on a line, or a rectangle in a bar chart.
///
/// See [LegendIndicatorRectContainer] for similar implementation.
///
/// It implements the mixins [WidthSizerLayouterChildMixin] and [HeightSizerLayouterChildMixin]
/// needed to lextr the [pointModel] to a position on the chart.
class BarPointContainer extends PointContainer {

  /// Generate view for this single leaf [PointModel] - a single [BarPointContainer].
  ///
  /// Note: On the leaf, we return single element by agreement, higher ups return lists.
  BarPointContainer({
    required model.PointModel pointModel,
    required ChartViewMaker chartViewMaker,
    List<BoxContainer>? children,
    ContainerKey? key,
  }) : super(
    pointModel: pointModel,
    chartViewMaker: chartViewMaker,
    children: children,
    key: key,
  );

  /// Full [layout] implementation calculates and sets the pixel width and height of the Rectangle
  /// that represents data.
  @override
  void layout() {
    buildAndReplaceChildren();

    DataRangeLabelInfosGenerator inputLabelsGenerator = chartViewMaker.inputLabelsGenerator;
    DataRangeLabelInfosGenerator outputLabelsGenerator = chartViewMaker.outputLabelsGenerator;

    // Create PointOffset from this [pointModel] by giving it a range,
    // positions the [pointModel] on the x axis on it's label x coordinate.
    // The [pointOffset] can be lextr-ed to it's target value depending on chart direction.
    PointOffset pointOffset = pointModel.asPointOffsetOnInputRange(
          dataRangeLabelInfosGenerator: inputLabelsGenerator,
        );
    PointOffset pixelPointOffset = pointOffset.lextrToPixelsMaybeTransposeInContextOf(
      chartOrientation: chartViewMaker.chartOrientation,
      constraintsOnImmediateOwner: constraints,
      inputDataRange: inputLabelsGenerator.dataRange,
      outputDataRange: outputLabelsGenerator.dataRange,
      heightToLextr: heightToLextr,
      widthToLextr: widthToLextr,
      isLextrUseSizerInsteadOfConstraint: false,
    );

    // In the bar container, we only need the [pixelPointOffset.barPointRectSize]
    // which is the [layoutSize] of the rectangle presenting the point.
    // The offset, [pixelPointOffset] is used in line chart.
    //
    // The [layoutSize] is also the size of the rectangle, which, when positioned
    // by the parent layouter, is the pixel-lextr-ed value of the [pointModel]
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
}

/// A dummy [BarPointContainer] with zero [layoutSize] in the direction of the main axis.,
class ZeroValueBarPointContainer extends BarPointContainer {

  ZeroValueBarPointContainer({
    required model.PointModel pointModel,
    required ChartViewMaker chartViewMaker,
    List<BoxContainer>? children,
    ContainerKey? key,
  }) : super(
    pointModel: pointModel,
    chartViewMaker: chartViewMaker,
    children: children,
    key: key,
  );

  /// Layout this container by calling super, then set the [layoutSize] in the value direction
  /// (owner layouter mainAxisDirection) to be zero.
  ///
  /// This container is a stand-in for Not-Stacked value point, on the positive or negative side against
  /// where the actual value bar is shown.
  // todo-014-functional : The algorithm is copied from super, just adding the piece of logic setting layoutSize 0.0 in the value direction.
  //                 This is bad for both performance and principle. Find a faster, clearer way - basically we need the logic from super to calculate layoutSize in the cross-value direction,
  //                 maybe not even that.
  @override
  void layout() {
    buildAndReplaceChildren();

    DataRangeLabelInfosGenerator inputLabelsGenerator = chartViewMaker.inputLabelsGenerator;
    DataRangeLabelInfosGenerator outputLabelsGenerator = chartViewMaker.outputLabelsGenerator;

    // Create PointOffset from this [pointModel] by giving it a range,
    // positions the [pointModel] on the x axis on it's label x coordinate.
    // The [pointOffset] can be lextr-ed to it's target value depending on chart direction.
    PointOffset pointOffset = pointModel.asPointOffsetOnInputRange(
      dataRangeLabelInfosGenerator: inputLabelsGenerator,
    );
    PointOffset pixelPointOffset = pointOffset.lextrToPixelsMaybeTransposeInContextOf(
      chartOrientation: chartViewMaker.chartOrientation,
      constraintsOnImmediateOwner: constraints,
      inputDataRange: inputLabelsGenerator.dataRange,
      outputDataRange: outputLabelsGenerator.dataRange,
      heightToLextr: heightToLextr,
      widthToLextr: widthToLextr,
      isLextrUseSizerInsteadOfConstraint: false,
    );

    // Make the layoutSize zero in the direction of the chart orientation
    layoutSize = pixelPointOffset.barPointRectSize.fromMySideAlongPassedAxisOtherSideAlongCrossAxis(
      axis: chartViewMaker.chartOrientation.inputDataAxisOrientation,
      other: const ui.Size(0.0, 0.0),
    );
  }

  @override
  paint(ui.Canvas canvas) {
    return;
  }
}
