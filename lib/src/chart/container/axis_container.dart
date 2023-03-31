import 'package:vector_math/vector_math.dart' as vector_math show Matrix2;

// base libraries
import '../../morphic/container/container_layouter_base.dart';
import '../../morphic/container/container_edge_padding.dart';
import '../../morphic/container/label_container.dart';
import '../../morphic/container/chart_support/chart_series_orientation.dart';
//import '../../morphic/ui2d/point.dart';
import '../../morphic/ui2d/point.dart';
import '../chart_label_container.dart';
import '../view_maker.dart';
import '../iterative_layout_strategy.dart';
import '../options.dart';

// this level libraries
import 'container_common.dart' as container_common_new;
import 'line_segment_container.dart';

class XContainer extends container_common_new.ChartAreaContainer {
  /// Constructs the container that holds X labels.
  ///
  /// The passed [BoxContainerConstraints] is (assumed) to direct the expansion to fill
  /// all available horizontal space, and only use necessary vertical space.
  XContainer({
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
      WidthSizerLayouter(
        children: [
          Column(children: [
            ExternalTicksRow(
              mainAxisExternalTicksLayoutProvider: labelsGenerator.asExternalTicksLayoutProvider(
                externalTickAtPosition: ExternalTickAtPosition.childCenter,
              ),
              children: [
                for (var labelInfo in labelsGenerator.labelInfoList)
                  // todo-02-next : check how X labels are created. Wolf, Deer, Owl etc positions seem fine, but how was it created?
                  XLabelContainer(
                    chartViewMaker: chartViewMaker,
                    label: labelInfo.formattedLabel,
                    labelTiltMatrix: vector_math.Matrix2.identity(),
                    // No tilted labels in YContainer
                    labelStyle: labelStyle,
                    labelInfo: labelInfo,
                    ownerChartAreaContainer: this,
                  )
              ],
            ),
          ]),
        ],
      ),
    ];

    addChildren(children);
  }
}

class AxisLineContainer extends LineBetweenPointOffsetsContainer {
  AxisLineContainer({
    super.fromPointOffset,
    super.toPointOffset,
    super.chartSeriesOrientation = ChartSeriesOrientation.column,
    required super.linePaint,
    required super.chartViewMaker,
    super.isLextrOnlyToValueSignPortion = true,
  });
}

class YContainer extends container_common_new.ChartAreaContainer {
  YContainer({
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
        child: HeightSizerLayouter(
          children: [
            Row(children: [
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
                      labelInfo: labelInfo,
                      ownerChartAreaContainer: this,
                    )
                ],
              ),
              // todo-00-last-progress  add LineSegment for axis line
              AxisLineContainer(
                fromPointOffset:
                    const PointOffset(inputValue: 0.0, outputValue: -1000.0, isLextrOnlyToValueSignPortion: false,), // labelsGenerator.dataRange.min),
                toPointOffset: const PointOffset(inputValue: 0.0, outputValue: 3400.0, isLextrOnlyToValueSignPortion: false,), // labelsGenerator.dataRange.max),
                linePaint: chartViewMaker.chartOptions.dataContainerOptions.gridLinesPaint(),
                chartViewMaker: chartViewMaker,
                isLextrOnlyToValueSignPortion: false,
                chartSeriesOrientation: ChartSeriesOrientation.column,
              ),
            ]),
          ],
        ),
      ),
    ];
    addChildren(children);
  }
}
