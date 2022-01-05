import 'dart:math' as math show min, max, pow;
import 'package:decimal/decimal.dart' as decimal;
import 'package:flutter_charts/flutter_charts.dart';
import 'package:flutter_charts/src/chart/options.dart';
import 'package:flutter_charts/src/util/test/generate_test_data_from_app_runs.dart';
import 'util_dart.dart' as util_dart;

// todo-13 - this library (range.dart) has been modified for Dart 2.0
//            using a hack which replaces all List<num> to List<double>,
//            also some int replaced with double. Parametrize with T

/* todo-00-last
/// Scalable range, supporting creation of scaled x and y axis labels.
///
class Range {
  final List<double> _dataYs;

  final ChartOptions _options;

  /// Constructs a scalable range from a list of passed [dataYs].
  ///
  /// Given a list of [dataYs] (to show on Y axis),
  /// [makeAutoLayoutYScalerWithLabelInfosFromDataYsOnScale] creates labels evenly distributed to cover the range of values,
  /// trying to not waste space, and show only relevant labels, in
  /// decimal steps.
  Range({
    required List<double> dataYs,
    required ChartOptions chartOptions,
  })  : _dataYs = dataYs,
        _options = chartOptions;
}
 */

// todo-00-last-document
/// Creates, scales, and formats the Y labels, all the way
/// from the transformed data to their positions and displayed strings on the Y axis.
///
/// Objects of this class are created in [Range.makeAutoLayoutYScalerWithLabelInfosFromDataYsOnScale].
///
///    - There are two members relevant in the creating and formatting labels
///       - [dataYsEnvelop]
///          Required to be passed in constructor, is the envelope of data, possibly extended to 0.
///            e.g. dataRange= [-600.0, 1800.0]  from data [-600.0 ....  1800.0]
///       - [labelInfos]
///         A list of labels with additional info.
///         This list is created in the constructor to cover the interval [dataYsEnvelop]
///         deduced from [labelYsInDataYsEnvelope] passed in constructor, previously
///         created by [Range.distributeLabelsIn()] method
///           The labelInfos may contain e.g. four labels: [-1000, 0, 1000, 2000]
///    - From the two members, the [mergedLabelYsIntervalWithDataYsEnvelop] can be calculated as a merge
///      of the [labelInfos] envelop and the [dataYsEnvelop]. The [mergedLabelYsIntervalWithDataYsEnvelop]
///      serves as the '(transformed) data range' - all (transformed) data are located in this range;
///      from this range, the data values and label positions are scaled to the Y axis scale.
///            e.g. [-1000, 2000]
class YScalerAndLabelFormatter {
  // todo-00-last-last : pass yUserLabels from _chartTopContainer.data.yUserLabels! MAKE PRIVATE
  List<String>? yUserLabels;
  
  // todo-00-last moved from range
  final List<double> _dataYs;

  /// [dataYsEnvelop] are created from the [StackableValuePoint.toY] by the [PointsColumns.flattenPointsValues()].
  /// The [StackableValuePoint]s are located on [PointsColumns], then [PointsColumn.stackableValuePoints].
  /// Pseudocode of the [dataYsEnvelop] creation:
  ///   ```
  ///   - YContainer.layout
  ///     - YContainer.layoutAutomatically
  ///       - YContainer._layoutCreateYScalerFromPointsColumnsData(axisYMin, axisYMax)
  ///         - dataYs = _chartTopContainer.pointsColumns.flattenPointsValues()
  ///         - new Range(values: dataYs, options)
  ///         - yScaler = Range.makeYScalerWithLabelInfosFromDataYsOnScale(axisYMin: axisYMin, axisYMax: axisYMax,)
  ///           - This creates the distributed labels as follows:
  ///             - distributedLabelYs = Range.distributeLabelsIn(Interval(dataYsMinExtendedTo0, dataYsMaxExtendedTo0,))
  ///               - So the labels are distributed in the TRANSFORMED dataYMin, dataYMax (maybe extended)
  ///             - yScaler = YScalerAndLabelFormatter(
  ///                 dataYsEnvelop: Interval(dataYsMinExtendedTo0, dataYsMaxExtendedTo0),
  ///                 labelYsInDataYsEnvelope: distributedLabelYs,
  ///                 axisYMin: axisYMin,
  ///                 axisYMax: axisYMax,
  ///                 chartOptions: _options);
  ///           - In the end, the yScaler scales from the (extended) dataYMin - dataYMax to the axisYMin - axisYMax. So, given a label's raw value, it will display the raw value, which is what we want.
  // todo-00-last-last make _ private
  late Interval dataYsEnvelop;
  
