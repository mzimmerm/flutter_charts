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
//    dart run example/lib/src/util/examples_descriptor.dart
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
  ex30AnimalsBySeasonWithLabelLayoutStrategy,
  ex31SomeNegativeValues,
  ex32AllPositiveYsYAxisStartsAbove0,
  ex33AllNegativeYsYAxisEndsBelow0,
  ex34OptionsDefiningUserTextStyleOnLabels,
  ex35AnimalsBySeasonNoLabelsShown,
  ex40LanguagesWithYOrdinalUserLabelsAndUserColors,
  ex50StocksWithNegativesWithUserColors,
  ex52AnimalsBySeasonLogarithmicScale,
  ex60LabelsIteration1,
  ex60LabelsIteration2,
  ex60LabelsIteration3,
  ex60LabelsIteration4,
  ex70AnimalsBySeasonLegendIsColumnStartLooseItemIsRowStartLoose,
  ex71AnimalsBySeasonLegendIsColumnStartTightItemIsRowStartTight,
  ex72AnimalsBySeasonLegendIsRowCenterLooseItemIsRowEndLoose,
  ex73AnimalsBySeasonLegendIsRowStartTightItemIsRowStartTight,
  ex74AnimalsBySeasonLegendIsRowStartTightItemIsRowStartTightSecondGreedy,

  // Range 900 - 999 are error testing examples
  ex900ErrorFixUserDataAllZero,
}

/// Describes chart types shown in examples or integration tests.
enum ExamplesChartTypeEnum {
  lineChart,
  verticalBarChart,
}

/// Defines the list of the examples available to be tested or run interactively in scripts.
///
/// Each example properties are the enums from [ExamplesEnum] (e.g. [ExamplesEnum.ex10RandomData])
/// and types (e.g. [ExamplesChartTypeEnum.lineChart], [ExamplesChartTypeEnum.verticalBarChart])
///
/// By scripts, we mean [run_all_tests.sh] and [run_representative_tests.sh] tests, and interactively running in [run_all_examples.sh].
///
/// The [_allowed] member is the list of allowed combinations of [ExamplesEnum] and [ExamplesChartTypeEnum].
/// Each enumerate in the [_allowed] list represents one set of chart data, options and type
///   for the flutter_charts example app in [example/lib/main.dart].
///
/// Method [asCommandLine] generates a shell snippet for an [_allowed] and requested example. The snippet may look like
///    ```shell
///    $1 --dart-define=EXAMPLE_TO_RUN=ex30AnimalsBySeasonWithLabelLayoutStrategy --dart-define=CHART_TYPE_TO_SHOW=lineChart $2
///    ```
/// and is used in the generated tmp file such as `examples_descriptor_generated_program_354.sh`.
///
/// The conversion from enumerates to data and options is in [example/lib/main.dart], see 'chartTypeToShow'.
/// The conversion from enumerates to chart type is in [example/lib/main.dart] see 'requestedExampleToRun'.
class ExamplesDescriptor {
  /// If set, only the requested example will run.
  ExamplesEnum? exampleRequested;

  ExamplesDescriptor({this.exampleRequested});

  final List<Tuple2<ExamplesEnum, ExamplesChartTypeEnum>> _allowed = [
    //
    const Tuple2(ExamplesEnum.ex10RandomData, ExamplesChartTypeEnum.lineChart),
    const Tuple2(ExamplesEnum.ex10RandomData, ExamplesChartTypeEnum.verticalBarChart),
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
    const Tuple2(ExamplesEnum.ex34OptionsDefiningUserTextStyleOnLabels, ExamplesChartTypeEnum.lineChart),
    //
    const Tuple2(ExamplesEnum.ex35AnimalsBySeasonNoLabelsShown, ExamplesChartTypeEnum.lineChart),
    const Tuple2(ExamplesEnum.ex35AnimalsBySeasonNoLabelsShown, ExamplesChartTypeEnum.verticalBarChart),
    //
    const Tuple2(ExamplesEnum.ex40LanguagesWithYOrdinalUserLabelsAndUserColors, ExamplesChartTypeEnum.lineChart),
    //
    const Tuple2(ExamplesEnum.ex50StocksWithNegativesWithUserColors, ExamplesChartTypeEnum.verticalBarChart),
    //
    const Tuple2(ExamplesEnum.ex52AnimalsBySeasonLogarithmicScale, ExamplesChartTypeEnum.lineChart),
    const Tuple2(ExamplesEnum.ex52AnimalsBySeasonLogarithmicScale, ExamplesChartTypeEnum.verticalBarChart),
    //
    const Tuple2(ExamplesEnum.ex60LabelsIteration1, ExamplesChartTypeEnum.verticalBarChart),
    //
    const Tuple2(ExamplesEnum.ex60LabelsIteration2, ExamplesChartTypeEnum.verticalBarChart),
    //
    const Tuple2(ExamplesEnum.ex60LabelsIteration3, ExamplesChartTypeEnum.verticalBarChart),
    //
    const Tuple2(ExamplesEnum.ex60LabelsIteration4, ExamplesChartTypeEnum.verticalBarChart),
    //
    const Tuple2(ExamplesEnum.ex70AnimalsBySeasonLegendIsColumnStartLooseItemIsRowStartLoose,
        ExamplesChartTypeEnum.verticalBarChart),
    //
    const Tuple2(ExamplesEnum.ex71AnimalsBySeasonLegendIsColumnStartTightItemIsRowStartTight,
        ExamplesChartTypeEnum.verticalBarChart),
    //
    const Tuple2(ExamplesEnum.ex72AnimalsBySeasonLegendIsRowCenterLooseItemIsRowEndLoose,
        ExamplesChartTypeEnum.verticalBarChart),
    //
    const Tuple2(ExamplesEnum.ex73AnimalsBySeasonLegendIsRowStartTightItemIsRowStartTight,
        ExamplesChartTypeEnum.verticalBarChart),
    //
    const Tuple2(ExamplesEnum.ex74AnimalsBySeasonLegendIsRowStartTightItemIsRowStartTightSecondGreedy,
        ExamplesChartTypeEnum.verticalBarChart),

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
  ///
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
          '\$2' // ' example/lib/main.dart'
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
