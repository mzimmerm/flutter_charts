import 'dart:math' as math show min, max;
// import 'package:flutter_charts/flutter_charts.dart';
// import 'package:flutter_charts/flutter_charts.dart';
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

  // todo-done-last : hack to get code access to ChartRootContainer, but can be null in tests
  late final NewDataModel? _newDataModelForFunction;
  bool? _isStacked;

  // todo-00-last-last-last : Storing the merged interval from labels and values.
  // todo-00-last-last : Note this is now from NewDataModelPoints !!
  late final util_dart.Interval _mergedIntervalsFromLabelsAndValues;

  List<String>? yUserLabels;

  /// The list of numeric Y values, passed to constructor.
  ///
  /// Calculated as : geometry.iterableNumToDouble(chartRootContainer.pointsColumns.flattenPointsValues()).toList(),
  ///                 contains all values in [DeprecatedChartData.dataRows].
  // todo-00-last-last-last : final List<double> _dataYs;

  /// Coordinates of the Y axis.
  final util_dart.Interval _axisY;

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
  /// todo-00-last-last : Note this is now from NewDataModelPoints !!
  /// todo-00-last-last : unused except tests : late final util_dart.Interval dataYsEnvelope;

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
    // todo-00-last-last-last : required List<double> dataYs,
    required util_dart.Interval axisY,
    required bool startYAxisAtDataMinAllowed,
    required Function valueToLabel,
    required Function yInverseTransform,
    this.yUserLabels,
    NewDataModel? newDataModelForFunction,
    bool? isStacked,
  })  :  // todo-00-last-last-last : _dataYs = dataYs,
        _axisY = axisY,
        _valueToLabel = valueToLabel,
        _yInverseTransform = yInverseTransform,
        _newDataModelForFunction = newDataModelForFunction,
        _isStacked = isStacked {
    // hack for tests to not have to change. todo-011 : fix in tests
    _isStacked ??= false;

    List<double> yLabelPositions;
    util_dart.Interval dataYsEnvelope;

    // Find the interval for Y values (may be an envelop around values, for example if we want Y to always start at 0),
    //   then create labels evenly distributed in the Y values interval.
    if (_isUsingUserLabels) {
      // todo-00-last-done : dataYsEnvelope = util_dart.deriveDataEnvelopeForUserLabels(_dataYs);
      // todo-00-last-done :  yLabelPositions = _distributeUserLabelsIn(dataYsEnvelope);
      dataYsEnvelope = _newDataModelForFunction!.dataValuesInterval(isStacked: _isStacked!);
      yLabelPositions = util_dart.evenlySpacedValuesIn(interval: dataYsEnvelope, pointsCount: yUserLabels!.length);
    } else {
      dataYsEnvelope = _newDataModelForFunction!.extendedDataValuesInterval(startYAxisAtDataMinAllowed: startYAxisAtDataMinAllowed, isStacked: _isStacked!);
      yLabelPositions = util_dart.generateValuesForLabelsIn(interval: dataYsEnvelope, startYAxisAtDataMinAllowed: startYAxisAtDataMinAllowed);
    }
    // Create LabelInfos for all labels and point each to this scaler
    labelInfos = yLabelPositions // this is the label/DataYs enveloper - all values after transform
        .map((transformedLabelValue) => LabelInfo(
              dataValue: transformedLabelValue,
              parentYScaler: this,
            ))
        .toList();

    // Once LabelInfos are prepared, we can store the merged interval
    // All values are calculated using the [NewDataModel] methods! That proves sameness nicely
    // dataYsOfLabels : not-scaled && transformed data from labelInfo.transformedDataValue
    _mergedIntervalsFromLabelsAndValues = util_dart.Interval(
      yLabelPositions.reduce(math.min),
      yLabelPositions.reduce(math.max),
    ).merge(dataYsEnvelope);

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

    /*
    // Collect data for testing. Disabled in production
    collectTestData(
        'for_Range.makeYScalerWithLabelInfosFromDataYsOnScale_test',
        [
          _dataYs,
          axisY.min,
          axisY.max,
          yLabelPositions,
          dataYsEnvelope.min,
          dataYsEnvelope.max,
        ],
        this);
    */
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
        fromDomainMin: _mergedIntervalsFromLabelsAndValues.min, // todo-00-last-last-last : _mergedLabelYsIntervalWithDataYsEnvelope(dataYsEnvelope: dataYsEnvelope, dataYsOfLabels: dataYsOfLabels).min.toDouble(),
        fromDomainMax: _mergedIntervalsFromLabelsAndValues.max, // todo-00-last-last-last : _mergedLabelYsIntervalWithDataYsEnvelope(dataYsEnvelope: dataYsEnvelope, dataYsOfLabels: dataYsOfLabels).max.toDouble(),
        toDomainNewMax: _axisY.max,
        toDomainNewMin: _axisY.min);
  }

  // ### Helper accessors to collection of LabelInfos

  /// Extracts not-scaled && transformed values where labels from [labelInfos] are positioned.
  List<double> get dataYsOfLabels => labelInfos.map((labelInfo) => labelInfo._dataValue.toDouble()).toList();

  /// Constructs interval which is a merge (outer bound) of
  /// two ranges: the labels interval [dataYsOfLabels] (calculated from [LabelInfo._dataValue])
  /// and the [dataYsEnvelope] (envelop of [_dataYs]).
  ///
  /// Both are not-scaled && transformed.
  ///
  /// Note: It is normal for one interval to be larger than the other on one or the other end,
  ///       but they should have a significant intersect.

/* todo-00-last-last-last : delete unused
  util_dart.Interval _mergedLabelYsIntervalWithDataYsEnvelope({
    required util_dart.Interval dataYsEnvelope,
    required List<double> dataYsOfLabels,
  }) {

    util_dart.Interval dataYsOfLabelsEnvelope = util_dart.Interval(
      dataYsOfLabels.reduce(math.min), // not-scaled && transformed data from  labelInfo.transformedDataValue
      dataYsOfLabels.reduce(math.max),
    );
    // if (!dataYsEnvelope.containsFully(dataYsOfLabelsEnvelope)) {
    //   throw StateError('!dataYsEnvelope.containsFully(dataYsOfLabelsEnvelope). dataYsEnvelope=$dataYsEnvelope, dataYsOfLabelsEnvelope=$dataYsOfLabelsEnvelope');
    // }
    return dataYsOfLabelsEnvelope.merge(dataYsEnvelope);
  } // dataY from PointsColumns, which is also not-scaled && transformed, data
*/

  // todo-00 : added the 4 getters for a quick access by the new scaler
  double get fromDomainMin => _mergedIntervalsFromLabelsAndValues.min; // todo-00-last-last-last : _mergedLabelYsIntervalWithDataYsEnvelope(dataYsEnvelope: dataYsEnvelope, dataYsOfLabels: dataYsOfLabels).min;
  double get fromDomainMax => _mergedIntervalsFromLabelsAndValues.max; // todo-00-last-last-last : _mergedLabelYsIntervalWithDataYsEnvelope(dataYsEnvelope: dataYsEnvelope, dataYsOfLabels: dataYsOfLabels).max;
  // used in new scaling within NewDataContainer coordinates!! So make sure it starts with 0.0 and
  // length is same as constraint size given to NewDataContainer.
  double get toDomainMin => 0.0;
  double get toDomainMax => _axisY.max - _axisY.min;


}

/// The [LabelInfo] is a holder for one label,
/// it's numeric values (raw, transformed, transformed and scaled)
/// and the displayed label.
///
/// It does not hold anything at all to do with UI - no layout sizes of labels in particular.
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
