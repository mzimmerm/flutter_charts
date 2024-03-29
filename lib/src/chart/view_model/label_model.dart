import 'dart:math' as math show min, max, pow;

// This level
import 'package:flutter_charts/src/chart/view_model/view_model.dart';

import 'package:flutter_charts/src/morphic/container/chart_support/chart_style.dart';

import 'package:flutter_charts/src/morphic/container/morphic_dart_enums.dart';
import 'package:flutter_charts/src/morphic/container/container_layouter_base.dart' show ExternalTicksLayoutDescriptor, ExternalTicksBoxLayouter;
import 'package:flutter_charts/src/morphic/container/layouter_one_dimensional.dart'
    show LayedoutLengthsPositioner, LengthsPositionerProperties, PositionedLineSegments, Align, Packing;
import 'package:flutter_charts/src/chart/model/data_model.dart';
import 'package:flutter_charts/src/chart/options.dart';

import 'package:flutter_charts/src/util/util_dart.dart' as util_dart;


/// Generates, describes, and manages the data range of values shown on chart, as well as label values,
/// and the tick values shown.
///
/// Part of View Model, rather than Model, as it depends on stacking, a view specific behavior.
///
/// Responsibility includes
///   1. management of data range,
///   2. management of labels
///   3. management of label values and positions (ticks),
///   4. transformations, formatting and affmap-ing (layout) of label positions to axis pixels.
///
/// The last step (4.) is delegated to [ExternalTicksLayoutDescriptor] by converting this instance to it,
/// using method [asExternalTicksLayoutDescriptor].
///
/// During construction, decides how many labels will be created, and generates points on which the labels
/// will be placed (these points are also values of the labels).
///
/// Data range and label values are generated using values in [ChartModel], unless labels are user defined.
///
class DataRangeTicksAndLabelsDescriptor {

