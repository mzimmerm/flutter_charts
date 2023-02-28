import 'dart:ui';

// base libraries
// import 'package:flutter_charts/flutter_charts.dart';
import 'package:flutter_charts/src/chart/container_layouter_base.dart';

// import '../container.dart' as container;
// import '../label_container.dart' as label_container;
// import '../container_layouter_base.dart' as container_base;
import '../view_maker.dart' as view_maker;
// import '../iterative_layout_strategy.dart' as strategy;

// this level libraries
// import '../container_new/axis_container_new.dart' as container_new;
import '../container_new/container_common_new.dart' as container_common_new;

class AxisCornerContainer extends container_common_new.ChartAreaContainer {
  AxisCornerContainer({
    required view_maker.ChartViewMaker chartViewMaker,
    List<BoxContainer>? children,
  }) : super(
          chartViewMaker: chartViewMaker,
          children: children,
        );

  /// This default implementation has no children, it is leaf, so override the only method
  /// needed to override for leafs
  @override
  layout_Post_Leaf_SetSize_FromInternals() {
    /// Set some small layoutSize
    /// todo-00!!!! should be set to 0.0
    layoutSize = const Size(50.0, 50.0);
  }
}
