import 'dart:ui' as ui show Rect, Offset, Canvas, Paint;
import 'package:flutter/material.dart' as material show Colors;

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

  late ui.Rect _rect;

  /// This default implementation has no children, it is leaf, so override the only method
  /// needed to override for leafs
  @override
  layout_Post_Leaf_SetSize_FromInternals() {
    /// Set some small layoutSize
    /// todo-00-last-last should be changed to 0.0 after we implement the 'pre-layout'
    _rect = const ui.Rect.fromLTWH(0.0, 0.0, 50.0, 50.0);

    layoutSize = _rect.size;
  }

  @override
  void applyParentOffset(LayoutableBox caller, ui.Offset offset) {
    _rect = _rect.shift(offset);
  }

  @override
  paint(ui.Canvas canvas) {
    ui.Paint paint = (ui.Paint()..color = material.Colors.red);
    canvas.drawRect(_rect, paint);
  }
}