  /// Generative constructor allows to create and manage labels, irrespective whether user defined, or generated
  /// by this [DataRangeTicksAndLabelsDescriptor].
  ///
  /// If [userLabels] list of user labels is passed, user labels will be used and distributed evenly (linearly)
  /// between the passed [chartModel] minimum and maximum.
  /// Otherwise, new labels are automatically generated with values of
  /// highest order of numeric values in the passed [chartModel].
  ///
  /// Parameters discussion:
  ///
  /// - [chartModel] contains the numeric data values, passed to constructor.
  ///   An envelope is created from the [chartModel] values, possibly extending the envelope interval to start or end at 0.
  ///   Whether the envelope interval starts or ends at 0.0, even if data are away from 0.0, is controlled by member
  ///   [extendAxisToOrigin].
  /// - [userLabels] may be set by user.
  /// - [_labelInfos] and [dataRange] are created from [dataMode] for only the highest order of values
  ///   in [chartModel], and can be both wider or narrower than extremes of the [chartModel].
  ///     1. Ex1. for [chartModel] values [-600.0 .. 2200.0]
  ///             ==> [labelInfos] =   [-1000, 0, 1000, 2000] (NARROWER THAN chartModel max 2200)
  ///             ==> [dataRange] = [-600 .. 2200]
  ///     2. Ex2. for [chartModel] values  [0.0 .. 1800.0]
  ///             ==> [labelInfos]   = [0, 1000, 2000]
  ///             ==> [dataRange] = [0 .. 2000] (WIDER than chartModel max 1800)
  ///
  /// Constructor calculates the following members:
  ///   - [dataRange]
  ///   - [_labelInfos]
  DataRangeTicksAndLabelsDescriptor({
    required this.chartOrientation,
    required ChartStacking chartStacking,
    required ChartViewModel chartViewModel,
    required this.dataDependency,
    required bool extendAxisToOrigin,
    required Function valueToLabel,
    required Function inverseTransform,
    List<String>? userLabels,
  })  :
        _valueToLabel = valueToLabel,
        _inverseTransform = inverseTransform
  {
    util_dart.Interval dataEnvelope;
    List<double> transformedLabelValues;

    // Finds the [dataRange] interval for data values
    //   (which may be an envelop around values, for example if we want to always start at 0),
    //   then creates [_labelInfos] labels evenly distributed in the [dataRange] interval.
    // Both local [dataEnvelope] and member [dataRange]
    //   are **transformed && not-extrapolated** data from [ChartModelPoint].
    if (userLabels != null) {
      switch(dataDependency) {
        case DataDependency.inputData:
          // On independent (X) axis, any stand-in interval will suffice, so pick <0.0-100.0>. Whatever
          //   the interval is, once the pixels range on the axis is available,
          //   it will be affmap-ed to the pixel range.
          // We COULD return the same valuesInterval(isStacked: isStacked) but
          //   as that is for dependent data, it would be confusing.
          dataEnvelope = chartViewModel.dataRangeWhenStringLabels;
          transformedLabelValues = _placeLabelPointsInInterval(
            interval: dataEnvelope,
            labelPointsCount: userLabels.length,
            pointPositionInSegment: util_dart.LineSegmentPosition.center,
          );
          break;
        case DataDependency.outputData:
          // This is ONLY needed for legacy coded_layout to work
          // On dependent (Y) axis, with user labels, we have to use actual data values,
          //   because all scaling uses actual data values
          dataEnvelope = chartViewModel.valuesInterval(chartStacking: chartStacking);
          double dataStepHeight = (dataEnvelope.max - dataEnvelope.min) / (userLabels.length - 1);
          transformedLabelValues =
              List.generate(userLabels.length, (index) => dataEnvelope.min + index * dataStepHeight);
          break;
      }
    } else {
      dataEnvelope = chartViewModel.extendedValuesInterval(
        extendAxisToOrigin: extendAxisToOrigin,
        chartStacking: chartStacking,
      );
      transformedLabelValues = _generateValuesForLabelsIn(
        interval: dataEnvelope,
        extendAxisToOrigin: extendAxisToOrigin,
      );
    }

    // Store the merged interval of values and label envelope for [AxisLabelInfos] creation
    // that can be created immediately after by invoking [createAxisLabelInfos].
    dataRange = util_dart.Interval(
      transformedLabelValues.reduce(math.min),
      transformedLabelValues.reduce(math.max),
    ).merge(dataEnvelope);

    // Format and extrapolate labels from the [_labelPositions] local to the [_labelInfos] member.
    List<AxisLabelInfo> labelInfos = transformedLabelValues
        .map((transformedLabelValue) =>
        AxisLabelInfo(
          centerTickValue: transformedLabelValue,
          outerRangeDescriptor: this,
        ))
        .toList();
    _labelInfos = _AxisLabelInfos(
      from: labelInfos,
      rangeDescriptor: this,
      userLabels: userLabels,
    );

  }

  final ChartOrientation chartOrientation; // todo-done-keep-for-later-removal : KEEP : added as a temporary to test old vs new

  /// Describes if this [DataRangeTicksAndLabelsDescriptor] instance is for dependent or independent data.
  ///
  /// [DataDependency.outputData] determines this instance is for dependent data,
  /// [DataDependency.inputData] determines this instance is for independent data.
  ///
  /// The significance of dependent/independent is
  final DataDependency dataDependency;

  /// Describes labels - their values and String values.
  /// Important note: [_AxisLabelInfos] should NOT be part of model,
  ///                 as different views would have a different instance of it.
  ///                 Reason: Different views may have different labels, esp. on the axis.
  late final _AxisLabelInfos _labelInfos;

  /// Returns label list, optionally reversed.
  ///
  /// If [isReversed] true, the labels list is reversed from the default order in [_labelInfos._labelInfoList].
  ///
  /// Intended for a potential use when adding labels to layouter children,
  /// private for now as it is currently not used outside of this class.
  ///
  /// See [labelInfoList] for details
  List<AxisLabelInfo> _reversibleLabelInfoList({bool isReversed = false}) {
    List<AxisLabelInfo> labels = List.from(_labelInfos._labelInfoList, growable: false);
    if (isReversed) {
      labels = labels.reversed.toList(growable: false);
    }
    return labels;
  }


