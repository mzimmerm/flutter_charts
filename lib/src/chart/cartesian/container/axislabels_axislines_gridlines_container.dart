import 'package:vector_math/vector_math.dart' as vector_math show Matrix2;

// this level
import 'package:flutter_charts/src/chart/cartesian/container/container_common.dart' as container_common;
import 'package:flutter_charts/src/chart/cartesian/container/line_segment_container.dart';

// base libraries
import 'package:flutter_charts/src/morphic/container/container_layouter_base.dart';
import 'package:flutter_charts/src/morphic/container/morphic_dart_enums.dart';
import 'package:flutter_charts/src/morphic/container/container_edge_padding.dart';
import 'package:flutter_charts/src/morphic/container/label_container.dart';
import 'package:flutter_charts/src/morphic/container/chart_support/chart_style.dart';
import 'package:flutter_charts/src/morphic/ui2d/point.dart';

import 'package:flutter_charts/src/chart/chart_label_container.dart';
import 'package:flutter_charts/src/chart/view_model/view_model.dart';
import 'package:flutter_charts/src/chart/view_model/label_model.dart';
import 'package:flutter_charts/src/chart/options.dart';

/// Container for line showing a horizontal or vertical axis.
///
/// Defined by its end points, [fromPointOffset] and [toPointOffset]. When defining these end points, assume that
/// orientation is [ChartOrientation.column].
///
/// See [LineBetweenPointOffsetsContainer]
class AxisLineContainer extends LineBetweenPointOffsetsContainer {
  AxisLineContainer({
    required super.fromPointOffset,
    required super.toPointOffset,
    super.constraintsWeight, //  = const ConstraintsWeight(weight: 0),
    required super.linePaint,
    required super.chartViewModel,
  });

  /// Unused - KEEP if we want to make AxisLineContainer to contain a single child LineBetweenPointOffsetsContainer,
  /// rather than extend it, similar to (same as?) _ChildrenOfGridMixin on TransposingAxisLabelsOrGridLines,
  /// see _ChildrenOfGridMixin._externallyTickedAxisLabelsOrGridLinesOnAxis
  /// which adds LineBetweenPointOffsetsContainer as children
  void howFromToAreCalculated(DataDependency axisDataDependency) {
    /*
    // to use this, make fromPointOffset member late
    DataRangeTicksAndLabelsDescriptor rangeDescriptor = chartViewModel.rangeDescriptorFor(axisDataDependency);
    DataRangeTicksAndLabelsDescriptor crossRangeDescriptor = chartViewModel.crossRangeDescriptorFor(axisDataDependency);

    double inputValueFrom, inputValueTo, outputValueFrom, outputValueTo;

    switch (axisDataDependency) {
      case DataDependency.inputData:
      // cross direction (output), zero or min on cross range
        outputValueFrom = crossRangeDescriptor.dataRange.zeroElseMin;
        outputValueTo = crossRangeDescriptor.dataRange.zeroElseMin;
        // same direction (input), from min to max on range independent of orientation
        inputValueFrom = rangeDescriptor.dataRange.min;
        inputValueTo = rangeDescriptor.dataRange.max;
        break;
      case DataDependency.outputData:
      // cross direction (input), zero or min on cross range
        inputValueFrom = crossRangeDescriptor.dataRange.zeroElseMin;
        inputValueTo = crossRangeDescriptor.dataRange.zeroElseMin;
        // same direction (output), from min to max on range independent of orientation
        outputValueFrom = rangeDescriptor.dataRange.min;
        outputValueTo = rangeDescriptor.dataRange.max;
        break;
    }


    fromPointOffset = PointOffset(
      inputValue: inputValueFrom,
      outputValue: outputValueFrom,
    );
    toPointOffset = PointOffset(
      inputValue: inputValueTo,
      outputValue: outputValueTo,
    );
    */

  }
}

