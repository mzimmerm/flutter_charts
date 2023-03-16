import 'dart:math' as math show min, max;
import 'dart:ui' as ui show Color;

// this level or equivalent
import '../../chart/options.dart';

// NEW
import '../../chart/model/data_model.dart';

/// Manages Chart Data.
@Deprecated('Use ChartModel instead.')
class ChartData {
  /// Data in rows.
  ///
  /// Each row of data represents one data series.
  /// Legends per row are managed by [dataRowsLegends].
  ///
  /// Each element of the outer list represents one row.
  /// Alternative name would be "data series".
  final List<List<double>> dataRows;

  /// Labels on independent (X) axis.
  ///
  /// It is assumed labels are defined, by the client
  /// and their number is the same as number of points
  /// in each row in [dataRows].
  final List<String> xUserLabels;

  /// The legends for the [dataRows] (data series).
  ///
  /// One Legend String per row.
  /// Alternative name would be "series names".
  final List<String> dataRowsLegends;

  /// User defined labels to be used by the chart, instead of labels auto-generated from data.
  ///
  /// Can be Strings or numbers.
  /// If not null, a "manual" layout is used in the [YContainer].
  /// If null, a "auto" layout is used in the [YContainer].
  ///
  final List<String>? yUserLabels;

  /// Colors corresponding to each data row (series) in [ChartData].
  final List<ui.Color> dataRowsColors;

  /// Chart options which may affect data validation.
  final ChartOptions chartOptions;

  /// Default constructor only assumes [dataRows] are set,
  /// and assigns default values of [dataRowsLegends], [dataRowsColors], [xUserLabels], [yUserLabels].
  ///
  ChartData({
    required this.dataRows,
    required this.xUserLabels,
    required this.dataRowsLegends,
    required this.chartOptions,
    this.yUserLabels,
    dataRowsColors,
  }) :
        // Initializing of non-nullable dataRowsColors which is a non-required argument
        // must be in the initializer list by a non-member function (member methods only in constructor)
        dataRowsColors = dataRowsColors ?? dataRowsDefaultColors(dataRows.length) {
    validate();
  }

  List<double> get flatten => dataRows.expand((element) => element).toList();
  double get dataYMax => flatten.reduce(math.max);
  double get dataYMin => flatten.reduce(math.min);

  void validate() {
    //                      But that would require ChartOptions available in ChartData.
    if (!(dataRows.length == dataRowsLegends.length)) {
      throw StateError('The number of legend labels provided in parameter "dataRowsLegends", '
          'does not equal the number of data rows provided in parameter "dataRows":\n'
          'Detail reason: Row legend labels must be provided in parameter "dataRowsLegends", '
          'and their number must be the same as number of data rows. '
          'However, in your data definition, that is not the case:\n'
          '   [number of dataRows: ${dataRows.length}] != [number of dataRowsLegends: ${dataRowsLegends.length}].\n'
          'To fix this: provide ${dataRows.length} "dataRowsLegends".');
    }
    if (!(dataRows.length == dataRowsColors.length)) {
      throw StateError('The number of legend colors provided in parameter "dataRowsColors", '
          'does not equal the number of data rows provided in parameter "dataRows":\n'
          'Detail reason: If not provided in "dataRowsColors", legend colors are generated. '
          'If the parameter "dataRowsColors" is provided, '
          'the number of colors must be the same as number of data rows. '
          'However, in your data definition, that is not the case:\n'
          '   [number of dataRows: ${dataRows.length}] != [number of dataRowsColors: ${dataRowsColors.length}].\n'
          'To fix this: provide ${dataRows.length} "dataRowsColors".');
    }
    for (List<double> dataRow in dataRows) {
      if (!(dataRow.length == xUserLabels.length)) {
        throw StateError('If xUserLabels are defined, their '
            'length must be the same as length of each dataRow'
            ' [dataRow length: ${dataRow.length}] '
            '!= [xUserLabels length: ${xUserLabels.length}]. ');
      }
    }
    // Check explicit log10 used in options. This test does not cover user's explicitly declared transforms.
    if (log10 == chartOptions.dataContainerOptions.yTransform) {
      if (!(dataYMin > 0.0)) {
        throw StateError('Using logarithmic Y scale requires only positive Y data');
      }
    }
  }
}