  /// The list of labels and their infos kept in [AxisLabelInfo].
  ///
  /// The list contains labels passed from user, or originating in code, as follows:
  ///
  ///   - If userLabels are passed in constructor [DataRangeTicksAndLabelsDescriptor],
  ///     the returned list in [labelInfoList] is in the same order as userLabels.
  ///   - Otherwise, data labels are generated by [DataRangeTicksAndLabelsDescriptor], and returned here in [labelInfoList].
  ///     The [AxisLabelInfo.centerTickValue]s in [labelInfoList] are numerically always numerically increasing.
  ///
  /// The labels' pixel layout placing is determined by values of [ExternalTicksLayoutDescriptor.tickPixels] created
  ///   during [ExternalTicksBoxLayouter]s  layout. The [ExternalTicksLayoutDescriptor.tickPixels] are used
  ///   to position rectangles with the labels in the returned [labelInfoList].
  ///
  /// See [ExternalTicksLayoutDescriptor.tickPixels] for placement logic of the returned label infos.
  /// See [_reversibleLabelInfoList] for a reversed list.
  List<AxisLabelInfo> get labelInfoList => _reversibleLabelInfoList(isReversed: false);

  /// The numerical range of data.
  ///
  /// Calculated in the constructor, from [ChartModelPoint]s.
  /// as the merged outer interval of generated labels and [ChartModelPoint] values.
  ///
  /// This [Interval] is displayed on the axis pixel range [AxisContainer.axisPixelsRange].
  /// Extrapolation is done between those intervals.
  late final util_dart.Interval dataRange;

  double dataRangeRatioOfPortionWithSign(Sign sign) {
    switch(sign) {
      case Sign.positiveOr0:
        return dataRange.ratioOfPositivePortion();
      case Sign.negative:
        return dataRange.ratioOfNegativePortion();
      case Sign.any:
        return dataRange.ratioOfAnySignPortion();
    }
  }

  /// The function converts value to label.
  ///
  /// Assigned from a corresponding function [ChartOptions.verticalAxisContainerOptions.outputValueToLabel].
  final Function _valueToLabel;

  /// The function for data inverse transform.
  ///
  /// Assigned from a corresponding function [ChartOptions.dataContainerOptions.yInverseTransform].
  final Function _inverseTransform;

  /// Given the member [chartOrientation] and passed [axisDataDependency], deduces if this [DataRangeTicksAndLabelsDescriptor]
  /// labels will be shown on [LayoutAxis.vertical] or [LayoutAxis.horizontal].
  ///
  /// Returns true if this [DataRangeTicksAndLabelsDescriptor] labels will be shown on [LayoutAxis.vertical].
  bool get isOnHorizontalAxis =>
      chartOrientation.layoutAxisForDataDependency(dataDependency: dataDependency) == LayoutAxis.horizontal;

  /// Extrapolates [value] from extended data range [dataRange],
  /// to the pixels range passed in the passed [axisPixelsMin], [axisPixelsMax].
  ///
  /// Lifecycle: This method must be invoked in or after [BoxLayouter.layout],
  ///            after the axis size is calculated.
  ///
  /// todo-04-cl-removal: used only for CL. Remove
  double affmapValueToPixels({
    required double value,
    required double axisPixelsMin,
    required double axisPixelsMax,
  }) {

    // Special case, if _rangeDescriptor.dataRange=(0.0,0.0), there are either no data, or all data 0.
    // Affmap the result to either start or end of the axis pixels, depending on [isAxisAndLabelsSameDirection]
    if (dataRange == const util_dart.Interval(0.0, 0.0)) {
      double pixels;
      if (!isOnHorizontalAxis) {
        pixels = axisPixelsMax;
      } else {
        pixels = axisPixelsMin;
      }
      return pixels;
    }
    // affmap the data value range [dataRange] on this [DataRangeTicksAndLabelsDescriptor] to the pixel range.
    // The pixel range must be the pixel range available to axis after [BoxLayouter.layout].
    return util_dart.ToPixelsAffineMap1D(
      fromValuesRange: util_dart.Interval(dataRange.min, dataRange.max),
      toPixelsRange: util_dart.Interval(axisPixelsMin, axisPixelsMax),
      isFlipToRange: !isOnHorizontalAxis,
    ).apply(value);
  }

