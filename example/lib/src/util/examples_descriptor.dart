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
import '../../../../lib/src/util/extensions_dart.dart' show StringExtension, multiplyListElementsBy;
import 'package:flutter_charts/src/morphic/container/chart_support/chart_style.dart'
    show ChartOrientation, ChartType, ChartStacking;

import 'package:tuple/tuple.dart' show Tuple2, Tuple5;

/// Present the [ExamplesDescriptor] as a command line for consumption by shell scripts
/// that require passing the examples to run or test using the environment variables `--dart-define`.
void main(List<String> args) {
  var exampleDescriptor = ExamplesDescriptor.allExamples();
  if (args.isNotEmpty && args[0].trim().isNotEmpty) {
    // If first command line argument is provided, all 4 must be provided, although some may be empty!
    // The empty args will be defaulted in the [asCommandLine] method.
    if (args.length != 5) {
      throw StateError('5 arguments required, but only the following provided: $args');
    }

    // Assumes argument name is one of ExamplesEnum, e.g. ex10RandomData
    ExamplesEnum exampleToRun = args[0].asEnum(ExamplesEnum.values);
    exampleDescriptor = ExamplesDescriptor(
      exampleRequested: exampleToRun,
      chartTypeRequested: args[1].isNotEmpty ? args[1].asEnum(ChartType.values) : null,
      chartOrientation: args[2].isNotEmpty ? args[2].asEnum(ChartOrientation.values) : null,
      chartStacking: args[3].isNotEmpty ? args[3].asEnum(ChartStacking.values) : null,
      isUseOldLayouter: args[4].isNotEmpty ? (args[4] == 'true' ? true : false) : null,

    );
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
  ex75AnimalsBySeasonLegendIsRowStartTightItemIsRowStartTightItemChildrenPadded,
  ex76AnimalsBySeasonLegendIsRowStartTightItemIsRowStartTightItemChildrenAligned,

  // Range 900 - 999 are error testing examples
  ex900ErrorFixUserDataAllZero,
}

/// Defines the list of the examples available to be tested or run interactively in scripts.
///
/// Each example properties are the enums from [ExamplesEnum] (e.g. [ExamplesEnum.ex10RandomData])
/// and types (e.g. [ExamplesChartTypeEnum.lineChart], [ExamplesChartTypeEnum.barChart])
///
/// By scripts, we mean [run_all_tests.sh] and [run_representative_tests.sh] tests,
/// and interactively running in [run_all_examples.sh].
///
/// The [_allowed] member is the list of allowed combinations of [ExamplesEnum] and [ExamplesChartTypeEnum].
/// Each enumerate in the [_allowed] list represents one set of chart data, options and type
///   for the flutter_charts example app in [example/lib/main.dart].
///
/// Method [asCommandLine] generates a shell snippet for all [_allowed] and requested example. The snippet may look like
///    ```shell
///    $1 --dart-define=EXAMPLE_TO_RUN=ex30AnimalsBySeasonWithLabelLayoutStrategy --dart-define=CHART_TYPE=lineChart $2
///    ```
/// and is used in the generated tmp file such as `examples_descriptor_generated_program_354.sh`.
///
/// The conversion from enumerates to data and options is in [example/lib/main.dart], see 'chartType'.
/// The conversion from enumerates to chart type is in [example/lib/main.dart] see 'requestedExampleToRun'.
class ExamplesDescriptor {
  /// If set, only the requested example will run.
  ExamplesEnum? exampleRequested;
  ChartType? chartTypeRequested;
  ChartOrientation? chartOrientation;
  ChartStacking? chartStacking;
  bool? isUseOldLayouter;

  ExamplesDescriptor({
    required this.exampleRequested,
    required this.chartTypeRequested,
    required this.chartOrientation,
    required this.chartStacking,
    required this.isUseOldLayouter,
  });

  ExamplesDescriptor.allExamples();

  final List<Tuple2<ExamplesEnum, ChartType>> _allowed = [
    //
    const Tuple2(ExamplesEnum.ex10RandomData, ChartType.lineChart),
    const Tuple2(ExamplesEnum.ex10RandomData, ChartType.barChart),
    //
    const Tuple2(ExamplesEnum.ex30AnimalsBySeasonWithLabelLayoutStrategy, ChartType.lineChart),
    const Tuple2(ExamplesEnum.ex30AnimalsBySeasonWithLabelLayoutStrategy, ChartType.barChart),
    //
    const Tuple2(ExamplesEnum.ex31SomeNegativeValues, ChartType.lineChart),
    const Tuple2(ExamplesEnum.ex31SomeNegativeValues, ChartType.barChart),
    //
    const Tuple2(ExamplesEnum.ex32AllPositiveYsYAxisStartsAbove0, ChartType.lineChart),
    const Tuple2(ExamplesEnum.ex32AllPositiveYsYAxisStartsAbove0, ChartType.barChart),
    //
    const Tuple2(ExamplesEnum.ex33AllNegativeYsYAxisEndsBelow0, ChartType.lineChart),
    //
    const Tuple2(ExamplesEnum.ex34OptionsDefiningUserTextStyleOnLabels, ChartType.lineChart),
    //
    const Tuple2(ExamplesEnum.ex35AnimalsBySeasonNoLabelsShown, ChartType.lineChart),
    const Tuple2(ExamplesEnum.ex35AnimalsBySeasonNoLabelsShown, ChartType.barChart),
    //
    const Tuple2(ExamplesEnum.ex40LanguagesWithYOrdinalUserLabelsAndUserColors, ChartType.lineChart),
    //
    const Tuple2(ExamplesEnum.ex50StocksWithNegativesWithUserColors, ChartType.barChart),
    //
    const Tuple2(ExamplesEnum.ex52AnimalsBySeasonLogarithmicScale, ChartType.lineChart),
    const Tuple2(ExamplesEnum.ex52AnimalsBySeasonLogarithmicScale, ChartType.barChart),
    //
    const Tuple2(ExamplesEnum.ex60LabelsIteration1, ChartType.barChart),
    //
    const Tuple2(ExamplesEnum.ex60LabelsIteration2, ChartType.barChart),
    //
    const Tuple2(ExamplesEnum.ex60LabelsIteration3, ChartType.barChart),
    //
    const Tuple2(ExamplesEnum.ex60LabelsIteration4, ChartType.barChart),
    //
    const Tuple2(ExamplesEnum.ex70AnimalsBySeasonLegendIsColumnStartLooseItemIsRowStartLoose,
        ChartType.barChart),
    //
    const Tuple2(ExamplesEnum.ex71AnimalsBySeasonLegendIsColumnStartTightItemIsRowStartTight,
        ChartType.barChart),
    //
    const Tuple2(ExamplesEnum.ex72AnimalsBySeasonLegendIsRowCenterLooseItemIsRowEndLoose,
        ChartType.barChart),
    //
    const Tuple2(ExamplesEnum.ex73AnimalsBySeasonLegendIsRowStartTightItemIsRowStartTight,
        ChartType.barChart),
    //
    const Tuple2(ExamplesEnum.ex74AnimalsBySeasonLegendIsRowStartTightItemIsRowStartTightSecondGreedy,
        ChartType.barChart),
    //
    const Tuple2(ExamplesEnum.ex75AnimalsBySeasonLegendIsRowStartTightItemIsRowStartTightItemChildrenPadded,
        ChartType.barChart),
    const Tuple2(ExamplesEnum.ex75AnimalsBySeasonLegendIsRowStartTightItemIsRowStartTightItemChildrenPadded,
        ChartType.lineChart),
    //
    const Tuple2(ExamplesEnum.ex76AnimalsBySeasonLegendIsRowStartTightItemIsRowStartTightItemChildrenAligned,
        ChartType.barChart),

    //
    const Tuple2(ExamplesEnum.ex900ErrorFixUserDataAllZero, ChartType.lineChart),
  ];

  /// Check if the example described with the passed enums should run in a test.
  ///
  /// Generally examples should run as either [ExamplesChartTypeEnum.lineChart]
  ///   or [ExamplesChartTypeEnum.barChart] except a few where only
  ///   one chart type makes sense to be presented.
  bool exampleComboIsAllowed(
    Tuple5<ExamplesEnum, ChartType, ChartOrientation, ChartStacking, bool> exampleComboToRun,
  ) {
    return _allowed.any((tuple) => tuple.item1 == exampleComboToRun.item1 && tuple.item2 == exampleComboToRun.item2);
  }

  /// Present this descriptor is a format suitable to run as a test from command line.
  void asCommandLine() {
    List<Tuple2<ExamplesEnum, ChartType>> combosToRun = exampleRequested == null
        ? _allowed
        : _allowed.where((tuple) => tuple.item1 == exampleRequested).toList();

    combosToRun = chartTypeRequested == null
        ? combosToRun
        : combosToRun.where((tuple) => tuple.item2 == chartTypeRequested).toList();

    if (combosToRun.isEmpty) {
      throw StateError('No examples requested to run are defined in examples_descriptor.');
    }

    isUseOldLayouter ??= true;

    List orientationsToRun;
    if (chartOrientation == null) {
      if (isUseOldLayouter!) {
        orientationsToRun = [ChartOrientation.column];
      } else {
        orientationsToRun = [ChartOrientation.column, ChartOrientation.row];
      }
    } else {
      orientationsToRun = [chartOrientation];
    }

    List stackingToRun;
    if (chartStacking == null) {
      if (isUseOldLayouter!) {
        stackingToRun = [ChartStacking.stacked];
      } else {
        stackingToRun = [ChartStacking.stacked, ChartStacking.nonStacked];
      }
    } else {
      stackingToRun = [chartStacking];
    }

    List<List> orientationsAndStackingToRun = multiplyListElementsBy(orientationsToRun, stackingToRun);

    List<Tuple5<ExamplesEnum, ChartType, ChartOrientation, ChartStacking, bool>>
    combos5ToRun = multiplyListElementsBy(combosToRun, orientationsAndStackingToRun).map((tuple2AndOrientationWithStacking) =>
        Tuple5(
          tuple2AndOrientationWithStacking[0].item1 as ExamplesEnum,
          tuple2AndOrientationWithStacking[0].item2 as ChartType,
          tuple2AndOrientationWithStacking[1][0] as ChartOrientation,
          tuple2AndOrientationWithStacking[1][1] as ChartStacking,
          isUseOldLayouter!,
        )).toList();

    for (Tuple5 tuple in combos5ToRun) {
      print('set -o errexit');
      print('echo');
      print('echo');
      print(
          'echo Running \$1 for EXAMPLE_TO_RUN=${enumName(tuple.item1)}, CHART_TYPE=${enumName(tuple.item2)}.');
      print(
          // generates cli representation of arguments
          '\$1 ' // 'flutter run --device-id=\$1 '
          '--dart-define=EXAMPLE_TO_RUN=${enumName(tuple.item1)} '
          '--dart-define=CHART_TYPE=${enumName(tuple.item2)} '
          '--dart-define=CHART_ORIENTATION=${enumName(tuple.item3)} '
          '--dart-define=CHART_STACKING=${enumName(tuple.item4)} '
          '--dart-define=IS_USE_OLD_LAYOUTER=$isUseOldLayouter '
          '\$2' // ' example/lib/main.dart'
          );
    }
  }
}

bool isExampleWithRandomData(
  Tuple5<ExamplesEnum, ChartType, ChartOrientation, ChartStacking, bool> exampleComboToRun,
) {
  if (enumName(exampleComboToRun.item1).contains('RandomData')) {
    return true;
  }
  return false;
}
