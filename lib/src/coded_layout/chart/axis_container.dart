import 'dart:ui' as ui show Size, Offset, Rect, Canvas;
import 'dart:math' as math show max;
import 'package:flutter_charts/src/morphic/container/morphic_dart_enums.dart';
import 'package:vector_math/vector_math.dart' as vector_math show Matrix2;
import 'package:flutter/widgets.dart' as widgets show TextStyle;

// this level or equivalent
import 'container.dart';
import 'data_container.dart';
import 'label_container.dart';
import '../../chart/container/container_common.dart';
import '../../chart/container/legend_container.dart';
import '../../chart/container/axislabels_axislines_gridlines_container.dart';
import '../../morphic/container/label_container.dart';
import '../../chart/view_model/view_model.dart';
import '../../morphic/container/container_layouter_base.dart'
    show LayoutableBox, BoxContainer;
import '../../chart/options.dart';
import '../../util/util_dart.dart';
import '../../chart/view_model/label_model.dart';
import '../../morphic/container/constraints.dart' show BoxContainerConstraints;

/// Common base class for containers of axes with their labels - [HorizontalAxisContainerCL] and [OutputAxisContainerCL].
abstract class AxisContainerCL extends ChartAreaContainer with PixelRangeProvider {
  AxisContainerCL({
    required ChartViewModel chartViewModel,
  }) : super(
    chartViewModel: chartViewModel,
  );
}

