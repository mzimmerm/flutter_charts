import 'dart:math' as math show min, max, pow;
// import 'package:flutter_charts/flutter_charts.dart';
import 'util_dart.dart';
import 'test/generate_test_data_from_app_runs.dart';
import '../chart/container.dart' show ChartBehavior;

/// Creates, scales, and formats the Y labels, from the transformed data
/// to their positions and formatted strings on the Y axis.
///
/// The following members are most relevant in the creating and formatting labels
/// - [_dataYs] is a list of numeric Y values, passed to constructor.
///   An envelope is created from [_dataYs], possibly extending the closure interval to start or end at 0.
///   1. Ex1. for [_dataYs] [-600.0 ....  2200.0] ==> [dataYsEnvelope] = [-600.0, 2200.0]
///   2. Ex2. for [_dataYs] [600.0 ....  1800.0]  ==> [dataYsEnvelope] = [0.0, 1800.0]
/// - [axisY] is the interval of the Y axis coordinates.
///      e.g. [8.0, 400.0]
/// - [yUserLabels] may be set by user.
/// - [labelInfos] are labels calculated to represent numeric Y values, ONLY in their highest order.
///   1. Ex1. [labelInfos] ==> [-1000, 0, 1000, 2000] (NOT ending at 2200)
///   2. Ex2. [labelInfos] ==> [0, 1000, 2000]
/// From the members [dataYsEnvelope] and [labelInfos], the [_mergedLabelYsIntervalWithDataYsEnvelope]
/// are calculated. The result serves as the '(transformed) data range'.
/// All (transformed) data and labels are located inside the [_mergedLabelYsIntervalWithDataYsEnvelope]
/// 1. Ex1. for [dataYsEnvelope]=[-600.0, 2200.0] and [labelInfos]=[-1000, 0, 1000, 2000] ==> merged=[-1000, 0, 1000, 2200]
/// 2. Ex2. for [dataYsEnvelope]= [0.0, 1800.0]   and [labelInfos]=[0, 1000, 2000]        ==> merged=[0, 1000, 2000]
class YLabelsCreatorAndPositioner {
  List<String>? yUserLabels;

  /// The list of numeric Y values, passed to constructor.
  final List<double> _dataYs;

  /// Coordinates of the Y axis.
  final Interval _axisY;

  /// The chart options.
  final ChartBehavior _chartBehavior;

  /// The function converts value to label.
  ///
  /// Assigned from a corresponding function [ChartOptions.yContainerOptions.valueToLabel].
  final Function _valueToLabel;

  /// The function for data inverse transform.
  ///
  /// Assigned from a corresponding function [ChartOptions.dataContainerOptions.yInverseTransform].
  final Function _yInverseTransform;

  /// The [dataYsEnvelope] is created from the input [_dataYs] as it's closure interval,
  /// possibly extended to start at 0.
  ///
  /// Further, the  [_dataYs] are from the [StackableValuePoint.toY] from the [PointsColumns.flattenPointsValues].
  /// The [StackableValuePoint]s are located on [PointsColumns], then [PointsColumn.stackableValuePoints].
  late final Interval dataYsEnvelope;

  /// Maintains labels created from data values, scaled and unscaled.
  late List<LabelInfo> labelInfos;

