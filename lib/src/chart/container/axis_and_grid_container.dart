import 'package:vector_math/vector_math.dart' as vector_math show Matrix2;

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



// this level libraries
import 'container_common.dart' as container_common;
import 'line_segment_container.dart';

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

/// Mixin injects children (labels or grid lines)
/// into the methods which build the ticked axis labels or grid lines containers;
/// Those build method is one of:
///   - [_InputAxisOrGridBuilderMixin._buildInputRangeTickedTransposingRow] and
///   - [_OutputAxisOrGridBuilderMixin._buildOutputRangeTickedTransposingColumn].
///
/// The passed [axisDataDependency] defines if the method builds the input or output;
/// it is translated to [DataRangeTicksAndLabelsDescriptor] which is used to iterate the ticked
/// labels or grid lines.
mixin _AxisOrGridChildrenMixin {
  List<BoxContainer> _externallyTickedAxisLabelsOrGridLinesOnAxis({
    required DataDependency axisDataDependency,
  });
}


/// See [_AxisOrGridChildrenMixin].
mixin _ChildrenOfAxisMixin on TransposingAxisLabelsOrGridLines implements _AxisOrGridChildrenMixin {

  @override
  List<BoxContainer> _externallyTickedAxisLabelsOrGridLinesOnAxis({
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
          // No tilted labels in OutputAxisContainer
          labelStyle: _labelStyle,
        )
    ];
  }
}

