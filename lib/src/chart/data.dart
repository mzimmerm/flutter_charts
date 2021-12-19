import 'dart:math' as math;
import 'dart:ui' as ui show Color;
import 'package:flutter/material.dart' as material show Colors;

// todo-00-last-last : Make final and rethink completely. 
//                     Should be able to set defauls for everything, unless set on construction time.

class ChartData {
  
  /// Default constructor only assumes [dataRows] are set,
  /// and assigns default values of [dataRowsLegends], [dataRowsColors], [xLabels], [yLabels].
  /// 
  // todo-00-last-last : make final and always define with DataRows.
  ChartData() {
    assignDataRowsDefaultLegends();
    assignDataRowsDefaultColors();
    // todo-00-last-last : deal with xLabels
    // todo-00-last-last : deal with yLabels
  }
  
  /// Data in rows. Each row of data represents one data series.
  ///
  /// Legends per row are managed by [dataRowsLegends].
  ///
  /// Each element of outer list represents one row.
  /// Alternative name would be "data series".
  List<List<double>> dataRows = List.empty(growable: true);

  /// Provides legends for [dataRows] (data series).
  ///
  /// One Legend String per row.
  /// Alternative name would be "series names".
  List<String> dataRowsLegends = List.empty(growable: true);

  /// Colors corresponding to each data row (series) in [ChartData].
  List<ui.Color> dataRowsColors = List.empty(growable: true);

  /// Labels on independent (X) axis.
  ///
  /// It is assumed labels are defined, by the client
  /// and their number is the same as number of points
  /// in each row in [dataRows].
  List<String> xLabels = List.empty(growable: true);

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
  List<String> yLabels = List.empty(growable: true);

  // todo-00-last-last : improve to check everything, then call on as many places as possible
  
  void validate() {
    if (dataRowsLegends.isNotEmpty &&
        dataRows.length != dataRowsLegends.length) {
      throw StateError(' If row legends are defined, their '
          'number must be the same as number of data rows. '
          ' [dataRows length: ${dataRows.length}] '
          '!= [dataRowsLegends length: ${dataRowsLegends.length}]. ');
    }
    for (List<double> dataRow in dataRows) {
      if (xLabels.isNotEmpty && dataRow.length != xLabels.length) {
        throw StateError(' If xLabels are defined, their '
            'length must be the same as length of each dataRow'
            ' [dataRow length: ${dataRow.length}] '
            '!= [xLabels length: ${xLabels.length}]. ');
      }
    }
  }

  List<double> _flattenData() {
    return dataRows.expand((i) => i).toList();
  }

  double maxData() {
    return _flattenData().reduce(math.max);
  }

  double minData() {
    return _flattenData().reduce(math.min);
  }

  /// Sets up legends names, first several explicitly, rest randomly.
  /// 
  /// This is used if user does not set legends.
  /// This should be kept in sync with colors below.
  void assignDataRowsDefaultLegends() {
    int dataRowsCount = dataRows.length;

    if (dataRowsCount >= 1) {
      dataRowsLegends.add('YELLOW');
    }
    if (dataRowsCount >= 2) {
      dataRowsLegends.add('GREEN');
    }
    if (dataRowsCount >= 3) {
      dataRowsLegends.add('BLUE');
    }
    if (dataRowsCount >= 4) {
      dataRowsLegends.add('BLACK');
    }
    if (dataRowsCount >= 5) {
      dataRowsLegends.add('GREY');
    }
    if (dataRowsCount >= 6) {
      dataRowsLegends.add('ORANGE');
    }
    if (dataRowsCount > 6) {
      for (int i = 3; i < dataRowsCount; i++) {
        // todo-1 when large value is generated, it paints outside canvas, fix.
        int number = math.Random().nextInt(10000);
        dataRowsLegends.add('OTHER ' + number.toString());
      }
    }
  }

  /// Sets up colors for legends, first several explicitly, rest randomly.
  /// 
  /// This is used if user does not set colors.
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
    if (dataRowsCount >= 4) {
      dataRowsColors.add(material.Colors.black);
    }
    if (dataRowsCount >= 5) {
      dataRowsColors.add(material.Colors.grey);
    }
    if (dataRowsCount >= 6) {
      dataRowsColors.add(material.Colors.orange);
    }
    if (dataRowsCount > 6) {
      for (int i = 3; i < dataRowsCount; i++) {
        int colorHex = math.Random().nextInt(0xFFFFFF);
        int opacityHex = 0xFF;
        // todo-11-last : cast toInt added - does this change results?
        dataRowsColors.add(
            ui.Color(colorHex + (opacityHex * math.pow(16, 6)).toInt()));
      }
    }
  }
}
