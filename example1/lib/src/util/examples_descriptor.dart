/// Library for a tool that helps generate programs that run chart examples and tests.
///
/// Library with has a main.dart which generates a shell script that allow
/// to run commands such as `flutter run` or `flutter drive`
/// on all examples defined in [ExamplesEnum].
///
///
///
// Removing import for whole flutter_charts.
//    import 'package:flutter_charts/flutter_charts.dart' show enumName;
// Reason: As part of a shell script, this needs to run as
//    dart run example1/lib/src/util/examples_descriptor.dart
// But, because importing flutter_charts.dart does
//    import 'dart:ui'
// then during 'dart run' we get messages such as :
//    Error: Not found: 'dart:ui'
// Import specifically only the source file where enumName is defined, and no 'dart:ui' is referenced
import '../../../../lib/src/util/util_dart.dart' show enumName;
import '../../../../lib/src/util/string_extension.dart';

import 'package:tuple/tuple.dart' show Tuple2;

/// Present the [ExamplesDescriptor] as a command line for consumption by shell scripts
/// that require passing the examples to run or test using the environment variables `--dart-define`.
void main(List<String> args) {
  var exampleDescriptor = ExamplesDescriptor();
  if (args.isNotEmpty && args[0].trim().isNotEmpty) {
    // Assumes argument name is one of ExamplesEnum, e.g. ex10RandomData
    ExamplesEnum exampleToRun = args[0].asEnum(ExamplesEnum.values);
    exampleDescriptor = ExamplesDescriptor(exampleRequested: exampleToRun);
  }
  exampleDescriptor.asCommandLine();
}

/// Describes the full set of charts shown in examples or integration tests.
enum ExamplesEnum {
  ex10RandomData,
  ex11RandomDataWithLabelLayoutStrategy,
  ex30AnimalsBySeasonWithLabelLayoutStrategy,
  ex31SomeNegativeValues,
  ex32AllPositiveYsYAxisStartsAbove0,
  ex33AllNegativeYsYAxisEndsBelow0,
  ex35AnimalsBySeasonNoLabelsShown,
  ex40LanguagesWithYOrdinalUserLabelsAndUserColors,
  ex50StocksWithNegativesWithUserColors,
  ex51AnimalsBySeasonManualLogarithmicScale,
  ex52AnimalsBySeasonLogarithmicScale,
  // Range 900 - 999 are error testing examples
  ex900ErrorFixUserDataAllZero,
}

/// Describes chart types shown in examples or integration tests..
enum ExamplesChartTypeEnum {
  lineChart,
  verticalBarChart,
}

/// Represents examples and tests to be run.
///
/// Each enumerate in the [_allowed] list represents one set of chart data, options and type
///   for the flutter_charts example app in [example1/lib/main.dart].
///
/// The conversion from enumerates to data and options is in [example1/lib/main.dart] [chartTypeToShow()].
/// The conversion from enumerates to chart type is in [example1/lib/main.dart] [requestedExampleToRun()].
class ExamplesDescriptor {
  /// If set, only the requested example will run.
  ExamplesEnum? exampleRequested;

  ExamplesDescriptor({this.exampleRequested});

  final List<Tuple2<ExamplesEnum, ExamplesChartTypeEnum>> _allowed = [
    // 
    const Tuple2(ExamplesEnum.ex10RandomData, ExamplesChartTypeEnum.lineChart),
    const Tuple2(ExamplesEnum.ex10RandomData, ExamplesChartTypeEnum.verticalBarChart),
    //
    const Tuple2(ExamplesEnum.ex11RandomDataWithLabelLayoutStrategy, ExamplesChartTypeEnum.lineChart),
    const Tuple2(ExamplesEnum.ex11RandomDataWithLabelLayoutStrategy, ExamplesChartTypeEnum.verticalBarChart),
    //
    const Tuple2(ExamplesEnum.ex30AnimalsBySeasonWithLabelLayoutStrategy, ExamplesChartTypeEnum.lineChart),
    const Tuple2(ExamplesEnum.ex30AnimalsBySeasonWithLabelLayoutStrategy, ExamplesChartTypeEnum.verticalBarChart),
    //
    const Tuple2(ExamplesEnum.ex31SomeNegativeValues, ExamplesChartTypeEnum.lineChart),
    const Tuple2(ExamplesEnum.ex31SomeNegativeValues, ExamplesChartTypeEnum.verticalBarChart),
    //
    const Tuple2(ExamplesEnum.ex32AllPositiveYsYAxisStartsAbove0, ExamplesChartTypeEnum.lineChart),
    const Tuple2(ExamplesEnum.ex32AllPositiveYsYAxisStartsAbove0, ExamplesChartTypeEnum.verticalBarChart),
    //
    const Tuple2(ExamplesEnum.ex33AllNegativeYsYAxisEndsBelow0, ExamplesChartTypeEnum.lineChart),
    //
    const Tuple2(ExamplesEnum.ex35AnimalsBySeasonNoLabelsShown, ExamplesChartTypeEnum.lineChart),
    const Tuple2(ExamplesEnum.ex35AnimalsBySeasonNoLabelsShown, ExamplesChartTypeEnum.verticalBarChart),
    // 
    const Tuple2(ExamplesEnum.ex40LanguagesWithYOrdinalUserLabelsAndUserColors, ExamplesChartTypeEnum.lineChart),
    // 
    const Tuple2(ExamplesEnum.ex50StocksWithNegativesWithUserColors, ExamplesChartTypeEnum.verticalBarChart),
    //
    const Tuple2(ExamplesEnum.ex51AnimalsBySeasonManualLogarithmicScale, ExamplesChartTypeEnum.lineChart),
    //
/* todo-00-last put back
    const Tuple2(ExamplesEnum.ex52AnimalsBySeasonLogarithmicScale, ExamplesChartTypeEnum.lineChart),
    const Tuple2(ExamplesEnum.ex52AnimalsBySeasonLogarithmicScale, ExamplesChartTypeEnum.verticalBarChart),
*/
    //
    const Tuple2(ExamplesEnum.ex900ErrorFixUserDataAllZero, ExamplesChartTypeEnum.lineChart),
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
    List<Tuple2<ExamplesEnum, ExamplesChartTypeEnum>> combosToRun =
        exampleRequested == null ? _allowed : _allowed.where((tuple) => tuple.item1 == exampleRequested).toList();

    if (combosToRun.isEmpty) {
      throw StateError('No examples requested to run are defined in examples_descriptor.');
    }

    for (Tuple2 tuple in combosToRun) {
      print('set -e');
      print('echo');
      print('echo');
      print(
          'echo Running \$1 for EXAMPLE_TO_RUN=${enumName(tuple.item1)}, CHART_TYPE_TO_SHOW=${enumName(tuple.item2)}.');
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