/// Container for line showing input values axis.
class TransposingInputAxisLine extends AxisLineContainer {
  /// Constructs a horizontal line which renders the input axis.
  /// See [TransposingOutputAxisLine] constructor.
  /// See documentation in [PointOffset.affmapInContextOf] column section for details.
  TransposingInputAxisLine({
    required ChartViewModel chartViewModel,
    super.constraintsWeight,
  }) : super(
          fromPointOffset: PointOffset(
            inputValue: chartViewModel.inputRangeDescriptor.dataRange.min,
            outputValue: chartViewModel.outputRangeDescriptor.dataRange.zeroElseMin,
          ),
          toPointOffset: PointOffset(
            inputValue: chartViewModel.inputRangeDescriptor.dataRange.max,
            outputValue: chartViewModel.outputRangeDescriptor.dataRange.zeroElseMin,
          ),
          linePaint: chartViewModel.chartOptions.dataContainerOptions.gridLinesPaint(),
          chartViewModel: chartViewModel,
        );

}

/// Container for line showing output values axis.
class TransposingOutputAxisLine extends AxisLineContainer {
  /// Constructs vertical line which renders output axis.
  ///
  /// The axis line ends are two points, the 'from' and 'to' [PointOffset] points, which form a HORIZONTAL line.
  ///
  /// If in [ChartOrientation.row] mode this horizontal line transforms and becomes VERTICAL due to the transpose
  ///   of coordinates in [AxisLineContainer.layout] calling [PointOffset.affmapBetweenRanges] on both points.
  ///
  /// See documentation in [PointOffset.affmapInContextOf] row section for details.
  TransposingOutputAxisLine({
    required ChartViewModel chartViewModel,
  }) : super(
          fromPointOffset: PointOffset(
            inputValue: chartViewModel.inputRangeDescriptor.dataRange.zeroElseMin, // inputRangeDescriptor.dataRange.min,
            outputValue: chartViewModel.outputRangeDescriptor.dataRange.min,
          ),
          toPointOffset: PointOffset(
            inputValue: chartViewModel.inputRangeDescriptor.dataRange.zeroElseMin, // inputRangeDescriptor.dataRange.min,
            outputValue: chartViewModel.outputRangeDescriptor.dataRange.max,
          ),
          linePaint: chartViewModel.chartOptions.dataContainerOptions.gridLinesPaint(),
          chartViewModel: chartViewModel,
        );
}

// -------------------------------------

/// Provides the single abstract method [_externallyTickedAxisLabelsOrGridLinesOnAxis] which
/// should create children (labels or grid lines) that can be placed into
/// the _build methods which build the ticked axis labels or grid lines containers.
///
/// The passed [chartViewModel] provides definition of chart type, orientation, and data ranges.
///
/// The passed [axisDataDependency] defines if the method builds the input or output;
/// it is translated to [DataRangeTicksAndLabelsDescriptor] which is used to iterate the ticked
/// labels or grid lines.
abstract class _ChildrenProviderMixin {
  List<BoxContainer> _externallyTickedAxisLabelsOrGridLinesOnAxis({
    required ChartViewModel chartViewModel,
    required DataDependency axisDataDependency,
  });
}

mixin _LabelStyleMixin {
  LabelStyle get labelStyle;
}

mixin _AxisLabelsProviderMixin implements _ChildrenProviderMixin, _LabelStyleMixin {

  @override
  List<BoxContainer> _externallyTickedAxisLabelsOrGridLinesOnAxis({
    required ChartViewModel chartViewModel,
    required DataDependency axisDataDependency,
  }) {
    DataRangeTicksAndLabelsDescriptor rangeDescriptor = chartViewModel.rangeDescriptorFor(axisDataDependency);

    return [
      // Add all labels from generator as children. Labels were created and placed in [labelInfoList]
      //   in the [DataRangeTicksAndLabelsDescriptor] constructor called in the [ChartViewModel] constructor,
      //   where both input and output [DataRangeTicksAndLabelsDescriptor]s are created.
      for (var labelInfo in rangeDescriptor.labelInfoList)
        AxisLabelContainer(
          chartViewModel: chartViewModel,
          label: labelInfo.formattedLabel,
          labelTiltMatrix: vector_math.Matrix2.identity(),
          labelStyle: labelStyle,
        )
    ];
  }
}


