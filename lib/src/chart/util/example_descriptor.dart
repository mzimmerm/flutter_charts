/// Library for a tool that helps generate programs that run chart examples and tests.
///
/// Library with has a main.dart which generates a shell script that allow
/// to run commands such as `flutter run` or `flutter drive`
/// on all examples defined in [ExampleEnum].
///
///
///
// Removing import for whole flutter_charts.
//    import 'package:flutter_charts/flutter_charts.dart' show enumName;
// Reason: As part of a shell script, this needs to run as
//    dart run lib/src/chart/util/example_descriptor.dart
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

    // Assumes argument name is one of ExampleEnum, e.g. ex10RandomData
    ExampleEnum exampleToRun = args[0].asEnum(ExampleEnum.values);
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
enum ExampleEnum {
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
  ex800EU12CountriesHistoricalPopulation,

  // Range 900 - 999 are error testing examples
  ex900ErrorFixUserDataAllZero,
}

/// Describes and generates properties of one example or a list of pre-configured chart examples.
///
/// The pre-configured chart examples can be used in several places:
///   - Run in the example app in `example/lib/src/main.dart`
///   - Be integration tested for sameness of results (generated screenshots)
///     in `integration_test/screenshot_create_test.dart` and  `test/screenshot_validate_test.dart`.
///
/// The [_allowed] member is the list of allowed combinations of [ExampleEnum] and [ChartType].
///
/// The following static methods support generation of [ExampleDescriptor] lists:
///   - todo-010
///
/// The following static members contain lists of [ExampleDescriptor]s to be tested or run in the example app:
///   - todo-010
///
/// @Deprecated Method [asCommandLine] generates a shell snippet for all [_allowed] and requested example.
/// A snippet may look like
///    ```shell
///      $1 \
///      --dart-define=EXAMPLE_TO_RUN=ex70AnimalsBySeasonLegendIsColumnStartLooseItemIsRowStartLoose \
///      --dart-define=CHART_TYPE=barChart \
///      --dart-define=CHART_ORIENTATION=column \
///      --dart-define=CHART_STACKING=stacked \
///      --dart-define=CHART_LAYOUTER=oldManualLayouter \
///      $2
///    ```
/// and is typically stored in a tmp file such as `test/tmp/example_descriptor_generated_program_354.sh`.
///
/// @Deprecated [requestedExampleToRun] reads `--dart-define` environment variables and generates an
///   [ExampleDescriptor] instance
///
class ExampleDescriptor {

  ExampleDescriptor({
    required this.exampleEnum,
    required this.chartType,
    required this.chartOrientation,
    required this.chartStacking,
    required this.chartLayouter,
  });

  ExampleEnum exampleEnum;
  ChartType chartType;
  ChartOrientation chartOrientation;
  ChartStacking chartStacking;
  ChartLayouter chartLayouter;

  /// Factory creates a helper instance needed when insufficient data exist to create an instance.
  ///
  /// This is for old examples processing only, when we want to express that all allowed examples should run.
  factory ExampleDescriptor.pluginForOldLayouterProcessing() {
    return ExampleDescriptor(
      exampleEnum: ExampleEnum.ex10RandomData, // unused
      chartType: ChartType.barChart, // unused
      chartOrientation: ChartOrientation.column, // unused
      chartStacking: ChartStacking.stacked, // unused
      chartLayouter: ChartLayouter.oldManualLayouter,
    );
  }

