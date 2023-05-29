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
//    dart run lib/src/chart/util/examples_descriptor.dart
// But, because importing flutter_charts.dart does
//    import 'dart:ui'
// then during 'dart run' we get messages such as :
//    Error: Not found: 'dart:ui'
// Import specifically only the source file where enumName is defined, and no 'dart:ui' is referenced

import '../../util/util_dart.dart' show enumName;
import '../../util/extensions_dart.dart' show StringExtension, multiplyListElementsBy;
import 'package:flutter_charts/src/morphic/container/chart_support/chart_style.dart'
    show ChartLayouter, ChartOrientation, ChartStacking, ChartType;

import 'package:tuple/tuple.dart' show Tuple2;

/// Present the [ExampleDescriptor] as a command line for consumption by shell scripts
/// that require passing the examples to run or test using the environment variables `--dart-define`.
void main(List<String> args) {
  ExampleDescriptor exampleDescriptor = ExampleDescriptor.pluginForOldLayouterProcessing();

  bool isAllExamplesRequested = false;

  if (args.isNotEmpty && args[0].trim().isNotEmpty) {
    // If first command line argument is provided, all 5 must be provided, although some may be empty!
    // The empty args will be defaulted in the [asCommandLine] method.
    if (args.length != 5) {
      throw StateError('5 arguments required, but only the following provided: $args');
    }

    // Assumes argument name is one of ExamplesEnum, e.g. ex10RandomData
    ExamplesEnum exampleToRun = args[0].asEnum(ExamplesEnum.values);
    exampleDescriptor = ExampleDescriptor(
      exampleEnum: exampleToRun,
      chartType: args[1].isNotEmpty ? args[1].asEnum(ChartType.values) : ChartType.barChart,
      chartOrientation: args[2].isNotEmpty ? args[2].asEnum(ChartOrientation.values) : ChartOrientation.column,
      chartStacking: args[3].isNotEmpty ? args[3].asEnum(ChartStacking.values) : ChartStacking.stacked,
      chartLayouter: args[4].isNotEmpty
          ? (args[4] == 'oldManualLayouter' ? ChartLayouter.oldManualLayouter : ChartLayouter.newAutoLayouter)
          : ChartLayouter.oldManualLayouter,
    );
  } else {
    // No args given, run all examples requested == run all examples in allowed
    isAllExamplesRequested = true;
  }
  // Support old method to run both lineChart and barChart if args[1] is empty
  // This is how we support old method of defining list of examples to run, yet enable [ExampleDescriptor]
  //   members to be not nullable
  bool isRunBothChartTypes = args[1].isEmpty;
  exampleDescriptor.asCommandLine(isAllExamplesRequested, isRunBothChartTypes);
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
/// The [allowed] member is the list of allowed combinations of [ExamplesEnum] and [ExamplesChartTypeEnum].
/// Each enumerate in the [allowed] list represents one set of chart data, options and type
///   for the flutter_charts example app in [example/lib/main.dart].
///
/// Method [asCommandLine] generates a shell snippet for all [allowed] and requested example. The snippet may look like
///    ```shell
///    $1 --dart-define=EXAMPLE_TO_RUN=ex30AnimalsBySeasonWithLabelLayoutStrategy --dart-define=CHART_TYPE=lineChart $2
///    ```
/// and is used in the generated tmp file such as `examples_descriptor_generated_program_354.sh`.
///
/// The conversion from enumerates to data and options is in [example/lib/main.dart], see 'chartType'.
/// The conversion from enumerates to chart type is in [example/lib/main.dart] see 'requestedExampleToRun'.
class ExampleDescriptor {
  /// If set, only the requested example will run.
  ExamplesEnum exampleEnum;
  ChartType chartType;
  ChartOrientation chartOrientation;
  ChartStacking chartStacking;
  ChartLayouter chartLayouter;


  ExampleDescriptor({
    required this.exampleEnum,
    required this.chartType,
    required this.chartOrientation,
    required this.chartStacking,
    required this.chartLayouter,
  });

  /// Factory creates a helper instance needed when insufficient data exist to create an instance.
  ///
  /// This is for old examples processing only, when we want to express that all allowed examples should run.
  factory ExampleDescriptor.pluginForOldLayouterProcessing() {
    return ExampleDescriptor(
      exampleEnum: ExamplesEnum.ex10RandomData, // unused
      chartType: ChartType.barChart, // unused
      chartOrientation: ChartOrientation.column, // unused
      chartStacking: ChartStacking.stacked, // unused
      chartLayouter: ChartLayouter.oldManualLayouter,
    );
  }

  static final List<Tuple2<ExamplesEnum, ChartType>> allowed = [
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
  static bool exampleComboIsAllowed(
      ExampleDescriptor exampleDescriptor,
  ) {
    return allowed.any((tuple) => tuple.item1 == exampleDescriptor.exampleEnum && tuple.item2 == exampleDescriptor.chartType);
  }

//// Returns the enum of the chart example to run *in widget tests, integration tests, or example/lib/main.dart*.
  ///
  /// The enums are pulled from environment variables named ['EXAMPLE_TO_RUN'] and ['CHART_TYPE']
  ///   passed to the main program by `--dart-define` options.
  ///
  /// Converts the dart-define(d) environment variables passed to 'flutter run', 'flutter test', or 'flutter driver',
  ///   by `--dart-define` for variables named 'EXAMPLE_TO_RUN', 'CHART_TYPE', 'CHART_STACKING', 'CHART_ORIENTATION'
  ///   and 'CHART_LAYOUTER' into enums which describe the example to run, and the chart type to show.
  ///
  static ExampleDescriptor requestedExampleToRun() {
    // Pickup what example to run, and which chart to show (line, vertical bar).
    const String exampleToRunStr = String.fromEnvironment('EXAMPLE_TO_RUN', defaultValue: 'ex10RandomData');
    ExamplesEnum examplesEnumToRun = exampleToRunStr.asEnum(ExamplesEnum.values);

    const String chartTypeStr = String.fromEnvironment('CHART_TYPE', defaultValue: 'lineChart');
    ChartType chartType = chartTypeStr.asEnum(ChartType.values);

    const String chartOrientationStr = String.fromEnvironment('CHART_ORIENTATION', defaultValue: 'column');
    ChartOrientation chartOrientation = ChartOrientation.fromStringDefaultOnEmpty(
      chartOrientationStr,
      ChartOrientation.column,
    );

    const String chartStackingStr = String.fromEnvironment('CHART_STACKING', defaultValue: 'stacked');
    ChartStacking chartStacking = chartStackingStr.asEnum(ChartStacking.values);

    String chartLayouterStr = const String.fromEnvironment('CHART_LAYOUTER', defaultValue: 'oldManualLayouter')
        .replaceFirst('ChartLayouter.', '');
    ChartLayouter chartLayouter = chartLayouterStr.asEnum(ChartLayouter.values);

    return ExampleDescriptor(
      exampleEnum: examplesEnumToRun,
      chartType: chartType,
      chartOrientation: chartOrientation,
      chartStacking: chartStacking,
      chartLayouter: chartLayouter,
    );
  }

  static bool isExampleWithRandomData(
      ExampleDescriptor exampleDescriptor,
      ) {
    if (enumName(exampleDescriptor.exampleEnum).contains('RandomData')) {
      return true;
    }
    return false;
  }

  /// Present this descriptor is a format suitable to run as a test from command line.
  void asCommandLine(bool isAllExamplesRequested, bool isRunBothChartTypes) {
    List<Tuple2<ExamplesEnum, ChartType>> combosToRun = isAllExamplesRequested
        ? allowed
        : allowed.where((tuple) => tuple.item1 == exampleEnum).toList();

    // [combosToRun] has 1 or 2 chartTypes, depending what is specified in allowed.
    // if [isRunBothChartTypes] is true, we OVERRIDE that, and run both charts.
    // This is how we support old method of defining list of examples to run, yet enable [ExampleDescriptor]
    //   members to be not nullable
    combosToRun = isRunBothChartTypes
        ? combosToRun
        : combosToRun.where((tuple) => tuple.item2 == chartType).toList();

    if (combosToRun.isEmpty) {
      throw StateError('No examples requested to run are defined in examples_descriptor.');
    }

    List orientationsToRun;
    List stackingToRun;
    if (chartLayouter == ChartLayouter.oldManualLayouter) {
      orientationsToRun = [ChartOrientation.column];
      stackingToRun = [ChartStacking.stacked];
    } else {
      orientationsToRun = [chartOrientation];
      stackingToRun = [chartStacking];
    }

    List<List> orientationsAndStackingToRun = multiplyListElementsBy(orientationsToRun, stackingToRun);

    List<ExampleDescriptor> examplesToRun =
      multiplyListElementsBy(combosToRun, orientationsAndStackingToRun).map((tuple2AndOrientationWithStacking) =>
        ExampleDescriptor(
          exampleEnum:      tuple2AndOrientationWithStacking[0].item1 as ExamplesEnum,
          chartType:        tuple2AndOrientationWithStacking[0].item2 as ChartType,
          chartOrientation: tuple2AndOrientationWithStacking[1][0] as ChartOrientation,
          chartStacking:    tuple2AndOrientationWithStacking[1][1] as ChartStacking,
          chartLayouter:    chartLayouter,
        )).toList();

    for (ExampleDescriptor exampleDescriptor in examplesToRun) {
      print('set -o errexit');
      print('echo');
      print('echo');
      print(
          'echo Running \$1 for EXAMPLE_TO_RUN=${enumName(exampleDescriptor.exampleEnum)}, CHART_TYPE=${enumName(exampleDescriptor.chartType)}.');
      print(
        // generates cli representation of arguments
          '\$1 ' // 'flutter run --device-id=\$1 '
              '--dart-define=EXAMPLE_TO_RUN=${enumName(exampleDescriptor.exampleEnum)} '
              '--dart-define=CHART_TYPE=${enumName(exampleDescriptor.chartType)} '
              '--dart-define=CHART_ORIENTATION=${enumName(exampleDescriptor.chartOrientation)} '
              '--dart-define=CHART_STACKING=${enumName(exampleDescriptor.chartStacking)} '
              '--dart-define=CHART_LAYOUTER=${enumName(chartLayouter)} '
              '\$2' // ' example/lib/main.dart'
      );
    }
  }
}