  /// Generative constructor allows to create labels.
  ///
  /// If [yUserLabels] list of user labels is passed, user labels will be used and distributed linearly between the
  /// passed [dataYs] minimum and maximum.
  /// Otherwise, new labels are automatically generated with values of
  /// highest order of numeric values in the passed [dataYs].
  /// See the class comment for examples of how auto labels are created.
  YLabelsCreatorAndPositioner({
    required List<double> dataYs,
    required Interval axisY,
    required ChartBehavior chartBehavior,
    required Function valueToLabel,
    required Function yInverseTransform,
    this.yUserLabels,
  })  : _dataYs = dataYs,
        _axisY = axisY,
        _chartBehavior = chartBehavior,
        _valueToLabel = valueToLabel,
        _yInverseTransform = yInverseTransform {
    List<double> distributedLabelYs;
    // Find the interval for Y values (may be an envelop around values, for example if we want Y to always start at 0),
    //   then create labels evenly distributed in the Y values interval.
    if (_isUsingUserLabels) {
      dataYsEnvelope = _deriveDataYsEnvelopeForUserLabels();
      distributedLabelYs = _distributeUserLabelsIn(dataYsEnvelope);
    } else {
      dataYsEnvelope = _deriveDataYsEnvelopeForAutoLabels();
      distributedLabelYs = _distributeAutoLabelsIn(dataYsEnvelope);
    }
    // Create LabelInfos for all labels and point each to this scaler
    labelInfos = distributedLabelYs // this is the label/DataYs enveloper - all values after transform
        .map((transformedLabelValue) => LabelInfo(
              dataValue: transformedLabelValue,
              parentYScaler: this,
            ))
        .toList();

    // Format and scale the labels we just created
    for (int i = 0; i < labelInfos.length; i++) {
      LabelInfo labelInfo = labelInfos[i];
      // Scale labels
      labelInfo._scaleLabelValue(); // This sets labelInfo._axisValue = YScaler.scaleY(labelInfo.transformedDataValue)

      // Format labels takes a different form in user labels
      if (_isUsingUserLabels) {
        labelInfo._formattedLabel = yUserLabels![i];
      } else {
        labelInfo._formattedLabel = _valueToLabel(labelInfo._rawDataValue);
      }
    }

    // This test is always true. Should address in the bigger context
    if (_axisY.min > _axisY.max) {
      // we are inverting scales, so invert labels.
      labelInfos = labelInfos.reversed.toList();
    }

    // Collect data for testing. Disabled in production
    collectTestData(
        'for_Range.makeYScalerWithLabelInfosFromDataYsOnScale_test',
        [
          _dataYs,
          axisY.min,
          axisY.max,
          distributedLabelYs,
          dataYsEnvelope.min,
          dataYsEnvelope.max,
        ],
        this);
  }

  bool get _isUsingUserLabels => yUserLabels != null;

  /// Scales [value]
  /// - From own scale, given be the merged data and label intervals
  ///   calculated in [_mergedLabelYsIntervalWithDataYsEnvelope]
  /// - To the Y axis scale defined by [_axisYMin], [_axisYMax].
  double scaleY({
    required double value,
  }) {
    // Use linear scaling utility to scale from data Y interval to axis Y interval
    return scaleValue(
        value: value.toDouble(),
        fromDomainMin: _mergedLabelYsIntervalWithDataYsEnvelope.min.toDouble(),
        fromDomainMax: _mergedLabelYsIntervalWithDataYsEnvelope.max.toDouble(),
        toDomainMin: _axisY.min,
        toDomainMax: _axisY.max);
  }

  // ### Helper accessors to collection of LabelInfos

  /// Extracts not-scaled && transformed values where labels from [labelInfos] are positioned.
  List<double> get dataYsOfLabels => labelInfos.map((labelInfo) => labelInfo._dataValue.toDouble()).toList();

  /// Constructs interval which is a merge (outer bound) of
  /// two ranges: the labels interval [dataYsOfLabels] (calculated from [LabelInfo._dataValue])
  /// and the [dataYsEnvelope] (envelop of [_dataYs]). Both are not-scaled && transformed.
  Interval get _mergedLabelYsIntervalWithDataYsEnvelope => Interval(
        dataYsOfLabels.reduce(math.min), // not-scaled && transformed data from  labelInfo.transformedDataValue
        dataYsOfLabels.reduce(math.max),
      ).merge(dataYsEnvelope); // dataY from PointsColumns, which is also not-scaled && transformed, data