  static final List<Tuple2<ExampleEnum, ChartType>> _allowed = [
    //
    const Tuple2(ExampleEnum.ex10RandomData, ChartType.lineChart),
    const Tuple2(ExampleEnum.ex10RandomData, ChartType.barChart),
    //
    const Tuple2(ExampleEnum.ex30AnimalsBySeasonWithLabelLayoutStrategy, ChartType.lineChart),
    const Tuple2(ExampleEnum.ex30AnimalsBySeasonWithLabelLayoutStrategy, ChartType.barChart),
    //
    const Tuple2(ExampleEnum.ex31SomeNegativeValues, ChartType.lineChart),
    const Tuple2(ExampleEnum.ex31SomeNegativeValues, ChartType.barChart),
    //
    const Tuple2(ExampleEnum.ex32AllPositiveYsYAxisStartsAbove0, ChartType.lineChart),
    const Tuple2(ExampleEnum.ex32AllPositiveYsYAxisStartsAbove0, ChartType.barChart),
    //
    const Tuple2(ExampleEnum.ex33AllNegativeYsYAxisEndsBelow0, ChartType.lineChart),
    //
    const Tuple2(ExampleEnum.ex34OptionsDefiningUserTextStyleOnLabels, ChartType.lineChart),
    //
    const Tuple2(ExampleEnum.ex35AnimalsBySeasonNoLabelsShown, ChartType.lineChart),
    const Tuple2(ExampleEnum.ex35AnimalsBySeasonNoLabelsShown, ChartType.barChart),
    //
    const Tuple2(ExampleEnum.ex40LanguagesWithYOrdinalUserLabelsAndUserColors, ChartType.lineChart),
    //
    const Tuple2(ExampleEnum.ex50StocksWithNegativesWithUserColors, ChartType.barChart),
    //
    const Tuple2(ExampleEnum.ex52AnimalsBySeasonLogarithmicScale, ChartType.lineChart),
    const Tuple2(ExampleEnum.ex52AnimalsBySeasonLogarithmicScale, ChartType.barChart),
    //
    const Tuple2(ExampleEnum.ex60LabelsIteration1, ChartType.barChart),
    //
    const Tuple2(ExampleEnum.ex60LabelsIteration2, ChartType.barChart),
    //
    const Tuple2(ExampleEnum.ex60LabelsIteration3, ChartType.barChart),
    //
    const Tuple2(ExampleEnum.ex60LabelsIteration4, ChartType.barChart),
    //
    const Tuple2(ExampleEnum.ex70AnimalsBySeasonLegendIsColumnStartLooseItemIsRowStartLoose,
        ChartType.barChart),
    //
    const Tuple2(ExampleEnum.ex71AnimalsBySeasonLegendIsColumnStartTightItemIsRowStartTight,
        ChartType.barChart),
    //
    const Tuple2(ExampleEnum.ex72AnimalsBySeasonLegendIsRowCenterLooseItemIsRowEndLoose,
        ChartType.barChart),
    //
    const Tuple2(ExampleEnum.ex73AnimalsBySeasonLegendIsRowStartTightItemIsRowStartTight,
        ChartType.barChart),
    //
    const Tuple2(ExampleEnum.ex74AnimalsBySeasonLegendIsRowStartTightItemIsRowStartTightSecondGreedy,
        ChartType.barChart),
    //
    const Tuple2(ExampleEnum.ex75AnimalsBySeasonLegendIsRowStartTightItemIsRowStartTightItemChildrenPadded,
        ChartType.barChart),
    const Tuple2(ExampleEnum.ex75AnimalsBySeasonLegendIsRowStartTightItemIsRowStartTightItemChildrenPadded,
        ChartType.lineChart),
    //
    const Tuple2(ExampleEnum.ex76AnimalsBySeasonLegendIsRowStartTightItemIsRowStartTightItemChildrenAligned,
        ChartType.barChart),
    //
    const Tuple2(ExampleEnum.ex800EU12CountriesHistoricalPopulation,
        ChartType.barChart),

    //
    const Tuple2(ExampleEnum.ex900ErrorFixUserDataAllZero, ChartType.lineChart),
  ];

  /// Check if the example described with the passed enums should run in a test.
  ///
  /// Generally examples should run as either [ExamplesChartTypeEnum.lineChart]
  ///   or [ExamplesChartTypeEnum.barChart] except a few where only
  ///   one chart type makes sense to be presented.
  static bool exampleIsAllowed(
      ExampleDescriptor exampleDescriptor,
  ) {
    return _allowed.any((tuple) => tuple.item1 == exampleDescriptor.exampleEnum && tuple.item2 == exampleDescriptor.chartType);
  }

