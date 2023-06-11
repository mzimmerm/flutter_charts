import 'package:vector_math/vector_math.dart' as vector_math show Matrix2;

// base libraries
import '../../morphic/container/container_layouter_base.dart';
import '../../morphic/container/morphic_dart_enums.dart';
import '../../morphic/container/container_edge_padding.dart';
import '../../morphic/container/label_container.dart';
import '../../morphic/container/chart_support/chart_style.dart';
import '../../morphic/container/layouter_one_dimensional.dart' show Align;
import '../../morphic/ui2d/point.dart';
import '../view_model/label_model.dart';
import '../chart_label_container.dart';
import '../view_model/view_model.dart';
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

class TransposingInputAxisLine extends AxisLineContainer {
  /// Creating a horizontal line between inputValue x min and x max, with outputValue y max.
  /// The reason for using y max: We want to paint HORIZONTAL line with 0 thickness, so
  ///   the layoutSize.height of the AxisLineContainer must be 0.
  /// That means, the AxisLineContainer INNER y pixel coordinates of both end points
  ///   must be 0 after all transforms.
  /// To achieve the 0 inner y pixel coordinates after all transforms, we need to start at the point
  ///   in y dataRange which transforms to 0 pixels. That point is y dataRange MAX, which we use here.
  /// See documentation in [PointOffset.affmapInContextOf] column section for details.
  TransposingInputAxisLine({
    required DataRangeTicksAndLabelsDescriptor inputRangeDescriptor,
    required DataRangeTicksAndLabelsDescriptor outputRangeDescriptor,
    required ChartViewModel chartViewModel,
    required super.constraintsWeight,
  }) : super(
          // Logic to handle PointOffset depending on orientation. Not possible to do pure affmap
          //   (from default column logic using outputValue:  outputRangeDescriptor.dataRange.max ),
          //   because [inputAxisLine] lives in [ContainerForBothBarsAreasAndInputAxisLine] inside Column,
          //   which adds offset and messes up positioning endpoints of axis line using pure affmap.
          //   todo-02-design : Deal with it better, but at the moment, I do not know how.
          fromPointOffset: PointOffset(
            inputValue: inputRangeDescriptor.dataRange.min,
            outputValue: chartViewModel.chartOrientation == ChartOrientation.column
                ? outputRangeDescriptor.dataRange.max
                : outputRangeDescriptor.dataRange.min,
          ),
          toPointOffset: PointOffset(
            inputValue: inputRangeDescriptor.dataRange.max,
            outputValue: chartViewModel.chartOrientation == ChartOrientation.column
                ? outputRangeDescriptor.dataRange.max
                : outputRangeDescriptor.dataRange.min,
          ),
          linePaint: chartViewModel.chartOptions.dataContainerOptions.gridLinesPaint(),
          chartViewModel: chartViewModel,
        );
}

/// Container for the Vertical axis line only, no other elements.
/// what chart orientation.
class TransposingOutputAxisLine extends AxisLineContainer {
  /// Here we use the magic of PointOffset transforms to define a HORIZONTAL line, which after
  ///   PointOffset transforms becomes VERTICAL due to the transpose of coordinates.
  /// See documentation in [PointOffset.affmapInContextOf] row section for details.
  TransposingOutputAxisLine({
    required DataRangeTicksAndLabelsDescriptor inputRangeDescriptor,
    required DataRangeTicksAndLabelsDescriptor outputRangeDescriptor,
    required ChartViewModel chartViewModel,
  }) : super(
          fromPointOffset: PointOffset(
            inputValue: inputRangeDescriptor.dataRange.min,
            outputValue: outputRangeDescriptor.dataRange.min,
          ),
          toPointOffset: PointOffset(
            inputValue: inputRangeDescriptor.dataRange.min,
            outputValue: outputRangeDescriptor.dataRange.max,
          ),
          linePaint: chartViewModel.chartOptions.dataContainerOptions.gridLinesPaint(),
          chartViewModel: chartViewModel,
        );
}