/// Container of the Y axis labels.
///
/// This [ChartAreaContainer] operates as follows:
/// - Vertically available space is all used (filled).
/// - Horizontally available space is used only as much as needed.
/// The used amount is given by maximum Y label width, plus extra spacing.
/// - See [layout] and [layoutSize] for resulting size calculations.
/// - See the [HorizontalAxisContainerCL] constructor for the assumption on [BoxContainerConstraints].
class OutputAxisContainerCL
    extends AxisContainerCL
    implements TransposingOutputAxisLabels {

  /// Constructs the container that holds Y labels.
  ///
  /// The passed [BoxContainerConstraints] is (assumed) to direct the expansion to fill
  /// all available vertical space, and only use necessary horizontal space.
  OutputAxisContainerCL({
    required ChartViewModel chartViewModel,
    required this.directionWrapperAround,
    double yLabelsMaxHeightFromFirstLayout = 0.0,
  }) : super(
    chartViewModel: chartViewModel,
  ) {
    yLabelsMaxHeightFromFirstLayout = yLabelsMaxHeightFromFirstLayout;
  }

  /// Containers of Y labels.
  late List<AxisLabelContainerCL> outputLabelContainerCLs;

  /// Maximum label height found by the first layout (pre-layout),
  /// is ONLY used to 'shorten' OutputAxisContainer constraints on top.
  double yLabelsMaxHeightFromFirstLayout = 0.0;

  /// Override needed because this member is from an implement class, not extend  class
  @override
  List<BoxContainer> Function(List<BoxContainer> p1, ChartPaddingGroup p2) directionWrapperAround;

  /// Overridden method creates this [OutputAxisContainerCL]'s hierarchy-children Y labels
  /// (instances of [OutputLabelContainer]) which are maintained in this [OutputAxisContainerCL.outputLabelContainerCLs].
  ///
  /// The reason the hierarchy-children Y labels are created late in this
  /// method [buildAndReplaceChildren] is that we MAY NOT know until the parent
  /// [chartViewModel] is being layed out, how much Y-space there is, therefore,
  /// how many Y labels would fit. BUT CURRENTLY, WE DO NOT MAKE USE OF THIS LATENESS ON [OutputAxisContainerCL],
  /// only on [HorizontalAxisContainerCL] re-layout.
  ///
  /// The created Y labels should be layed out by invoking [layout]
  /// immediately after this method [buildAndReplaceChildren]
  /// is invoked.
  @override
  void buildAndReplaceChildren() {

    // Init the list of y label containers
    outputLabelContainerCLs = [];

    // Code above MUST run for the side-effects of setting [axisPixels] and extrapolating the [labelInfos].
    // Now can check if labels are shown, set empty children and return.
    if (!chartViewModel.chartOptions.verticalAxisContainerOptions.isShown) {
      outputLabelContainerCLs = List.empty(growable: false); // must be set for yLabelsMaxHeight to function
      replaceChildrenWith(outputLabelContainerCLs);
      return;
    }

    ChartOptions options = chartViewModel.chartOptions;

    // Initially all [LabelContainer]s share same text style object from options.
    LabelStyle labelStyle = LabelStyle(
      textStyle: options.labelCommonOptions.labelTextStyle,
      textDirection: options.labelCommonOptions.labelTextDirection,
      textAlign: options.labelCommonOptions.labelTextAlign, // center text
      textScaleFactor: options.labelCommonOptions.labelTextScaleFactor,
    );

    for (AxisLabelInfo labelInfo in chartViewModel.outputRangeDescriptor.labelInfoList) {
      var outputLabelContainer = AxisLabelContainerCL(
        chartViewModel: chartViewModel,
        label: labelInfo.formattedLabel,
        labelTiltMatrix: vector_math.Matrix2.identity(), // No tilted labels in OutputAxisContainer
        labelStyle: labelStyle,
        labelInfo: labelInfo,
        outerChartAreaContainer: this,
      );

      outputLabelContainerCLs.add(outputLabelContainer);
    }

    replaceChildrenWith(outputLabelContainerCLs);
  }

  /// Lays out this [OutputAxisContainerCL] - the area containing the Y axis labels -
  /// which children were build during [buildAndReplaceChildren].
  ///
  /// As this [OutputAxisContainerCL] is [BuilderOfChildrenDuringParentLayout],
  /// this method should be called just after [buildAndReplaceChildren]
  /// which builds hierarchy-children of this container.
  ///
  /// In the hierarchy-parent [ChartRootContainerCL.layout],
  /// the call to this object's [layout] is second, after [LegendContainer.layout].
  /// This [OutputAxisContainerCL.layout] calculates [OutputAxisContainerCL]'s labels width,
  /// the width taken by this container for the Y axis labels.
  ///
  /// The remaining horizontal width of [ChartRootContainerCL.chartArea] minus
  /// [OutputAxisContainerCL]'s labels width provides remaining available
  /// horizontal space for the [GridLinesContainer] and [HorizontalAxisContainerCL].
  @override
  void layout() {
    buildAndReplaceChildren();

    // [_axisYMin] and [_axisYMax] define end points of the Y axis, in the OutputAxisContainer coordinates.
    // The [_axisYMin] does not start at 0, but leaves space for half label height
    double axisPixelsMin = yLabelsMaxHeightFromFirstLayout / 2;
    // The [_axisYMax] does not end at the constraint size, but leaves space for a vertical tick
    double axisPixelsMax =
        constraints.size.height - (chartViewModel.chartOptions.dataContainerOptions.dataBottomTickHeight);

    axisPixelsRange = Interval(axisPixelsMin, axisPixelsMax);

    // The code above must be performed for axisPixelsRange to initialize
    if (!chartViewModel.chartOptions.verticalAxisContainerOptions.isShown) {
      // Special no-labels branch must initialize the layoutSize
      layoutSize = const ui.Size(0.0, 0.0); // must be initialized
      return;
    }

    // labelInfos.extrapolateLabels(axisPixelsYMin: verticalAxisContainerAxisPixelsYMin, axisPixelsYMax: verticalAxisContainerAxisPixelsYMax);

    // Iterate, apply parent constraints, then layout all labels in [outputLabelContainerCLs],
    //   which were previously created in [_createOutputLabelContainers]
    for (var outputLabelContainer in outputLabelContainerCLs) {
      // Constraint will allow to set labelMaxWidth which has been taken out of constructor.
      outputLabelContainer.applyParentConstraints(this, BoxContainerConstraints.infinity());
      outputLabelContainer.layout();

      double yTickY = outputLabelContainer.parentOffsetTick;
      double labelTopY = yTickY - outputLabelContainer.layoutSize.height / 2;

      // Move the contained LabelContainer to correct position
      outputLabelContainer.applyParentOffset(this,
        ui.Offset(chartViewModel.chartOptions.verticalAxisContainerOptions.labelPadLR, labelTopY),
      );
    }

    // Set the [layoutSize]
    double yLabelsContainerWidth =
        outputLabelContainerCLs.map((outputLabelContainer) => outputLabelContainer.layoutSize.width).reduce(math.max) +
            2 * chartViewModel.chartOptions.verticalAxisContainerOptions.labelPadLR;

    layoutSize = ui.Size(yLabelsContainerWidth, constraints.size.height);
  }

  @override
  void applyParentOffset(LayoutableBox caller, ui.Offset offset) {
    if (!chartViewModel.chartOptions.verticalAxisContainerOptions.isShown) {
      return;
    }
    for (AxisLabelContainerCL outputLabelContainer in outputLabelContainerCLs) {
      outputLabelContainer.applyParentOffset(this, offset);
    }
  }

  @override
  void paint(ui.Canvas canvas) {
    if (!chartViewModel.chartOptions.verticalAxisContainerOptions.isShown) {
      return;
    }
    for (AxisLabelContainerCL outputLabelContainer in outputLabelContainerCLs) {
      outputLabelContainer.paint(canvas);
    }
  }

  double get yLabelsMaxHeight {
    // todo-04 replace-this-pattern-with-fold - look for '? 0.0'
    return outputLabelContainerCLs.isEmpty
        ? 0.0
        : outputLabelContainerCLs.map((outputLabelContainer) => outputLabelContainer.layoutSize.height).reduce(math.max);
  }

  // todo-00-last : throw exceptions on getters setters separately
  @override
  late DataDependency dataDependency;

  @override
  late TickPositionInLabel tickPositionInLabel;

  @override
  LabelStyle get labelStyle => throw UnimplementedError();
}

