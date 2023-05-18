import 'package:vector_math/vector_math.dart' as vector_math show Matrix2;

// base libraries
import '../../morphic/container/container_layouter_base.dart';
import '../../morphic/container/morphic_dart_enums.dart';
import '../../morphic/container/container_edge_padding.dart';
import '../../morphic/container/label_container.dart';
import '../../morphic/container/chart_support/chart_style.dart';
import '../../morphic/container/layouter_one_dimensional.dart' show Align;
import '../../morphic/ui2d/point.dart';
import '../model/label_model.dart';
import '../chart_label_container.dart';
import '../view_model.dart';
import '../options.dart';

// this level libraries
import 'container_common.dart' as container_common;
import 'line_segment_container.dart';

/// Container for line showing a horizontal or vertical axis.
///
/// Defined by its end points, [fromPointOffset] and [toPointOffset].
///
/// Neither this container, not it's end points specify [ChartOrientation], as they are defined
/// in a coordinate system assuming orientation [ChartOrientation.column].
/// The orientation is determined by member [chartViewModel]'s [ChartViewModel.chartOrientation];
/// if orientation is set to [ChartOrientation.row], the line is transformed to it's row orientation by
/// transforming the end points [fromPointOffset] and [toPointOffset]
/// using their [PointOffset.affmapBetweenRanges].
///
class AxisLineContainer extends LineBetweenPointOffsetsContainer {
  AxisLineContainer({
    super.fromPointOffset,
    super.toPointOffset,
    // For the pos/neg to create weight-defined constraints when in Column or Row, ConstraintsWeight must be set.
    super.constraintsWeight = const ConstraintsWeight(weight: 0),
    required super.linePaint,
    required super.chartViewModel,
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
  /// See documentation in [PointOffset.affmapInContextOf] column section for details.
  TransposingInputAxisLineContainer({
    required DataRangeLabelInfosGenerator inputLabelsGenerator,
    required DataRangeLabelInfosGenerator outputLabelsGenerator,
    required ChartViewModel chartViewModel,
    required super.constraintsWeight,
  }) : super(
          // Logic to handle PointOffset depending on orientation. Not possible to do pure affmap
          //   (from default column logic using outputValue:  outputLabelsGenerator.dataRange.max ),
          //   because [inputAxisLine] lives in [ContainerForBothBarsAreasAndInputAxisLine] inside Column,
          //   which adds offset and messes up positioning endpoints of axis line using pure affmap.
          //   todo-010 : Deal with it better, but at the moment, I do not know how.
          fromPointOffset: PointOffset(
            inputValue: inputLabelsGenerator.dataRange.min,
            outputValue: chartViewModel.chartOrientation == ChartOrientation.column
                ? outputLabelsGenerator.dataRange.max
                : outputLabelsGenerator.dataRange.min,
          ),
          toPointOffset: PointOffset(
            inputValue: inputLabelsGenerator.dataRange.max,
            outputValue: chartViewModel.chartOrientation == ChartOrientation.column
                ? outputLabelsGenerator.dataRange.max
                : outputLabelsGenerator.dataRange.min,
          ),
          linePaint: chartViewModel.chartOptions.dataContainerOptions.gridLinesPaint(),
          chartViewModel: chartViewModel,
        );
}

/// Container for the Vertical axis line only, no other elements.
/// what chart orientation.
class TransposingOutputAxisLineContainer extends AxisLineContainer {
  /// Here we use the magic of PointOffset transforms to define a HORIZONTAL line, which after
  ///   PointOffset transforms becomes VERTICAL due to the transpose of coordinates.
  /// See documentation in [PointOffset.affmapInContextOf] row section for details.
  TransposingOutputAxisLineContainer({
    required DataRangeLabelInfosGenerator inputLabelsGenerator,
    required DataRangeLabelInfosGenerator outputLabelsGenerator,
    required ChartViewModel chartViewModel,
  }) : super(
          fromPointOffset: PointOffset(
            inputValue: inputLabelsGenerator.dataRange.min,
            outputValue: outputLabelsGenerator.dataRange.min,
          ),
          toPointOffset: PointOffset(
            inputValue: inputLabelsGenerator.dataRange.min,
            outputValue: outputLabelsGenerator.dataRange.max,
          ),
          linePaint: chartViewModel.chartOptions.dataContainerOptions.gridLinesPaint(),
          chartViewModel: chartViewModel,
        );
}

abstract class TransposingAxisContainer extends container_common.ChartAreaContainer {
  TransposingAxisContainer({
    required super.chartViewModel,
  }) {
    _outputLabelsGenerator = chartViewModel.outputLabelsGenerator;
    _inputLabelsGenerator = chartViewModel.inputLabelsGenerator;
    _padGroup = ChartPaddingGroup(fromChartOptions: chartViewModel.chartOptions);

    // Initially all [LabelContainer]s share same text style object from options.
    _labelStyle = LabelStyle(
      textStyle: chartViewModel.chartOptions.labelCommonOptions.labelTextStyle,
      textDirection: chartViewModel.chartOptions.labelCommonOptions.labelTextDirection,
      textAlign: chartViewModel.chartOptions.labelCommonOptions.labelTextAlign, // center text
      textScaleFactor: chartViewModel.chartOptions.labelCommonOptions.labelTextScaleFactor,
    );
  }

  // Capture some named instances in members for reuse by extensions,
  // making clear what is needed from params
  late final ChartPaddingGroup _padGroup;
  late final DataRangeLabelInfosGenerator _outputLabelsGenerator;
  late final DataRangeLabelInfosGenerator _inputLabelsGenerator;
  late final LabelStyle _labelStyle;

  factory TransposingAxisContainer.Vertical({
    required ChartViewModel chartViewModel,
  }) {
    switch (chartViewModel.chartOrientation) {
      case ChartOrientation.column:
        return TransposingOutputAxisContainer(
          chartViewModel: chartViewModel,
          directionWrapperAround: _verticalWrapperAround,
        );
      case ChartOrientation.row:
        return TransposingInputAxisContainer(
          chartViewModel: chartViewModel,
          directionWrapperAround: _verticalWrapperAround,
        );
    }
  }

  factory TransposingAxisContainer.Horizontal({
    required ChartViewModel chartViewModel,
  }) {
    switch (chartViewModel.chartOrientation) {
      case ChartOrientation.column:
        return TransposingInputAxisContainer(
          chartViewModel: chartViewModel,
          directionWrapperAround: _horizontalWrapperAround,
        );
      case ChartOrientation.row:
        return TransposingOutputAxisContainer(
          chartViewModel: chartViewModel,
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
    required ChartViewModel chartViewModel,
    required List<BoxContainer> Function(List<BoxContainer>, ChartPaddingGroup) directionWrapperAround,
  }) : super(
          chartViewModel: chartViewModel,
        ) {
    List<BoxContainer> children = directionWrapperAround(
      [
        TransposingRoller.Column(
          chartOrientation: chartViewModel.chartOrientation,
          children: [
            TransposingExternalTicks.Row(
              chartOrientation: chartViewModel.chartOrientation,
              mainAxisExternalTicksLayoutProvider: _inputLabelsGenerator.asExternalTicksLayoutProvider(
                externalTickAtPosition: ExternalTickAtPosition.childCenter,
              ),
              children:  [
                // Add all labels from generator as children. Labels were created and placed in [labelInfoList]
                //   in the [DataRangeLabelInfosGenerator] constructor called in the  [ChartViewModel]  constructor,
                //   where both input and output [DataRangeLabelInfosGenerator]s are created.
                for (var labelInfo in _inputLabelsGenerator.labelInfoList)
                  // todo-013 : check how X labels are created. Wolf, Deer, Owl etc positions seem fine, but how was it created?
                  AxisLabelContainer(
                    chartViewModel: chartViewModel,
                    label: labelInfo.formattedLabel,
                    labelTiltMatrix: vector_math.Matrix2.identity(),
                    // No tilted labels in VerticalAxisContainer
                    labelStyle: _labelStyle,
                  )
              ],
            ),
          ],
        )
      ],
      _padGroup,
    );

    addChildren(children);
  }
}

class TransposingOutputAxisContainer extends TransposingAxisContainer {
  TransposingOutputAxisContainer({
    required ChartViewModel chartViewModel,
    required List<BoxContainer> Function(List<BoxContainer>, ChartPaddingGroup) directionWrapperAround,
  }) : super(
          chartViewModel: chartViewModel,
        ) {
    List<BoxContainer> children = directionWrapperAround(
      [
        // Row with Column of Y labels and Y axis (Output labels and output axis)
        TransposingRoller.Row(
            chartOrientation: chartViewModel.chartOrientation,
            mainAxisAlign: Align.start, // default
            isMainAxisAlignFlippedOnTranspose: false, // but do not flip to Align.end, children have no weight=no divide
            children: [
              TransposingExternalTicks.Column(
                chartOrientation: chartViewModel.chartOrientation,
                mainAxisExternalTicksLayoutProvider: _outputLabelsGenerator.asExternalTicksLayoutProvider(
                  externalTickAtPosition: ExternalTickAtPosition.childCenter,
                ),
                children: [
                  // Add all labels from generator as children. See comment in TransposingInputAxisContainer
                  for (var labelInfo in _outputLabelsGenerator.labelInfoList)
                    AxisLabelContainer(
                      chartViewModel: chartViewModel,
                      label: labelInfo.formattedLabel,
                      labelTiltMatrix: vector_math.Matrix2.identity(),
                      // No tilted labels in VerticalAxisContainer
                      labelStyle: _labelStyle,
                    )
                ],
              ),
              // Y axis line to the right of labels
              TransposingOutputAxisLineContainer(
                inputLabelsGenerator: _inputLabelsGenerator,
                outputLabelsGenerator: _outputLabelsGenerator,
                chartViewModel: chartViewModel,
              ),
            ]),
      ],
      _padGroup,
    );

    addChildren(children);
  }
}