/// The implementation returns a list of grid lines as [LineBetweenPointOffsetsContainer], each
/// representing one grid line for input axis or output axis, as defined by arguments possed
/// to [_externallyTickedAxisLabelsOrGridLinesOnAxis].
///
/// See also [_ChildrenProviderMixin].
mixin _GridLinesProviderMixin implements _ChildrenProviderMixin {

  /// Implementation of [_ChildrenProviderMixin] mixin's method which creates grid lines.
  ///
  /// The passed [axisDataDependency] describes the children (labels for axis, grid lines for grid)
  /// being build:
  ///   - for [axisDataDependency] equal to [DataDependency.inputData], children for input axis are built;
  ///     also, the line is between [ChartViewModel.outputRangeDescriptor] max and min.
  ///   - equivalent for  [axisDataDependency] equal to [DataDependency.outputData],
  ///
  /// Important note:
  ///   This method also needs the cross-descriptor, obtained by [ChartViewModel.crossRangeDescriptorFor]
  ///   from which it needs the start and end of the grid lines!
  @override
  List<BoxContainer> _externallyTickedAxisLabelsOrGridLinesOnAxis({
    required ChartViewModel chartViewModel,
    required DataDependency axisDataDependency,
  }) {

    DataRangeTicksAndLabelsDescriptor rangeDescriptor = chartViewModel.rangeDescriptorFor(axisDataDependency);
    DataRangeTicksAndLabelsDescriptor crossRangeDescriptor = chartViewModel.crossRangeDescriptorFor(axisDataDependency);

    // Set values of the 'from' and 'to' points of grid lines.
    // The values are the same for all grid lines; each grid line is placed at min pixels (horizontal or vertical),
    // in the direction cross to the line direction. The external ticks layouter then moves the grid line to
    // it's final absolute position (within the ticks layouter, further offset by parents is done later).

    // The dataDependency for which we build these grid lines, is cross to the direction of the grid lines, in detail:
    //   - if passed = input,  lines are parallel to output, that is, lines have same input  values.
    //   - if passed = output, lines are parallel to input,  that is, lines have same output values.
    // So (this example is for DataDependency.inputData):
    //   - in the cross direction to the passed data dependency, line is from min to max
    //     on the data dependency cross-range
    //   - in the direction       of the passed data dependency, line is from min to min or from max to max
    //     on the data dependency range, depending on orientation. In detail:
    //       inputValue: for ChartOrientation.column
    //         - Start and end at min. affmap places it to affmap-input.min horizontal pixels
    //         - Then, ticks will move it to tick position
    //       inputValue: forChartOrientation.row
    //         - Start and end at max. affmap places it to affmap-output.min vertical pixels
    //         - Then, ticks will move it to tick position
    double inputValueFrom, inputValueTo, outputValueFrom, outputValueTo;

    switch(axisDataDependency) {
      case DataDependency.inputData:
        // cross direction, from min to max on cross range (output range)
        outputValueFrom = crossRangeDescriptor.dataRange.min;
        outputValueTo = crossRangeDescriptor.dataRange.max;
        // same direction, from min to min or max to max on range (output range) depending on orientation
        inputValueFrom = chartViewModel.chartOrientation == ChartOrientation.column
            ? rangeDescriptor.dataRange.min
            : rangeDescriptor.dataRange.max;
        inputValueTo = inputValueFrom;
        break;
      case DataDependency.outputData:
        // cross direction, from min to max on cross range (input range)
        inputValueFrom = crossRangeDescriptor.dataRange.min;
        inputValueTo = crossRangeDescriptor.dataRange.max;
        // same direction, from min to min or max to max on range (input range) depending on orientation
        outputValueFrom = chartViewModel.chartOrientation == ChartOrientation.column
            ? rangeDescriptor.dataRange.max // affmap places it to min on vertical pixels, ticks move it to position
            : rangeDescriptor.dataRange.min;
        outputValueTo = outputValueFrom;
        break;
    }

    return [
      for (var labelInfo in rangeDescriptor.labelInfoList)
        LineBetweenPointOffsetsContainer(
          fromPointOffset: PointOffset(
            inputValue: inputValueFrom,
            outputValue: outputValueFrom,
          ),
          toPointOffset: PointOffset(
            inputValue:  inputValueTo,
            outputValue: outputValueTo,
          ),
          linePaint: chartViewModel.chartOptions.dataContainerOptions.gridLinesPaint(),
          chartViewModel: chartViewModel,
        )
    ];
  }

}