  /// Creates an instance of [ExternalTicksLayoutDescriptor] from self.
  ///
  /// As this [DataRangeTicksAndLabelsDescriptor] holds on everything about relative (data ranged)
  /// position of labels, it can be converted to a provider of these label positions as tick values
  /// for layouts that use externally defined positions to layout their children on the tick values.
  ///
  /// The tick values can be placed at the start, center, or end of the labels, depending on
  /// the passed [externalTickAtPosition] value:
  ///   - For value [ExternalTickAtPosition.childStart], each tick is at the start of each label
  ///   - For value [ExternalTickAtPosition.childCenter], each tick is at the center of each label
  ///   - For value [ExternalTickAtPosition.childEnd], each tick is at the end of each label.
  ///
  /// The passed [moveTickTo] moves the tick from the position determined
  /// by the [externalTickAtPosition] value as follows:
  ///   - For value [MoveTickTo.middlePreviousAndThis], each tick is moved to the center point between
  ///     the previous tick and this tick (both previously determined by [externalTickAtPosition])
  ///   - For value [MoveTickTo.stayAtThis], each tick remains as the position determined by [externalTickAtPosition]
  ///   - For value [MoveTickTo.middleThisAndNext], each tick is is moved to the center point between
  ///     this tick and the next tick (both previously determined by [externalTickAtPosition])
  ///
  ///
  ExternalTicksLayoutDescriptor asExternalTicksLayoutDescriptor({
    required ExternalTickAtPosition externalTickAtPosition,
    MoveTickTo moveTickTo = MoveTickTo.stayAtThis,
  }) {
    // Return [ExternalTicksLayoutDescriptor] and provide ticks.
    // The ticks must be affmap-ed to pixels, once ticksPixelsRange is known.
    // See [ExternalTicksBoxLayouter].
    List<double> tickValues;
    switch(moveTickTo) {
      case MoveTickTo.middlePreviousAndThis:
        tickValues =  labelInfoList.map((labelInfo) => labelInfo.leftBorderTickValue).toList(growable: false);
        break;
      case MoveTickTo.stayAtThis:
        tickValues = labelInfoList.map((labelInfo) => labelInfo.centerTickValue).toList(growable: false);
        break;
      case MoveTickTo.middleThisAndNext:
        tickValues =  labelInfoList.map((labelInfo) => labelInfo.rightBorderTickValue).toList(growable: false);
        break;
    }

    return ExternalTicksLayoutDescriptor(
      tickValues: tickValues,
      tickValuesRange: dataRange,
      isOnHorizontalAxis: isOnHorizontalAxis,
      externalTickAtPosition: externalTickAtPosition,
    );
  }

