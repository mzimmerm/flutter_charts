import 'package:vector_math/vector_math.dart' as vector_math show Matrix2;

// base libraries
import 'package:flutter_charts/src/morphic/container/container_layouter_base.dart';
import 'package:flutter_charts/src/morphic/container/morphic_dart_enums.dart';
import 'package:flutter_charts/src/morphic/container/container_edge_padding.dart';
import 'package:flutter_charts/src/morphic/container/label_container.dart';
import 'package:flutter_charts/src/morphic/container/chart_support/chart_style.dart';
import 'package:flutter_charts/src/morphic/container/layouter_one_dimensional.dart' show Align;
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
    super.constraintsWeight, //  = const ConstraintsWeight(weight: 0),
    required super.linePaint,
    required super.chartViewModel,
  });
}

class TransposingInputAxisLine extends AxisLineContainer {
  /// Constructs a horizontal line which renders the input axis.
  /// See [TransposingOutputAxisLine] constructor.
  /// See documentation in [PointOffset.affmapInContextOf] column section for details.
  TransposingInputAxisLine({
    required DataRangeTicksAndLabelsDescriptor inputRangeDescriptor,
    required DataRangeTicksAndLabelsDescriptor outputRangeDescriptor,
    required ChartViewModel chartViewModel,
    super.constraintsWeight,
  }) : super(
          fromPointOffset: PointOffset(
            inputValue: inputRangeDescriptor.dataRange.min,
            outputValue: outputRangeDescriptor.dataRange.zeroElseMin,
          ),
          toPointOffset: PointOffset(
            inputValue: inputRangeDescriptor.dataRange.max,
            outputValue: outputRangeDescriptor.dataRange.zeroElseMin,
          ),
          linePaint: chartViewModel.chartOptions.dataContainerOptions.gridLinesPaint(),
          chartViewModel: chartViewModel,
        );

}

/// Container for the Vertical axis line only, no other elements.
/// what chart orientation.
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
    required DataRangeTicksAndLabelsDescriptor inputRangeDescriptor,
    required DataRangeTicksAndLabelsDescriptor outputRangeDescriptor,
    required ChartViewModel chartViewModel,
  }) : super(
          fromPointOffset: PointOffset(
            inputValue: inputRangeDescriptor.dataRange.zeroElseMin, // inputRangeDescriptor.dataRange.min,
            outputValue: outputRangeDescriptor.dataRange.min,
          ),
          toPointOffset: PointOffset(
            inputValue: inputRangeDescriptor.dataRange.zeroElseMin, // inputRangeDescriptor.dataRange.min,
            outputValue: outputRangeDescriptor.dataRange.max,
          ),
          linePaint: chartViewModel.chartOptions.dataContainerOptions.gridLinesPaint(),
          chartViewModel: chartViewModel,
        );
}

// -------------------------------------

/// Mixin injects children into the build methods
///   - [_InputAxisOrGridBuilderMixin._buildInputRangeTickedTransposingRow] and
///   - [_OutputAxisOrGridBuilderMixin._buildOutputRangeTickedTransposingColumn]
/// which builds the ticked axis or grid.
///
/// The passed [rangeDescriptor] is used to iterate labels on which the ticked labels or grid lines are placed. // todo-01000 : the actual labelInfo is not used. Add some kind of iterator to range to replace it.
mixin _AxisOrGridChildren {
  List<BoxContainer> _externallyTickedAxisOrGridChildren(DataDependency dataDependency);
}

