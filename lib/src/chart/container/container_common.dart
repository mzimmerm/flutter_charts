// this level base libraries or equivalent
import '../../morphic/container/container_layouter_base.dart' as container_base;
import '../view_model/view_model.dart' as view_model;
import '../../morphic/container/container_key.dart';
import '../iterative_layout_strategy.dart' as strategy show LabelLayoutStrategy;

/// Base class which manages, lays out, offsets, and paints
/// all [container_base.BoxContainer] derived classes used on charts.
///
/// In addition to the [container_base.BoxContainer] responsibilities,
/// this class has access to [chartViewModel], instance of [ChartViewModel],
/// which builds the whole [ChartRootContainer] container hierarchy.
///
/// The basic top level chart blocks are:
/// - [ChartRootContainer] - the whole chart
/// - [LegendContainer] - manages the legend
/// - [VerticalAxisContainer] - manages the Y labels layout, which defines:
///   - Y axis label sizes
///   - Y positions of Y axis labels, defined as yTickY.
///     yTicksY s are the Y points of extrapolated data values
///     and also Y points on which the Y labels are centered.
/// - [HorizontalAxisContainer] - Equivalent to VerticalAxisContainer, but manages X direction
///   layout and labels.
/// - [DataContainer] and extensions - manages the area which displays:
///   - Data as bar chart, line chart, or other chart type.
///   - Grid (this includes the X and Y axis).
///
/// See [BoxContainer] for discussion of roles of this class.
/// This extension of  [BoxContainer] has the added ability
/// to access the container's parent, which is handled by
/// [chartViewModel].
abstract class ChartAreaContainer extends container_base.PositioningBoxContainer {

  /// Constructs instance, by providing (this derived class required) [chartViewModel].
  ///
  /// The instance of [ChartViewModel] is needed on all instances of [ChartAreaContainer]s
  /// tha
  ChartAreaContainer({
    required this.chartViewModel,
    List<container_base.BoxContainer>? children,
    ContainerKey? key,
    container_base.ConstraintsWeight constraintsWeight = container_base.ConstraintsWeight.defaultWeight,
  }) : super(
    children: children,
    key: key,
    constraintsWeight: constraintsWeight,
  );

  /// The instance of [ChartViewModel] which makes (produces) the chart view:
  /// both the view root, the [ChartRootContainer], and all [ChartAreaContainer]s inside.
  ///
  /// Needed to be held on this [ChartAreaContainer]s for the legacy subsystem
  /// to reach data model, as well as the view.
  // todo-02-design-legacy : can we move this on a CL class if only needed by legacy?
  final view_model.ChartViewModel chartViewModel;

  // todo-later : Go over all usages, and move child building to this method
  //              from constructors.
  //              In particular: why do we construct in buildAndReplaceChildren in DataContainer,
  //                             while construct in constructor in NewVerticalAxisContainer?
  //                             Etc
  @override
  void buildAndReplaceChildren() {
    buildAndReplaceChildrenDefault();
  }
}


/// [ChartAreaContainer] which provides ability to connect [LabelLayoutStrategy] to [BoxContainer].
///
/// Extensions can create [ChartAreaContainer]s with default or custom layout strategy.
abstract class AdjustableLabelsChartAreaContainer extends ChartAreaContainer implements AdjustableLabels {
  /// The strategy of this [AdjustableLabelsChartAreaContainer] and all instances
  /// is shared from the (single) [ChartViewModel.inputLabelLayoutStrategyInst].
  strategy.LabelLayoutStrategy get labelLayoutStrategy => chartViewModel.inputLabelLayoutStrategyInst;

  AdjustableLabelsChartAreaContainer({
    required view_model.ChartViewModel chartViewModel,
  }) : super(
          chartViewModel: chartViewModel,
        ) {
    chartViewModel.inputLabelLayoutStrategyInst.onContainer(this);
  }
}

/// A marker of container with adjustable contents,
/// such as labels that can be skipped.
// todo-04-morph LabelLayoutStrategy should be a member of AdjustableContainer, not
//          in AdjustableLabelsChartAreaContainer
//          Also, AdjustableLabels and perhaps AdjustableLabelsChartAreaContainer should be a mixin.
//          But Dart bug #25742 does not allow mixins with named parameters.

abstract class AdjustableLabels {
  bool labelsOverlap();
}

/// The behavior mixin class allows to plug in to the [ChartRootContainer] a behavior that is specific for a line chart
/// or vertical bar chart.
///
/// The behavior is plugged in the [view_model.ChartViewModel].
abstract class ChartBehavior {
  /// Behavior allows to start Y axis at data minimum (rather than 0).
  ///
  /// The request is asked by [DataContainerOptions.extendAxisToOriginRequested],
  /// but the implementation of this behavior must confirm it.
  /// See the extensions of this class for overrides of this method.
  ///
  /// [ChartBehavior] is mixed in to [ChartRootContainer]. This method
  /// is implemented by concrete [LineChartRootContainer] and [BarChartRootContainer].
  /// - In the stacked containers, such as [BarChartRootContainer], it should return [false],
  ///   as stacked values should always start at zero, because stacked charts must show absolute values.
  ///   See [BarChartRootContainer.extendAxisToOrigin].
  /// - In the unstacked containers such as  [LineChartRootContainer], this is usually implemented to
  ///   return the option [DataContainerOptions.extendAxisToOriginRequested],
  ///   see [LineChartRootContainer.extendAxisToOrigin].
  ///
  bool get extendAxisToOrigin;
}



