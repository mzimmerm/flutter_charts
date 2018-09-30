import 'dart:math' as math;
import 'dart:ui' as ui show Color;
import 'package:flutter/material.dart' as material show Colors;

class ChartData {
  /// Data in rows. Each row of data represents one data series.
  ///
  /// Legends per row are managed by [dataRowsLegends].
  ///
  /// Each element of outer list represents one row.
  /// Alternative name would be "data series".
  List<List<double>> dataRows = new List();

  /// Provides legends for [dataRows] (data series).
  ///
  /// One Legend String per row.
  /// Alternative name would be "series names".
  List<String> dataRowsLegends = new List();

  /// Colors corresponding to each data row (series) in [ChartData].
  List<ui.Color> dataRowsColors = new List<ui.Color>();

  /// Labels on independent (X) axis.
  ///
  /// It is generally assumed labels are defined,
  /// and their number is the same as number of points
  /// in each row in [dataRows].
  List<String> xLabels = new List();

  /// Labels on dependent (Y) axis.
  ///
  /// - If you need Data-Generated Y label numbers with units (e.g. %),
  ///   - Do not set [yLabels]
  ///   - Set [ChartOptions.useUserProvidedYLabels] to false
  ///   - define [ChartOptions.yLabelUnits] in options
  /// - If you need User-Defined "Ordinal" (Strings with order) Y labels,
  ///   - Set [yLabels] to ordinal values
  ///   - Set [ChartOptions.useUserProvidedYLabels] to true.
  ///   - [ChartOptions.yLabelUnits] are ignored
  ///
  /// This [yLabels] member is used only if
  /// [ChartOptions.useUserProvidedYLabels] is true.
  ///
  List<String> yLabels = new List();

  void validate() {
    if (dataRowsLegends.length > 0 &&
        dataRows.length != dataRowsLegends.length) {
      throw new StateError(" If row legends are defined, their "
          "number must be the same as number of data rows. "
          " [dataRows length: ${dataRows.length}] "
          "!= [dataRowsLegends length: ${dataRowsLegends.length}]. ");
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

  /// Sets up colors first threee data rows (series) explicitly, rest randomly
  void assignDataRowsDefaultColors() {
    int dataRowsCount = dataRows.length;

    if (dataRowsCount >= 1) {
      dataRowsColors.add(material.Colors.yellow);
    }
    if (dataRowsCount >= 2) {
      dataRowsColors.add(material.Colors.green);
    }
    if (dataRowsCount >= 3) {
      dataRowsColors.add(material.Colors.blue);
    }
    if (dataRowsCount > 3) {
      for (int i = 3; i < dataRowsCount; i++) {
        int colorHex = new math.Random().nextInt(0xFFFFFF);
        int opacityHex = 0xFF;
        dataRowsColors
            .add(new ui.Color(colorHex + (opacityHex * math.pow(16, 6))));
      }
    }
  }
}
