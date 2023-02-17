
// base libraries
import '../container.dart' as container;
import '../view_maker.dart' as view_maker;
import '../iterative_layout_strategy.dart' as strategy;

class NewXContainer extends container.XContainer {
  /// Constructs the container that holds X labels.
  ///
  /// The passed [BoxContainerConstraints] is (assumed) to direct the expansion to fill
  /// all available horizontal space, and only use necessary vertical space.
  NewXContainer({
    required view_maker.ChartViewMaker chartViewMaker,
    strategy.LabelLayoutStrategy? xContainerLabelLayoutStrategy,
  }) : super(
    chartViewMaker: chartViewMaker,
    xContainerLabelLayoutStrategy: xContainerLabelLayoutStrategy,
  );
}

class NewYContainer extends container.YContainer {
  /// Constructs the container that holds X labels.
  ///
  /// The passed [BoxContainerConstraints] is (assumed) to direct the expansion to fill
  /// all available horizontal space, and only use necessary vertical space.
  NewYContainer({
    required view_maker.ChartViewMaker chartViewMaker,
    strategy.LabelLayoutStrategy? xContainerLabelLayoutStrategy,
  }) : super(
    chartViewMaker: chartViewMaker,
  );
}