  /// Maintains labels created from data values, scaled and unscaled.
  // TODO-00-LAST CAN THIS BE PRIVATE
  late List<LabelInfo> labelInfos;
  
  final Interval _axisY;
  
  final ChartOptions _options;

  // TODO-00-LAST : MAKE ALL METHODS PRIVATE.
  YScalerAndLabelFormatter({
    required List<double> dataYs,
    // todo-00-last removed : required this.dataYsEnvelop,
    // todo-00-last removed : required List<double> labelYsInDataYsEnvelope,
    required Interval axisY,
    required ChartOptions chartOptions,
    this.yUserLabels,
  })  : _dataYs = dataYs,
        _axisY = axisY,
        _options = chartOptions {
    
    List<double> distributedLabelYs;
    if (isUsingUserLabels) {
      // todo-00-last-last-done moved pieces of code from manualLayoutExtractLabelsDistribution here
      dataYsEnvelop = _deriveDataYsEnvelopForUserLabels() ;
      distributedLabelYs = _distributeUserLabelsIn(dataYsEnvelop);
    } else {
      dataYsEnvelop = _deriveDataYsEnvelopForAutoLabels();
      distributedLabelYs = _distributeAutoLabelsIn(dataYsEnvelop);
    }
    // Create LabelInfos for all labels and point each to this scaler
    labelInfos = distributedLabelYs  // this is the label/DataYs enveloper - all values after transform
        .map((transformedLabelValue) => LabelInfo(
      transformedDataValue: transformedLabelValue,
      parentYScaler: this,
    ))
        .toList();

    scaleLabelInfos();

    if (isUsingUserLabels) {
      // todo-00-last-last-last finish this
      // Use list comprehension to iterate two arrays in parallel
      for(int i = 0; i < labelInfos.length; i += 1) {
        labelInfos[i].formattedLabel = yUserLabels![i];
      }
      
/* todo-00-last
      for (LabelInfo labelInfo in labelInfos) {
        labelInfo.formattedLabel = _options.yContainerOptions.valueToLabel(labelInfo.dataValue);
      }

      yScaler.setLabelValuesForManualLayout(
          labelValues: yLabelsDividedInYDataRange,
          scaledLabelValues: manuallyDistributedLabelYs,
          formattedYLabels: yUserLabels);


      for (int i = 0; i < labelValues.length; i++) {
        labelInfos[i].dataValue = labelValues[i];
        labelInfos[i].transformedDataValue = _options.dataContainerOptions.yTransform(labelInfos[i].dataValue);
        labelInfos[i].axisValue = scaledLabelValues[i];
        labelInfos[i].formattedLabel = formattedYLabels[i];
      }

      if (_axisY.min > _axisY.max) {
        // we are inverting scales, so invert labels.
        labelInfos = labelInfos.reversed.toList();
      }
*/


    } else {
      _formatAutoLabels();
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
          dataYsEnvelop.min,
          dataYsEnvelop.max,
        ],
        this);
  }
  
  bool get isUsingUserLabels => yUserLabels != null;

  /// Scales [value]
  ///   - from own scale, given be the merged data and label intervals
  ///   calculated in [mergedLabelYsIntervalWithDataYsEnvelop]
  ///   - to the Y axis scale defined by [_axisYMin], [_axisYMax].
  double scaleY({
    required double value,
  }) {
    // Use linear scaling utility to scale from data Y interval to axis Y interval
    return util_dart.scaleValue(
        value: value.toDouble(),
        fromDomainMin: mergedLabelYsIntervalWithDataYsEnvelop.min.toDouble(),
        fromDomainMax: mergedLabelYsIntervalWithDataYsEnvelop.max.toDouble(),
        toDomainMin: _axisY.min,
        toDomainMax: _axisY.max);
  }

  /// Self-scales the Y label values in [labelInfos] to the scale
  /// of the available chart size.
  /// todo 1 maybe make private and wrap - need for manual layout - better, create method for manual layout and move code from containers here
  void scaleLabelInfos() {
    for (LabelInfo labelInfo in labelInfos) {
      labelInfo._scaleLabelValue();
    }

/* todo-00-last-last-last moved at the end
    if (_axisY.min > _axisY.max) {
      // we are inverting scales, so invert labels.
      labelInfos = labelInfos.reversed.toList();
    }
*/
  }

  /// Manual layout helper, forces values and scaled values.
  void setLabelValuesForManualLayout({
    required List labelValues,
    required List scaledLabelValues,
    required List formattedYLabels,
  }) {
    for (int i = 0; i < labelValues.length; i++) {
      labelInfos[i].dataValue = labelValues[i];
      labelInfos[i].transformedDataValue = _options.dataContainerOptions.yTransform(labelInfos[i].dataValue);
      labelInfos[i].axisValue = scaledLabelValues[i];
      labelInfos[i].formattedLabel = formattedYLabels[i];
    }

    if (_axisY.min > _axisY.max) {
      // we are inverting scales, so invert labels.
      labelInfos = labelInfos.reversed.toList();
    }
  }

  /// Format labels in a way suitable for presentation on the Y axis.
  ///
  /// [ChartOptions] allow for customization.
  /// todo 1 maybe make private and wrap - need for manual layout - better, create a constructor for manual layout and move code from containers here
  void _formatAutoLabels() {
    for (LabelInfo labelInfo in labelInfos) {
      labelInfo.formattedLabel = _options.yContainerOptions.valueToLabel(labelInfo.dataValue);
    }
  }

  // ### Helper accessors to collection of LabelInfos

  /// Extracts not-scaled && transformed values where labels from [labelInfos] are positioned.
  List<double> get dataYsOfLabels => labelInfos.map((labelInfo) => labelInfo.transformedDataValue.toDouble()).toList();

  /// Constructs interval which is a merge (outer bound) of
  /// two ranges: the labels range [dataYsOfLabels] (calculated from [YScalerAndLabelFormatter] [LabelInfo.transformedDataValue.])
  /// and the [dataYsEnvelop] which is also transformed data. Both are not-scaled && transformed.
  ///
  // TODO-00-LAST : IS THIS ACTUALLY NEEDED? MAYBE THE SCALING IS RIGHT WITHOUT THIS? 
  Interval get mergedLabelYsIntervalWithDataYsEnvelop => Interval(
        dataYsOfLabels.reduce(math.min), // not-scaled && transformed data from  labelInfo.transformedDataValue
        dataYsOfLabels.reduce(math.max),
      ).merge(dataYsEnvelop); // dataY from PointsColumns, which is also not-scaled && transformed, data