  /// Derive the interval of [dataY] values for automatically created labels.
  ///
  /// This is the closure of the [_dataYs] numeric values, extended (in default situation)
  /// to start at 0 (if all positive values), or end at 0 (if all negative values).
  Interval _deriveDataYsEnvelopeForAutoLabels() {
    double dataYsMin = _dataYs.reduce(math.min);
    double dataYsMax = _dataYs.reduce(math.max);

    Poly polyMin = Poly(from: dataYsMin);
    Poly polyMax = Poly(from: dataYsMax);

    int signMin = polyMin.signum;
    int signMax = polyMax.signum;

    // Minimum and maximum for all y values, by DEFAULT EXTENDED TO 0.
    // More precisely, "extended to 0" means that
    //   if all y values are positive,
    //     the range start at 0 (that is, dataYsMinExt is 0);
    //   else if all y values are negative,
    //     the range ends at 0 (that is, dataYsMaxExt is 0);
    //   otherwise [there are both positive and negative y values]
    //     the dataYsMinExt is the minimum of data, the dataYsMaxExt is the maximum of data.
    double dataYsMinExt, dataYsMaxExt;

    if (signMax <= 0 && signMin <= 0 || signMax >= 0 && signMin >= 0) {
      if (_chartBehavior.startYAxisAtDataMinAllowed) {
        if (signMax <= 0) {
          dataYsMinExt = dataYsMin;
          dataYsMaxExt = dataYsMax;
        } else {
          dataYsMinExt = dataYsMin;
          dataYsMaxExt = dataYsMax;
        }
      } else {
        // both negative or positive, extend the range to start or end at zero
        if (signMax <= 0) {
          dataYsMinExt = dataYsMin;
          dataYsMaxExt = 0.0;
        } else {
          dataYsMinExt = 0.0;
          dataYsMaxExt = dataYsMax;
        }
      }
    } else {
      dataYsMinExt = dataYsMin;
      dataYsMaxExt = dataYsMax;
    }

    // Now create distributedLabelYs, evenly distributed in
    //   the dataYsMinExt, dataYsMaxExt interval.
    // Make distributedLabelYs only in polyMax steps (e.g. 100, 200 - not 100, 110 .. 200).
    // Label values are (obviously) unscaled, that is, on the scale of transformed data.
    return Interval(dataYsMinExt, dataYsMaxExt);
  }

  /// Derive the interval of [dataY] values for user defined labels.
  ///
  /// This is simply the closure of the [_dataYs] numeric values.
  /// The user defined string labels are then distributed in the returned interval.
  Interval _deriveDataYsEnvelopeForUserLabels() {
    return Interval(_dataYs.reduce(math.min), _dataYs.reduce(math.max));
  }

  /// Automatically generates labels from data.
  ///
  /// Labels are encapsulated in the created and returned [YLabelsCreatorAndPositioner],
  /// which manages [LabelInfo]s for all generated labels.
  ///
  /// The [axisYMin] and [axisYMax] define the top and the bottom of the Y axis in the canvas coordinate system.

