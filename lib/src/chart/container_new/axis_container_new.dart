import 'dart:ui';

import 'package:vector_math/vector_math.dart' as vector_math show Matrix2;

// base libraries
import '../container_layouter_base.dart';
import '../container_edge_padding.dart';

import '../../coded_layout/chart/container.dart' as container;
import '../label_container.dart';
import '../view_maker.dart';
import '../iterative_layout_strategy.dart';
import '../options.dart';
import '../../util/util_dart.dart';

// this level libraries
import 'container_common_new.dart' as container_common_new;

  class NewXContainer extends container_common_new.ChartAreaContainer implements container.XContainer {
    /// Constructs the container that holds X labels.
    ///
    /// The passed [BoxContainerConstraints] is (assumed) to direct the expansion to fill
    /// all available horizontal space, and only use necessary vertical space.
    NewXContainer({
      required ChartViewMaker chartViewMaker,
      LabelLayoutStrategy? xContainerLabelLayoutStrategy,
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
        Column(children: [
          // todo-00-!!!!! add LineSegment for axis line
          ExternalTicksRow(
            mainAxisExternalTicksLayoutProvider: labelsGenerator.asExternalTicksLayoutProvider(
              externalTickAtPosition: ExternalTickAtPosition.childCenter,
            ),
            children: [
              for (var labelInfo in labelsGenerator.labelInfoList)
                // todo-00-last : check how X labels are created. Wolf, Deer, Owl etc positions seem fine, but how was it created?
                XLabelContainer(
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
    required ChartViewMaker chartViewMaker,
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

    var padGroup = ChartPaddingGroup(fromChartOptions: options);

    List<BoxContainer> children = [
      // Row contains Column of labels and vertical LineSegment for Y axis

      Padder(
        edgePadding: EdgePadding.withSides(
          top: padGroup.heightPadTopOfYAndData(),
          bottom: padGroup.heightPadBottomOfYAndData(),
        ),
        child: Row(children: [
          // todo-00-!!!!! add LineSegment for axis line
          ExternalTicksColumn(
            mainAxisExternalTicksLayoutProvider: labelsGenerator.asExternalTicksLayoutProvider(
              externalTickAtPosition: ExternalTickAtPosition.childCenter,
            ),
            children: [
              for (var labelInfo in labelsGenerator.labelInfoList)
                YLabelContainer(
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
      ),
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

