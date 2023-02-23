// this level base libraries or equivalent
//import '../container.dart' as container;
import '../container_layouter_base.dart' as container_base;
//import '../model/data_model_new.dart' as model;
import '../view_maker.dart' as view_maker;
//import '../layouter_one_dimensional.dart';
import '../../container/container_key.dart';
//import '../../util/util_dart.dart';
//import '../../util/util_labels.dart' show DataRangeLabelInfosGenerator;

/// Base class which manages, lays out, offsets, and paints
/// each [container_base.BoxContainer] used on charts.
///
/// In addition to the [container_base.BoxContainer] roles,
/// this class has access to [chartViewMaker], instance of [ChartViewMaker],
/// which builds the whole [ChartRootContainer] container hierarchy.
///
/// The basic top level chart blocks are:
/// - [ChartRootContainer] - the whole chart
/// - [LegendContainer] - manages the legend
/// - [YContainer] - manages the Y labels layout, which defines:
///   - Y axis label sizes
///   - Y positions of Y axis labels, defined as yTickY.
///     yTicksY s are the Y points of extrapolated data values
///     and also Y points on which the Y labels are centered.
/// - [XContainer] - Equivalent to YContainer, but manages X direction
///   layout and labels.
/// - [DataContainer] and extensions - manages the area which displays:
///   - Data as bar chart, line chart, or other chart type.
///   - Grid (this includes the X and Y axis).
///
/// See [BoxContainer] for discussion of roles of this class.
/// This extension of  [BoxContainer] has the added ability
/// to access the container's parent, which is handled by
/// [chartViewMaker].
abstract class ChartAreaContainer extends container_base.BoxContainer {

  /// Constructs instance, by providing (this derived class required) [chartViewMaker].
  ///
  /// The instance of [ChartViewMaker] is needed on all instances of [ChartAreaContainer]s
  /// tha
  ChartAreaContainer({
    required this.chartViewMaker,
    List<container_base.BoxContainer>? children,
    ContainerKey? key,
    container_base.ConstraintsWeight constraintsWeight = container_base.ConstraintsWeight.defaultWeight,
  }) : super(
    children: children,
    key: key,
    constraintsWeight: constraintsWeight,
  );

  /// The instance of [ChartViewMaker] which makes (produces) instances of
  /// the view root for all [ChartAreaContainer]s, the [ChartRootContainer].
  ///
  /// Needed to be held on this [ChartAreaContainer]s for the legacy subsystem
  /// to reach data model, as well as the view.
  final view_maker.ChartViewMaker chartViewMaker;

  @override
  void buildAndReplaceChildren(covariant container_base.LayoutContext layoutContext) {
    buildAndReplaceChildrenDefault(layoutContext);
  }
}