  /// Makes anywhere from zero to nine label values, of greatest power of
  /// the passed [dataYsEnvelope.max].
  ///
  /// Precision is 1 (that is, only leading digit, rest 0s).
  ///
  /// Examples:
  ///   1. [Interval] is <0, 123> then labels=[0, 100]
  ///   2. [Interval] is <0, 299> then labels=[0, 100, 200]
  ///   3. [Interval] is <0, 999> then labels=[0, 100, 200 ... 900]
  ///
  List<double> _distributeAutoLabelsIn(Interval dataYsEnvelope) {
    Poly polyMin = Poly(from: dataYsEnvelope.min);
    Poly polyMax = Poly(from: dataYsEnvelope.max);

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
        if (_chartBehavior.startYAxisAtDataMinAllowed) {
          endCoeff = signMax * coeffMax;
        }
        for (double l = startCoeff; l <= endCoeff; l++) {
          labels.add(l * math.pow(10, power));
        }
      } else {
        // signMax >= 0
        double startCoeff = 1.0 * 0;
        int endCoeff = signMax * coeffMax;
        if (_chartBehavior.startYAxisAtDataMinAllowed) {
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

    return labels;
  }

  /// Evenly distributes non-null [yUserLabels] inside the passed interval [dataYsEnvelope].
  ///
  /// The passed interval[dataYsEnvelope] is the closure interval of all Y values
  /// [StackableValuePoint.dataY] in all [StackableValuePoint]s created from [ChartData.dataRows].
  ///
  /// The first label from the [yUserLabels] list is positioned on the Y closure minimum values
  /// (which corresponds with the start of the Y axis - the horizontal level of the X axis).
  ///
  /// Preconditions:
  /// - This method assumes that a list of user labels was provided in [ChartData.yUserLabels].
  List<double> _distributeUserLabelsIn(Interval dataYsEnvelope) {
    double dataStepHeight = (dataYsEnvelope.max - dataYsEnvelope.min) / (yUserLabels!.length - 1);

    // Evenly distribute labels in [dataYsEnvelope]
    List<double> yLabelsInDataYsEnvelope = List.empty(growable: true);
    for (int yIndex = 0; yIndex < yUserLabels!.length; yIndex++) {
      yLabelsInDataYsEnvelope.add(dataYsEnvelope.min + dataStepHeight * yIndex);
    }
    return yLabelsInDataYsEnvelope;
  }
}

/// The [LabelInfo] is a holder for one label, it's numeric value and the displayed label.
///
/// There are four values each [LabelInfo] manages:
/// - The [_rawDataValue] : The value of dependent (y) variable in data, given by
///   the [YLabelsCreatorAndPositioner._mergedLabelYsIntervalWithDataYsEnvelope].
///   - This value is **not-scaled && not-transformed**.
///   - This value is in the interval extended from the interval of minimum and maximum y in data
///     to the interval of the displayed labels. The reason is the chart may show axis lines and labels
///     beyond the strict interval between minimum and maximum y in data.
///   - This value is created in the generative constructor's [LabelInfo]
///     initializer list from the [transformedDataValue].
/// - The [_dataValue] : The [_rawDataValue] after transformation by the [DataContainerOptions.yTransform]
///   function.
///   - This value is **not-scaled && transformed**
///   - This value is same as [_rawDataValue] if the [DataContainerOptions.yTransform]
///     is an identity (this is the default behavior). See [lib/chart/options.dart].
///   - This value is passed in the primary generative constructor [LabelInfo].
/// - The [_axisValue] :  Equals to the **scaled && transformed** dataValue, in other words
///   ```dart
///    _axisValue = parentYScaler.scaleY(value: transformedDataValue.toDouble());
///   ```
///   It is created as scaled [_dataValue], in the [PointsColumns]
///   where the scaling is from the Y data and labels envelop to the Y axis envelop.
///   - This value is **transformed and scaled**.
///   - This value is obtained as follows
///     ```dart
///        _axisValue = parentYScaler.scaleY(value: transformedDataValue.toDouble());
///        // which does
///        return scaleValue(
///            value: value.toDouble(),
///            fromDomainMin: mergedLabelYsIntervalWithDataYsEnvelop.min.toDouble(),
///            fromDomainMax: mergedLabelYsIntervalWithDataYsEnvelop.max.toDouble(),
///            toDomainMin: _axisYMin,
///            toDomainMax: _axisYMax);
///     ```
///   - The [_formattedLabel] : The formatted String-value of [_rawDataValue].
///
/// Note: The **scaled && not-transformed ** value is not maintained.
///
/// Note:  **Data displayed inside the chart use transformed data values, displayed labels show raw data values.**
///
class LabelInfo {
  final YLabelsCreatorAndPositioner _parentYScaler;

  /// Not-scaled and not-transformed label value.
  ///
  /// This is only used in labels display, never to calculate or display data values.
  /// All data values calculations are using the [_dataValue].
  late final num _rawDataValue;

  /// The transformed [_rawDataValue].
  final num _dataValue;

  /// Scaled label value.
  ///
  /// [_axisValue]s are on the scale of y axis length.
  late final num _axisValue;
  num get axisValue => _axisValue;

  /// Label showing on the Y axis; typically a value with unit.
  ///
  /// Formatted label is just formatted [_axisValue].
  late final String _formattedLabel;
  String get formattedLabel => _formattedLabel;

  /// Constructs from value at the label, using scaler which keeps dataRange
  /// and axisRange (min, max).
  LabelInfo({
    required num dataValue,
    required YLabelsCreatorAndPositioner parentYScaler,
  })  : _dataValue = dataValue,
        _parentYScaler = parentYScaler {
    var yInverseTransform = _parentYScaler._yInverseTransform;
    _rawDataValue = yInverseTransform(_dataValue);
  }

  /// Scales this [LabelInfo] to the position on the Y axis.
  void _scaleLabelValue() {
    // todo-13 consider what to do about the toDouble() - ensure higher up so if parent scaler not set by now, scaledLabelValue remains null.
    _axisValue = _parentYScaler.scaleY(value: _dataValue.toDouble());
  }

  @override
  String toString() {
    return super.toString() +
        ' dataValue=$_rawDataValue,' +
        ' transformedDataValue=$_dataValue,' +
        ' _axisValue=$_axisValue,' +
        ' _formattedLabel=$_formattedLabel,';
  }
}
