import 'package:vector_math/vector_math.dart' as vector_math show Matrix2;

// base libraries
import '../../morphic/container/container_layouter_base.dart';
import '../../morphic/container/container_layouter_base_dart_support.dart';
import '../../morphic/container/container_edge_padding.dart';
import '../../morphic/container/label_container.dart';
import '../../morphic/container/chart_support/chart_orientation.dart';
//import '../../morphic/ui2d/point.dart';
import '../../morphic/container/layouter_one_dimensional.dart' show Align;
import '../../morphic/ui2d/point.dart';
import '../../util/util_labels.dart';
import '../chart_label_container.dart';
import '../view_maker.dart';
// import '../iterative_layout_strategy.dart';
import '../options.dart';

// this level libraries
import 'container_common.dart' as container_common;
import 'line_segment_container.dart';

/// Container for line showing a horizontal or vertical axis.
///
/// Defined by its end points, [fromPointOffset] and [toPointOffset].
///
/// Neither this container, not it's end points specify [ChartSeriesOrientation], as they are defined
/// in a coordinate system assuming orientation [ChartSeriesOrientation.column].
/// The orientation is determined by member [chartViewMaker]'s [ChartViewMaker.chartSeriesOrientation];
/// if orientation is set to [ChartSeriesOrientation.row], the line is transformed to it's row orientation by
/// transforming the end points [fromPointOffset] and [toPointOffset]
/// using their [PointOffset.lextrToPixelsMaybeTransposeInContextOf].
///
class AxisLineContainer extends LineBetweenPointOffsetsContainer {
  AxisLineContainer({
    super.fromPointOffset,
    super.toPointOffset,
    // For the pos/neg to create weight-defined constraints when in Column or Row, ConstraintsWeight must be set.
    super.constraintsWeight = const ConstraintsWeight(weight: 0),
    required super.linePaint,
    required super.chartViewMaker,
    super.isLextrUseSizerInsteadOfConstraint = false,
  });
}

class TransposingInputAxisLineContainer extends AxisLineContainer {
  /// Creating a horizontal line between inputValue x min and x max, with outputValue y max.
  /// The reason for using y max: We want to paint HORIZONTAL line with 0 thickness, so
  ///   the layoutSize.height of the AxisLineContainer must be 0.
  /// That means, the AxisLineContainer INNER y pixel coordinates of both end points
  ///   must be 0 after all transforms.
  /// To achieve the 0 inner y pixel coordinates after all transforms, we need to start at the point
  ///   in y dataRange which transforms to 0 pixels. That point is y dataRange MAX, which we use here.
  /// See documentation in [PointOffset.lextrInContextOf] column section for details.
  TransposingInputAxisLineContainer({
    required DataRangeLabelInfosGenerator inputLabelsGenerator,
    required DataRangeLabelInfosGenerator outputLabelsGenerator,
    required ChartViewMaker chartViewMaker,
  }) : super(
    fromPointOffset: PointOffset(inputValue: inputLabelsGenerator.dataRange.min, outputValue: outputLabelsGenerator.dataRange.max),
    toPointOffset:   PointOffset(inputValue: inputLabelsGenerator.dataRange.max, outputValue: outputLabelsGenerator.dataRange.max),
  linePaint: chartViewMaker.chartOptions.dataContainerOptions.gridLinesPaint(),
  chartViewMaker: chartViewMaker,
  isLextrUseSizerInsteadOfConstraint: true, // Lextr to full Sizer Height, AND Ltransf, not Lscale
  );
}

/// Container for the Vertical axis line only, no other elements.
/// what chart orientation.
class TransposingOutputAxisLineContainer extends AxisLineContainer {
  /// Here we use the magic of PointOffset transforms to define a HORIZONTAL line, which after
  ///   PointOffset transforms becomes VERTICAL due to the transpose of coordinates.
  /// See documentation in [PointOffset.lextrInContextOf] row section for details.
  TransposingOutputAxisLineContainer({
    required DataRangeLabelInfosGenerator inputLabelsGenerator,
    required DataRangeLabelInfosGenerator outputLabelsGenerator,
    required ChartViewMaker chartViewMaker,
  }) : super(
          fromPointOffset:
              PointOffset(inputValue: inputLabelsGenerator.dataRange.min, outputValue: outputLabelsGenerator.dataRange.min),
          toPointOffset:
              PointOffset(inputValue: inputLabelsGenerator.dataRange.min, outputValue: outputLabelsGenerator.dataRange.max),
          linePaint: chartViewMaker.chartOptions.dataContainerOptions.gridLinesPaint(),
          chartViewMaker: chartViewMaker,
          isLextrUseSizerInsteadOfConstraint: true, // Lextr to full Sizer Height, AND Ltransf, not Lscale
        );
}

