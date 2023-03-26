import 'dart:math' as math show min, max, pow;

import '../morphic/container/container_layouter_base.dart';
import '../chart/model/data_model.dart';
import '../chart/options.dart';
import '../chart/view_maker.dart';
import '../morphic/container/layouter_one_dimensional.dart'
    show LayedoutLengthsPositioner, LengthsPositionerProperties, PositionedLineSegments, Align, Packing;

import 'util_dart.dart' as util_dart;

// todo-doc-01 documentation fix, this is old
/// Generates label values from data values, and allows label manipulation: transform, format, extrapolate to axis pixels.
///
/// During construction, decides how many labels will be created, and generates points on which the labels
/// will be placed (these points are also values of the labels).
///
/// All values, including the [AxisLabelInfo]s are calculated using [ChartModel].
///
/// The labels are managed in the [labelInfos] member in all forms - raw, transformed, scaled, and raw formatted.
///
class DataRangeLabelInfosGenerator {

  /// Generative constructor allows to create and manage labels, irrespective whether user defined, or generated
  /// by this [DataRangeLabelInfosGenerator].
  ///
  /// If [userLabels] list of user labels is passed, user labels will be used and distributed linearly between the
  /// passed [dataModel] minimum and maximum.
  /// Otherwise, new labels are automatically generated with values of
  /// highest order of numeric values in the passed [dataModel].
  ///
  /// Parameters discussion:
  ///
  /// - [dataModel] contains the numeric data values, passed to constructor.
  ///   An envelope is created from the [dataModel] values, possibly extending the envelope interval to start or end at 0.
  ///   Whether the envelope interval starts or ends at 0.0, even if data are away from 0.0, is controlled by member
  ///   [extendAxisToOrigin].
  /// - [userLabels] may be set by user.
  /// - [_labelInfos] and [dataRange] are created from [dataMode] for only the highest order of values
  ///   in [dataModel], and can be both wider or narrower than extremes of the [dataModel].
  ///     1. Ex1. for [dataModel] values [-600.0 .. 2200.0]
  ///             ==> [labelInfos] =   [-1000, 0, 1000, 2000] (NARROWER THAN dataModel max 2200)
  ///             ==> [dataRange] = [-600 .. 2200]
  ///     2. Ex2. for [dataModel] values  [0.0 .. 1800.0]
  ///             ==> [labelInfos]   = [0, 1000, 2000]
  ///             ==> [dataRange] = [0 .. 2000] (WIDER than dataModel max 1800)
  ///
  /// Constructor calculates the following members:
  ///   - [dataRange]
  ///   - [_labelInfos]
  DataRangeLabelInfosGenerator({
    required this.chartViewMaker, // todo-00-done : added as a temporary to test old vs new
    required ChartModel dataModel,
    required this.dataDependency,
    required bool extendAxisToOrigin,
    required Function valueToLabel,
    required Function inverseTransform,
    required bool isStacked,
    required this.isAxisPixelsAndDisplayedValuesInSameDirection,
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
    //   are **not-extrapolated && transformed** data from [ChartModelPoint].
    if (userLabels != null) {
      switch(dataDependency) {
        case DataDependency.independentData:
          // On independent (X) axis, any stand-in interval will suffice, so pick <0.0-100.0>. Whatever
          //   the interval is, once the pixels range on the axis is available,
          //   it will be lextr-ed to the pixel range.
          // We COULD return the same valuesInterval(isStacked: isStacked) but
          //   as that is for dependent data, it would be confusing.
          dataEnvelope = const util_dart.Interval(0.0, 100.0);
          transformedLabelValues = _placeLabelPointsInInterval(
            interval: dataEnvelope,
            labelPointsCount: userLabels.length,
            pointPositionInSegment: util_dart.LineSegmentPosition.center,
          );
          break;
        case DataDependency.dependentData:
          // This is ONLY needed for legacy coded_layout to work
          // On dependent (Y) axis, with user labels, we have to use actual data values,
          //   because all scaling uses actual data values
          dataEnvelope = dataModel.valuesInterval(isStacked: isStacked);
          double dataStepHeight = (dataEnvelope.max - dataEnvelope.min) / (userLabels.length - 1);
          transformedLabelValues =
              List.generate(userLabels.length, (index) => dataEnvelope.min + index * dataStepHeight);
          break;
      }
    } else {
      dataEnvelope = dataModel.extendedValuesInterval(
        extendAxisToOrigin: extendAxisToOrigin,
        isStacked: isStacked,
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
          outputValue: transformedLabelValue,
          labelsGenerator: this,
        ))
        .toList();
    _labelInfos = _AxisLabelInfos(
      from: labelInfos,
      labelsGenerator: this,
      userLabels: userLabels,
    );

  }

  final ChartViewMaker chartViewMaker; // todo-00-done : added as a temporary to test old vs new

  /// Describes if this [DataRangeLabelInfosGenerator] instance is for dependent or independent data.
  ///
  /// [DataDependency.dependentData] determines this instance is for dependent data,
  /// [DataDependency.independentData] determines this instance is for independent data.
  ///
  /// The significance of dependent/independent is
  final DataDependency dataDependency;

  /// Describes labels - their values and String values.
  /// Important note: [_AxisLabelInfos] should NOT be part of model,
  ///                 as different views would have a different instance of it.
  ///                 Reason: Different views may have different labels, esp. on the axis.
  late final _AxisLabelInfos _labelInfos;

  /// List describes the labels generated by [DataRangeLabelInfosGenerator],
  /// or all user defined labels from [userLabels].
  ///
  /// User labels from [userLabels], if set, are used, otherwise, the generated labels are used.
  /// The labels are always ordered - numerically increasing by value for numerical
  /// labels, or in the order initialized by user in [userLabels].
  ///
  /// The labels are always in increasing order: For data labels, they are numerically increasing,
  /// for user labels, their order given by user is considered ordered the same order as provided.
  ///
  List<AxisLabelInfo> get labelInfoList => List.from(_labelInfos._labelInfoList, growable: false);


  /// The numerical range of data.
  ///
  /// Calculated in the constructor, from [ChartModelPoint]s.
  /// as the merged outer interval of generated labels and [ChartModelPoint] values.
  ///
  /// This [Interval] is displayed on the axis pixel domain [AxisContainer.axisPixelsRange].
  /// Extrapolation is done between those intervals.
  late final util_dart.Interval dataRange;

  // Along the Y axis, label values go up, but axis down. true extrapolate inverses that.
  final bool isAxisPixelsAndDisplayedValuesInSameDirection;

  /// The function converts value to label.
  ///
  /// Assigned from a corresponding function [ChartOptions.yContainerOptions.valueToLabel].
  final Function _valueToLabel;

  /// The function for data inverse transform.
  ///
  /// Assigned from a corresponding function [ChartOptions.dataContainerOptions.yInverseTransform].
  final Function _inverseTransform;

  /// Extrapolates [value] from extended data range [dataRange],
  /// to the pixels domain passed in the passed [axisPixelsMin], [axisPixelsMax],
  /// in the direction defined by [isAxisAndLabelsSameDirection].
  ///
  /// Lifecycle: This method must be invoked in or after [BoxLayouter.layout],
  ///            after the axis size is calculated.
  double lextrValueToPixels({
    required double value,
    required double axisPixelsMin,
    required double axisPixelsMax,
  }) {

    // Special case, if _labelsGenerator.dataRange=(0.0,0.0), there are either no data, or all data 0.
    // Lerp the result to either start or end of the axis pixels, depending on [isAxisAndLabelsSameDirection]
    if (dataRange == const util_dart.Interval(0.0, 0.0)) {
      double pixels;
      if (!isAxisPixelsAndDisplayedValuesInSameDirection) {
        pixels = axisPixelsMax;
      } else {
        pixels = axisPixelsMin;
      }
      return pixels;
    }
    // lextr the data value range [dataRange] on this [DataRangeLabelInfosGenerator] to the pixel range.
    // The pixel range must be the pixel range available to axis after [BoxLayouter.layout].
    return util_dart.ToPixelsExtrapolation1D(
      fromValuesMin: dataRange.min,
      fromValuesMax: dataRange.max,
      toPixelsMin: axisPixelsMin,
      toPixelsMax: axisPixelsMax,
      doInvertToDomain: !isAxisPixelsAndDisplayedValuesInSameDirection,
    ).apply(value);
  }

  /// Creates an instance of [ExternalTicksLayoutProvider] from self.
  ///
  /// As this [DataRangeLabelInfosGenerator] holds on everything about relative (data ranged)
  /// position of labels, it can be converted to a provider of these label positions
  /// for layouts that use externally defined positions to layout their children.
  ExternalTicksLayoutProvider asExternalTicksLayoutProvider({
    required ExternalTickAtPosition externalTickAtPosition,
  }) {
    // Return [ExternalTicksLayoutProvider] and provide ticks.
    // The ticks must be lextr-ed to pixels, once ticksPixelsDomain is known.
    // See [ExternalTicksBoxLayouter].
    return ExternalTicksLayoutProvider(
      tickValues: labelInfoList.map((labelInfo) => labelInfo.outputValue).toList(growable: false),
      tickValuesDomain: dataRange,
      isAxisPixelsAndDisplayedValuesInSameDirection: isAxisPixelsAndDisplayedValuesInSameDirection,
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
  ///       (which it would be even for logarithmic scale). The interval represents transformed (ususally identity),
  ///       non-lextr-ed values.
  List<double> _placeLabelPointsInInterval({
    required util_dart.Interval interval,
    required int labelPointsCount,
    required util_dart.LineSegmentPosition pointPositionInSegment,
  }) {
    if (labelPointsCount < 0) {
      throw StateError('Cannot distribute negative number of positions');
    }

    // Use existing positioner to find segments for labels
    PositionedLineSegments positionedSegments = LayedoutLengthsPositioner(
      lengths: List.generate(labelPointsCount, (index) => interval.length / labelPointsCount),
      lengthsPositionerProperties: const LengthsPositionerProperties(
        align: Align.start,
        packing: Packing.tight,
      ),
      lengthsConstraint: interval.length,
    ).positionLengths();

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
  /// be displayed as label in [interval], which represents a domain
  ///
  /// More precisely, all generated label values are inside, or slightly protruding from,
  /// the passed [interval], which was created as tight envelope of all data values.
  ///
  /// As the values are generated from [interval], the values us whatever is the
  /// [interval]'s values scale and transform. Likely, the [interval] represents
  /// transformed but non-extrapolated values.
  ///
  /// The label values power is the same as the greatest power
  /// of the passed number [interval.end], when expanded to 10 based power series.
  ///
  /// Precision is 1 (that is, only leading digit is non-zero, rest are zeros).
  ///
  /// Examples:
  ///   1. [util_dart.Interval] is <0, 123> then labels=[0, 100]
  ///   2. [util_dart.Interval] is <0, 299> then labels=[0, 100, 200]
  ///   3. [util_dart.Interval] is <0, 999> then labels=[0, 100, 200 ... 900]
  ///
  /// Further notes and related topics:
  ///   - Labels are encapsulated in the [DataRangeLabelInfosGenerator],
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

  /// Calculates the 1-based portion of the length used by positive range.
  ///
  /// The length is lextr equivalent to pixels used up by positive axis. The returned value is in interval <0.0, 1.0>.
  /// 0.0 value represents there are no positive values, 1.0 represents there are only positive or zero values.
  ///
  /// Motivation: When data on chart have and show both positive and negative values,
  ///             the [DataContainer.buildAndReplaceChildren] show the positive and negative
  ///             axis in a [Column] layouter; the first (top) column elements shows positives,
  ///             the second (bottom) column elements shows negatives. We need to assign weight
  ///             to the top and bottom in the ratio of the positive and negative axis lengths.
  ///             This method [portionOfPositiveRange] and [portionOfNegativeRange] serves as the [Column]
  ///             positive and negative weight.
  double portionOfPositiveRange() {
    if (dataRange.min >= dataRange.max) {
      // Arbitrary portion if interval is collapsed
      if (dataRange.max < 0.0) {
        return 0.0;
      } else if (dataRange.max >= 0.0) {
        return 1.0;
      }
      throw StateError('Invalid dataRange=$dataRange');
    }

    if (dataRange.max < 0.0) {
      // dataRange purely negative
      return 0.0;
    } else if (dataRange.min >= 0.0) {
      // dataRange purely positive or 0
      return 1.0;
    }

    if (!(dataRange.min < 0.0 && dataRange.max > 0.0)) {
      throw StateError('Internal error: Invalid assumption of dataRange=$dataRange');
    }
    return dataRange.max / (dataRange.max - dataRange.min);
  }

  /// Remainder to 1.0 of [portionOfPositiveRange]. See [portionOfPositiveRange] for details.
  double portionOfNegativeRange() {
    return 1.0 - portionOfPositiveRange();
  }
}

/// The [AxisLabelInfo] is a holder for one label,
/// it's numeric values (raw, transformed, transformed and extrapolated)
/// and the displayed label String.
///
/// It does not hold anything at all to do with UI - no layout sizes of labels in particular.
///
/// The values used and shown on the chart undergo the following processing:
///    1. [_rawOutputValue] -- using [DataContainerOptions.yTransform] (or [DataContainerOptions.xTransform])
///       ==> [outputValue] (transformed)
///    2. [outputValue]    -- using [DataRangeLabelInfosGenerator.lextrValueToPixels]
///       ==> [parentOffsetTick]
///    3. [_rawOutputValue] -- using formatted String-value
///       ==> [_formattedLabel]
///
/// todo-01-doc below finish documentation, this stuff is old, and simplify
/// The last mapping in item 3. is using either `toString` if [DataRangeLabelInfosGenerator.userLabels] are used,
/// or [DataRangeLabelInfosGenerator._valueToLabel] for chart-generated labels.
///
/// There are four values each [AxisLabelInfo] manages:
/// 1. The [_rawOutputValue] : The value of dependent (y) variable in data, given by
///   the [DataRangeLabelInfosGenerator._mergedLabelYsIntervalWithdataEnvelope].
///   - This value is **not-transformed && not-extrapolated**.
///   - This value is in the interval extended from the interval of minimum and maximum data values (x or y)
///     to the interval of the displayed labels. The reason is the chart may show axis lines and labels
///     beyond the strict interval between minimum and maximum in data.
///   - This value is created in the generative constructor's [AxisLabelInfo]
///     initializer list from the [transformedOutputValue].
/// 2. The [outputValue] : The [_rawOutputValue] after transformation by the [DataContainerOptions.yTransform]
///   function.
///   - This value is **not-extrapolated && transformed**
///   - This value is same as [_rawOutputValue] if the [DataContainerOptions.yTransform]
///     is an identity (this is the default behavior). See [lib/chart/options.dart].
///   - This value is passed in the primary generative constructor [AxisLabelInfo].
/// 3. The [parentOffsetTick] :  Equals to the **transformed && extrapolated** outputValue, in other words
///   ```dart
///    _axisValue = labelsGenerator.scaleY(value: transformedOutputValue.toDouble());
///   ```
///   It is created as extrapolated [outputValue], in the [PointsColumns]
///   where the extrapolation is from the Y data and labels envelop to the Y axis envelop.
///   - This value is **transformed and extrapolated**.
///   - This value is obtained as follows
///     ```dart
///        _axisValue = labelsGenerator.scaleY(value: transformedOutputValue.toDouble());
///        // which does
///        return extrapolateValue(
///            value: value.toDouble(),
///            fromDomainMin: mergedLabelYsIntervalWithDataYsEnvelop.min.toDouble(),
///            fromDomainMax: mergedLabelYsIntervalWithDataYsEnvelop.max.toDouble(),
///            toDomainMin: _axisYMin,
///            toDomainMax: _axisYMax);
///     ```
/// 4. The [_formattedLabel] : The formatted String-value of [_rawOutputValue].
///
/// Note: The **not-transformed && extrapolated** value is NOT used - does not make sense.
///
/// Note:  **Data displayed inside the chart use transformed data values, displayed labels show raw data values.**
///
class AxisLabelInfo {

  /// Constructs from value at the label, holding on the owner [labelsGenerator],
  /// which provides data range corresponding to axis range.
  AxisLabelInfo({
    // todo-00-last-last : required num outputValue,
    required this.outputValue,
    required DataRangeLabelInfosGenerator labelsGenerator,
  })  : // todo-00-last-last : outputValue = outputValue,
        _labelsGenerator = labelsGenerator {
    var yInverseTransform = _labelsGenerator._inverseTransform;
    _rawOutputValue = yInverseTransform(outputValue);
  }

  final DataRangeLabelInfosGenerator _labelsGenerator;

  /// Not-extrapolated and not-transformed label value.
  ///
  /// This is only used in labels display, never to calculate or display data values.
  /// All data values calculations are using the [outputValue].
  late final num _rawOutputValue;

  /// The transformed [_rawOutputValue].
  ///
  /// In non-transferred (e.g. non-log) charts, this is equal to [_rawOutputValue].
  ///
  /// This is the value shown on the chart, before any scaling to pixel value.
  final double outputValue;

  /// Label showing on the Y axis; typically a value with unit.
  ///
  /// Formatted label is just formatted [parentOffsetTick].
  late final String _formattedLabel;
  String get formattedLabel => _formattedLabel;

  @override
  String toString() {
    return ' outputValue=$_rawOutputValue,'
        ' transformedOutputValue=$outputValue,'
        ' _formattedLabel=$_formattedLabel,';
  }
}

/// A wrapper for the list of [AxisLabelInfo]s shown on an axis.
///
/// Stores the list of labels as [_AxisLabelInfos] created by [DataRangeLabelInfosGenerator].
///
/// During creation from the `List<LabelInfo>` argument [from] ,
/// formats the labels using each [AxisLabelInfo]'s own formatter.
class _AxisLabelInfos {
  _AxisLabelInfos({
    required List<AxisLabelInfo> from,
    required DataRangeLabelInfosGenerator labelsGenerator,
    List<String>? userLabels,
  })  : _labelInfoList = from
  {
    // Format labels during creation
    for (int i = 0; i < _labelInfoList.length; i++) {
      AxisLabelInfo labelInfo = _labelInfoList[i];
      // If labels were set by user in [userLabels], their formatted value [_formattedLabel]
      //   is set to the user String without formatting or mangling.
      // Otherwise, labels are the raw data values previously generated
      //   by [DataRangeLabelInfosGenerator], formatted by applying the [_valueToLabel]
      if (userLabels != null) {
        labelInfo._formattedLabel = userLabels[i];
      } else {
        labelInfo._formattedLabel = labelsGenerator._valueToLabel(labelInfo._rawOutputValue);
      }
    }
  }

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