/// Container of the X axis labels.
///
/// This [ChartAreaContainer] operates as follows:
/// - Horizontally available space is all used (filled).
/// - Vertically available space is used only as much as needed.
/// The used amount is given by maximum X label height, plus extra spacing.
/// - See [layout] and [layoutSize] for resulting size calculations.
/// - See the [HorizontalAxisContainerCL] constructor for the assumption on [BoxContainerConstraints].
class HorizontalAxisContainerCL
    extends AdjustableLabelsChartAreaContainer
    with PixelRangeProvider
    implements TransposingInputAxisLabels {

  /// Constructs the container that holds X labels.
  ///
  /// The passed [BoxContainerConstraints] is (assumed) to direct the expansion to fill
  /// all available horizontal space, and only use necessary vertical space.
  HorizontalAxisContainerCL({
    required ChartViewModel chartViewModel,
    required this.directionWrapperAround,
  }) : super(
    chartViewModel: chartViewModel,
  );

  /// X labels. Can NOT be final or late, as the list changes on [reLayout]
  List<AxisLabelContainerCL> inputLabelContainerCLs = List.empty(growable: true);

  double _xGridStep = 0.0;

  double get xGridStep => _xGridStep;

  /// Size allocated for each shown label (>= [_xGridStep]
  double _shownLabelsStepWidth = 0.0;

  /// Member to manage temporary layout size during relayout.
  ///
  /// Because [layoutSize] is late final, we cannot keep setting it during relayout.
  /// Instead, we set this member, and when relayouting is done, we use it to late-set [layoutSize] once.
  ui.Size lateReLayoutSize = const ui.Size(0.0, 0.0);

  /// Override needed because this member is from an implement class, not extend  class
  @override
  List<BoxContainer> Function(List<BoxContainer> p1, ChartPaddingGroup p2) directionWrapperAround;

  @override
  /// Overridden method creates this [HorizontalAxisContainerCL]'s hierarchy-children X labels
  /// (instances of [InputLabelContainer]) which are maintained in this [inputLabelContainerCLs].
  ///
  /// The reason the hierarchy-children Y labels are created late in this
  /// method [buildAndReplaceChildren], invoked as first message send in [layout],
  /// is that we do not know until the [chartViewModel] on this [ChartAreaContainer]
  /// is being layed out, how much Y-space there is, therefore, how many X labels would fit.
  /// During re-layout, this [buildAndReplaceChildren] is invoked again, and may build
  /// less children labels in this [inputLabelContainerCLs]
  ///
  /// The created X labels should be layed out by invoking [layout]
  /// immediately after this method [buildAndReplaceChildren]
  /// is invoked.
  void buildAndReplaceChildren() {

    // First clear any children that could be created on nested re-layout
    inputLabelContainerCLs = List.empty(growable: true);

    ChartOptions options = chartViewModel.chartOptions;
    List<AxisLabelInfo> inputUserLabels = chartViewModel.inputRangeDescriptor.labelInfoList;
    LabelStyle labelStyle = _styleForLabels(options);

    // Core layout loop, creates a AxisLabelContainer from each xLabel,
    //   and lays out the InputLabelContainers along X in _gridStepWidth increments.

    for (int xIndex = 0; xIndex < inputUserLabels.length; xIndex++) {
      var inputLabelContainer = AxisLabelContainerCL(
        chartViewModel: chartViewModel,
        label: inputUserLabels[xIndex].formattedLabel,
        labelTiltMatrix: labelLayoutStrategy.labelTiltMatrix, // Possibly tilted labels in HorizontalAxisContainer
        labelStyle: labelStyle,
        // In [InputLabelContainer], [labelInfo] is NOT used, as we do not create LabelInfo for XAxis
        labelInfo: chartViewModel.inputRangeDescriptor.labelInfoList[xIndex],
        outerChartAreaContainer: this,
      );
      inputLabelContainerCLs.add(inputLabelContainer);
    }
    replaceChildrenWith(inputLabelContainerCLs);
  }

  @override
  /// Lays out the chart in horizontal (x) direction.
  ///
  /// Evenly divides the available width to all labels (spacing included).
  /// First / Last vertical line is at the center of first / last label.
  ///
  /// The layout is independent of whether the labels are tilted or not,
  ///   in the sense that all tilting logic is in
  ///   [LabelContainer], and queried by [LabelContainer.layoutSize].
  void layout() {
    buildAndReplaceChildren();

    ChartOptions options = chartViewModel.chartOptions;

    // Purely artificial on HorizontalAxisContainer for now, we are taking labels from data, or user, NOT generating range.
    axisPixelsRange = chartViewModel.dataRangeWhenStringLabels;

    List<AxisLabelInfo> inputUserLabels = chartViewModel.inputRangeDescriptor.labelInfoList;
    double       yTicksWidth =
        options.dataContainerOptions.dataLeftTickWidth + options.dataContainerOptions.dataRightTickWidth;
    double       availableWidth = constraints.size.width - yTicksWidth;
    double       labelMaxAllowedWidth = availableWidth / inputUserLabels.length;
    int numShownLabels    = (inputUserLabels.length ~/ labelLayoutStrategy.showEveryNthLabel);
    _xGridStep            = labelMaxAllowedWidth;
    _shownLabelsStepWidth = availableWidth / numShownLabels;

    // Layout all X labels in inputLabelContainerCLs created and added in [buildAndAddChildrenLateDuringParentLayout]
    int xIndex = 0;
    for (AxisLabelContainerCL inputLabelContainer in inputLabelContainerCLs) {
      inputLabelContainer.applyParentConstraints(this, BoxContainerConstraints.infinity());
      inputLabelContainer.layout();

      // We only know if parent ordered skip after layout (because some size is too large)
      inputLabelContainer.applyParentOrderedSkip(this, !_isLabelOnIndexShown(xIndex));

      // Core of X layout calcs - get the layed out label size,
      //   then find xTickX - the X middle of the label bounding rectangle in hierarchy-parent [HorizontalAxisContainer]
      ui.Rect labelBound = ui.Offset.zero & inputLabelContainer.layoutSize;
      double halfStepWidth = _xGridStep / 2;
      double atIndexOffset = _xGridStep * xIndex;
      double xTickX = halfStepWidth + atIndexOffset + options.dataContainerOptions.dataLeftTickWidth;
      double labelTopY = options.horizontalAxisContainerOptions.labelPadTB; // down by HorizontalAxisContainer padding

      inputLabelContainer.parentOffsetTick = xTickX;

      // tickX and label centers are same. labelLeftTop = label paint start.
      var labelLeftTop = ui.Offset(
        xTickX - labelBound.width / 2,
        labelTopY,
      );

      // labelLeftTop + offset for envelope
      inputLabelContainer.applyParentOffset(this, labelLeftTop + inputLabelContainer.tiltedLabelEnvelopeTopLeft);

      xIndex++;
    }

    // Set the layout size calculated by this layout. This may be called multiple times during relayout.
    lateReLayoutSize = ui.Size(
      constraints.size.width,
      xLabelsMaxHeight + 2 * options.horizontalAxisContainerOptions.labelPadTB,
    );

    if (!chartViewModel.chartOptions.horizontalAxisContainerOptions.isShown) {
      // If not showing this container, no layout needed, just set size to 0.
      lateReLayoutSize = const ui.Size(0.0, 0.0);
      return;
    }

    // This achieves auto-layout of labels to fit along X axis.
    // Iterative call to this layout method, until fit or max depth is reached,
    //   whichever comes first.
    labelLayoutStrategy.reLayout(BoxContainerConstraints.unused());
  }

  /// Get the height of xlabels area without padding.
  double get xLabelsMaxHeight {
    return inputLabelContainerCLs.isEmpty
        ? 0.0
        : inputLabelContainerCLs.map((inputLabelContainer) => inputLabelContainer.layoutSize.height).reduce(math.max);
  }

  LabelStyle _styleForLabels(ChartOptions options) {
    // Use widgets.TextStyle obtained from ChartOptions and "extend it" as a copy, so a
    //   (potentially modified) TextStyle from Options is used in all places in flutter_charts.

    widgets.TextStyle labelTextStyle = options.labelCommonOptions.labelTextStyle.copyWith(
      fontSize: labelLayoutStrategy.labelFontSize,
    );

    // Initially all [LabelContainer]s share same text style object from options.
    LabelStyle labelStyle = LabelStyle(
      textStyle: labelTextStyle,
      textDirection: options.labelCommonOptions.labelTextDirection,
      textAlign: options.labelCommonOptions.labelTextAlign, // center text
      textScaleFactor: options.labelCommonOptions.labelTextScaleFactor,
    );
    return labelStyle;
  }

  @override
  void applyParentOffset(LayoutableBox caller, ui.Offset offset) {
    if (!chartViewModel.chartOptions.horizontalAxisContainerOptions.isShown) {
      return;
    }
    // super.applyParentOffset(caller, offset); // super did double-offset as inputLabelContainer are on 2 places

    for (AxisLabelContainerCL inputLabelContainer in inputLabelContainerCLs) {
      inputLabelContainer.applyParentOffset(this, offset);
    }
  }

  /// Paints this [HorizontalAxisContainerCL] on the passed [canvas].
  ///
  /// Delegates painting to all contained [ChartLabelContainer]s.
  /// Any contained [ChartLabelContainer] must have been offset to the appropriate position.
  ///
  /// A special situation is when the [ChartLabelContainer]s are tilted, say counterclockwise.
  /// Because labels are always painted horizontally in the screen coordinate system, we much tilt them
  /// by painting them on a rotated position.
  /// This is achieved as follows: At the moment of calling this [paint],
  /// the top-left corner of the container (where the label will start painting), must be moved
  /// by rotation from the it's intended position clockwise. The [canvas]
  /// will be saved, then rotated, then labels painted horizontally into the offset,
  /// then the canvas rotated back for further painting.
  /// The canvas rotation back counterclockwise 'carries' with it the horizontally painted labels,
  /// which end up in the intended position but rotated counterclockwise.
  @override
  void paint(ui.Canvas canvas) {
    if (!chartViewModel.chartOptions.horizontalAxisContainerOptions.isShown) {
      return;
    }
    if (labelLayoutStrategy.isRotateLabelsReLayout) {
      // Tilted X labels. Must use canvas and offset coordinate rotation.
      canvas.save();
      canvas.rotate(labelLayoutStrategy.labelTiltRadians);

      _paintLabelContainers(canvas);

      canvas.restore();
    } else {
      // Horizontal X labels, potentially skipped or shrinked
      _paintLabelContainers(canvas);
    }
  }

  void _paintLabelContainers(canvas) {
    for (AxisLabelContainerCL  inputLabelContainer in inputLabelContainerCLs) {
      if (!inputLabelContainer.orderedSkip) inputLabelContainer.paint(canvas);
    }
  }

  bool _isLabelOnIndexShown(int xIndex) {
    if (xIndex % labelLayoutStrategy.showEveryNthLabel == 0) return true;
    return false;
  }

  // Checks the contained labels, represented as [AxisLabelContainer],
  // for overlap.
  //
  /// Only should be called after [layout]
  ///
  /// Identifying overlap is crucial in labels auto-layout.
  ///
  /// Notes:
  /// - [_xGridStep] is a limit for each label container width in the X direction.
  ///
  /// - Labels are layed out evenly, so if any label container's [layoutSize]
  /// in the X direction overflows the [_xGridStep],
  /// labels containers DO overlap. In such situation, the caller should
  /// take action to make labels smaller, tilt, or skip.
  ///
  @override
  bool labelsOverlap() {
    if (inputLabelContainerCLs.any((axisLabelContainer) =>
    !axisLabelContainer.orderedSkip && axisLabelContainer.layoutSize.width > _shownLabelsStepWidth)) {
      return true;
    }

    return false;
  }
  // todo-00-last : throw exceptions on getters setters separately
  @override
  late final DataDependency dataDependency;

  @override
  late final TickPositionInLabel tickPositionInLabel;

  @override
  LabelStyle get labelStyle => throw UnimplementedError();

}