// -------------------------------------
/// Provides method [_buildTickedInputRangeRowOrOutputRangeColumn]
/// which builds ticked container with labels (for axis) or grid lines (for grid).
///
/// Implements [_ChildrenProviderMixin], the common class-parent for [_AxisLabelsProviderMixin]
/// and [_GridLinesProviderMixin].
mixin _LabelsOrGridContainerBuilderMixin implements _ChildrenProviderMixin {

  /// Builds ticked container with labels (for axis) or grid lines (for grid).
  ///
  /// The children are created by the concrete mixin implementation
  /// of [_ChildrenProviderMixin._externallyTickedAxisLabelsOrGridLinesOnAxis].
  ///
  /// The container should be ticked by input or output range, depending on which range is rendered.
  ///
  /// Invoked by [TransposingAxisLabels] and [TransposingGridLines] in their core build methods
  /// [TransposingAxisLabels.buildAndReplaceChildren] and [TransposingGridLines.buildAndReplaceChildren].
  /// 
  /// Implemented by all leaf-classes, 
  /// [TransposingInputAxisLabels],  [TransposingInputGridLines], [TransposingOutputAxisLabels], [TransposingOutputGridLines], 
  /// where it delegates to either [_InputAxisOrGridBuilderMixin._buildInputRangeTickedTransposingRow]
  /// or [_OutputAxisOrGridBuilderMixin._buildOutputRangeTickedTransposingColumn],
  /// depending on whether they are input or output containers.
  TransposingExternalTicks _buildTickedInputRangeRowOrOutputRangeColumn({
    required ChartViewModel chartViewModel,
    required DataDependency dataDependency,
    required MoveTickTo moveTickTo,
  }) {

    ChartOrientation chartOrientation = chartViewModel.chartOrientation;

    switch (dataDependency) {
      case DataDependency.inputData:
        return TransposingExternalTicks.Row(
          chartOrientation: chartOrientation,
          mainAxisExternalTicksLayoutDescriptor: chartViewModel.inputRangeDescriptor.asExternalTicksLayoutDescriptor(
            externalTickAtPosition: ExternalTickAtPosition.childCenter,
            moveTickTo: moveTickTo,
          ),
          children: _externallyTickedAxisLabelsOrGridLinesOnAxis(chartViewModel: chartViewModel, axisDataDependency: dataDependency, ),
        );
      case DataDependency.outputData:
        return TransposingExternalTicks.Column(
          chartOrientation: chartOrientation,
          mainAxisExternalTicksLayoutDescriptor: chartViewModel.outputRangeDescriptor.asExternalTicksLayoutDescriptor(
            externalTickAtPosition: ExternalTickAtPosition.childCenter,
            moveTickTo: moveTickTo,
          ),
          children: _externallyTickedAxisLabelsOrGridLinesOnAxis(chartViewModel: chartViewModel, axisDataDependency: dataDependency, ),
        );
    }
  }
}

// -------------------------------------

/// Abstract base class for for axis labels container [TransposingAxisLabels]
/// and grid lines container [TransposingGridLines].
///
/// To support the ability to transpose, both input and output range descriptors are needed,
/// they are both available in the [ChartViewModel] provided by the superclass.
///
/// The appropriate range is selected given [dataDependency].
/// The [moveTickTo] is used to place grid lines around bars and labels on the bar chart,
/// which in the center of labels on the line chart.
///
abstract class TransposingAxisLabelsOrGridLines extends container_common.ChartAreaContainer {
  TransposingAxisLabelsOrGridLines({
    required super.chartViewModel,
  }) {
    _padGroup = ChartPaddingGroup(fromChartOptions: chartViewModel.chartOptions);
  }

  /// Defines either input or output data.
  ///
  /// If set to [DataDependency.inputData], implementations must use [ChartViewModel.inputRangeDescriptor],
  /// if set to [DataDependency.outputData], implementations must use [ChartViewModel.outputRangeDescriptor].
  late final DataDependency dataDependency;

