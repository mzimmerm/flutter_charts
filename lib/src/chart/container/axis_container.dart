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

class AxisLineContainer extends LineBetweenPointOffsetsContainer {
  AxisLineContainer({
    super.fromPointOffset,
    super.toPointOffset,
    super.chartSeriesOrientation = ChartSeriesOrientation.column,
    required super.linePaint,
    required super.chartViewMaker,
    super.isLextrOnlyToValueSignPortion = false,
    super.isLextrUseSizerInsteadOfConstraint = false,
  });
}

class AxisLineContainerOrig20230331 extends LineBetweenPointOffsetsContainer {
  AxisLineContainerOrig20230331({
    super.fromPointOffset,
    super.toPointOffset,
    super.chartSeriesOrientation = ChartSeriesOrientation.column,
    required super.linePaint,
    required super.chartViewMaker,
    super.isLextrOnlyToValueSignPortion = false,
    super.isLextrUseSizerInsteadOfConstraint = false,
  });
}
/* KEEP :
  AxisLineContainerOrig20230331 called as:

              // Y axis line to the right of labels
              AxisLineContainerOrig20230331(
                fromPointOffset: PointOffset(inputValue: 0.0, outputValue: labelsGenerator.dataRange.min),
                toPointOffset:   PointOffset(inputValue: 0.0, outputValue: labelsGenerator.dataRange.max),
                chartSeriesOrientation: ChartSeriesOrientation.column,
                linePaint: chartViewMaker.chartOptions.dataContainerOptions.gridLinesPaint(),
                chartViewMaker: chartViewMaker,
                isLextrOnlyToValueSignPortion: false, // Lextr from full Y range (negative + positive portion)
                isLextrUseSizerInsteadOfConstraint: true, // Lextr to full Sizer Height, AND Ltransf, not Lscale
              ),

                    // X axis line. Could place in Row with main constraints weight=0.0
                    AxisLineContainerOrig20230331(
                        fromPointOffset:
                            PointOffset(inputValue: chartViewMaker.xLabelsGenerator.dataRange.min, outputValue: 0.0),
                        toPointOffset:
                            PointOffset(inputValue: chartViewMaker.xLabelsGenerator.dataRange.max, outputValue: 0.0),
                        linePaint: chartViewMaker.chartOptions.dataContainerOptions.gridLinesPaint(),
                        chartViewMaker: chartViewMaker,
                    ),
 */

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
    var xLabelsGenerator = chartViewMaker.xLabelsGenerator;
    var yLabelsGenerator = chartViewMaker.yLabelsGenerator;

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
              mainAxisExternalTicksLayoutProvider: xLabelsGenerator.asExternalTicksLayoutProvider(
                externalTickAtPosition: ExternalTickAtPosition.childCenter,
              ),
              children: [
                for (var labelInfo in xLabelsGenerator.labelInfoList)
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

class YContainer extends container_common_new.ChartAreaContainer {
  YContainer({
    required ChartViewMaker chartViewMaker,
  }) : super(
          chartViewMaker: chartViewMaker,
        ) {
    var options = chartViewMaker.chartOptions;
    var yLabelsGenerator = chartViewMaker.yLabelsGenerator;
    var xLabelsGenerator = chartViewMaker.xLabelsGenerator;

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
                mainAxisExternalTicksLayoutProvider: yLabelsGenerator.asExternalTicksLayoutProvider(
                  externalTickAtPosition: ExternalTickAtPosition.childCenter,
                ),
                children: [
                  for (var labelInfo in yLabelsGenerator.labelInfoList)
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
              // Y axis line to the right of labels
              AxisLineContainer(
                // Note: Here we use the magic of PointOffset transforms to define a HORIZONTAL line, which after
                //       PointOffset transforms becomes VERTICAL due to the transpose of coordinates.
                //       See documentation in [PointOffset.lextrInContextOf] row section for details.
                fromPointOffset: PointOffset(inputValue: xLabelsGenerator.dataRange.min, outputValue: yLabelsGenerator.dataRange.min),
                toPointOffset:   PointOffset(inputValue: xLabelsGenerator.dataRange.max, outputValue: yLabelsGenerator.dataRange.min),
                chartSeriesOrientation: ChartSeriesOrientation.row,
                linePaint: chartViewMaker.chartOptions.dataContainerOptions.gridLinesPaint(),
                chartViewMaker: chartViewMaker,
                // isLextrOnlyToValueSignPortion: false, // default : Lextr from full Y range (negative + positive portion)
                isLextrUseSizerInsteadOfConstraint: true, // Lextr to full Sizer Height, AND Ltransf, not Lscale
              ),
            ]),
          ],
        ),
      ),
    ];
    addChildren(children);
  }
}