  /// Places [labelPointsCount] positions evenly distanced in [interval] between [interval.min]
  /// and [interval.max], and returns the positions list.
  ///
  /// Motivation and role:
  ///   We need to evenly place [labelPointsCount] labels inside [interval].
  ///   This method allows to do that, returning positions of label starts, label centers,
  ///   or label ends in the [interval]. The positions are controlled by the passed [pointPositionInSegment].
  ///
  /// Algorithm:
  ///   The returned positions list is calculated by dividing the [interval] into [labelPointsCount]
  ///   line segments of type [util_dart.LineSegment], and returning the start, center, or end of the line segments,
  ///   depending on [pointPositionInSegment] set to one of [util_dart.LineSegmentPosition.min],
  ///   [util_dart.LineSegmentPosition.center], or [util_dart.LineSegmentPosition.max]
  ///
  /// Notes:
  ///   1. This algorithm makes no attempt to guarantee whether each label actually fits it's allocated line segment
  ///      [util_dart.LineSegment], it merely ensures the chosen point of all line segments (start, center, end)
  ///      is within the passed [interval], and the points are evenly distributed.
  ///   2. Returned point positions are as follows:
  ///      - If [pointPositionInSegment] is [util_dart.LineSegmentPosition.min], the first point in the returned list
  ///        is [interval.min], and there is no point on [interval.max]
  ///        (last point is at `interval.max - points_equidistance`)
  ///      - If [pointPositionInSegment] is [util_dart.LineSegmentPosition.center], there are no points on the
  ///        neither [interval.min] nor [interval.max]. The first and last points are half of the points even distance
  ///        to the right of the [interval.min], and to the left of [interval.max] respectively.
  ///      - If [pointPositionInSegment] is [util_dart.LineSegmentPosition.max], the first point in the returned list
  ///        is at  at `interval.min + points_equidistance`, the last point is at [interval.max].
  ///    3. As this method simply divides the available interval into [labelPointsCount],
  ///       it is not relevant whether the interval is translated or extrapolated or not, as long as it is linear
  ///       (which it would be even for logarithmic scale). The interval represents transformed (usually identity),
  ///       not-affmap-ed values.
  List<double> _placeLabelPointsInInterval({
    required util_dart.Interval interval,
    required int labelPointsCount,
    required util_dart.LineSegmentPosition pointPositionInSegment,
  }) {
    if (labelPointsCount < 0) {
      throw StateError('Cannot distribute negative number of positions');
    }

    // Use existing positioner to find layedout line segments for labels
    PositionedLineSegments positionedSegments = LayedoutLengthsPositioner(
      lengths: List.generate(labelPointsCount, (index) => interval.length / labelPointsCount),
      lengthsPositionerProperties: const LengthsPositionerProperties(
        align: Align.start,
        packing: Packing.tight,
      ),
      lengthsConstraint: interval.length,
    ).positionLengths();
    // todo-02-design ^^ Call to positionLengths() is questionable. Should this be done using layout? BASICALLY THIS FEEDS OFF THE 1D LENGTHS LAYOUT DEEP INTO IT'S GUTS.

    switch(pointPositionInSegment) {
      case util_dart.LineSegmentPosition.min:
        return positionedSegments.lineSegments.map((lineSegment) => lineSegment.min).toList();
      case util_dart.LineSegmentPosition.center:
        return positionedSegments.lineSegments.map((lineSegment) => lineSegment.center).toList();
      case util_dart.LineSegmentPosition.max:
        return positionedSegments.lineSegments.map((lineSegment) => lineSegment.max).toList();
    }
  }