/// See also [_AxisOrGridChildren].
mixin _ChildrenOfAxisMixin on TransposingAxisOrGrid implements _AxisOrGridChildren {

  @override
  List<BoxContainer> _externallyTickedAxisOrGridChildren(DataDependency dataDependency) {
    DataRangeTicksAndLabelsDescriptor rangeDescriptor = chartViewModel.rangeDescriptorFor(dataDependency);

    return [
      // Add all labels from generator as children. Labels were created and placed in [labelInfoList]
      //   in the [DataRangeTicksAndLabelsDescriptor] constructor called in the  [ChartViewModel]  constructor,
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

/// See also [_AxisOrGridChildren].
mixin _ChildrenOfGridMixin on TransposingAxisOrGrid implements _AxisOrGridChildren {

  /// Implementation of [_AxisOrGridChildren] mixin's method which injects children
  /// into the build methods for grid lines.
  ///
  /// The passed [rangeDescriptor] must be the one in direction that iterates labels or grid lines.
  ///
  /// Important note:
  ///   This method also needs the cross-descriptor, obtained by [TransposingAxisOrGrid.crossRangeDescriptorOf]
  ///   from which it needs the start and end of the grid lines!
  @override
  List<BoxContainer> _externallyTickedAxisOrGridChildren(DataDependency dataDependency) {
    DataRangeTicksAndLabelsDescriptor rangeDescriptor = chartViewModel.rangeDescriptorFor(dataDependency);
    DataRangeTicksAndLabelsDescriptor crossRangeDescriptor = crossRangeDescriptorOf(rangeDescriptor);

    // Note: NOW WE BUILD INPUT, SO rangeDescriptor == _inputRangeDescriptor

    // For the data dependency cross the   dependency lines we are building:
    //   - line is always from min to max
    // For the data dependency same as the dependency lines we are building, line is from min to

    return [
      // For each label, add a grid line in the external ticks center for line chart,
      //   in the external ticks end for bar chart.
      for (var labelInfo in rangeDescriptor.labelInfoList)
        // ChartOrientation.column inputValue:
        //   - always start at min. affmap will place it to affmap-input.min
        //   - Then, ticks will move it to tick position
        // ChartOrientation.row inputValue:
        //   - always start at max. affmap will place it to affmap-output.min
        //   - Then, ticks will move it to tick position
        //
        LineBetweenPointOffsetsContainer(
          fromPointOffset: PointOffset(
            inputValue: chartViewModel.chartOrientation == ChartOrientation.column
                ? rangeDescriptor.dataRange.min
                : rangeDescriptor.dataRange.max,
            outputValue: crossRangeDescriptor.dataRange.min, // works: crossRangeDescriptor.dataRange.min,
          ),
          toPointOffset: PointOffset(
            inputValue:  chartViewModel.chartOrientation == ChartOrientation.column
                ? rangeDescriptor.dataRange.min
                : rangeDescriptor.dataRange.max,
            outputValue: crossRangeDescriptor.dataRange.max, // works: crossRangeDescriptor.dataRange.max,
          ),
          linePaint: chartViewModel.chartOptions.dataContainerOptions.gridLinesPaint(),
          chartViewModel: chartViewModel,
        )
    ];
  }

}

// -------------------------------------
mixin _BuilderMixin {

  /// Implementations should build a container with labels (for axis) or grid lines (for grid).
  ///
  /// The container should be ticked by input or output range, depending on which range is rendered.
  ///
  /// Invoked by [TransposingAxis] and [TransposingGrid] in their core build methods
  /// [TransposingAxis.buildAndReplaceChildren] and [TransposingGrid.buildAndReplaceChildren].
  /// 
  /// Implemented by all leaf-classes, 
  /// [TransposingInputAxis],  [TransposingInputGrid], [TransposingOutputAxis], [TransposingOutputGrid], 
  /// where it delegates to either [_InputAxisOrGridBuilderMixin._buildInputRangeTickedTransposingRow]
  /// or  [_OutputAxisOrGridBuilderMixin._buildOutputRangeTickedTransposingColumn],
  /// depending on whether they are input or output containers.
  ///
  TransposingRoller _buildTickedInputRangeRowOrOutputRangeColumn();
}

/// Builds the core container for [TransposingInputAxis] or [TransposingInputGrid], 
/// ticked by input [DataRangeTicksAndLabelsDescriptor].
///
/// See the [_OutputAxisOrGridBuilderMixin] for documentation of the invoked
/// [_AxisOrGridChildren._externallyTickedAxisOrGridChildren]. and how it forms the axis or grid
/// depending on being mixed in the [TransposingAxis] or [TransposingGrid].
///
mixin _InputAxisOrGridBuilderMixin on TransposingAxisOrGrid, _AxisOrGridChildren {

  TransposingRoller _buildInputRangeTickedTransposingRow() {
    // Transposing Column with single child, the TransposingExternalTicks.Row,
    // which has one item per label in [_inputRangeDescriptor.labelInfoList]
    // todo-0100 : is the column needed here? try to remove
    return TransposingRoller.Column(
      chartOrientation: chartViewModel.chartOrientation,
      children: [
        TransposingExternalTicks.Row(
          chartOrientation: chartViewModel.chartOrientation,
          mainAxisExternalTicksLayoutDescriptor: _inputRangeDescriptor.asExternalTicksLayoutDescriptor(
            externalTickAtPosition: ExternalTickAtPosition.childCenter,
          ),
          children: _externallyTickedAxisOrGridChildren(DataDependency.inputData),
        ),
      ],
    );
  }

}

/// Builds the core container for [TransposingOutputAxis] or [TransposingOutputGrid], 
/// ticked by output [DataRangeTicksAndLabelsDescriptor].
///
/// The invoked [_AxisOrGridChildren._externallyTickedAxisOrGridChildren] is called with
/// [DataRangeTicksAndLabelsDescriptor] argument [_outputRangeDescriptor]. This call to
/// [_AxisOrGridChildren._externallyTickedAxisOrGridChildren] returns a list of:
///   - axis labels if mixed in [TransposingAxis] to form [TransposingOutputAxis] the or grid lines,
///   - grid lines if mixed in [TransposingGrid] to form [TransposingOutputGrid] the or grid lines,
///
mixin _OutputAxisOrGridBuilderMixin on TransposingAxisOrGrid, _AxisOrGridChildren {

  TransposingRoller _buildOutputRangeTickedTransposingColumn() {
    return TransposingRoller.Row(
        chartOrientation: chartViewModel.chartOrientation,
        mainAxisAlign: Align.start, // default
        isMainAxisAlignFlippedOnTranspose: false, // but do not flip to Align.end, children have no weight=no divide
        children: [
          TransposingExternalTicks.Column(
            chartOrientation: chartViewModel.chartOrientation,
            mainAxisExternalTicksLayoutDescriptor: _outputRangeDescriptor.asExternalTicksLayoutDescriptor(
              externalTickAtPosition: ExternalTickAtPosition.childCenter,
            ),
            children: _externallyTickedAxisOrGridChildren(DataDependency.outputData),
          ),
        ]);
  }

}

// -------------------------------------

/// Abstract class with factory methods to create axis and grid containers.
///
/// To support the ability to transpose, both input and output range descriptors are needed,
/// they are both available in the [ChartViewModel].
///
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

  /// Returns the descriptor of the 'other direction' axis.
  DataRangeTicksAndLabelsDescriptor crossRangeDescriptorOf(DataRangeTicksAndLabelsDescriptor rangeDescriptor) {
    if (rangeDescriptor == _inputRangeDescriptor) {
      return _outputRangeDescriptor;
    }
    if (rangeDescriptor == _outputRangeDescriptor) {
      return _inputRangeDescriptor;
    }
    throw StateError('$runtimeType: The passed descriptor $rangeDescriptor is neither of member '
        '_inputRangeDescriptor nor _outputRangeDescriptor');
  }

}

/// Abstract class common for input and output axis.
abstract class TransposingAxis extends TransposingAxisOrGrid with _ChildrenOfAxisMixin implements _BuilderMixin  {
  TransposingAxis({
    required super.chartViewModel,
    required this.directionWrapperAround,
  });

  factory TransposingAxis.OutputAxis({
    required ChartViewModel chartViewModel,
  }) {
    switch (chartViewModel.chartOrientation) {
      case ChartOrientation.column:
        return TransposingOutputAxis(
          chartViewModel: chartViewModel,
          directionWrapperAround: _verticalWrapperAround,
        );
      case ChartOrientation.row:
        return TransposingInputAxis(
          chartViewModel: chartViewModel,
          directionWrapperAround: _verticalWrapperAround,
        );
    }
  }

  factory TransposingAxis.InputAxis({
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

/// Abstract class common for input and output grid.
abstract class TransposingGrid extends TransposingAxisOrGrid with _ChildrenOfGridMixin implements _BuilderMixin {
  TransposingGrid({
    required super.chartViewModel,
  });

  factory TransposingGrid.InputGrid({
    required ChartViewModel chartViewModel,
  }) {
/* todo-00-next : check how this works, simplify, and so similar simplification on labels.
    switch (chartViewModel.chartOrientation) {
      case ChartOrientation.column:
        return TransposingInputGrid(
          chartViewModel: chartViewModel,
        );
      case ChartOrientation.row:
        return TransposingOutputGrid(
          chartViewModel: chartViewModel,
        );
    }
 */

    return TransposingInputGrid(
      chartViewModel: chartViewModel,
    );
  }

  factory TransposingGrid.OutputGrid({
    required ChartViewModel chartViewModel,
  }) {
/* todo-00-next  : check how this works, simplify, and so similar simplification on labels.
    switch (chartViewModel.chartOrientation) {
      case ChartOrientation.column:
        return TransposingOutputGrid(
          chartViewModel: chartViewModel,
        );
      case ChartOrientation.row:
        return TransposingInputGrid(
          chartViewModel: chartViewModel,
        );
    }
*/
    return TransposingOutputGrid(
      chartViewModel: chartViewModel,
    );
  }

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

/// Container of input axis.
///
/// The [directionWrapperAround] must be the same (and use same padding) as [DataContainer].
class TransposingInputAxis extends TransposingAxis with _InputAxisOrGridBuilderMixin {
  TransposingInputAxis({
    required super.chartViewModel,
    required super.directionWrapperAround,
  });

  /// When invoked by [buildAndReplaceChildren] in [TransposingAxis],
  /// builds container of labels for input range [_inputRangeDescriptor].
  @override
  TransposingRoller _buildTickedInputRangeRowOrOutputRangeColumn() {
    return _buildInputRangeTickedTransposingRow();
  }

}

/// Container of output axis.
///
/// The [directionWrapperAround] must be the same (and use same padding) as [DataContainer].
class TransposingOutputAxis extends TransposingAxis with _OutputAxisOrGridBuilderMixin {
  TransposingOutputAxis({
    required super.chartViewModel,
    required super.directionWrapperAround,
  });

  /// When invoked by [buildAndReplaceChildren] in [TransposingAxis],
  /// builds container of labels for output range [_outputRangeDescriptor].
  @override
  TransposingRoller _buildTickedInputRangeRowOrOutputRangeColumn() {
    return _buildOutputRangeTickedTransposingColumn();
  }
}

class TransposingInputGrid extends TransposingGrid with _InputAxisOrGridBuilderMixin {

  TransposingInputGrid({
    required super.chartViewModel,
  });

  /// When invoked by [buildAndReplaceChildren] in [TransposingGrid],
  /// builds container of grid lines for input range [_inputRangeDescriptor].
  @override
  TransposingRoller _buildTickedInputRangeRowOrOutputRangeColumn() {
    return _buildInputRangeTickedTransposingRow();
  }

}

class TransposingOutputGrid extends TransposingGrid with _OutputAxisOrGridBuilderMixin {

  TransposingOutputGrid({
    required super.chartViewModel,
  });

  /// When invoked by [buildAndReplaceChildren] in [TransposingGrid],
  /// builds container of grid lines for output range [_outputRangeDescriptor].
  @override
  TransposingRoller _buildTickedInputRangeRowOrOutputRangeColumn() {
    return _buildOutputRangeTickedTransposingColumn();
  }

}

/// Container with both horizontal and vertical grid lines.
///
class TransposingCrossGrid extends TransposingStackLayouter { //  extends NonPositioningBoxLayouter {
  TransposingCrossGrid({
    required this.chartViewModel,
    // required this.transposingOutputGrid,
  }) {
    transposingInputGrid = TransposingGrid.InputGrid(chartViewModel: chartViewModel);
    // , transposingOutputGrid =  TransposingGrid.HorizontalGrid(chartViewModel: chartViewModel) as TransposingOutputGrid;
  }
  final ChartViewModel chartViewModel;
  late TransposingGrid transposingInputGrid;
  // late TransposingGrid transposingOutputGrid;

  @override
  void buildAndReplaceChildren() {
    List<BoxContainer> children =
    [
      // TransposingStackLayouter(children: [
      transposingInputGrid,
      // transposingOutputGrid
      //  ]),
    ];

    replaceChildrenWith(children);
  }
}