  /// Determines the position, on which label centers or grid lines are placed.
  ///
  /// Bar charts on input range should be set to [MoveTickTo.middleThisAndNext],
  /// all other chart types and ranges should be set to [MoveTickTo.stayAtThis].
  late final MoveTickTo moveTickTo;

  /// Padding common to grid lines container, labels container, as well as `DataContainer`.
  late final ChartPaddingGroup _padGroup;
}

/// Abstract container of axis labels, common for input and output axis.
/// Provides factory methods to create transposing input and output axis labels container,
/// the [TransposingAxisLabels.VerticalAxis] and the [TransposingAxisLabels.HorizontalAxis].
///
/// The mixin [_LabelsOrGridContainerBuilderMixin] provides the ability to build this container of axis labels.
/// The mixin [_AxisLabelsProviderMixin] provides the ability to create this container's children (which are placed
/// to the above container).
abstract class TransposingAxisLabels extends TransposingAxisLabelsOrGridLines
    with _AxisLabelsProviderMixin, _LabelsOrGridContainerBuilderMixin
    implements _ChildrenProviderMixin, _LabelStyleMixin
{
  TransposingAxisLabels({
    required super.chartViewModel,
    required this.directionWrapperAround,
  }) {
    // Initially all [LabelContainer]s share same text style object from options.
    _labelStyle = LabelStyle(
      textStyle: chartViewModel.chartOptions.labelCommonOptions.labelTextStyle,
      textDirection: chartViewModel.chartOptions.labelCommonOptions.labelTextDirection,
      textAlign: chartViewModel.chartOptions.labelCommonOptions.labelTextAlign, // center text
      textScaleFactor: chartViewModel.chartOptions.labelCommonOptions.labelTextScaleFactor,
    );

    // Label centers are always placed at [_AxisLabelInfo.centerTickValue] - any ChartOrientation, both input and output
    moveTickTo = MoveTickTo.stayAtThis;
  }

  late final LabelStyle _labelStyle;

  /// Concrete implementer of [_LabelStyleMixin.labelStyle].
  @override
  LabelStyle get labelStyle => _labelStyle;

  factory TransposingAxisLabels.VerticalAxis({
    required ChartViewModel chartViewModel,
  }) {
    /* Removing the chartOrientation switch as in OutputGridLines does not work, as range also needs to switch
     return TransposingOutputAxisLabels(
      chartViewModel: chartViewModel,
      directionWrapperAround: _verticalWrapperAround,
    );
   */
    switch (chartViewModel.chartOrientation) {
      case ChartOrientation.column:
        return TransposingOutputAxisLabels(
          chartViewModel: chartViewModel,
          directionWrapperAround: _verticalWrapperAround,
        );
      case ChartOrientation.row:
        return TransposingInputAxisLabels(
          chartViewModel: chartViewModel,
          directionWrapperAround: _verticalWrapperAround,
        );
    }
  }

  factory TransposingAxisLabels.HorizontalAxis({
    required ChartViewModel chartViewModel,
  }) {
    switch (chartViewModel.chartOrientation) {
      case ChartOrientation.column:
        return TransposingInputAxisLabels(
          chartViewModel: chartViewModel,
          directionWrapperAround: _horizontalWrapperAround,
        );
      case ChartOrientation.row:
        return TransposingOutputAxisLabels(
          chartViewModel: chartViewModel,
          directionWrapperAround: _horizontalWrapperAround,
        );
    }
  }

  /// Implementors should be a function which takes the list of containers passed in the first argument,
  /// wrapped in a [Padder] with [Padder.edgePadding] sides created from the second argument's [ChartPaddingGroup]
  /// height and width.
  ///
  /// The [Padder]'s single child must be a [HeightSizerLayouter] or a [WidthSizerLayouter], ensuring
  /// the same sizer is used for both `DataContainer` and [TransposingAxisLabels] container
  List<BoxContainer> Function(List<BoxContainer>, ChartPaddingGroup) directionWrapperAround;

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
          top: padGroup.heightPadTop(),
          bottom: padGroup.heightPadBottom(),
        ),
        child: HeightSizerLayouter(
          children: children,
        ),
      ),
    ];
  }

  @override
  void buildAndReplaceChildren() {
    // The [directionWrapperAround] may add padding, then wraps children in [HeightSizerLayouter] or [WidthSizerLayouter]
    List<BoxContainer> children = directionWrapperAround(
      [
        // Builds container with input or output labels, ticked by input or output range.
        _buildTickedInputRangeRowOrOutputRangeColumn(
          chartViewModel: chartViewModel,
          dataDependency: dataDependency,
          moveTickTo: moveTickTo, // MoveTickTo.center
        ),
      ],
      _padGroup,
    );

    replaceChildrenWith(children);
  }

}