abstract class TransposingAxisContainer extends container_common.ChartAreaContainer {
  TransposingAxisContainer({
    required super.chartViewMaker,
  }) {
    _options = chartViewMaker.chartOptions;
    _outputLabelsGenerator = chartViewMaker.outputLabelsGenerator;
    _inputLabelsGenerator = chartViewMaker.inputLabelsGenerator;
    _padGroup = ChartPaddingGroup(fromChartOptions: _options);

    // Initially all [LabelContainer]s share same text style object from options.
    _labelStyle = LabelStyle(
      textStyle: _options.labelCommonOptions.labelTextStyle,
      textDirection: _options.labelCommonOptions.labelTextDirection,
      textAlign: _options.labelCommonOptions.labelTextAlign, // center text
      textScaleFactor: _options.labelCommonOptions.labelTextScaleFactor,
    );
  }

  late final ChartOptions _options;
  late final ChartPaddingGroup _padGroup;
  late final DataRangeLabelInfosGenerator _outputLabelsGenerator;
  late final DataRangeLabelInfosGenerator _inputLabelsGenerator;
  late final LabelStyle _labelStyle;

  factory TransposingAxisContainer.Vertical({
    required ChartSeriesOrientation chartSeriesOrientation,
    required ChartViewMaker chartViewMaker,
  }) {
    switch (chartSeriesOrientation) {
      case ChartSeriesOrientation.column:
        return TransposingOutputAxisContainer(
          chartViewMaker: chartViewMaker,
          directionWrapperAround: _verticalWrapperAround,
        );
      case ChartSeriesOrientation.row:
        return TransposingInputAxisContainer(
          chartViewMaker: chartViewMaker,
          directionWrapperAround: _verticalWrapperAround,
        );
    }
  }

  factory TransposingAxisContainer.Horizontal({
    required ChartSeriesOrientation chartSeriesOrientation,
    required ChartViewMaker chartViewMaker,
  }) {
    switch (chartSeriesOrientation) {
      case ChartSeriesOrientation.column:
        return TransposingInputAxisContainer(
          chartViewMaker: chartViewMaker,
          directionWrapperAround: _horizontalWrapperAround,
        );
      case ChartSeriesOrientation.row:
        return TransposingOutputAxisContainer(
          chartViewMaker: chartViewMaker,
          directionWrapperAround: _horizontalWrapperAround,
        );
    }
  }

  static List<BoxContainer> _horizontalWrapperAround(List<BoxContainer> children, ChartPaddingGroup padGroup) {
    return [
      WidthSizerLayouter(
        children: children,
      )
    ];
  }

  static List<BoxContainer> _verticalWrapperAround(List<BoxContainer> children, ChartPaddingGroup padGroup) {
    return [
      // Row contains Column of labels and vertical LineSegment for Y axis
      Padder(
        edgePadding: EdgePadding.withSides(
          top: padGroup.heightPadTopOfYAndData(),
          bottom: padGroup.heightPadBottomOfYAndData(),
        ),
        child: HeightSizerLayouter(
          children: children,
        ),
      ),
    ];
  }
}

