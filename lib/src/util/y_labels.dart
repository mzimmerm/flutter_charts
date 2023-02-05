import 'dart:math' as math show min, max, pow;
// import 'package:flutter_charts/flutter_charts.dart';
import 'package:flutter_charts/flutter_charts.dart';
import 'package:flutter_charts/src/chart/model/new_data_model.dart';

import 'util_dart.dart' as util_dart;
import 'test/generate_test_data_from_app_runs.dart';
import '../chart/container.dart' show ChartBehavior;

/// Creates, transforms (e.g. to log values), scales to Y axis pixels, and formats the Y labels.
///
/// The Y labels are kept in the [labelInfos] member in all forms - raw, transformed, scaled, and raw formatted.
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

  // todo-00-last-last-done : hack to get code access to ChartRootContainer, but can be null in tests
  late final NewDataModel? _newDataModelForFunction;
  bool? _isStacked;

  List<String>? yUserLabels;

  /// The list of numeric Y values, passed to constructor.
  ///
  /// Calculated as : geometry.iterableNumToDouble(chartRootContainer.pointsColumns.flattenPointsValues()).toList(),
  ///                 contains all values in [DeprecatedChartData.dataRows].
  final List<double> _dataYs;

  /// Coordinates of the Y axis.
  final util_dart.Interval _axisY;

  /// The chart options.
  // todo-00-last-last : removed final bool _startYAxisAtDataMinAllowed;

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
  late final util_dart.Interval dataYsEnvelope;

  /// Maintains labels created from data values, scaled and not-scaled.
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
    required util_dart.Interval axisY,
    required bool startYAxisAtDataMinAllowed,
    required Function valueToLabel,
    required Function yInverseTransform,
    this.yUserLabels,
    NewDataModel? newDataModelForFunction,
    bool? isStacked,
  })  : _dataYs = dataYs,
        _axisY = axisY,
        // todo-00-last-last : removed _startYAxisAtDataMinAllowed = startYAxisAtDataMinAllowed,
        _valueToLabel = valueToLabel,
        _yInverseTransform = yInverseTransform,
        _newDataModelForFunction = newDataModelForFunction,
        _isStacked = isStacked {
    // hack for tests to not have to change. todo-011 : fix in tests
    _isStacked ??= false;

    List<double> distributedLabelYs;
    // Find the interval for Y values (may be an envelop around values, for example if we want Y to always start at 0),
    //   then create labels evenly distributed in the Y values interval.
    if (_isUsingUserLabels) {
      dataYsEnvelope = util_dart.deriveDataEnvelopeForUserLabels(_dataYs);
      distributedLabelYs = _distributeUserLabelsIn(dataYsEnvelope);
    } else {
      // todo-00-last-last-last : replaced with new version : dataYsEnvelope = util_dart.deriveDataEnvelopeForAutoLabels(_dataYs, _chartBehavior.startYAxisAtDataMinAllowed);
      // todo-00-last-last-last : added arg : distributedLabelYs = _distributeAutoLabelsIn(dataYsEnvelope);

      dataYsEnvelope = _newDataModelForFunction!.dataValuesEnvelope(isStacked: _isStacked!);
      distributedLabelYs = _distributeAutoLabelsIn(dataYsEnvelope, startYAxisAtDataMinAllowed);
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
    return util_dart.scaleValue(
        value: value.toDouble(),
        fromDomainMin: _mergedLabelYsIntervalWithDataYsEnvelope.min.toDouble(),
        fromDomainMax: _mergedLabelYsIntervalWithDataYsEnvelope.max.toDouble(),
        toDomainNewMax: _axisY.max,
        toDomainNewMin: _axisY.min);
  }

  // ### Helper accessors to collection of LabelInfos

  /// Extracts not-scaled && transformed values where labels from [labelInfos] are positioned.
  List<double> get dataYsOfLabels => labelInfos.map((labelInfo) => labelInfo._dataValue.toDouble()).toList();

  /// Constructs interval which is a merge (outer bound) of
  /// two ranges: the labels interval [dataYsOfLabels] (calculated from [LabelInfo._dataValue])
  /// and the [dataYsEnvelope] (envelop of [_dataYs]). Both are not-scaled && transformed.
  util_dart.Interval get _mergedLabelYsIntervalWithDataYsEnvelope => util_dart.Interval(
        dataYsOfLabels.reduce(math.min), // not-scaled && transformed data from  labelInfo.transformedDataValue
        dataYsOfLabels.reduce(math.max),
      ).merge(dataYsEnvelope); // dataY from PointsColumns, which is also not-scaled && transformed, data

  // todo-00 : added the 4 getters for a quick access by the new scaler
  double get fromDomainMin => _mergedLabelYsIntervalWithDataYsEnvelope.min;
  double get fromDomainMax => _mergedLabelYsIntervalWithDataYsEnvelope.max;
  // used in new scaling within NewDataContainer coordinates!! So make sure it starts with 0.0 and
  // length is same as constraint size given to NewDataContainer.
  double get toDomainMin => 0.0;
  double get toDomainMax => _axisY.max - _axisY.min;

  /// Automatically generates labels from data.
  ///
  /// Labels are encapsulated in the created and returned [YLabelsCreatorAndPositioner],
  /// which manages [LabelInfo]s for all generated labels.
  ///
  /// The [axisYMin] and [axisYMax] define the top and the bottom of the Y axis in the canvas coordinate system.

  /// Makes anywhere from zero to nine label values, of greatest power of
  /// the passed [dataYsEnvelope.end].
  ///
  /// Precision is 1 (that is, only leading digit, rest 0s).
  ///
  /// Examples:
  ///   1. [util_dart.Interval] is <0, 123> then labels=[0, 100]
  ///   2. [util_dart.Interval] is <0, 299> then labels=[0, 100, 200]
  ///   3. [util_dart.Interval] is <0, 999> then labels=[0, 100, 200 ... 900]
  ///
  List<double> _distributeAutoLabelsIn(util_dart.Interval dataYsEnvelope, bool startYAxisAtDataMinAllowed) {
    var polyMin = util_dart.Poly(from: dataYsEnvelope.min);
    var polyMax = util_dart.Poly(from: dataYsEnvelope.max);

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
        if (startYAxisAtDataMinAllowed) {
          endCoeff = signMax * coeffMax;
        }
        for (double l = startCoeff; l <= endCoeff; l++) {
          labels.add(l * math.pow(10, power));
        }
      } else {
        // signMax >= 0
        double startCoeff = 1.0 * 0;
        int endCoeff = signMax * coeffMax;
        if (startYAxisAtDataMinAllowed) {
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
  /// [StackableValuePoint.dataY] in all [StackableValuePoint]s created from [DeprecatedChartData.dataRows].
  ///
  /// The first label from the [yUserLabels] list is positioned on the Y closure minimum values
  /// (which corresponds with the start of the Y axis - the horizontal level of the X axis).
  ///
  /// Preconditions:
  /// - This method assumes that a list of user labels was provided in [DeprecatedChartData.yUserLabels].
  List<double> _distributeUserLabelsIn(util_dart.Interval dataYsEnvelope) {
    double dataStepHeight = (dataYsEnvelope.max - dataYsEnvelope.min) / (yUserLabels!.length - 1);

    // Evenly distribute labels in [dataYsEnvelope]
    List<double> yLabelsInDataYsEnvelope = List.empty(growable: true);
    for (int yIndex = 0; yIndex < yUserLabels!.length; yIndex++) {
      yLabelsInDataYsEnvelope.add(dataYsEnvelope.min + dataStepHeight * yIndex);
    }
    return yLabelsInDataYsEnvelope;
  }
}

/// The [LabelInfo] is a holder for one label,
/// it's numeric values (raw, transformed, transformed and scaled)
/// and the displayed label.
///
/// The values used and shown on the chart undergo the following processing:
///    [_rawDataValue] -- using [DataContainerOptions.yTransform]         --> [_dataValue] (transformed)
///    [_dataValue]    -- using parentYScaler.scaleY(value: _dataValue)   --> [_axisValue] (transformed AND scaled)
///    [_rawDataValue] -- using formatted String-value of [_rawDataValue] --> [_formattedLabel]
/// The last mapping is using either `toString` if [YLabelsCreatorAndPositioner.yUserLabels] are used,
/// or [YLabelsCreatorAndPositioner._valueToLabel] for chart-generated labels.
///
/// There are four values each [LabelInfo] manages:
/// 1. The [_rawDataValue] : The value of dependent (y) variable in data, given by
///   the [YLabelsCreatorAndPositioner._mergedLabelYsIntervalWithDataYsEnvelope].
///   - This value is **not-scaled && not-transformed**.
///   - This value is in the interval extended from the interval of minimum and maximum y in data
///     to the interval of the displayed labels. The reason is the chart may show axis lines and labels
///     beyond the strict interval between minimum and maximum y in data.
///   - This value is created in the generative constructor's [LabelInfo]
///     initializer list from the [transformedDataValue].
/// 2. The [_dataValue] : The [_rawDataValue] after transformation by the [DataContainerOptions.yTransform]
///   function.
///   - This value is **not-scaled && transformed**
///   - This value is same as [_rawDataValue] if the [DataContainerOptions.yTransform]
///     is an identity (this is the default behavior). See [lib/chart/options.dart].
///   - This value is passed in the primary generative constructor [LabelInfo].
/// 3. The [_axisValue] :  Equals to the **scaled && transformed** dataValue, in other words
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
/// 4. The [_formattedLabel] : The formatted String-value of [_rawDataValue].
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
    // todo-02 consider what to do about the toDouble() - ensure higher up so if parent scaler not set by now, scaledLabelValue remains null.
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