/// Abstract container common for containers of input and output grid lines.
abstract class TransposingGridLines extends TransposingAxisLabelsOrGridLines
    with _GridLinesProviderMixin, _LabelsOrGridContainerBuilderMixin
    implements _ChildrenProviderMixin {

  /// Constructs this container.
  TransposingGridLines({
    required super.chartViewModel,
  });

  @override
  void buildAndReplaceChildren() {
    // The [directionWrapperAround] may add padding, then wraps children in [HeightSizerLayouter] or [WidthSizerLayouter]
    List<BoxContainer> children = [
      // Builds container with input or output grid lines, ticked by input or output range.
      _buildTickedInputRangeRowOrOutputRangeColumn(
        chartViewModel: chartViewModel,
        dataDependency: dataDependency,
        moveTickTo: moveTickTo, // MoveTickTo.middleThisAndNext for barChart input, MoveTickTo.center otherwise
      ),
    ];

    replaceChildrenWith(children);
  }
}

/// Container of input axis labels.
///
/// The [directionWrapperAround] must be the same (and use same padding) as [DataContainer].
class TransposingInputAxisLabels extends TransposingAxisLabels {
  TransposingInputAxisLabels({
    required super.chartViewModel,
    required super.directionWrapperAround,

  }) {
    // set data dependency to input
    dataDependency = DataDependency.inputData;
  }

}

/// Container of output axis labels.
///
/// The [directionWrapperAround] must be the same (and use same padding) as [DataContainer].
class TransposingOutputAxisLabels extends TransposingAxisLabels {
  TransposingOutputAxisLabels({
    required super.chartViewModel,
    required super.directionWrapperAround,
  }) {
    // set data dependency to input
    dataDependency = DataDependency.outputData;
  }

}

/// Container of input grid lines.
class TransposingInputGridLines extends TransposingGridLines {

  TransposingInputGridLines({
    required super.chartViewModel,

  }) {
    // set data dependency to input
    dataDependency = DataDependency.inputData;

    // grid lines are placed at around bars, between this and next bar
    if (chartViewModel.chartType == ChartType.barChart) {
      moveTickTo = MoveTickTo.middleThisAndNext;
    } else {
      moveTickTo = MoveTickTo.stayAtThis;
    }
  }

}

/// Container of output grid lines.
class TransposingOutputGridLines extends TransposingGridLines {

  TransposingOutputGridLines({
    required super.chartViewModel,
  }) {
    // set data dependency to input
    dataDependency = DataDependency.outputData;

    // output grid lines are always at [_AxisLabelInfo.center] on any chart.
    moveTickTo = MoveTickTo.stayAtThis;
  }

}

/// Container with both horizontal and vertical grid line containers, layed out using
/// the (class-parent) [TransposingStackLayouter].
///
class TransposingCrossGridLines extends TransposingStackLayouter { //  extends NonPositioningBoxLayouter {
  TransposingCrossGridLines({
    required this.chartViewModel,
    // required this.transposingOutputGrid,
  }) {
    transposingInputGrid = TransposingInputGridLines(chartViewModel: chartViewModel);
    transposingOutputGrid = TransposingOutputGridLines(chartViewModel: chartViewModel);
  }
  final ChartViewModel chartViewModel;
  late TransposingGridLines transposingInputGrid;
  late TransposingGridLines transposingOutputGrid;

  @override
  void buildAndReplaceChildren() {
    List<BoxContainer> children =
    [
      // TransposingStackLayouter(children: [
      transposingInputGrid,
      transposingOutputGrid
      //  ]),
    ];

    replaceChildrenWith(children);
  }
}
