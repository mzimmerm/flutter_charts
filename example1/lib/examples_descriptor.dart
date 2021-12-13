/// todo-00-document
/// 
import 'ExamplesChartTypeEnum.dart' show ExamplesChartTypeEnum;
import 'ExamplesEnum.dart' show ExamplesEnum;
// Removing import for whole flutter_charts. 
//    import 'package:flutter_charts/flutter_charts.dart' show enumName;
// Reason: As part of a shell script, this needs to run as
//    dart run example1/lib/examples_descriptor.dart
// But, because importing flutter_charts.dart does
//    import 'dart:ui'
// then during 'dart run' we get messages such as :
//    Error: Not found: 'dart:ui'
// Import specifically only the source file where enumName is defined
import '../../lib/src/util/util_dart.dart' show enumName;

import 'package:tuple/tuple.dart' show Tuple2;

// todo-00-now: pull ExamplesChartTypeEnum and ExamplesEnum in this package.

/// Represents examples and tests to be run.
/// 
/// Each enumerate in the [_allowed] list represents one set of chart data, options and type
///   for the flutter_charts example app in [example1/lib/main.dart].
///   
/// The conversion from enumerates to data and options is in [example1/lib/main.dart] [chartTypeToShow()].
/// The conversion from enumerates to chart type is in [example1/lib/main.dart] [requestedExampleToRun()].
class ExamplesDescriptor {
  final List<Tuple2<ExamplesEnum, ExamplesChartTypeEnum>> _allowed = [
    const Tuple2(ExamplesEnum.ex10RandomData, ExamplesChartTypeEnum.lineChart),
    const Tuple2(ExamplesEnum.ex10RandomData, ExamplesChartTypeEnum.verticalBarChart),

    const Tuple2(ExamplesEnum.ex30AnimalsBySeasonWithLabelLayoutStrategy, ExamplesChartTypeEnum.lineChart),
    const Tuple2(ExamplesEnum.ex30AnimalsBySeasonWithLabelLayoutStrategy, ExamplesChartTypeEnum.verticalBarChart),

    const Tuple2(ExamplesEnum.ex20RandomDataWithLabelLayoutStrategy, ExamplesChartTypeEnum.lineChart),
    const Tuple2(ExamplesEnum.ex20RandomDataWithLabelLayoutStrategy, ExamplesChartTypeEnum.verticalBarChart),

    const Tuple2(ExamplesEnum.ex40LanguagesWithYOrdinalUserLabelsAndUserColors, ExamplesChartTypeEnum.lineChart),
    //  const Tuple2(ExamplesEnum.ex_4_0_LanguagesYOrdinarLevelFromData_UserYOrdinarLevelLabels_UserColors, ExamplesChartTypeEnum.VerticalBarChart),

    // const  Tuple2(ExamplesEnum.ex_5_0_StocksRankedOnYWithNegatives_DataYLabels_UserColors, ExamplesChartTypeEnum.LineChart),
    const Tuple2(ExamplesEnum.ex50StocksWithNegativesWithUserColors, ExamplesChartTypeEnum.verticalBarChart),
  ];

  /// Check if the example described by the passed enums should run in a test.
  ///
  /// Generally examples should run as either [ExamplesChartTypeEnum.lineChart]
  ///   or [ExamplesChartTypeEnum.verticalBarChart] except a few where only
  ///   one chart type makes sense to be presented.
  bool exampleComboIsAllowed(Tuple2<ExamplesEnum, ExamplesChartTypeEnum> exampleComboToRun) {
    return _allowed.any((tuple) => tuple.item1 == exampleComboToRun.item1 && tuple.item2 == exampleComboToRun.item2);
  }

  /// Present this descriptor is a format suitable to run as a test from command line.
  void asCommandLine() {
    for (Tuple2 tuple in _allowed) {
      print('set -e');
      print('echo');
      print('echo');
      print('echo Running \$1 for EXAMPLE_TO_RUN=${enumName(tuple.item1)}, CHART_TYPE_TO_SHOW=${enumName(tuple.item2)}.');
      print(
          // generates cli representation of arguments 
          '\$1 ' // 'flutter run --device-id=\$1 '
          '--dart-define=EXAMPLE_TO_RUN=${enumName(tuple.item1)} '
          '--dart-define=CHART_TYPE_TO_SHOW=${enumName(tuple.item2)} '
          '\$2' // ' example1/lib/main.dart'
          );
    }
  }
}

bool isExampleWithRandomData(Tuple2<ExamplesEnum, ExamplesChartTypeEnum> exampleComboToRun) {
  
  if (enumName(exampleComboToRun.item1).contains('RandomData')) {
    return true;
  }
  return false;
  
}

/// Present this descriptor as a command line.
void main() {
  ExamplesDescriptor().asCommandLine();
}