  /// Automatically generates values (anywhere from zero to nine values) intended to
  /// be displayed as label in [interval], which represents a range
  ///
  /// More precisely, all generated label values are inside, or slightly protruding from,
  /// the passed [interval], which was created as tight envelope of all data values.
  ///
  /// As the values are generated from [interval], the values us whatever is the
  /// [interval]'s values scale and transform. Likely, the [interval] represents
  /// transformed but not-extrapolated values.
  ///
  /// The label values power is the same as the greatest power
  /// of the passed number [interval.end], when expanded to 10 based power series.
  ///
  /// Precision is 1 (that is, only leading digit is not-zero, rest are zeros).
  ///
  /// Examples:
  ///   1. [util_dart.Interval] is <0, 123> then labels=[0, 100]
  ///   2. [util_dart.Interval] is <0, 299> then labels=[0, 100, 200]
  ///   3. [util_dart.Interval] is <0, 999> then labels=[0, 100, 200 ... 900]
  ///
  /// Further notes and related topics:
  ///   - Labels are encapsulated in the [DataRangeTicksAndLabelsDescriptor],
  ///     which creates [AxisLabelInfo]s for all generated labels.
  ///   - The [axisYMin] and [axisYMax] define the top and the bottom of the Y axis in the canvas coordinate system.
  ///
  List<double> _generateValuesForLabelsIn({
    required util_dart.Interval interval,
    required bool extendAxisToOrigin,
  }) {
    var polyMin = util_dart.Poly(from: interval.min);
    var polyMax = util_dart.Poly(from: interval.max);

    int powerMax = polyMax.maxPower;
    int coeffMax = polyMax.coefficientAtMaxPower;
    int signMax = polyMax.signum;

    // using Min makes sense if one or both (min, max) are negative
    int powerMin = polyMin.maxPower;
    int coeffMin = polyMin.coefficientAtMaxPower;
    int signMin = polyMin.signum;

    List<double> labels = [];
    int power = math.max(powerMin, powerMax);

    if (signMax <= 0 && signMin <= 0 || signMax >= 0 && signMin >= 0) {
      // both negative or positive
      if (signMax <= 0) {
        double startCoeff = 1.0 * signMin * coeffMin;
        int endCoeff = 0;
        if (!extendAxisToOrigin) {
          endCoeff = signMax * coeffMax;
        }
        for (double l = startCoeff; l <= endCoeff; l++) {
          labels.add(l * math.pow(10, power));
        }
      } else {
        // signMax >= 0
        double startCoeff = 1.0 * 0;
        int endCoeff = signMax * coeffMax;
        if (!extendAxisToOrigin) {
          startCoeff = 1.0 * coeffMin;
        }
        for (double l = startCoeff; l <= endCoeff; l++) {
          labels.add(l * math.pow(10, power));
        }
      }
    } else {
      // min is negative, max is positive - need added logic
      if (powerMax == powerMin) {
        for (double l = 1.0 * signMin * coeffMin; l <= signMax * coeffMax; l++) {
          labels.add(l * math.pow(10, power));
        }
      } else if (powerMax < powerMin) {
        for (double l = 1.0 * signMin * coeffMin; l <= 1; l++) {
          // just one over 0
          labels.add(l * math.pow(10, power));
        }
      } else if (powerMax > powerMin) {
        for (double l = 1.0 * signMin * 1; l <= signMax * coeffMax; l++) {
          // just one under 0
          labels.add(l * math.pow(10, power));
        }
      } else {
        throw Exception('Unexpected power: $powerMin, $powerMax ');
      }
    }

    // Check if positions are fully inside interval - probably not, which is fine
    return labels;
  }

}

