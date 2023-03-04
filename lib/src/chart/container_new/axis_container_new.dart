import 'dart:ui';

import 'package:vector_math/vector_math.dart' as vector_math show Matrix2;

// base libraries
import 'package:flutter_charts/flutter_charts.dart';
import 'package:flutter_charts/src/chart/container_layouter_base.dart';

import '../container.dart' as container;
import '../label_container.dart' as label_container;
import '../container_layouter_base.dart' as container_base;
import '../view_maker.dart' as view_maker;
import '../iterative_layout_strategy.dart' as strategy;

// this level libraries
// import '../container_new/axis_container_new.dart' as container_new;
import '../container_new/container_common_new.dart' as container_common_new;

  class NewXContainer extends container_common_new.ChartAreaContainer implements container.XContainer {
    /// Constructs the container that holds X labels.
    ///
    /// The passed [BoxContainerConstraints] is (assumed) to direct the expansion to fill
    /// all available horizontal space, and only use necessary vertical space.
    NewXContainer({
      required view_maker.ChartViewMaker chartViewMaker,
      strategy.LabelLayoutStrategy? xContainerLabelLayoutStrategy,
    }) : super(
      chartViewMaker: chartViewMaker,
    ) {
      var options = chartViewMaker.chartOptions;
      var labelsGenerator = chartViewMaker.xLabelsGenerator;

      // Initially all [LabelContainer]s share same text style object from options.
      LabelStyle labelStyle = LabelStyle(
        textStyle: options.labelCommonOptions.labelTextStyle,
        textDirection: options.labelCommonOptions.labelTextDirection,
        textAlign: options.labelCommonOptions.labelTextAlign, // center text
        textScaleFactor: options.labelCommonOptions.labelTextScaleFactor,
      );

      List<BoxContainer> children = [
        container_base.Column(children: [
          // todo-00-!!!!! add LineSegment for axis line
          container_base.ExternalTicksRow(
            mainAxisExternalTicksLayoutProvider: labelsGenerator.asExternalTicksLayoutProvider(
              externalTickAt: ExternalTickAt.childCenter,
            ),
            children: [
              for (var labelInfo in labelsGenerator.labelInfoList)
                // todo-00-last : check how X labels are created. Wolf, Deer, Owl etc positions seem fine, but how was it created?
                label_container.XLabelContainer(
                  chartViewMaker: chartViewMaker,
                  label: labelInfo.formattedLabel,
                  labelTiltMatrix: vector_math.Matrix2.identity(),
                  // No tilted labels in YContainer
                  labelStyle: labelStyle,
                  options: options,
                  labelInfo: labelInfo,
                  ownerAxisContainer: this,
                )
            ],
          ),
        ]),
      ];

      addChildren(children);
    }


  // --------------- overrides to implement legacy vvvvv
  @override
  Interval get axisPixelsRange => throw UnimplementedError();
  @override
  set axisPixelsRange(Interval _) => throw UnimplementedError();
  @override
  Size get lateReLayoutSize => throw UnimplementedError();
  @override
  set lateReLayoutSize(Size _) => throw UnimplementedError();
  @override
  LabelLayoutStrategy get labelLayoutStrategy => throw UnimplementedError();
  @override
  bool labelsOverlap() => throw UnimplementedError();
  @override
  double get xGridStep => throw UnimplementedError();
  @override
  double get xLabelsMaxHeight => throw UnimplementedError();
  // --------------- overrides to implement legacy ^^^^^
}

class NewYContainer extends container_common_new.ChartAreaContainer implements container.YContainer {

  NewYContainer({
    required view_maker.ChartViewMaker chartViewMaker,
  }) : super(
          chartViewMaker: chartViewMaker,
        ) {

    var options = chartViewMaker.chartOptions;
    var labelsGenerator = chartViewMaker.yLabelsGenerator;

    // Initially all [LabelContainer]s share same text style object from options.
    LabelStyle labelStyle = LabelStyle(
      textStyle: options.labelCommonOptions.labelTextStyle,
      textDirection: options.labelCommonOptions.labelTextDirection,
      textAlign: options.labelCommonOptions.labelTextAlign, // center text
      textScaleFactor: options.labelCommonOptions.labelTextScaleFactor,
    );

    List<BoxContainer> children = [
      // Row contains Column of labels and vertical LineSegment for Y axis
      container_base.Row(children: [
        // todo-00-!!!!! add LineSegment for axis line
        container_base.ExternalTicksColumn(
          mainAxisExternalTicksLayoutProvider: labelsGenerator.asExternalTicksLayoutProvider(
            externalTickAt: ExternalTickAt.childCenter,
          ),
          children: [
            for (var labelInfo in labelsGenerator.labelInfoList)
              label_container.YLabelContainer(
                chartViewMaker: chartViewMaker,
                label: labelInfo.formattedLabel,
                labelTiltMatrix: vector_math.Matrix2.identity(),
                // No tilted labels in YContainer
                labelStyle: labelStyle,
                options: options,
                labelInfo: labelInfo,
                ownerAxisContainer: this,
              )
          ],
        ),
      ]),
    ];

    addChildren(children);
  }

  // --------------- overrides to implement legacy vvvvv
  @override
  Interval get axisPixelsRange => throw StateError('Should not be called for new layouters');
  @override
  set axisPixelsRange(Interval _) => throw StateError('Should not be called for new layouters');
  @override
  double get yLabelsMaxHeight => throw UnimplementedError();
// --------------- overrides to implement legacy ^^^^^^
}

