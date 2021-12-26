import 'dart:math' as math show min, max, pow;
import 'package:decimal/decimal.dart' as decimal;
import 'package:flutter_charts/src/chart/options.dart';
import 'util_dart.dart' as util_dart;

// todo-2 - this library (range.dart) has been modified for Dart 2.0
//            using a hack which replaces all List<num> to List<double>,
//            also some int replaced with double. Parametrize with T

/// Scalable range, supporting creation of scaled x and y axis labels.
///
class Range {
  // ### Public api

  // ### Private api

  final List<double> _values;

  final ChartOptions _options;

  /// Constructs a scalable range from a list of passed [values].
  ///
  /// Given a list of [values] (to show on Y axis),
  /// [makeLabelsFromData] creates labels evenly distributed to cover the range of values,
  /// trying to not waste space, and show only relevant labels, in
  /// decimal steps.
  Range({
    required List<double> values,
    required ChartOptions chartOptions,
  })  : _values = values,
        // todo 1 maxLabels does not work. Enable and add to test
        _options = chartOptions;

  /// superior and inferior closure - min and max of values
  Interval get _closure => Interval(_values.reduce(math.min).toDouble(), _values.reduce(math.max).toDouble(), true,
      true); // todo-2 remove toDouble after parametrization

  /// Automatically generates unscaled labels (more precisely their values)
  /// from data.
  ///
  /// The [toDisplayScaleMin] and [toDisplayScaleMax] are the display scale,
  /// for example the range of Y axis positions between bottom and top.
  YScalerAndLabelFormatter makeLabelsFromDataOnScale({
    required double toDisplayScaleMin,
    required double toDisplayScaleMax,
  }) {
    double min = _closure.min;
    double max = _closure.max;

    Poly polyMin = Poly(from: min);
    Poly polyMax = Poly(from: max);

    int signMin = polyMin.signum;
    int signMax = polyMax.signum;

    // envelope for all y values
    double from, to;

    // Need to handle all combinations of the above (a < b < c etc).
    // There are not that many, because pMin <= pMax and pDiff <= pMax.
    /* keep
    if (false && powerDiff < powerMin) {
      // todo-11-github-issue-31-allow-start-Y-axis-from-non-zero
      //          to allow for details, mainly for lots of values.
      //          Make an option for this. Add to tests.
      from = polyMin.floorAtMaxPower.toDouble();
      to = polyMax.ceilAtMaxPower.toDouble();
    } else {
      */
    // for now, always start with min or 0, and end at max (reverse if both negative).

    if (signMax <= 0 && signMin <= 0 || signMax >= 0 && signMin >= 0) {
      // both negative or positive
      if (signMax <= 0) {
        from = min;
        to = 0.0;
      } else {
        from = 0.0;
        to = max;
      }
    } else {
      from = min;
      to = max;
    }
    // keep }

    // Now make labels, evenly distributed in the from, to range.
    // Make labels only in polyMax steps (e.g. 100, 200 - not 100, 110 .. 200).
    // Labels are (obviously) unscaled, that is, on the scale of data,
    // not the displayed pixels scale.

    List<double> labels = _distributeLabelsIn(Interval(from, to)); // todo 0 pull only once (see below)

    // print( " ################ makeLabelsFromData: For ###_values=$_values found ###labeValues=${labels} and ###dataRange= ${from} to ${to} ");

    var yScaler = YScalerAndLabelFormatter(
        dataRange: Interval(from, to),
        valueOnLabels: labels,
        toDisplayScaleMin: toDisplayScaleMin,
        toDisplayScaleMax: toDisplayScaleMax,
        chartOptions: _options);

    yScaler.scaleLabelInfos();
    yScaler.makeLabelsPresentable();

    return yScaler;
  }