/// Represents the position in label.
///
/// This assumes labels mark positions on an ordered axis which has a norm. This allows for label size,
/// and calculating a point (tick) at a position between neighbouring labels.
enum MoveTickTo {
  middlePreviousAndThis,
  stayAtThis,
  middleThisAndNext,
}
/// The [AxisLabelInfo] is a holder for one label,
/// it's numeric values (raw, transformed, transformed and extrapolated)
/// and the displayed label String.
///
/// It does not hold anything at all to do with UI - no layout sizes of labels in particular.
///
/// The values used and shown on the chart undergo the following processing:
///    1. [_rawCenterTickValue] -- using [DataContainerOptions.yTransform] (or [DataContainerOptions.xTransform])
///       ==> [centerTickValue] (transformed)
///    2. [centerTickValue]    -- using [DataRangeTicksAndLabelsDescriptor.affmapValueToPixels]
///       ==> [parentOffsetTick]
///    3. [_rawCenterTickValue] -- using formatted String-value
///       ==> [_formattedLabel]
///
/// todo-02-doc below finish documentation, this stuff is old, and simplify
/// The last mapping in item 3. is using either `toString` if [DataRangeTicksAndLabelsDescriptor.userLabels] are used,
/// or [DataRangeTicksAndLabelsDescriptor._valueToLabel] for chart-generated labels.
///
/// There are four values each [AxisLabelInfo] manages:
/// 1. The [_rawCenterTickValue] : The value of dependent (y) variable in data, given by
///   the [DataRangeTicksAndLabelsDescriptor._mergedLabelYsIntervalWithdataEnvelope].
///   - This value is **not-transformed && not-extrapolated**.
///   - This value is in the interval extended from the interval of minimum and maximum data values (x or y)
///     to the interval of the displayed labels. The reason is the chart may show axis lines and labels
///     beyond the strict interval between minimum and maximum in data.
///   - This value is created in the generative constructor's [AxisLabelInfo]
///     initializer list from the [transformedOutputValue].
/// 2. The [centerTickValue] : The [_rawCenterTickValue] after transformation by the [DataContainerOptions.yTransform]
///   function.
///   - This value is **not-extrapolated && transformed**
///   - This value is same as [_rawCenterTickValue] if the [DataContainerOptions.yTransform]
///     is an identity (this is the default behavior). See [lib/chart/options.dart].
///   - This value is passed in the primary generative constructor [AxisLabelInfo].
/// 3. The [parentOffsetTick] :  Equals to the **transformed && extrapolated** outputValue, in other words
///   ```dart
///    _axisValue = rangeDescriptor.scaleY(value: transformedOutputValue.toDouble());
///   ```
///   It is created as extrapolated [centerTickValue], in the [PointsColumns]
///   where the extrapolation is from the Y data and labels envelop to the Y axis envelop.
///   - This value is **transformed and extrapolated**.
///   - This value is obtained as follows
///     ```dart
///        _axisValue = rangeDescriptor.scaleY(value: transformedOutputValue.toDouble());
///        // which does
///        return extrapolateValue(
///            value: value.toDouble(),
///            fromRangeMin: mergedLabelYsIntervalWithDataYsEnvelop.min.toDouble(),
///            fromRangeMax: mergedLabelYsIntervalWithDataYsEnvelop.max.toDouble(),
///            toRangeMin: _axisYMin,
///            toRangeMax: _axisYMax);
///     ```
/// 4. The [_formattedLabel] : The formatted String-value of [_rawCenterTickValue].
///
/// Note: The **not-transformed && extrapolated** value is NOT used - does not make sense.
///
/// Note:  **Data displayed inside the chart use transformed data values, displayed labels show raw data values.**
///
class AxisLabelInfo {

  /// Constructs from value at the label, holding on the [outerRangeDescriptor],
  /// which provides data range corresponding to axis range.
  AxisLabelInfo({
    required this.centerTickValue,
    required DataRangeTicksAndLabelsDescriptor outerRangeDescriptor,
  })  :
        _outerRangeDescriptor = outerRangeDescriptor {
    var yInverseTransform = _outerRangeDescriptor._inverseTransform;
    _rawCenterTickValue = yInverseTransform(centerTickValue);
  }

  final DataRangeTicksAndLabelsDescriptor _outerRangeDescriptor;

  /// not-extrapolated and not-transformed label value.
  ///
  /// This is only used in labels display, never to calculate or display data values.
  /// All data values calculations are using the [centerTickValue].
  late final num _rawCenterTickValue;

  /// The transformed [_rawCenterTickValue].
  ///
  /// In not-transferred charts (e.g. not-log-valued charts), this is equal to [_rawCenterTickValue].
  ///
  /// This is the value shown on the chart, before any scaling to pixel value.
  final double centerTickValue;

  /// Value on the left border of the label.
  /// If label has no defined width, it is a point in the middle of this [centerTickValue]
  /// and predecessor label [centerTickValue].
  /// As setting this values requires predecessor and successor labels, it can only be set during or after
  /// labels are collected in [_AxisLabelInfos].
  late final double leftBorderTickValue;
  late final double rightBorderTickValue;