  /// Extract [ExampleDescriptor] list from environment.
  ///
  /// The list must be pushed via `--dart-define` for example,
  /// `--dart-define=EXAMPLES_DESCRIPTORS='ex75_lineChart_row_nonStacked_newAutoLayouter ex75_barChart_row_nonStacked_newAutoLayouter'`
  ///
  static List<ExampleDescriptor> extractExamplesDescriptorsFromDartDefine({String? message}) {
    String env = const String.fromEnvironment('EXAMPLES_DESCRIPTORS', defaultValue: '');
    List<String> descriptorsStrings = [];
    if (env != '') {
      descriptorsStrings = env.split(' ');
    }
    if (message != null) {
      print(' ### Log.Info: $message: Passed examplesDescriptors=$descriptorsStrings, length=${descriptorsStrings.length}');
    }
    return ExampleDescriptor.parseEnhancedDescriptors(descriptorsStrings);
  }

  /// Returns the enum of the chart example to run *in widget tests, integration tests, or example/lib/main.dart*.
  ///
  /// The enums are pulled from environment variables named ['EXAMPLE_TO_RUN'] and ['CHART_TYPE']
  ///   passed to the main program by `--dart-define` options.
  ///
  /// Converts the dart-define(d) environment variables passed to 'flutter run', 'flutter test', or 'flutter driver',
  ///   by `--dart-define` for variables named 'EXAMPLE_TO_RUN', 'CHART_TYPE', 'CHART_STACKING', 'CHART_ORIENTATION'
  ///   and 'CHART_LAYOUTER' into enums which describe the example to run, and the chart type to show.
  ///
  // @Deprecated('ExampleDescriptor.requestedExampleToRun will be removed in the next major version')
  static ExampleDescriptor requestedExampleToRun() {
    // Pickup what example to run, and which chart to show (line, vertical bar).
    const String exampleToRunStr = String.fromEnvironment('EXAMPLE_TO_RUN', defaultValue: 'ex10RandomData');
    ExampleEnum exampleEnumToRun = exampleToRunStr.asEnum(ExampleEnum.values);

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
      exampleEnum: exampleEnumToRun,
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

  /// Returns a list of [ExampleDescriptor]s matching the passed [descriptor].
  ///
  /// Assumes that [descriptor] String is in format with 5 fields, each fields represents
  /// one enum member in [ExampleDescriptor]. The enum member can be represented either by being string value of the enum,
  /// or '*', which translates to all enum values
  ///
  /// Examples of valid descriptor:
  /// 
  ///   - `ex76_barChart_column_stacked_oldManualLayouter`:
  ///        matches ex76, creates 1 [ExampleDescriptor] with described properties
  ///   - `ex76_*_*_*_*` :
  ///        matches ex76, creates 2x2x2x2 [ExampleDescriptor]s with all * matching properties
  ///   - `ex_barChart_column_stacked_newAutoLayouter` :
  ///        matches ex10, ex20, etc, creates as many [ExampleDescriptor]s as there are examples, each has named properties
  ///   
  /// Fields assumed order and values:
  ///    - Field 0: [ExampleEnum]       - for example, 'ex76'
  ///    - Field 1: [ChartType]         - for example, 'lineChart'
  ///    - Field 2: [ChartOrientation]  - for example, 'column'
  ///    - Field 3: [ChartStacking]     - for example, 'nonStacked'
  ///    - Field 4: [ChartLayouter]     - for example, 'newAutoLayouter'
  ///    
  ///   
  static List<ExampleDescriptor> _parseDescriptor(String descriptor) {
    var parsedFields = descriptor.split('_');
    if (parsedFields.length != 5) throw StateError('Descriptor requires 5 _ separated fields: descriptor=$descriptor');
    
    // Field 0: [ExampleEnum]
    String exampleNameStartStr = parsedFields[0];
    List<ExampleEnum> exampleEnums = _allowed
        .where((tuple) => tuple.item1.name.startsWith(exampleNameStartStr))
        .map((tuple) => tuple.item1).toList();
    if (exampleEnums.isEmpty) {
      throw StateError('Invalid (zero based) ExampleEnum field 0 in descriptor=$descriptor. '
          'Perhaps descriptor missing in _allowed=$_allowed?');
    }
    // ExampleEnum exampleEnum = exampleEnums.first;
    exampleEnums = exampleEnums.toSet().toList();

    // Field 1: [ChartType]
    List<ChartType> chartTypes = parsedFields[1] == '*'
        ? ChartType.values.toList()
        : [
            ChartType.asEnum(
              parsedFields[1],
              'Invalid (zero based) ChartType field 1 in $descriptor',
            )
          ];

    // Field 2: [ChartOrientation]
    List<ChartOrientation> chartOrientations = parsedFields[2] == '*'
        ? ChartOrientation.values.toList()
        : [
            ChartOrientation.asEnum(
              parsedFields[2],
              'Invalid (zero based) ChartOrientation field 2 in $descriptor',
            )
          ];

    // Field 3: [ChartStacking]
    List<ChartStacking> chartStackings = parsedFields[3] == '*'
        ? ChartStacking.values.toList()
        : [
            ChartStacking.asEnum(
              parsedFields[3],
              'Invalid (zero based) ChartStacking field 3 in $descriptor',
            )
          ];

    //  Field 4: [ChartLayouter]
    List<ChartLayouter> chartLayouters = parsedFields[4] == '*'
        ? ChartLayouter.values.toList()
        : [
            ChartLayouter.asEnum(
              parsedFields[4],
              'Invalid (zero based) ChartLayouter field 4 in $descriptor',
            )
          ];

    List<ExampleDescriptor> exampleDescriptors = [];
    for (var exampleEnum in exampleEnums) {
      for (var chartType in chartTypes) {
        for (var chartOrientation in chartOrientations) {
          for (var chartStacking in chartStackings) {
            for (var chartLayouter in chartLayouters) {
              exampleDescriptors.add(
                ExampleDescriptor(
                  exampleEnum: exampleEnum,
                  chartType: chartType,
                  chartOrientation: chartOrientation,
                  chartStacking: chartStacking,
                  chartLayouter: chartLayouter,
                ),
              );
            }
          }
        }
      }
    }

    return exampleDescriptors;
  }

  /// Parse the passed [descriptors] strings and convert them to [ExampleDescriptor] objects.
  static List<ExampleDescriptor> parseDescriptors(List<String> descriptors) {
    return descriptors
        .map((descriptor) => _parseDescriptor(descriptor))
        .expand((element) => element)
        .toList();
  }

  static List<ExampleDescriptor> current = parseDescriptors([
    'ex800_barChart_column_stacked_newAutoLayouter',
  ]);

  static List<ExampleDescriptor> absoluteMinimumNew = parseDescriptors([
    'ex75_lineChart_row_nonStacked_newAutoLayouter',
    'ex31_barChart_column_stacked_newAutoLayouter',
  ]);

  static List<ExampleDescriptor> minimumNew = parseDescriptors([
    'ex31_lineChart_*_nonStacked_newAutoLayouter',
    'ex31_barChart_*_*_newAutoLayouter',
  ]);

  static List<ExampleDescriptor> allSupportedNew = parseDescriptors([
    'ex31_lineChart_*_nonStacked_newAutoLayouter',
    'ex31_barChart_*_*_newAutoLayouter',
    'ex75_lineChart_*_nonStacked_newAutoLayouter',
    'ex75_barChart_*_*_newAutoLayouter',
  ]);

  static List<ExampleDescriptor> minimumOld = parseDescriptors([
    // 'ex10_lineChart_column_nonStacked_oldManualLayouter',
    // 'ex10_barChart_column_stacked_oldManualLayouter',
    'ex75_lineChart_column_nonStacked_oldManualLayouter',
    'ex31_barChart_column_stacked_oldManualLayouter',
  ]);

  static List<ExampleDescriptor> allSupportedOld = parseDescriptors([
    'ex10_lineChart_column_nonStacked_oldManualLayouter',
    'ex10_barChart_column_stacked_oldManualLayouter',
    'ex30_lineChart_column_nonStacked_oldManualLayouter',
    'ex30_barChart_column_stacked_oldManualLayouter',
    'ex31_lineChart_column_nonStacked_oldManualLayouter',
    'ex31_barChart_column_stacked_oldManualLayouter',
    'ex32_lineChart_column_nonStacked_oldManualLayouter',
    'ex32_barChart_column_stacked_oldManualLayouter',
    'ex33_lineChart_column_nonStacked_oldManualLayouter',
    'ex34_lineChart_column_nonStacked_oldManualLayouter',
    'ex35_lineChart_column_nonStacked_oldManualLayouter',
    'ex35_barChart_column_stacked_oldManualLayouter',
    'ex40_lineChart_column_nonStacked_oldManualLayouter',
    'ex50_barChart_column_stacked_oldManualLayouter',
    'ex52_lineChart_column_nonStacked_oldManualLayouter',
    'ex52_barChart_column_stacked_oldManualLayouter',
    'ex60_barChart_column_stacked_oldManualLayouter',
    'ex60_barChart_column_stacked_oldManualLayouter',
    'ex60_barChart_column_stacked_oldManualLayouter',
    'ex60_barChart_column_stacked_oldManualLayouter',
    'ex70_barChart_column_stacked_oldManualLayouter',
    'ex71_barChart_column_stacked_oldManualLayouter',
    'ex72_barChart_column_stacked_oldManualLayouter',
    'ex73_barChart_column_stacked_oldManualLayouter',
    'ex74_barChart_column_stacked_oldManualLayouter',
    'ex75_barChart_column_stacked_oldManualLayouter',
    'ex75_lineChart_column_nonStacked_oldManualLayouter',
    'ex76_barChart_column_stacked_oldManualLayouter',
    'ex90_lineChart_column_nonStacked_oldManualLayouter',
  ]);

  static List<ExampleDescriptor> minimum = List.from(minimumNew)..addAll(minimumOld);

  static List<ExampleDescriptor> allSupported = List.from(allSupportedNew)..addAll(allSupportedOld);

  static List<ExampleDescriptor> parseEnhancedDescriptors(List<String> descriptors) {
    List<ExampleDescriptor> allDefined = [];
    for (var descriptor in descriptors) {
      _GroupDescriptor? maybeGroupDescriptor = _GroupDescriptor.asEnum(descriptor, orElse: () => null);
      if (maybeGroupDescriptor == null) {
        allDefined.addAll(_parseDescriptor(descriptor));
      } else {
        switch (maybeGroupDescriptor) {
          case _GroupDescriptor.absoluteMinimumNew:
            allDefined.addAll(absoluteMinimumNew);
            break;
          case _GroupDescriptor.minimumNew:
            allDefined.addAll(minimumNew);
            break;
          case _GroupDescriptor.allSupportedNew:
            allDefined.addAll(allSupportedNew);
            break;
          case _GroupDescriptor.minimumOld:
            allDefined.addAll(minimumOld);
            break;
          case _GroupDescriptor.allSupportedOld:
            allDefined.addAll(allSupportedOld);
            break;
          case _GroupDescriptor.minimum:
            allDefined.addAll(minimum);
            break;
          case _GroupDescriptor.allSupported:
            allDefined.addAll(allSupported);
            break;
        }
      }
    }
    return allDefined;
  }
  
  /// Present this descriptor is a format suitable to run as a test from command line.
  // @Deprecated('ExampleDescriptor.asCommandLine will be removed in the next major version')
  void asCommandLine(bool isAllExamplesRequested, bool isRunBothChartTypes) {
    List<Tuple2<ExampleEnum, ChartType>> combosToRun = isAllExamplesRequested
        ? _allowed
        : _allowed.where((tuple) => tuple.item1 == exampleEnum).toList();

    // [combosToRun] has 1 or 2 chartTypes, depending what is specified in allowed.
    // if [isRunBothChartTypes] is true, we OVERRIDE that, and run both charts.
    // This is how we support old method of defining list of examples to run, yet enable [ExampleDescriptor]
    //   members to be not nullable
    combosToRun = isRunBothChartTypes
        ? combosToRun
        : combosToRun.where((tuple) => tuple.item2 == chartType).toList();

    if (combosToRun.isEmpty) {
      throw StateError('No examples requested to run are defined in example_descriptor.');
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
          exampleEnum:      tuple2AndOrientationWithStacking[0].item1 as ExampleEnum,
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

  @override
  bool operator ==(Object other) =>
      other is ExampleDescriptor &&
          other.runtimeType == runtimeType &&
          other.exampleEnum == exampleEnum &&
          other.chartType == chartType &&
          other.chartOrientation == chartOrientation &&
          other.chartStacking == chartStacking &&
          other.chartLayouter == chartLayouter;

  @override
  int get hashCode => Object.hash(
        exampleEnum,
        chartType,
        chartOrientation,
        chartStacking,
        chartLayouter,
      );

  @override
  String toString() => 'exampleEnum=$exampleEnum, '
      'chartType=$chartType, '
      'chartOrientation=$chartOrientation, '
      'chartStacking=$chartStacking, '
      'chartLayouter=$chartLayouter, ';
}

/// Describes static members on [ExampleDescriptor] that represent groups of descriptors for
/// testing using a brief name.
enum _GroupDescriptor {
  absoluteMinimumNew,
  minimumNew,
  allSupportedNew,
  minimumOld,
  allSupportedOld,
  minimum,
  allSupported;

  /// Converts [enumStr] to a matching value of this enum, throws [StateError] with [errorMessage] if
  /// the [enumStr] does not match any enum value.
  static _GroupDescriptor? asEnum(String enumStr, {required Function orElse}) {
    if (_GroupDescriptor.values.map((value) => value.name).where((enumName) => enumName == enumStr).toList().isEmpty) {
      return orElse();
    }
    _GroupDescriptor groupDescriptor = enumStr.asEnum(_GroupDescriptor.values);
    return groupDescriptor;
  }
  
}

/// Encapsulates information needed to run `example/lib/src/main.dart` which are also
/// needed in tests.
///
/// The commonality of need in 2 places is the reason for placing outside the `example/lib` tree.
///
class ExampleMainAndTestSupport {

  /// Tooltips on Floating button in the example app, also used in tests.
  ///
  // static const String floatingButtonTooltipNewRandomData = 'New Random Data';
  // static const String floatingButtonTooltipOnLastExample = 'On Last Example';
  static const String floatingButtonTooltipMoveToNextExample = 'Move to Next Example';

  /*
  String get floatingButtonTooltip({required ExampleRunState exampleRunState,}) {
    String floatingButtonTooltip = 'Initial';
    if (exampleRunState.isConfiguredForMultiExample) {
      exampleRunState.moveToNextExample();
      if (exampleRunState.isRunningExampleLast) {
        floatingButtonTooltip = ExampleMainAndTestSupport.floatingButtonTooltipMoveToNextExample;
      } else {
        floatingButtonTooltip = ExampleMainAndTestSupport.floatingButtonTooltipMoveToNextExample;
      }
    } else {
      floatingButtonTooltip = ExampleMainAndTestSupport.floatingButtonTooltipMoveToNextExample;
    }

    return floatingButtonTooltip;
  }
  */

}