  /// Makes anywhere from zero to nine label values, of greatest power of
  /// the passed [interval.max].
  ///
  /// Precision is 1 (that is, only leading digit, rest 0s).
  ///
  /// Examples:
  ///   1. [Interval] is <0, 123> then labels=[0, 100]
  ///   2. [Interval] is <0, 299> then labels=[0, 100, 200]
  ///   3. [Interval] is <0, 999> then labels=[0, 100, 200 ... 900]
  ///
  List<double> _distributeLabelsIn(Interval interval) {
    Poly polyMin = Poly(from: interval.min);
    Poly polyMax = Poly(from: interval.max);

    int powerMax = polyMax.maxPower;
    int coeffMax = polyMax.coefficientAtMaxPower;
    int signMax = polyMax.signum;

    // using Min makes sense if one or both (min, max) are negative
    int powerMin = polyMin.maxPower;
    int coeffMin = polyMin.coefficientAtMaxPower;
    int signMin = polyMin.signum;

    List<double> labels = [];
    int power = math.max(powerMin, powerMax);

    // todo-1 refactor this and make generic
    if (signMax <= 0 && signMin <= 0 || signMax >= 0 && signMin >= 0) {
      // both negative or positive
      if (signMax <= 0) {
        for (double l = 1.0 * signMin * coeffMin; l <= 0; l++) {
          labels.add(l * math.pow(10, power));
        }
      } else {
        // signMax >= 0
        for (double l = 1.0 * 0; l <= signMax * coeffMax; l++) {
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
}

/// Encapsulating Y axis scaling (dataRange scaling to available pixels)
/// and Y Labels creation and formatting.
class YScalerAndLabelFormatter {
  /// Manages, formats, and scales Y labels created from data values
  /// by [Range].
  ///
  /// and unscaled (closure is on the scale of data).
  ///
  /// Note: generally, the interval of labels from [labelInfos]
  ///       and data interval [dataRange] overlap/intersect,
  ///       but are not a subset of one another.
  Interval dataRange;

  /// Maintains labels created from data values, scaled and unscaled.
  List<LabelInfo> labelInfos;

  final double _toDisplayScaleMin;
  final double _toDisplayScaleMax;
  final ChartOptions _options;

  YScalerAndLabelFormatter({
    required this.dataRange,
    required List<double> valueOnLabels,
    required double toDisplayScaleMin,
    required double toDisplayScaleMax,
    required ChartOptions chartOptions,
  })  : labelInfos = valueOnLabels.map((value) => LabelInfo(value)).toList(),
        _toDisplayScaleMin = toDisplayScaleMin,
        _toDisplayScaleMax = toDisplayScaleMax,
        _options = chartOptions {
    // late initialize the parentScaler
    for (LabelInfo labelInfo in labelInfos) {
      labelInfo.parentScaler = this;
    }
  }

  /// Scales [value]
  ///   - from the own scale, given be the merged data and label intervals
  ///   calculated in [labelAndDataRangeMerged]
  ///   - to the Y axis scale defined by [_toDisplayScaleMin], [_toDisplayScaleMax].
  double scaleY({
    required double value,
  }) {
    Interval mergedYValueScale = labelValuesAndDataRangesMerged;
    return util_dart.scaleValue(
        value: value.toDouble(),
        yValueScaleMin: mergedYValueScale.min.toDouble(),
        yValueScaleMax: mergedYValueScale.max.toDouble(),
        toDisplayScaleMin: _toDisplayScaleMin,
        toDisplayScaleMax: _toDisplayScaleMax);
  }

  /// Self-scales the Y label values in [labelInfos] to the scale
  /// of the available chart size.
  /// todo 1 maybe make private and wrap - need for manual layout - better, create method for manual layout and move code from containers here
  void scaleLabelInfos() {
    for (LabelInfo labelInfo in labelInfos) {
      labelInfo._scaleLabelValue();
    }

    if (_toDisplayScaleMin > _toDisplayScaleMax) {
      // we are inverting scales, so invert labels.
      labelInfos = labelInfos.reversed.toList();
    }
  }

  /// Manual layout helper, forces values and scaled values.
  void setLabelValuesForManualLayout({
    required List labelValues,
    required List scaledLabelValues,
    required List formattedYLabels,
  }) {
    for (int i = 0; i < labelValues.length; i++) {
      labelInfos[i].labelValue = labelValues[i];
      labelInfos[i].scaledLabelValue = scaledLabelValues[i];
      labelInfos[i].formattedYLabel = formattedYLabels[i];
    }

    if (_toDisplayScaleMin > _toDisplayScaleMax) {
      // we are inverting scales, so invert labels.
      labelInfos = labelInfos.reversed.toList();
    }
  }

  /// Format labels in a way suitable for presentation on the Y axis.
  ///
  /// [ChartOptions] allow for customization.
  /// todo 1 maybe make private and wrap - need for manual layout - better, create a constructor for manual layout and move code from containers here
  void makeLabelsPresentable() {
    for (LabelInfo labelInfo in labelInfos) {
      labelInfo.formattedYLabel = _options.yContainerOptions.valueToLabel(labelInfo.labelValue);
    }
  }

  // ### Helper accessors to collection of LabelInfos

  /// Extracts unscaled values of labels from [labelInfos].
  List<double> get labelValues => labelInfos.map((labelInfo) => labelInfo.labelValue.toDouble()).toList();

  /// Constructs interval which is a merge (outer bound) of
  /// two ranges: the labels range stored in [ labelValues]
  /// and the [dataRange].
  ///
  /// Typically, [labelRange] and [dataRange] overlap but are not subset
  /// of one another - but that will in the future change in some
  /// cases, as defined by [ChartOptions].
  ///
  /// **The returned [Interval] is intended to be used as the full extend
  /// of the unscaled Y axis.**
  Interval get labelValuesAndDataRangesMerged =>
      Interval(labelValues.reduce(math.min), labelValues.reduce(math.max)).merge(dataRange);
}

/// Manages labels and their values: scaled in , unscaled, and presented (formatted)
///
///  YLabels Note:
///
///    - There are 3 intervals (example values in text):
///     - We have these scales:
///       - *YScalerAndLabelFormatter.dataRange* e.g.  ###dataRange= [-600.0, 1800.0]  from data _values=[-600.0 ....  1800.0]
///       - *YScalerAndLabelFormatter.labelRange* = [-1000, 1000] was correctly deduced
///       - *YScalerAndLabelFormatter.labelAndDataRangeMerged* =  [-1000, 1800] - merge of the above
///       - *_yAxisAvailableHeight* = 376.0
///       - *Further, y axis must start at _yAxisMinOffsetFromTop = 8.0*
///     - *So, we need to*:
///       - 1. *Map / scale all YScalerAndLabelFormatter.labelValues using:*
///         - /yValueScale=labelAndDataRangeMerged=[-1000, 1800]/,
///         - /toDisplayScale=[8, 8+376]/;
///       - 2. yAxis scale is [8, 8+376]=[_yAxisMinOffsetFromTop,  _yAxisMinOffsetFromTop + _yAxisAvailableHeight]

class LabelInfo {
  late YScalerAndLabelFormatter parentScaler;

  /// Unscaled label value, ([labelValues] are on the scale of data).
  num labelValue;

  /// Label showing on the Y axis; typically a value with unit.
  ///
  /// Formatted label is just formatted [scaledLabelValue].
  late String formattedYLabel;

  /// Scaled label value.
  ///
  /// [scaledLabelValue]s are on the scale of y axis length.
  double scaledLabelValue = 0.0;

  /// Constructs from value at the label, using scaler which keeps dataRange
  /// and axisRange (min, max).
  LabelInfo(this.labelValue);

  /// Self-scale the RangeOutput to the scale of the available chart size.
  void _scaleLabelValue() {
    // todo-2 consider what to do about the toDouble() - may want to ensure higher up
    // so if parent scaler not set by now, scaledLabelValue remains null.
    scaledLabelValue = parentScaler.scaleY(value: labelValue.toDouble());
  }

  @override
  String toString() {
    return super.toString() +
        ' scaledLabelValue=$scaledLabelValue,' +
        ' labelValue=$labelValue,' +
        ' formattedYLabel=$formattedYLabel';
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
}