  /// Label showing on the Y axis; typically a value with unit.
  ///
  /// Formatted label is just formatted [parentOffsetTick].
  late final String _formattedLabel;
  String get formattedLabel => _formattedLabel;

  @override
  String toString() {
    return ' outputValue=$_rawCenterTickValue,'
        ' transformedOutputValue=$centerTickValue,'
        ' _formattedLabel=$_formattedLabel,';
  }
}

/// A wrapper for the list of [AxisLabelInfo]s shown on an axis.
///
/// Stores the list of labels as [_AxisLabelInfos] created by [DataRangeTicksAndLabelsDescriptor].
///
/// During creation from the `List<LabelInfo>` argument [from] ,
/// formats the labels using each [AxisLabelInfo]'s own formatter.
class _AxisLabelInfos {
  _AxisLabelInfos({
    required List<AxisLabelInfo> from,
    required DataRangeTicksAndLabelsDescriptor rangeDescriptor,
    List<String>? userLabels,
  })  : _labelInfoList = from
  {
    // Format labels during creation
    for (int i = 0; i < _labelInfoList.length; i++) {
      AxisLabelInfo labelInfo = _labelInfoList[i];
      _setRightAndLeftBorderOnLabelInfo(i, labelInfo, rangeDescriptor);
      // If labels were set by user in [userLabels], their formatted value [_formattedLabel]
      //   is set to the user String without formatting or mangling.
      // Otherwise, labels are the raw data values previously generated
      //   by [DataRangeTicksAndLabelsDescriptor], formatted by applying the [_valueToLabel]
      if (userLabels != null) {
        labelInfo._formattedLabel = userLabels[i];
      } else {
        labelInfo._formattedLabel = rangeDescriptor._valueToLabel(labelInfo._rawCenterTickValue);
      }
    }
  }

  void _setRightAndLeftBorderOnLabelInfo(int i, AxisLabelInfo labelInfo, DataRangeTicksAndLabelsDescriptor rangeDescriptor) {
    if (i == 0) {
      labelInfo.leftBorderTickValue = rangeDescriptor.dataRange.min;
      if (_labelInfoList.length == 1) {
        labelInfo.rightBorderTickValue = rangeDescriptor.dataRange.max;
      } else {
        // There is a next i (1)
        labelInfo.rightBorderTickValue = (_labelInfoList[i+1].centerTickValue + labelInfo.centerTickValue) / 2;
      }
    } else if (i == _labelInfoList.length - 1) {
      // If we get here, there are 2 or more element, and we are at end, so we can look one back from [i]
      labelInfo.leftBorderTickValue = (_labelInfoList[i - 1].centerTickValue + labelInfo.centerTickValue) / 2;
      labelInfo.rightBorderTickValue = rangeDescriptor.dataRange.max;
    } else {
      // If we get here, there are 3 or more elements, and we are not at end,
      // so we can look one back and one forward from [i]
      labelInfo.leftBorderTickValue = (_labelInfoList[i-1].centerTickValue + labelInfo.centerTickValue) / 2;
      labelInfo.rightBorderTickValue = (_labelInfoList[i+1].centerTickValue + labelInfo.centerTickValue) / 2;
    }
  }

  /// The labels' values; if numerical, always in increasing order.
  ///
  /// For the logic of layout placing, see [DataRangeTicksAndLabelsDescriptor.labelInfoList].
  final List<AxisLabelInfo> _labelInfoList;
}

// ########################## Functions ##########################

util_dart.Interval extendToOrigin(util_dart.Interval interval, bool extendAxisToOrigin) {
  if (interval.min - util_dart.epsilon > interval.max) {
    throw StateError('Min < max on interval $interval');
  }
  if (extendAxisToOrigin) {
    return util_dart.Interval(
      interval.min >= 0.0 ? math.min(0.0, interval.min) : interval.min,
      interval.max >= 0.0 ? math.max(0.0, interval.max) : 0.0,
    );
  }
  return interval;
}

