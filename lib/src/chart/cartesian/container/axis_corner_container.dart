import 'dart:ui' as ui show Rect, Canvas, Paint;
import 'package:flutter/material.dart' as material show Colors;

// this level
import 'package:flutter_charts/src/chart/cartesian/container/container_common.dart' as container_common;

import 'package:flutter_charts/src/chart/view_model/view_model.dart' as view_model;

// base libraries
import 'package:flutter_charts/src/morphic/container/container_layouter_base.dart';



class AxisCornerContainer extends container_common.ChartAreaContainer {
  AxisCornerContainer({
    required view_model.ChartViewModel chartViewModel,
    List<BoxContainer>? children,
  }) : super(
          chartViewModel: chartViewModel,
          children: children,
        );

  /// This default implementation has no children, it is leaf, so override the only method
  /// needed to override for leafs
  @override
  layout_Post_Leaf_SetSize_FromInternals() {
    /// Set some small layoutSize
    ui.Rect rect = const ui.Rect.fromLTWH(0.0, 0.0, 20.0, 20.0);

    layoutSize = rect.size;
  }

  @override
  paint(ui.Canvas canvas) {
    ui.Paint paint = (ui.Paint()..color = material.Colors.red);
    canvas.drawRect(offset & layoutSize, paint);
  }
}