///////////////////////////////////////////////////////////////
// todo-00-last : moved here from Range
  /// superior and inferior closure - min and max of values
// todo-13-move-to-interval class
// todo-13-parametrize-interval-then-remove-toDouble
// todo-00-last moved here from range
/* todo-00-last-done removed, put inline, as only one use
  Interval get _dataYsEnvelop => Interval(
        _dataYs.reduce(math.min).toDouble(),
        _dataYs.reduce(math.max).toDouble(),
        // todo-00-last true,
        // todo-00-last true,
      );
*/

// todo-00-later document
  /// Derive the interval of dataY values, by default extended to start at 0 (all positive values),
  /// or end at 0 (all negative values).
// todo-00-last moved here from Range
  Interval _deriveDataYsEnvelopForAutoLabels() {
    
/* todo-00-last-done
    double dataYsMin = _dataYsEnvelop.min;
    double dataYsMax = _dataYsEnvelop.max;
*/
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
      if (_options.startYAxisAtDataMinAllowed) {
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

  // todo-00-last-last-last
  Interval _deriveDataYsEnvelopForUserLabels() {
      return Interval(_dataYs.reduce(math.min), _dataYs.reduce(math.max));
  }
// todo-00-last : moved here from Range
  /// Automatically generates labels from data.
  ///
  /// Labels are encapsulated in the created and returned [YScalerAndLabelFormatter],
  /// which manages [LabelInfo]s for all generated labels.
  ///
  /// The [axisYMin] and [axisYMax] define the top and the bottom of the Y axis in the canvas coordinate system.
/* todo-00-last : moved to constructor
  YScalerAndLabelFormatter makeAutoLayoutYScalerWithLabelInfosFromDataYsOnScale({
    required double axisYMin,
    required double axisYMax,
  }) {
    Interval dataYsExt = _deriveDataYsExt();
    List<double> distributedLabelYs = distributeAutoLabelsIn(dataYsExt);

    var yScaler = YScalerAndLabelFormatter(
        dataYsEnvelop: Interval(dataYsExt.min, dataYsExt.max),
        labelYsInDataYsEnvelope: distributedLabelYs,
        axisYMin: axisYMin,
        axisYMax: axisYMax,
        chartOptions: _options);

    yScaler.scaleLabelInfos();
    yScaler.makeLabelsPresentable();

    // Collect data for testing. Disabled in production
    collectTestData(
        'for_Range.makeYScalerWithLabelInfosFromDataYsOnScale_test',
        [
          _dataYs,
          axisYMin,
          axisYMax,
          distributedLabelYs,
          yScaler.dataYsEnvelop.min,
          yScaler.dataYsEnvelop.max,
        ],
        yScaler);

    return yScaler;
  }
 */
  
// todo-00-later try to move this to LabelInfo; also refactor and make more generic in respect to log scale.
  /// Makes anywhere from zero to nine label values, of greatest power of
  /// the passed [dataYsEnvelop.max].
  ///
  /// Precision is 1 (that is, only leading digit, rest 0s).
  ///
  /// Examples:
  ///   1. [Interval] is <0, 123> then labels=[0, 100]
  ///   2. [Interval] is <0, 299> then labels=[0, 100, 200]
  ///   3. [Interval] is <0, 999> then labels=[0, 100, 200 ... 900]
  ///
  List<double> _distributeAutoLabelsIn(Interval dataYsEnvelop) {
    Poly polyMin = Poly(from: dataYsEnvelop.min);
    Poly polyMax = Poly(from: dataYsEnvelop.max);

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
        if (_options.startYAxisAtDataMinAllowed) {
          endCoeff = signMax * coeffMax;
        }
        for (double l = startCoeff; l <= endCoeff; l++) {
          labels.add(l * math.pow(10, power));
        }
      } else {
        // signMax >= 0
        double startCoeff = 1.0 * 0;
        int endCoeff = signMax * coeffMax;
        if (_options.startYAxisAtDataMinAllowed) {
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
  
  // todo-00-last-last-last finish this
  List<double> _distributeUserLabelsIn(Interval dataYsEnvelop) {
    double dataStepHeight = (dataYsEnvelop.max - dataYsEnvelop.min) / (yUserLabels!.length - 1);

    /* todo-00-last-last : this code is doing same as label transformedDataValues scaling to axis scale!! 
    Interval yAxisInterval = Interval(axisYMin, axisYMax);

    double yGridStepHeight = (yAxisInterval.max - yAxisInterval.min) / (yUserLabels!.length - 1);

    //                     this should have same result as scaleY called later in scaleLabelInfos!!
    List<double> manuallyDistributedLabelYs = List.empty(growable: true);
    for (int yIndex = 0; yIndex < yUserLabels.length; yIndex++) {
      manuallyDistributedLabelYs.add(yAxisInterval.min + yGridStepHeight * yIndex);
    }
    */
    List<double> yLabelsDividedInYDataRange = List.empty(growable: true);
    for (int yIndex = 0; yIndex < yUserLabels!.length; yIndex++) {
      yLabelsDividedInYDataRange.add(dataYsEnvelop.min + dataStepHeight * yIndex);
    }
    return yLabelsDividedInYDataRange;    
  }

}

/// The [LabelInfo] is a holder for one label, it's numeric value and the displayed label.
///
/// There are four values each [LabelInfo] manages:
///   - [dataValue] : The value of dependent (y) variable in data,
///       given by [YScalerAndLabelFormatter.mergedLabelYsIntervalWithDataYsEnvelop].
///       - This value is **not-scaled && not-transformed**.
///       - This value is in the interval extended from the interval of minimum and maximum y in data
///         to the interval of the displayed labels. The reason is the chart may show axis lines and labels
///         beyond the strict interval between minimum and maximum y in data.
///       - This value is created in the generative constructor's [LabelInfo()]
///         initializer list from the [transformedDataValue].
///   - [transformedDataValue] : The [dataValue] after transformation by the [DataContainerOptions.yTransform]
///       function.
///       - This value is **not-scaled && transformed**
///       - This value is same as [dataValue] if the [DataContainerOptions.yTransform]
///         is an [identity()] (this is the default behavior). See [lib/chart/options.dart].
///       - This value is passed in the primary generative constructor [LabelInfo()].
///   - [axisValue] :  Equals to the **scaled && transformed** dataValue, in other words
///       ```dart
///        axisValue = parentYScaler.scaleY(value: transformedDataValue.toDouble());
///       ```
///       It is created as scaled [transformedDataValue], in the [PointsColumns]
///        where the scaling is from the Y data and labels envelop to the Y axis envelop.
///       - This value is **transformed and scaled**.
///       - This value is obtained as follows
///         ```dart
///             axisValue = parentYScaler.scaleY(value: transformedDataValue.toDouble());
///             // which does
///             return util_dart.scaleValue(
///                 value: value.toDouble(),
///                 fromDomainMin: mergedLabelYsIntervalWithDataYsEnvelop.min.toDouble(),
///                 fromDomainMax: mergedLabelYsIntervalWithDataYsEnvelop.max.toDouble(),
///                 toDomainMin: _axisYMin,
///                 toDomainMax: _axisYMax);
///         ```
///
///   - [formattedLabel] : The formatted String-value of [dataValue].
///
/// Note: The **scaled && not-transformed ** value is not maintained.
///
/// Note:  **Data displayed inside the chart use transformed data values, displayed labels show raw data values.**
///

class LabelInfo {
  YScalerAndLabelFormatter parentYScaler;

  /// Not-scaled and not-transformed label value.
  ///
  /// This is only used in labels display, never to calculate or display data values.
  /// All data values calculations are using the [transformedDataValue].
  late num dataValue;

  /// The transformed [dataValue].
  num transformedDataValue;

  /// Scaled label value.
  ///
  /// [axisValue]s are on the scale of y axis length.
  late num axisValue;

  /// Label showing on the Y axis; typically a value with unit.
  ///
  /// Formatted label is just formatted [axisValue].
  late String formattedLabel;

  /// Constructs from value at the label, using scaler which keeps dataRange
  /// and axisRange (min, max).
  LabelInfo({
    required this.transformedDataValue,
    required this.parentYScaler,
  }) {
    var yInverseTransform = parentYScaler._options.dataContainerOptions.yInverseTransform;
    dataValue = yInverseTransform(transformedDataValue);
  }

  /// Self-scale the RangeOutput to the scale of the available chart size.
  // todo-00-later-document well
  void _scaleLabelValue() {
    // todo-13 consider what to do about the toDouble() - ensure higher up so if parent scaler not set by now, scaledLabelValue remains null.
    axisValue = parentYScaler.scaleY(value: transformedDataValue.toDouble());
  }

  @override
  String toString() {
    return super.toString() +
        ' dataValue=$dataValue,' +
        ' transformedDataValue=$transformedDataValue,' +
        ' axisValue=$axisValue,' +
        ' formattedLabel=$formattedLabel,';
  }
}

/// A minimal polynomial needed for Y label and axis scaling.
///
/// Not fully a polynomial. Uses the [decimal] package.
class Poly {
  // ### members

  final decimal.Decimal _dec;
  final decimal.Decimal _one;
  final decimal.Decimal _ten;

  // ### constructors

  /// Create
  Poly({required num from})
      : _dec = dec(from.toString()),
        _one = numToDec(1),
        // 1.0
        _ten = numToDec(10);

  // ### methods

  // todo-11-last : added static on the 2 methods below. can this improve?
  static decimal.Decimal dec(String value) => decimal.Decimal.parse(value);

  static decimal.Decimal numToDec(num value) => dec(value.toString());

  int get signum => _dec.signum;

  int get fractLen => _dec.scale;

  int get totalLen => _dec.precision;

  int get coefficientAtMaxPower => (_dec.abs() / numToDec(math.pow(10, maxPower))).toInt();

  int get floorAtMaxPower => (numToDec(coefficientAtMaxPower) * numToDec(math.pow(10, maxPower))).toInt();

  int get ceilAtMaxPower => ((numToDec(coefficientAtMaxPower) + dec('1')) * numToDec(math.pow(10, maxPower))).toInt();

  /// Position of first significant non zero digit.
  ///
  /// Calculated by starting from 0 at the decimal point, first to the left,
  /// if no non zero is find on the left, then to the right.
  ///
  /// Zeros (0, 0.0 +-0.0 etc) are the only numbers where [maxPower] is 0.
  int get maxPower {
    if (totalLen == fractLen) {
      // pure fraction
      // multiply by 10 till >= 1.0 (not pure fraction)
      return _ltOnePower(_dec);
    }
    return totalLen - fractLen - 1;
  }

  int _ltOnePower(decimal.Decimal tester) {
    if (tester >= _one) throw Exception('$tester Failed: tester < 1.0');
    int power = 0;
    while (tester < _one) {
      tester = tester * _ten;
      power -= 1; // power = -1, -2, etc
    }
    return power;
  }
}

// todo 0 add tests; also make constant; also add validation for min before max
// todo-2: replaced num with double,  parametrize with T instead so it works for both

class Interval {
  Interval(this.min, this.max, [this.includesMin = true, this.includesMax = true]);

  final double min;
  final double max;
  final bool includesMin;
  final bool includesMax;

  bool includes(num comparable) {
    // before - read as: if negative, true, if zero test for includes, if positive, false.
    int beforeMin = comparable.compareTo(min);
    int beforeMax = comparable.compareTo(max);

    // Hopefully these complications gain some minor speed,
    // dealing with the obvious cases first.
    if (beforeMin < 0 || beforeMax > 0) return false;
    if (beforeMin > 0 && beforeMax < 0) return true;
    if (beforeMin == 0 && includesMin) return true;
    if (beforeMax == 0 && includesMax) return true;

    return false;
  }

  /// Outermost union of this interal with [other].
  Interval merge(Interval other) {
    return Interval(math.min(min, other.min), math.max(max, other.max));
  }

  @override
  String toString() {
    return 'Interval($min, $max)';
  }
}