abstract class TransposingAxisOrGrid extends container_common.ChartAreaContainer {
  TransposingAxisOrGrid({
    required super.chartViewModel,
  }) {
    _outputRangeDescriptor = chartViewModel.outputRangeDescriptor;
    _inputRangeDescriptor = chartViewModel.inputRangeDescriptor;
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
  late final DataRangeTicksAndLabelsDescriptor _outputRangeDescriptor;
  late final DataRangeTicksAndLabelsDescriptor _inputRangeDescriptor;
  late final LabelStyle _labelStyle;

  factory TransposingAxisOrGrid.VerticalAxis({
    required ChartViewModel chartViewModel,
  }) {
    switch (chartViewModel.chartOrientation) {
      case ChartOrientation.column:
        return TransposingOutputAxis(
          chartViewModel: chartViewModel,
          directionWrapperAround: _verticalWrapperAround,
          isShowOutputAxisLine: true,
        );
      case ChartOrientation.row:
        return TransposingInputAxis(
          chartViewModel: chartViewModel,
          directionWrapperAround: _verticalWrapperAround,
        );
    }
  }

  factory TransposingAxisOrGrid.HorizontalAxis({
    required ChartViewModel chartViewModel,
  }) {
    switch (chartViewModel.chartOrientation) {
      case ChartOrientation.column:
        return TransposingInputAxis(
          chartViewModel: chartViewModel,
          directionWrapperAround: _horizontalWrapperAround,
        );
      case ChartOrientation.row:
        return TransposingOutputAxis(
          chartViewModel: chartViewModel,
          directionWrapperAround: _horizontalWrapperAround,
          isShowOutputAxisLine: true,
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

abstract class TransposingInputAxisOrGrid extends TransposingAxisOrGrid {
  /// Constructs the abstract container for extensions holding one of:
  ///   - labels for input values (aka independent labels, X labels), [TransposingInputAxis],
  ///   - (transposing) grid lines for input values, [TransposingInputGrid]
  ///
  /// The [constraints] provided by container-parent is (assumed) to direct the expansion to fill
  /// all available horizontal space, and only use the necessary vertical space.
  ///
  /// The [externallyTickedAxisChildren] should return a list of [AxisLabelContainer]s or [GridLine]s.
  ///
  /// The [directionWrapperAround] should be set to a padding common with [DataContainer].
  TransposingInputAxisOrGrid({
    required super.chartViewModel,
    required this.directionWrapperAround,
    // required this.externallyTickedAxisChildren,
  });

  List<BoxContainer> Function(List<BoxContainer>, ChartPaddingGroup) directionWrapperAround;
  List<BoxContainer> get externallyTickedAxisChildren;

  @override
  void buildAndReplaceChildren() {
    List<BoxContainer> children = directionWrapperAround(
      [
        // Transposing Column with single child, the TransposingExternalTicks.Row,
        // which has one item per label in [_inputRangeDescriptor.labelInfoList]
        TransposingRoller.Column(
          chartOrientation: chartViewModel.chartOrientation,
          children: [
            TransposingExternalTicks.Row(
              chartOrientation: chartViewModel.chartOrientation,
              mainAxisExternalTicksLayoutDescriptor: _inputRangeDescriptor.asExternalTicksLayoutDescriptor(
                externalTickAtPosition: ExternalTickAtPosition.childCenter,
              ),
              children:
/* todo-00-last-done
              [
                // Add all labels from generator as children. Labels were created and placed in [labelInfoList]
                //   in the [DataRangeTicksAndLabelsDescriptor] constructor called in the  [ChartViewModel]  constructor,
                //   where both input and output [DataRangeTicksAndLabelsDescriptor]s are created.
                for (var labelInfo in _inputRangeDescriptor.labelInfoList)
                  AxisLabelContainer(
                    chartViewModel: chartViewModel,
                    label: labelInfo.formattedLabel,
                    labelTiltMatrix: vector_math.Matrix2.identity(),
                    // No tilted labels in VerticalAxisContainer
                    labelStyle: _labelStyle,
                  )
              ],
*/
            externallyTickedAxisChildren,
            ),
          ],
        )
      ],
      _padGroup,
    );

    replaceChildrenWith(children);
  }
}

class TransposingInputAxis extends TransposingInputAxisOrGrid {
  TransposingInputAxis({
    required super.chartViewModel,
    required super.directionWrapperAround,
  });

  @override
  List<BoxContainer> get externallyTickedAxisChildren => [
    // Add all labels from generator as children. Labels were created and placed in [labelInfoList]
    //   in the [DataRangeTicksAndLabelsDescriptor] constructor called in the  [ChartViewModel]  constructor,
    //   where both input and output [DataRangeTicksAndLabelsDescriptor]s are created.
    for (var labelInfo in _inputRangeDescriptor.labelInfoList)
      AxisLabelContainer(
        chartViewModel: chartViewModel,
        label: labelInfo.formattedLabel,
        labelTiltMatrix: vector_math.Matrix2.identity(),
        // No tilted labels in VerticalAxisContainer
        labelStyle: _labelStyle,
      )
  ];

}

/// Constructs the abstract container for extensions holding one of:
///   - labels for output values (aka dependent labels, Y labels), [TransposingOutputAxis],
///   - (transposing) grid lines for input values, [TransposingOutputGrid]
///
/// The [constraints] provided by container-parent is (assumed) to direct the expansion to fill
/// all available vertical space, and only use the necessary horizontal space.
///
/// The [externallyTickedAxisChildren] should return a list of [AxisLabelContainer]s or [GridLine]s.
///
/// The [isShowOutputAxisLine] should be `true` if used on axis, `false` if used on grid.
///
/// The [directionWrapperAround] should be set to a padding common with [DataContainer].
///
abstract class TransposingOutputAxisOrGrid extends TransposingAxisOrGrid {
  TransposingOutputAxisOrGrid({
    required super.chartViewModel,
    required this.directionWrapperAround,
    required this.isShowOutputAxisLine,
  });

  List<BoxContainer> Function(List<BoxContainer>, ChartPaddingGroup) directionWrapperAround;
  List<BoxContainer> get externallyTickedAxisChildren;
  bool isShowOutputAxisLine;

  @override
  void buildAndReplaceChildren() {
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
                mainAxisExternalTicksLayoutDescriptor: _outputRangeDescriptor.asExternalTicksLayoutDescriptor(
                  externalTickAtPosition: ExternalTickAtPosition.childCenter,
                ),
                children:
/* todo-00-done
                [
                  // Add all labels from generator as children. See comment in TransposingInputAxis
                  for (var labelInfo in _outputRangeDescriptor.labelInfoList)
                    AxisLabelContainer(
                      chartViewModel: chartViewModel,
                      label: labelInfo.formattedLabel,
                      labelTiltMatrix: vector_math.Matrix2.identity(),
                      // No tilted labels in VerticalAxisContainer
                      labelStyle: _labelStyle,
                    )
                ],
*/
              externallyTickedAxisChildren,
              ),
              // Y axis line to the right of labels
              if (isShowOutputAxisLine)
                TransposingOutputAxisLine(
                  inputRangeDescriptor: _inputRangeDescriptor,
                  outputRangeDescriptor: _outputRangeDescriptor,
                  chartViewModel: chartViewModel,
                ),
            ]),
      ],
      _padGroup,
    );

    addChildren(children);
  }
}

class TransposingOutputAxis extends TransposingOutputAxisOrGrid {
  TransposingOutputAxis({
    required super.chartViewModel,
    required super.directionWrapperAround,
    required super.isShowOutputAxisLine,
  });

  @override
  List<BoxContainer> get externallyTickedAxisChildren => [
    // Add all labels from generator as children. See comment in TransposingInputAxis
    for (var labelInfo in _outputRangeDescriptor.labelInfoList)
      AxisLabelContainer(
        chartViewModel: chartViewModel,
        label: labelInfo.formattedLabel,
        labelTiltMatrix: vector_math.Matrix2.identity(),
        // No tilted labels in VerticalAxisContainer
        labelStyle: _labelStyle,
      )
  ];

}