/// Implements [_externallyTickedAxisLabelsOrGridLinesOnAxis] for grid lines.
///
/// The implementation returns a list of [LineBetweenPointOffsetsContainer], each
/// representing one grid line for input axis or output axis, as defined by the passed [axisDataDependency].
///
/// See also [_AxisOrGridChildrenMixin].
///
///
mixin _ChildrenOfGridMixin on TransposingAxisLabelsOrGridLines implements _AxisOrGridChildrenMixin {

  /// Implementation of [_AxisOrGridChildrenMixin] mixin's method which injects children
  /// into the build methods for grid lines.
  ///
  /// The passed [axisDataDependency] describes the children (labels for axis, grid lines for grid)
  /// being build:
  ///   - for [axisDataDependency] equal to [DataDependency.inputData], children for input axis are built;
  ///     that also implies that the [_inputRangeDescriptor] is used to 
  ///
  /// Important note:
  ///   This method also needs the cross-descriptor, obtained by [ChartViewModel.crossRangeDescriptorFor]
  ///   from which it needs the start and end of the grid lines!
  @override
  List<BoxContainer> _externallyTickedAxisLabelsOrGridLinesOnAxis({
    required DataDependency axisDataDependency,
  }) {

    DataRangeTicksAndLabelsDescriptor rangeDescriptor = chartViewModel.rangeDescriptorFor(axisDataDependency);
    DataRangeTicksAndLabelsDescriptor crossRangeDescriptor = chartViewModel.crossRangeDescriptorFor(axisDataDependency);

    // The dataDependency for which we build these grid lines,
    // is cross to the direction of the grid lines, in detail:
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
mixin _AxisOrGridBuilderMixin {

  /// Implementations should build a container with labels (for axis) or grid lines (for grid).
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
  ///
  TransposingExternalTicks _buildTickedInputRangeRowOrOutputRangeColumn();
}

/// Builds the core container for [TransposingInputAxisLabels] or [TransposingInputGridLines], 
/// ticked by the input range descriptor [DataRangeTicksAndLabelsDescriptor].
///
/// See the [_OutputAxisOrGridBuilderMixin] for documentation of the invoked
/// [_AxisOrGridChildrenMixin._externallyTickedAxisLabelsOrGridLinesOnAxis], for how it builds
/// the axis or grid container depending on being mixed in the [TransposingAxisLabels] or [TransposingGridLines].
///
mixin _InputAxisOrGridBuilderMixin on TransposingAxisLabelsOrGridLines, _AxisOrGridChildrenMixin {
  /// Wraps children (grid lines or labels injected by _AxisOrGridChildrenMixin) in TransposingExternalTicks.Row
  TransposingExternalTicks _buildInputRangeTickedTransposingRow() {
    return TransposingExternalTicks.Row(
      chartOrientation: chartViewModel.chartOrientation,
      mainAxisExternalTicksLayoutDescriptor: chartViewModel.inputRangeDescriptor.asExternalTicksLayoutDescriptor(
        externalTickAtPosition: ExternalTickAtPosition.childCenter,
      ),
      children: _externallyTickedAxisLabelsOrGridLinesOnAxis(axisDataDependency: DataDependency.inputData),
    );
  }
}

/// Builds the core container for [TransposingOutputAxisLabels] or [TransposingOutputGridLines], 
/// ticked by output [DataRangeTicksAndLabelsDescriptor].
///
/// The invoked [_AxisOrGridChildrenMixin._externallyTickedAxisLabelsOrGridLinesOnAxis] is called with
/// [DataRangeTicksAndLabelsDescriptor] argument [_outputRangeDescriptor]. This call to
/// [_AxisOrGridChildrenMixin._externallyTickedAxisLabelsOrGridLinesOnAxis] returns a list of:
///   - axis labels if mixed in [TransposingAxisLabels] to form [TransposingOutputAxisLabels] the or grid lines,
///   - grid lines if mixed in [TransposingGridLines] to form [TransposingOutputGridLines] the or grid lines,
///
mixin _OutputAxisOrGridBuilderMixin on TransposingAxisLabelsOrGridLines, _AxisOrGridChildrenMixin {

  /// Wraps children (grid lines or labels injected by _AxisOrGridChildrenMixin) in TransposingExternalTicks.Column
  TransposingExternalTicks _buildOutputRangeTickedTransposingColumn() {
    return TransposingExternalTicks.Column(
      chartOrientation: chartViewModel.chartOrientation,
      mainAxisExternalTicksLayoutDescriptor: chartViewModel.outputRangeDescriptor.asExternalTicksLayoutDescriptor(
        externalTickAtPosition: ExternalTickAtPosition.childCenter,
      ),
      children: _externallyTickedAxisLabelsOrGridLinesOnAxis(axisDataDependency: DataDependency.outputData),
    );
  }
}

// -------------------------------------

/// Abstract class which concrete extensions create the containers for axis labels and grid lines.
///
/// To support the ability to transpose, both input and output range descriptors are needed,
/// they are both available in the [ChartViewModel].
///
abstract class TransposingAxisLabelsOrGridLines extends container_common.ChartAreaContainer {
  TransposingAxisLabelsOrGridLines({
    required super.chartViewModel,
  }) {
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
  late final LabelStyle _labelStyle;

}

/// Abstract container of axis labels, common for input and output axis.
/// Provides factory methods to create input and output axis labels container.
abstract class TransposingAxisLabels extends TransposingAxisLabelsOrGridLines with _ChildrenOfAxisMixin implements _AxisOrGridBuilderMixin  {
  TransposingAxisLabels({
    required super.chartViewModel,
    required this.directionWrapperAround,
  });

  factory TransposingAxisLabels.OutputAxis({
    required ChartViewModel chartViewModel,
  }) {
    /* Removing the switch as in OutputGridLines does not work.
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

  factory TransposingAxisLabels.InputAxis({
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
          top: padGroup.heightPadTopOfYAndData(),
          bottom: padGroup.heightPadBottomOfYAndData(),
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
        _buildTickedInputRangeRowOrOutputRangeColumn(),
      ],
      _padGroup,
    );

    replaceChildrenWith(children);
  }

}

/// Abstract class common for containers of input and output grid lines.
abstract class TransposingGridLines extends TransposingAxisLabelsOrGridLines with _ChildrenOfGridMixin implements _AxisOrGridBuilderMixin {
  TransposingGridLines({
    required super.chartViewModel,
  });

  @override
  void buildAndReplaceChildren() {
    // The [directionWrapperAround] may add padding, then wraps children in [HeightSizerLayouter] or [WidthSizerLayouter]
    List<BoxContainer> children =  [
        // Builds container with input or output grid lines, ticked by input or output range.
        _buildTickedInputRangeRowOrOutputRangeColumn(),
      ];

    replaceChildrenWith(children);
  }

}

/// Container of input axis labels.
///
/// The [directionWrapperAround] must be the same (and use same padding) as [DataContainer].
class TransposingInputAxisLabels extends TransposingAxisLabels with _InputAxisOrGridBuilderMixin {
  TransposingInputAxisLabels({
    required super.chartViewModel,
    required super.directionWrapperAround,
  });

  /// When invoked by [buildAndReplaceChildren] in [TransposingAxisLabels],
  /// builds container of labels for input range [_inputRangeDescriptor].
  @override
  TransposingExternalTicks _buildTickedInputRangeRowOrOutputRangeColumn() {
    return _buildInputRangeTickedTransposingRow();
  }

}

/// Container of output axis labels.
///
/// The [directionWrapperAround] must be the same (and use same padding) as [DataContainer].
class TransposingOutputAxisLabels extends TransposingAxisLabels with _OutputAxisOrGridBuilderMixin {
  TransposingOutputAxisLabels({
    required super.chartViewModel,
    required super.directionWrapperAround,
  });

  /// When invoked by [buildAndReplaceChildren] in [TransposingAxisLabels],
  /// builds container of labels for output range [_outputRangeDescriptor].
  @override
  TransposingExternalTicks _buildTickedInputRangeRowOrOutputRangeColumn() {
    return _buildOutputRangeTickedTransposingColumn();
  }
}

/// Container of input grid lines.
class TransposingInputGridLines extends TransposingGridLines with _InputAxisOrGridBuilderMixin {

  TransposingInputGridLines({
    required super.chartViewModel,
  });

  /// When invoked by [buildAndReplaceChildren] in [TransposingGridLines],
  /// builds container of grid lines for input range [_inputRangeDescriptor].
  @override
  TransposingExternalTicks _buildTickedInputRangeRowOrOutputRangeColumn() {
    return _buildInputRangeTickedTransposingRow();
  }

}

/// Container of output grid lines.
class TransposingOutputGridLines extends TransposingGridLines with _OutputAxisOrGridBuilderMixin {

  TransposingOutputGridLines({
    required super.chartViewModel,
  });

  /// When invoked by [buildAndReplaceChildren] in [TransposingGridLines],
  /// builds container of grid lines for output range [_outputRangeDescriptor].
  @override
  TransposingExternalTicks _buildTickedInputRangeRowOrOutputRangeColumn() {
    return _buildOutputRangeTickedTransposingColumn();
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
