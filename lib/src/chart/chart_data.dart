import 'dart:math' as math;

class ChartData {

  /// Data in rows.
  ///
  /// Each element of outer list represents one row.
  /// Alternative name would be "data series".
  List<List<double>> dataRows = new List();

  /// Provides legends for rows.
  ///
  /// One Legend String per row.
  /// Alternative name would be "series names".
  List<String> rowLegends = new List();

  /// Labels on independent (X) axis.
  ///
  /// It is generally assumed labels are defined,
  /// and their number is the same as number of points
  /// in each row in [dataRows].
  List<String> xLabels = new List();

  /// Labels on dependent (Y) axis. They must be numbers.
  ///
  /// If you need number labels with units (e.g. %), define % in options
  /// If you need purely String labels, this is a todo 1.
  ///
  /// This is used only if [ChartOptions.doManualLayoutUsingYLabels] is true.
  ///
  /// They may be undefined, in which case the
  /// Y axis is likely not shown.
  List<String> yLabels = new List();

  void validate() {
    if (rowLegends.length > 0 && dataRows.length != rowLegends.length) {
      throw new StateError(" If row legends are defined, their "
          "number must be the same as number of data rows. "
          " [dataRows length: ${dataRows.length}] "
          "!= [rowLegends length: ${rowLegends.length}]. ");
    }
    for (List<double> dataRow in dataRows) {
      if (xLabels.length > 0 && dataRow.length != xLabels.length) {
        throw new StateError(" If xLabels are defined, their "
            "length must be the same as length of each dataRow"
            " [dataRow length: ${dataRow.length}] "
            "!= [xLabels length: ${xLabels.length}]. ");
      }
    }
  }

  List<double> _flattenData() {
    return this.dataRows.expand((i) => i).toList();
  }

  double maxData() {
     return _flattenData().reduce(math.max);
  }

  double minData() {
     return _flattenData().reduce(math.min);
  }

}