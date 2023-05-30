import 'example_descriptor.dart' show ExampleDescriptor, ExampleEnum;
// todo-00-next : use main_new : import '../../main_new.dart' show requestedExampleToRun;
// import 'example_descriptor.dart' as example_descriptor show requestedExampleToRun;
import 'package:flutter_charts/src/morphic/container/chart_support/chart_style.dart'
    show ChartLayouter, ChartOrientation, ChartStacking, ChartType;


/// Describes all attributes of one chart example that can run or be tested.
///
/// Intended only as part of outer [ChartExamples].
///
/// Difference from [ExampleDescriptor] :
///    - [ExampleDescriptor] exists for the benefit of shell scripts, is used to generate scripts commands
///      using [ExampleDescriptor.asCommandLine]. List of [ExampleDescriptor.asCommandLine] results is captured in
///      `test/tmp/example_descriptor_generated_program_RANDOM.sh`,
///      that can be executed by other scripts as 'flutter drive`, or `flutter run`.
///      All the properties of the [ExampleDescriptor] are passed to 'flutter drive`, or `flutter run`
///      as `--dart-define` arguments, then re-created in the running app as state
///        ```dart
///          Tuple5<ExampleEnum, ChartType, ChartOrientation, ChartStacking, ChartLayouter> descriptorOfExampleToRun
///        ```
///      This happens in `main.dart` during widget creation in [requestedExampleToRun],
///      and is used in [ExampleWidgetCreator] around
///        ```dart
///          // On state:
///          Tuple5<ExampleEnum, ChartType, ChartOrientation, ChartStacking, ChartLayouter> descriptorOfExampleToRun =
///               requestedExampleToRun();
///          // In build()
///          ExampleWidgetCreator definer = ExampleWidgetCreator(descriptorOfExampleToRun);
///          Widget chartToRun = definer.createRequestedChart();
///          ExampleSideEffects exampleSpecific = definer.exampleSideEffects;
///        ```
///    - [ChartExamples] translates String arguments passed to a Flutter `main.dart`
///      into a list of examples to run in the Flutter app (as apposed in a shell script).
///      All the properties of [ChartExample] are created inside the Flutter app,
///      and converted to [ExampleDescriptor].
class ChartExample {

  ChartExample({
    required this.exampleEnum,
    required this.chartTypeGroup,
    required this.chartOrientationGroup,
    required this.chartStackingGroup,
    required this.chartLayouterGroup,
  });

  final ExampleEnum exampleEnum;
  final ChartType chartTypeGroup;
  final Set<ChartOrientation> chartOrientationGroup;
  final Set<ChartStacking> chartStackingGroup;
  final Set<ChartLayouter> chartLayouterGroup;

}

/// Describes a list of chart examples that can run or be tested.
class ChartExamples {

}