class TransposingInputAxisContainer extends TransposingAxisContainer {
  /// Constructs the container that holds X labels.
  ///
  /// The passed [BoxContainerConstraints] is (assumed) to direct the expansion to fill
  /// all available horizontal space, and only use necessary vertical space.
  TransposingInputAxisContainer({
    required ChartViewMaker chartViewMaker,
    required List<BoxContainer> Function (List<BoxContainer>, ChartPaddingGroup) directionWrapperAround,
  }) : super(
          chartViewMaker: chartViewMaker,
        ) {
    List<BoxContainer> children =
       directionWrapperAround(
          [TransposingRoller.Column(
            chartSeriesOrientation: chartViewMaker.chartSeriesOrientation,
            children: [
            TransposingExternalTicks.Row(
              chartSeriesOrientation: chartViewMaker.chartSeriesOrientation,
              mainAxisExternalTicksLayoutProvider: _inputLabelsGenerator.asExternalTicksLayoutProvider(
                externalTickAtPosition: ExternalTickAtPosition.childCenter,
              ),
              children: [
                for (var labelInfo in _inputLabelsGenerator.labelInfoList)
                  // todo-010 : check how X labels are created. Wolf, Deer, Owl etc positions seem fine, but how was it created?
                  InputLabelContainer(
                    chartViewMaker: chartViewMaker,
                    label: labelInfo.formattedLabel,
                    labelTiltMatrix: vector_math.Matrix2.identity(),
                    // No tilted labels in VerticalAxisContainer
                    labelStyle: _labelStyle,
                    labelInfo: labelInfo,
                    ownerChartAreaContainer: this,
                  )
              ],
            ),
          ],
         )],
         _padGroup,
      );

    addChildren(children);
  }
}

class TransposingOutputAxisContainer extends TransposingAxisContainer {
  TransposingOutputAxisContainer({
    required ChartViewMaker chartViewMaker,
    required List<BoxContainer> Function(List<BoxContainer>, ChartPaddingGroup) directionWrapperAround,
  }) : super(
          chartViewMaker: chartViewMaker,
        ) {
    var barsContainerMainAxisAlign1 = chartViewMaker.chartSeriesOrientation == ChartSeriesOrientation.column ? Align.start : Align.end; // todo-00-last-last-progress : added
    List<BoxContainer> children = directionWrapperAround(
      [
        // Row with Column of Y labels and Y axis (Output labels and output axis)
        TransposingRoller.Row(
            chartSeriesOrientation: chartViewMaker.chartSeriesOrientation,
            mainAxisAlign: barsContainerMainAxisAlign1, // todo-00-last-last-LAST-LAST-LAST-LAST progress : added : THIS FINALLY FIXED THE LAYOUT in row mode.
                                                        // todo-00-last-last-LAST-LAST-LAST-LAST : Try to remove the other equivalent code and keep only this code.
                                                        // todo-00-last-last-LAST-LAST-LAST-LAST : But this is a syndrom of a deeper issue: The TransposingRoller (and maybe all transposing) should ONLY be used with divided constraints - e.g. for multiple children with weights defined.
            children: [
              TransposingExternalTicks.Column(
                chartSeriesOrientation: chartViewMaker.chartSeriesOrientation,
                mainAxisExternalTicksLayoutProvider: _outputLabelsGenerator.asExternalTicksLayoutProvider(
                  externalTickAtPosition: ExternalTickAtPosition.childCenter,
                ),
                children: [
                  // [labelInfo] in [labelInfoList] is numerically increasing. Their pixel layout order will be determined
                  //   by order of ExternalTicksLayoutProvider.tickPixels created and possibly reversed from
                  //   ExternalTicksLayoutProvider.tickValues. See [_outputLabelsGenerator.asExternalTicksLayoutProvider]
                  for (var labelInfo in _outputLabelsGenerator.labelInfoList)
                    OutputLabelContainer(
                      chartViewMaker: chartViewMaker,
                      label: labelInfo.formattedLabel,
                      labelTiltMatrix: vector_math.Matrix2.identity(),
                      // No tilted labels in VerticalAxisContainer
                      labelStyle: _labelStyle,
                      labelInfo: labelInfo,
                      ownerChartAreaContainer: this,
                    )
                ],
              ),
              // Y axis line to the right of labels
              TransposingOutputAxisLineContainer(
                inputLabelsGenerator: _inputLabelsGenerator,
                outputLabelsGenerator: _outputLabelsGenerator,
                chartViewMaker: chartViewMaker,
              ),
            ]),
      ],
      _padGroup,
    );

    addChildren(children);
  }
}
