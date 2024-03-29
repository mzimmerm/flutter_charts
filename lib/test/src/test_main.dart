/// Example app for flutter_charts.
///
/// All classes without prefix in this code are either
/// - from material.dart or
/// - from flutter_charts.dart exports (this library)
/// Also, material.dart exports many dart files, including widgets.dart,
/// so Widget classes are referred to without prefix
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:io' as io show exit;
import 'dart:ui' as ui show Color;
import 'package:logger/logger.dart';

import 'package:flutter_charts/src/chart/cartesian/chart_type/line/chart.dart';
import 'package:flutter_charts/src/chart/cartesian/chart_type/bar/chart.dart';
import 'package:flutter_charts/src/chart/model/data_model.dart';
import 'package:flutter_charts/src/chart/iterative_layout_strategy.dart';
import 'package:flutter_charts/src/chart/options.dart';
import 'package:flutter_charts/test/src/chart/options.dart' as test_options show LegendAndItemLayoutEnum;
import 'package:flutter_charts/src/chart/model/random_chart_data.dart';

import 'package:flutter_charts/src/morphic/container/chart_support/chart_style.dart';
import 'package:flutter_charts/src/switch_view_model/view_model.dart';
import 'package:flutter_charts/src/chart/painter.dart' show FlutterChartPainter;

// Can import without 'package' here, because the file is under same lib directory.
import 'package:flutter_charts/src/chart/util/example_descriptor.dart'
    show ExampleDescriptor, ExampleEnum, ExampleMainAndTestSupport;

/// Test app for use in tests and integration tests in `flutter_charts`.
///
/// The app is configurable to run either a single chart, or multiple charts;
/// the floating button for multi-chart configuration steps through the charts in order.
///
/// Note: There is another example app [main_run_doc_example.dart](example/main_run_doc_example.dart),
///       which is intended to run only one example. This example app exists to:
///   - a) satisfy the flutter and dart conventions for presence of example app in a library
///   - b) be edited by a program which pastes sample chart code from README.md and appends
///        its result to README.md..
///
/// The application is very simple, it has:
///
///   - several labels and text fields surrounding a sample chart created by this library.
///   - a floating button with a plus (+) sign and a tooltip.
///
/// The application can be configured through either arguments to [main] or `--dart-define`
/// to run either a single example, or multiple examples during the same test.
///
///   - When configured to run a single example, clicking the floating button causes [setState] to run a no-op branch,
///     which causes Flutter to re-run the [ExampleHomePageState.build] using the same example.
///   - When configured to run multiple examples, clicking the floating button causes [setState] to run a branch which
///     changes the example to tne next example from the list, which causes Flutter
///     to run the [ExampleHomePageState.build] on the next example from the list.
///
/// The state is encapsulated in the class [ExampleRunState].
///
/// The example chart that runs is determined in two ways :
///
///   - The old method using `--dart-define` command line argument named 'EXAMPLE_TO_RUN' picked up in
///     a global function [ExampleDescriptor.requestedExampleToRun], used in [ExampleWidgetCreator.createRequestedChart].
///   - The new method using arguments [examplesDescriptors] passed to [main].
///
/// Library note: This file is on the same level as _lib_, so everything from _lib_ must
/// be imported using the "package:" scheme, e.g.
/// ```dart
///    import 'package:flutter_charts/flutter_charts.dart';
/// ```
void main() {
  
  // Set logging level. There should be some kind of configuration for this.
  Logger.level = Level.warning;

  // Extract descriptors for examples to run. examplesDescriptors must be pushed via --dart-define=EXAMPLES_DESCRIPTORS.
  List<ExampleDescriptor> examplesDescriptors = ExampleDescriptor.extractExamplesDescriptorsFromDartDefine(
    message: 'From lib/test/src/test_main.dart',
  );

  // runApp is function (not method) in PROJ/packages/flutter/lib/src/widgets/binding.dart.
  //
  // Why we do not have to import binding.dart?
  //
  // In brief, because it is imported through another file, material.dart.
  //
  // Longer reason
  //
  //      - Because Any Flutter app must have:
  //        1) main() { runApp(ExampleApp()) } // entry point
  //        2) import 'package:flutter/material.dart';
  //          Note: *NOT* 'package:flutter/material/material.dart'.
  //          Note: material.dart is on path: PROJ/packages/flutter/lib/material.dart
  //          so another note:
  //             * the lib level is skipped int the import reference
  //             * package: represent a directory where packages
  //               for this project are installed in pub update package
  //      - And:
  //        3) The imported 'package:flutter/material.dart' contains line:
  //            export 'widgets.dart';
  //            which references, at the same level, a path:
  //               PROJ/packages/flutter/lib/widgets.dart
  //            which contains:
  //               export 'src/widgets/binding.dart';
  //               on path: PROJ/packages/flutter/lib/src/widgets/binding.dart
  //            which contains the function runApp().
  //
  //  So, eventually, the loading of binding.dart, and it's runApp() function
  //  in ExampleApp is achieved this way:
  //    1) This file 'lib/test/src/test_main.dart' has
  //        - import 'package:flutter/material.dart' (references PROJ/packages/flutter/lib/material.dart)
  //    2) material.dart has
  //        - export 'widgets.dart'; (references same dir        PROJ/packages/flutter/lib/widgets.dart)
  //    3) widgets.dart has
  //        - export 'src/widgets/binding.dart'; (references dir PROJ/packages/flutter/lib/src/widgets/binding.dart)
  //    4) binding.dart has
  //        - the runApp() top level function
  //
  // This process achieves importing (heh via exports) the file
  //    packages/flutter/lib/src/widgets/binding.dart
  //    which has the runApp() function which does the following:
  //    ```dart
  //      void runApp(Widget app) {
  //        WidgetsFlutterBinding.ensureInitialized()
  //          ..scheduleAttachRootWidget(app)
  //          ..scheduleWarmUpFrame();
  //      }
  //    ```

  // Configure the examples to run.
  if (examplesDescriptors.isEmpty) {
    // With no arguments, use the old method - using --dart-define - to extract the (always single) example to run.
    ExampleDescriptor exampleToRun = ExampleDescriptor.requestedExampleToRun();
    if (!ExampleDescriptor.exampleIsAllowed(exampleToRun)) {
      // Better: SystemChannels.platform.invokeMethod('SystemNavigator.pop');
      print(' ### Log.Error: The passed combination of example enum and chart type is not allowed, exiting!');
      io.exit(0);
    }
    examplesDescriptors.add(exampleToRun);
  }
  ExampleRunState exampleRunState = ExampleRunState(examplesToRun: examplesDescriptors);

  // If using a client-specific font, such as GoogleFonts, this is needed, in conjunction with
  // installing the fonts in pubspec.yaml.
  // But these 2 additions are needed ONLY in integration tests. App works without those 2 additions.
  GoogleFonts.config.allowRuntimeFetching = false;

  runApp(ExampleApp(
    exampleRunState: exampleRunState,
  ));
}

class ExampleApp extends StatelessWidget {
  const ExampleApp({
    required this.exampleRunState,
    Key? key,
  }) : super(key: key);

  final ExampleRunState exampleRunState;

  /// Builds the widget which becomes the root of the application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Charts Demo Title',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: ExampleHomePage(
        title: 'Flutter Charts Demo',
        exampleRunState: exampleRunState,
      ),
    );
  }
}

class ExampleHomePage extends StatefulWidget {
  const ExampleHomePage({
    Key? key,
    required this.title,
    required this.exampleRunState,
  }) : super(key: key);

  // This widget is the home page of your application. It is stateful,
  // meaning that it has a State object (defined below) that contains
  // fields that affect how it looks.

  // This class is the configuration for the state. It holds the
  // values (in this case the title) provided by the parent (in this
  // case the App widget) and used by the build method of the State.
  // Fields in a Widget subclass are always marked "final".

  final String title;
  final ExampleRunState exampleRunState;

  /// Stateful widgets must implement the [createState] method.
  ///
  /// The [createState] method will typically return the
  /// new state of the widget.
  @override
  ExampleHomePageState createState() => ExampleHomePageState(exampleRunState: exampleRunState);
}

/// This state object is created in the stateful widget's [ExampleHomePage] call to
/// [ExampleHomePage.createState].
///
/// In the rest of the lifecycle, this state object holds on one object,
/// - [exampleToRun]
///
/// The rest of the objects (options, data, etc) are created during the build.
///
/// While this home page state object is created only once (hence, the above
/// state's member [exampleToRun], is created only once, the charts shown
/// in this demo, the [LineChart] and the [BarChart], are recreated
/// in this object's [build] method - so, **the chart objects are created over
/// and over**.
///
/// Note: The (each [build]) recreated chart objects reuse the state's members
/// [exampleToRun], so this could be considered
/// "expensive to create".
///
/// Note: At the same time, because the this state's [build] calls
///    _ExampleDefiner definer = _ExampleDefiner(descriptorOfExampleToRun);
///     Widget chartToRun = definer.createRequestedChart();
/// recreates lineChartOptions, barChartOptions, chartModel,
/// and inputLabelLayoutStrategy, the core of this state object (all members)
/// is effectively recreated on each state's [build] call.
///
class ExampleHomePageState extends State<ExampleHomePage> {

  /// Default constructor uses member defaults for all options and data.
  ExampleHomePageState({
    required this.exampleRunState,
  });

  /// Describes the example or examples being run.
  final ExampleRunState exampleRunState;
  String floatingButtonTooltip = ExampleMainAndTestSupport.floatingButtonTooltipMoveToNextExample;

  /// Calls this [ExampleHomePageState] instance's [setState] which is the default [State.setState].
  ///
  /// Call to [State.setState] tells the Flutter framework that something has changed in this State.
  /// Code in [State.setState] will
  ///   - First invoke the passed method, which makes changes
  ///     to this [ExampleHomePageState]'s state (see below for details).
  ///   - Invoke this [ExampleHomePageState.build] method, with the changed State; the build reflects the
  ///     updated values in the UI.
  ///
  /// If we changed state without calling [setState], the build method would not be called again,
  /// and so nothing would appear to happen.
  ///
  /// Implementation:
  ///   - For multi example will move the [exampleRunState] to next example by invoking
  ///     `exampleRunState.moveToNextExample()`, which will be plugged in to [ExampleHomePageState.build]
  ///     as `exampleRunState.runningExample` ; see
  ///     ```dart
  ///       ExampleWidgetCreator definer = ExampleWidgetCreator(exampleRunState.runningExample);
  ///       Widget chartToRun = definer.createRequestedChart();
  ///       ExampleSideEffects exampleSpecific = definer.exampleSideEffects;
  ///     ```
  ///   - For single example there is no state change, [exampleRunState] is kept on the same example;
  ///     [ExampleHomePageState.build]  may show different data, if data are obtained remotely or generated randomly.
  ///
  void _chartStateChanger() {
    setState(() {
      if (exampleRunState.isConfiguredForMultiExample) {
        exampleRunState.moveToNextExample();
      }
    });
  }

  /// Builds the widget that is the home page state.
  @override
  Widget build(BuildContext context) {
    // General notes on Windows and sizing in Flutter
    //
    // The (singleton?) window object is available anywhere using ui.
    // From window, we can get ui.window.devicePixelRatio, and also
    //   ui.Size windowLogicalSize = ui.window.physicalSize / devicePixelRatio
    // Note: Do not use ui.window for any sizing: see
    //       https://github.com/flutter/flutter/issues/11697
    //
    // MediaQueryData mediaQueryData = MediaQuery.of(context);
    // Use MediaQuery.of(context) for any sizing.
    // Note: mediaQueryData can still return 0 size,
    //       but if MediaQuery.of(context) is used, Flutter will guarantee
    //       the build(context) will be called again !
    //        (once non 0 size becomes available)
    //
    // Note: windowLogicalSize = size of the media (screen) in logical pixels
    // Note: same as ui.window.physicalSize / ui.window.devicePixelRatio;
    // ui.Size windowLogicalSize = mediaQueryData.size;
    //
    // `devicePixelRatio` = number of device pixels for each logical pixel.
    // Note: in all known hardware, size(logicalPixel) > size(devicePixel)
    // Note: this is also, practically, never needed
    // double logicalToDevicePixelSize = mediaQueryData.devicePixelRatio;
    //
    // `textScaleFactor` = number of font pixels for each logical pixel.
    // Note: with some fontSize, if text scale factor is 1.5
    //       => text font is 1.5x larger than the font size.
    // double fontScale = mediaQueryData.textScaleFactor;
    //
    // To give the LineChart full width and half of height of window.
    // final ui.Size chartLogicalSize =
    //     new Size(windowLogicalSize.width, windowLogicalSize.height / 2);
    //
    // print(" ### Size: ui.window.physicalSize=${ui.window.physicalSize}, "
    //     "windowLogicalSize = mediaQueryData.size = $windowLogicalSize,"
    //     "chartLogicalSize=$chartLogicalSize");

    // The [_ExampleDefiner] creates the instance of the example chart that will be displayed.
    ExampleWidgetCreator definer = ExampleWidgetCreator(exampleRunState.runningExample);
    Widget chartToRun = definer.createRequestedChart();
    ExampleSideEffects exampleSpecific = definer.exampleSideEffects;

    // [ExampleHomePage] extends [StatefulWidget].
    // [StatefulWidget] calls build(context) every time setState is called,
    // for instance as done by the _chartStateChanger method above.
    // The Flutter framework has been optimized to make rerunning
    // build methods fast, so that you can just rebuild anything that
    // needs updating rather than having to individually change
    // instances of widgets.
    return Scaffold(
      appBar: AppBar(
        // Here we take the value from the ExampleHomePage object that
        // was created by the App.build method, and use it to set
        // our appbar title.
        title: Text(widget.title),
      ),
      // Center is a layout widget. It takes a single child and
      // positions it in the middle of the parent.
      body: Center(
        // Column is also layout widget. It takes a list of children
        // and arranges them vertically. By default, it sizes itself
        // to fit its children horizontally, and tries to be as tall
        // as its parent.
        //
        // Invoke "debug paint" (press "p" in the console where you
        // ran "flutter run", or select "Toggle Debug Paint" from the
        // Flutter tool window in IntelliJ) to see the wireframe for
        // each widget.
        //
        // Column has various properties to control how it sizes
        // itself and how it positions its children. Here we use
        // mainAxisAlignment to center the children vertically; the
        // main axis here is the vertical axis because Columns are
        // vertical (the cross axis would be horizontal).

        // Expanded can be around one child of a Row or a Column
        // (there can be one or more children of those layouts).
        //
        // In this document below, we use | as abbreviation for vertical expansion,
        // <--> for horizontal expansion.
        //
        // "Expanded" placed around one of children of Row, or Column,
        // stretches/pulls the expanded child in the parent's
        // "growing" direction.
        //
        // So:
        //   - Inside Column (children: [A, B, Expanded (C)]) stretches C in
        //     column's "growing" direction (that is vertically |)
        //     to the fullest available outside height.
        //   - For Row  (children: [A, B, Expanded (C)]) stretches C in
        //     row's "growing" direction (that is horizontally <-->)
        //     to the fullest available outside width.
        // The layout of this code, is, structurally like this:
        //   Column (
        //      mainAxisAlignment: MainAxisAlignment.center,
        //      children: [
        //        vvv,
        //        Expanded (
        //          Row  (
        //            crossAxisAlignment: CrossAxisAlignment.stretch,
        //            children: [
        //              >>>, Expanded (Chart), <<<,
        //            ]),
        //        ^^^
        //      ])
        // The outer | expansion, in the Column's middle child
        //   pulls/stretches the row vertically |
        //   BUT also needs explicit
        //   crossAxisAlignment: CrossAxisAlignment.stretch.
        //   The cross alignment stretch carries
        //   the | expansion to all <--> expanded children.
        //  Basically, while "Expanded" only applies stretch in one
        //    direction, another outside "Expanded" with CrossAxisAlignment.stretch
        //    can force the innermost child to be stretched in both directions.
        child: Column(
          // mainAxisAlignment: MainAxisAlignment.center, // = default, not needed
          children: <Widget>[
            ElevatedButton(
              // Style would need a custom MaterialStateColor extension.
              //   style: ButtonStyle(backgroundColor: MyMaterialStateColor.resolve(() => Set(Colors))),
              onPressed: _chartStateChanger,
              child: null,
            ),
            const Text(
              'vvvvvvvv:',
            ),
            Expanded(
              // expansion inside Column pulls contents |
              child: Row(
                // mainAxisAlignment: MainAxisAlignment.center, // = default, not needed
                // this stretch carries | expansion to <--> Expanded children
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(exampleSpecific.leftSqueezeText), // '>>>' by default
                  // LineChart is CustomPaint:
                  // A widget that provides a canvas on which to draw
                  // during the paint phase.

                  // Row -> Expanded -> Chart expands chart horizontally <-->
                  Expanded(
                    // #### Core chart
                    child: chartToRun, // barChart, lineChart
                  ),
                  Text(exampleSpecific.rightSqueezeText), // '<<' by default
                  // labels fit horizontally
                  // const Text('<<<<<<'), // default, labels tilted, all present
                  // const Text('<<<<<<<<<<<'),   // labels skipped (shows 3 labels, legend present)
                  // const Text('<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<'), // labels skipped (shows 2 labels, legend present but text vertical)
                  // const Text('<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<'),// labels do overlap, legend NOT present
                ],
              ),
            ),
            const Text('^^^^^^:'),
            ElevatedButton(
              // style would need a custom MaterialStateColor extension.
              // style: ButtonStyle(backgroundColor: MyMaterialStateColor.resolve(() => Set(Colors))),
              onPressed: _chartStateChanger,
              child: null,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        // If onPressed is null, the button would be disabled. But we never disable it, for screenshots look the same.
        // onPressed: exampleRunState.isFloatingButtonDisabled ? null : _chartStateChanger,
        onPressed: _chartStateChanger,
        tooltip: floatingButtonTooltip,
        child: const Icon(Icons.add),
      ),
    );
  }
}

/// An example user-defined extension of [LabelCommonOptions] overrides the [LabelCommonOptions.labelTextStyle]
/// which is the source for user-specific font on labels.
class MyLabelCommonOptions extends LabelCommonOptions {
  const MyLabelCommonOptions(
  ) : super ();
  
  /// Override [labelTextStyle] with a new font, color, etc.
  @override
  get labelTextStyle => GoogleFonts.comforter(
        textStyle: const TextStyle(
          color: ui.Color(0xFF757575),
          fontSize: 14.0,
          fontWeight: FontWeight.w400, // Regular
        ),
      );
  
  /* This alternative works in an app as well, but not in integration test. All style set in options defaults.
  get labelTextStyle =>
      const ChartOptions().labelCommonOptions.labelTextStyle.copyWith(
        fontFamily: GoogleFonts.comforter().fontFamily,
      );
  */
}

/// The enabler of widget changes in the main test app by the code in [ExampleWidgetCreator].
/// 
/// This enables support for each example ability to manipulate it's environment
/// (by environment we mean the widgets in test_main.dart outside the chart).
/// 
/// Some examples need to change widgets of the main test app that are not part of the Chart.
/// For example, some test examples need to run in an increasingly 'squeezed' space available for the chart,
/// to test label changes with available space.
/// 
/// This class allows to carry such changes from the [ExampleWidgetCreator] to the widgets in the main app.
/// 
class ExampleSideEffects {
  String leftSqueezeText = '>>>';
  String rightSqueezeText = '<<';
}

/// Creates the chart [Widget] for the examples which will be tested and run in scripts.
///
/// The core method [createRequestedChart] creates the chart [Widget] for the examples which are tested
/// in [run_all_tests.sh] and [deprecated_run_representative_tests.sh] tests, and interactively running
/// in [run_all_examples.sh].
///
/// Collects all 'variables' that are needed for each example: chart data, labels, colors and so on.
/// Makes available the barChart and the lineChart constructed from the 'variables'.
class ExampleWidgetCreator {

  /// Construct the definer object for the example.
  ExampleWidgetCreator(this.exampleToRun);

  /// Tuple which describes the example
  ExampleDescriptor exampleToRun;

  var animalsDefaultData = const [
    [10.0, 20.0, 5.0, 30.0, 5.0, 20.0],
    [30.0, 60.0, 16.0, 100.0, 12.0, 120.0],
    [25.0, 40.0, 20.0, 80.0, 12.0, 90.0],
    [12.0, 30.0, 18.0, 40.0, 10.0, 30.0],
  ];
  var animalsXUserLabels = const ['Wolf', 'Deer', 'Owl', 'Mouse', 'Hawk', 'Vole'];
  var animalsDataRowsLegends = const [
    'Spring',
    'Summer',
    'Fall',
    'Winter',
  ];

  /// Support for each example manipulate it's environment - the widgets in test_main.dart outside the chart.
  ///
  /// [exampleSideEffects] contain simple text strings such as '>>' and '<<', which are when running examples,
  /// placed to the left and right of the chart, to execute 'squeezing' the chart from the left and the right.
  ExampleSideEffects exampleSideEffects = ExampleSideEffects();

  /// Creates the example chart with name given in [exampleToRun] 
  /// through command line parameter --dart-define.
  ///
  /// Example assumes Android emulator is running or an Android/iOS device is connected:
  /// - Running:
  ///   ```sh
  ///     flutter run lib/test/src/test_main.dart \
  ///       --dart-define=EXAMPLE_TO_RUN=ex10RandomData \
  ///       --dart-define=CHART_TYPE=lineChart
  ///   ```
  /// will set [exampleToRun] to a concrete Tuple of [ExampleEnum] and [ExamplesChartTypeEnum], 
  /// such as `Tuple(ex10RandomData, lineChart)`
  Widget createRequestedChart() {
    // Example requested to run
    ExampleEnum exampleEnumToRun = exampleToRun.exampleEnum;
    ChartType chartType = exampleToRun.chartType;
    ChartOrientation chartOrientation = exampleToRun.chartOrientation;
    ChartStacking chartStacking = exampleToRun.chartStacking;
    ChartLayouter chartLayouter = exampleToRun.chartLayouter;


    // Declare chartModel; the data object will be different in every examples.
    ChartModel chartModel;

    // Create chartOptions defaults here, so we do not repeat it in every example section,
    //   unless specific examples need to override this chartOptions default.
    ChartOptions chartOptions = const ChartOptions();

    // Declare a null inputLabelLayoutStrategy.
    // To use a specific, client defined extension of DefaultIterativeLabelLayoutStrategy or LayoutStrategy,
    //   just create the extension instance similar to the DefaultIterativeLabelLayoutStrategy below.
    // If inputLabelLayoutStrategy is not set in an example (remains null), the charts instantiate
    //   a DefaultIterativeLabelLayoutStrategy.
    LabelLayoutStrategy? inputLabelLayoutStrategy;
    
    /// Main switch that includes code to all examples.
    /// The example which [ExampleEnum] and [ExamplesChartTypeEnum] is passed in the combo is returned.
    /// Each example can also generate side effects in [exampleSideEffects], which allow the code in this 
    /// [createRequestedChart] method to influence the returned chart's surrounding widgets in the main app.
    switch (exampleEnumToRun) {
      case ExampleEnum.ex10RandomData:
        // Example shows a demo-type data generated randomly in a range.
        chartOptions = const ChartOptions(
          legendOptions: LegendOptions(
              legendAndItemLayoutEnum:
                  test_options.LegendAndItemLayoutEnum.legendIsRowStartTightItemIsRowStartTightItemChildrenPadded),
        );
        chartModel = RandomChartModel.generated(
          chartOptions: chartOptions,
        );
        break;

      case ExampleEnum.ex30AnimalsBySeasonWithLabelLayoutStrategy:
        // Example shows an explicit use of the DefaultIterativeLabelLayoutStrategy.
        // The inputLabelLayoutStrategy, if set to null or not set at all, 
        //   defaults to DefaultIterativeLabelLayoutStrategy
        // Clients can also create their own LayoutStrategy.
        inputLabelLayoutStrategy = DefaultIterativeLabelLayoutStrategy(
          options: chartOptions,
        );
        chartModel = ChartModel(
          dataRows: const [
            [10.0, 20.0, 5.0, 30.0, 5.0, 20.0],
            [30.0, 60.0, 16.0, 100.0, 12.0, 120.0],
            [25.0, 40.0, 20.0, 80.0, 12.0, 90.0],
            [12.0, 30.0, 18.0, 40.0, 10.0, 30.0],
          ],
          inputUserLabels: const ['Wolf', 'Deer', 'Owl', 'Mouse', 'Hawk', 'Vole'],
          legendNames: const [
            'Spring',
            'Summer',
            'Fall',
            'Winter',
          ],
          chartOptions: chartOptions,
        );
        // chartModel._byRowDefaultLegendColors(); // if not set, called in constructor
        break;

      case ExampleEnum.ex31SomeNegativeValues:
        // Example shows a mix of positive and negative data values.
        chartModel = ChartModel(
          dataRows: const [
            [2000.0, 1800.0, 2200.0, 2300.0, 1700.0, 1800.0],
            [1100.0, 1000.0, 1200.0, 800.0, 700.0, 800.0],
            [0.0, 100.0, -200.0, 150.0, -100.0, -150.0],
            [-800.0, -400.0, -300.0, -400.0, -200.0, -250.0],
          ],
          inputUserLabels: const ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun'],
          legendNames: const [
            'Big Corp',
            'Medium Corp',
            'Print Shop',
            'Bar',
          ],
          chartOptions: chartOptions,
        );
        break;

      case ExampleEnum.ex32AllPositiveYsYAxisStartsAbove0:
        // Example shows how to create ChartOptions instance 
        //   which will request to start Y axis at data minimum.
        // Even though startYAxisAtDataMinRequested is set to true, this will not be granted on bar chart,
        //   as it does not make sense there.
        chartOptions = const ChartOptions(
          dataContainerOptions: DataContainerOptions(
            extendAxisToOriginRequested: false,
          ),
        );
        chartModel = ChartModel(
          dataRows: const [
            [20.0, 25.0, 30.0, 35.0, 40.0, 20.0],
            [35.0, 40.0, 20.0, 25.0, 30.0, 20.0],
          ],
          inputUserLabels: const ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun'],
          legendNames: const [
            'Off zero 1',
            'Off zero 2',
          ],
          chartOptions: chartOptions,
        );
        break;

      case ExampleEnum.ex33AllNegativeYsYAxisEndsBelow0:
        // Example shows how to create ChartOptions instance
        //   which will request to end Y axis at maximum data (as all data negative).
        // Even though startYAxisAtDataMinRequested is set to true, this will not be granted on bar chart,
        //   as it does not make sense there.
        chartOptions = const ChartOptions(
          dataContainerOptions: DataContainerOptions(
            extendAxisToOriginRequested: false,
          ),
        );
        chartModel = ChartModel(
          dataRows: const [
            [-20.0, -25.0, -30.0, -35.0, -40.0, -20.0],
            [-35.0, -40.0, -20.0, -25.0, -30.0, -20.0],
          ],
          inputUserLabels: const ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun'],
          legendNames: const [
            'Off zero 1',
            'Off zero 2',
          ],
          chartOptions: chartOptions,
        );
        break;
      case ExampleEnum.ex34OptionsDefiningUserTextStyleOnLabels:
        // Example shows how to use user-defined font in the chart labels.
        // In fact, same approach can be used more generally, to set any property 
        //   in user-defined TextStyle (font, font color, etc - any property available on TextStyle) on labels. 
        // To achieve setting custom fonts and/or any member of TextStyle, 
        //   client can declare their own extension of 'LabelCommonOptions', and override the `labelTextStyle` getter.
        // A sample declaration of the class MyLabelCommonOptions, is given here as a comment.
        // ```dart
        //      /// An example user-defined extension of [LabelCommonOptions] overrides the [LabelCommonOptions.labelTextStyle]
        //      /// which is the source for user-specific font on labels.
        //      class MyLabelCommonOptions extends LabelCommonOptions {
        //        const MyLabelCommonOptions(
        //        ) : super ();
        //  
        //        /// Override [labelTextStyle] with a new font, color, etc.
        //        @override
        //        get labelTextStyle => GoogleFonts.comforter(
        //          textStyle: const TextStyle(
        //          color: ui.Color(0xFF757575),
        //          fontSize: 14.0,
        //          fontWeight: FontWeight.w400, // Regular
        //          ),
        //        );
        //  
        //        /* This alternative works in an app as well, but not in the integration test. All style set in options defaults.
        //        get labelTextStyle =>
        //          const ChartOptions().labelCommonOptions.labelTextStyle.copyWith(
        //            fontFamily: GoogleFonts.comforter().fontFamily,
        //          );
        //        */
        //      }
        // ```
        // Given such extended class, declare ChartOptions as follows:
        chartOptions = const ChartOptions(
          labelCommonOptions: MyLabelCommonOptions(),
          );
        // Then proceed as usual
        chartModel = ChartModel(
          dataRows: const [
            [20.0, 25.0, 30.0, 35.0, 40.0, 20.0],
            [35.0, 40.0, 20.0, 25.0, 30.0, 20.0],
          ],
          inputUserLabels: const ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun'],
          legendNames: const [
            'Font Test Series1',
            'Font Test Series2',
          ],
          chartOptions: chartOptions,
        );
        break;
      case ExampleEnum.ex35AnimalsBySeasonNoLabelsShown:
        // Set chart options to show no labels
        chartOptions = const ChartOptions.noLabels();

        chartModel = ChartModel(
          dataRows: const [
            [10.0, 20.0, 5.0, 30.0, 5.0, 20.0],
            [30.0, 60.0, 16.0, 100.0, 12.0, 120.0],
            [25.0, 40.0, 20.0, 80.0, 12.0, 90.0],
            [12.0, 30.0, 18.0, 40.0, 10.0, 30.0],
          ],
          inputUserLabels: const ['Wolf', 'Deer', 'Owl', 'Mouse', 'Hawk', 'Vole'],
          legendNames: const [
            'Spring',
            'Summer',
            'Fall',
            'Winter',
          ],
          chartOptions: chartOptions,
        );
        break;

      case ExampleEnum.ex40LanguagesWithYOrdinalUserLabelsAndUserColors:
        // User-Provided Data (Y values), User-Provided X Labels, User-Provided Data Rows Legends, User-Provided Y Labels, User-Provided Colors
        // This example shows user defined Y Labels that derive order from data.
        //   When setting output labels by user, the [ChartModel.dataRows] value extrapolate
        //   is irrelevant. User can use for example interval <0, 1>,
        //   <0, 10>, or any other, even negative ranges. Here we use <0-10>.
        //   The only thing that matters is  the relative values in the data Rows.
        // Current implementation sets
        //   the minimum of [ChartModel.dataRows] range (1.0 in this example)
        //     on the level of the first Y Label ("Low" in this example),
        //   and the maximum  of [ChartModel.dataRows] range (10.0 in this example)
        //     on the level of the last Y Label ("High" in this example).
        chartModel = ChartModel(
          dataRows: const [
            [9.0, 4.0, 3.0, 9.0],
            [7.0, 6.0, 7.0, 6.0],
            [4.0, 9.0, 6.0, 8.0],
            [3.0, 9.0, 10.0, 1.0],
          ],
          inputUserLabels: const ['Speed', 'Readability', 'Level of Novel', 'Usage'],
          legendColors: const [
            Colors.blue,
            Colors.yellow,
            Colors.green,
            Colors.amber,
          ],
          legendNames: const ['Java', 'Dart', 'Python', 'Newspeak'],
          outputUserLabels: const [
            'Low',
            'Medium',
            'High',
          ],
          chartOptions: chartOptions,
        );

        break;

      case ExampleEnum.ex50StocksWithNegativesWithUserColors:
        // User-Provided Data (Y values), User-Provided X Labels, User-Provided Data Rows Legends, Data-Based Y Labels, User-Provided Colors,
        //        This shows a bug where negatives go below X axis.
        // If we want the chart to show User-Provided textual Y labels with
        // In each column, adding it's absolute values should add to same number:
        // todo-04 100 would make more sense, to represent 100% of stocks in each category. Also columns should add to the same number?

        chartModel = ChartModel(
          // each column should add to same number. everything else is relative.
          dataRows: const [
            [-9.0, -8.0, -8.0, -5.0, -8.0],
            [-1.0, -2.0, -4.0, -1.0, -1.0],
            [7.0, 8.0, 7.0, 11.0, 9.0],
            [3.0, 2.0, 1.0, 3.0, 3.0],
          ],
          inputUserLabels: const ['Energy', 'Health', 'Finance', 'Chips', 'Oil'],
          legendNames: const [
            '-2% or less',
            '-2% to 0%',
            '0% to +2%',
            'more than +2%',
          ],
          legendColors: const [
            Colors.red,
            Colors.grey,
            Colors.greenAccent,
            Colors.black,
          ],
          chartOptions: chartOptions,
        );
        break;

      case ExampleEnum.ex52AnimalsBySeasonLogarithmicScale:
        chartOptions = const ChartOptions(
          dataContainerOptions: DataContainerOptions(
            yTransform: log10,
            yInverseTransform: inverseLog10,
          ),
        );
        chartModel = ChartModel(
          dataRows: const [
            [10.0, 600.0, 1000000.0],
            [20.0, 1000.0, 1500000.0],
          ],
          inputUserLabels: const ['Wolf', 'Deer', 'Mouse'],
          legendNames: const [
            'Spring',
            'Summer',
          ],
          chartOptions: chartOptions,
        );
        break;

      case ExampleEnum.ex60LabelsIteration1:
        // Example with side effects cannot be simply pasted to your code, as the ExampleSideEffects is private
        // This example shows the result with sufficient space to show all labels
        chartModel = ChartModel(
          dataRows: const [
            [200.0, 190.0, 180.0, 200.0, 250.0, 300.0],
            [300.0, 280.0, 260.0, 240.0, 300.0, 350.0],
          ],
          inputUserLabels: const ['January', 'February', 'March', 'April', 'May', 'June'],
          legendNames: const [
            'Owl count',
            'Hawk count',
          ],
          chartOptions: chartOptions,
        );
        exampleSideEffects = ExampleSideEffects()..leftSqueezeText=''.. rightSqueezeText='';
        break;

      case ExampleEnum.ex60LabelsIteration2:
        // Example with side effects cannot be simply pasted to your code, as the ExampleSideEffects is private
        // This example shows the result with sufficient space to show all labels, but not enough to be horizontal;
        // The iterative layout strategy makes the labels to tilt but show fully.
        chartModel = ChartModel(
          dataRows: const [
            [200.0, 190.0, 180.0, 200.0, 250.0, 300.0],
            [300.0, 280.0, 260.0, 240.0, 300.0, 350.0],
          ],
          inputUserLabels: const ['January', 'February', 'March', 'April', 'May', 'June'],
          legendNames: const [
            'Owl count',
            'Hawk count',
          ],
          chartOptions: chartOptions,
        );
        exampleSideEffects = ExampleSideEffects()..leftSqueezeText='>>'.. rightSqueezeText='<' * 3;
        break;

      case ExampleEnum.ex60LabelsIteration3:
        // Example with side effects cannot be simply pasted to your code, as the ExampleSideEffects is private
        // This example shows the result with sufficient space to show all labels, not even tilted;
        // The iterative layout strategy causes some labels to be skipped.
        chartModel = ChartModel(
          dataRows: const [
            [200.0, 190.0, 180.0, 200.0, 250.0, 300.0],
            [300.0, 280.0, 260.0, 240.0, 300.0, 350.0],
          ],
          inputUserLabels: const ['January', 'February', 'March', 'April', 'May', 'June'],
          legendNames: const [
            'Owl count',
            'Hawk count',
          ],
          chartOptions: chartOptions,
        );
        exampleSideEffects = ExampleSideEffects()..leftSqueezeText='>>'.. rightSqueezeText='<' * 6;
        break;

      case ExampleEnum.ex60LabelsIteration4:
      // Example with side effects cannot be simply pasted to your code, as the ExampleSideEffects is private
      // This example shows the result with sufficient space to show all labels, not even tilted;
      // The iterative layout strategy causes more labels to be skipped.
        chartModel = ChartModel(
          dataRows: const [
            [200.0, 190.0, 180.0, 200.0, 250.0, 300.0],
            [300.0, 280.0, 260.0, 240.0, 300.0, 350.0],
          ],
          inputUserLabels: const ['January', 'February', 'March', 'April', 'May', 'June'],
          legendNames: const [
            'Owl count',
            'Hawk count',
          ],
          chartOptions: chartOptions,
        );
        exampleSideEffects = ExampleSideEffects()..leftSqueezeText='>>'.. rightSqueezeText='<' * 30;
        break;

      case ExampleEnum.ex70AnimalsBySeasonLegendIsColumnStartLooseItemIsRowStartLoose:
        chartOptions = const ChartOptions(
          legendOptions: LegendOptions(
              legendAndItemLayoutEnum: test_options.LegendAndItemLayoutEnum.legendIsColumnStartLooseItemIsRowStartLoose),
        );

        chartModel = ChartModel(
          dataRows: animalsDefaultData,
          inputUserLabels: animalsXUserLabels,
          legendNames: animalsDataRowsLegends,
          chartOptions: chartOptions,
        );
        break;

      case ExampleEnum.ex71AnimalsBySeasonLegendIsColumnStartTightItemIsRowStartTight:
        chartOptions = const ChartOptions(
          legendOptions: LegendOptions(
              legendAndItemLayoutEnum: test_options.LegendAndItemLayoutEnum.legendIsColumnStartTightItemIsRowStartTight),
        );

        chartModel = ChartModel(
          dataRows: animalsDefaultData,
          inputUserLabels: animalsXUserLabels,
          legendNames: animalsDataRowsLegends,
          chartOptions: chartOptions,
        );
        break;

      case ExampleEnum.ex72AnimalsBySeasonLegendIsRowCenterLooseItemIsRowEndLoose:
        chartOptions = const ChartOptions(
          legendOptions: LegendOptions(
              legendAndItemLayoutEnum: test_options.LegendAndItemLayoutEnum.legendIsRowCenterLooseItemIsRowEndLoose),
        );

        chartModel = ChartModel(
          dataRows: animalsDefaultData,
          inputUserLabels: animalsXUserLabels,
          legendNames: animalsDataRowsLegends,
          chartOptions: chartOptions,
        );
        break;

      case ExampleEnum.ex73AnimalsBySeasonLegendIsRowStartTightItemIsRowStartTight:
        chartOptions = const ChartOptions(
          legendOptions: LegendOptions(
              legendAndItemLayoutEnum: LegendAndItemLayoutEnum.legendIsRowStartTightItemIsRowStartTightDefault),
        );

        chartModel = ChartModel(
          dataRows: animalsDefaultData,
          inputUserLabels: animalsXUserLabels,
          legendNames: animalsDataRowsLegends,
          chartOptions: chartOptions,
        );
        break;

      case ExampleEnum.ex74AnimalsBySeasonLegendIsRowStartTightItemIsRowStartTightSecondGreedy:
        chartOptions = const ChartOptions(
          legendOptions: LegendOptions(
              legendAndItemLayoutEnum: test_options.LegendAndItemLayoutEnum.legendIsRowStartTightItemIsRowStartTightSecondGreedy),
        );

        chartModel = ChartModel(
          dataRows: animalsDefaultData,
          inputUserLabels: animalsXUserLabels,
          legendNames: animalsDataRowsLegends,
          chartOptions: chartOptions,
        );
        break;

      case ExampleEnum.ex75AnimalsBySeasonLegendIsRowStartTightItemIsRowStartTightItemChildrenPadded:
        chartOptions = const ChartOptions(
          legendOptions: LegendOptions(
              legendAndItemLayoutEnum:
              test_options.LegendAndItemLayoutEnum.legendIsRowStartTightItemIsRowStartTightItemChildrenPadded),
        );

        chartModel = ChartModel(
          dataRows: animalsDefaultData,
          inputUserLabels: animalsXUserLabels,
          legendNames: animalsDataRowsLegends,
          chartOptions: chartOptions,
        );
        break;

      case ExampleEnum.ex76AnimalsBySeasonLegendIsRowStartTightItemIsRowStartTightItemChildrenAligned:
        chartOptions = const ChartOptions(
          legendOptions: LegendOptions(
              legendAndItemLayoutEnum:
              test_options.LegendAndItemLayoutEnum.legendIsRowStartTightItemIsRowStartTightItemChildrenAligned),
        );

        chartModel = ChartModel(
          dataRows: animalsDefaultData,
          inputUserLabels: animalsXUserLabels,
          legendNames: animalsDataRowsLegends,
          chartOptions: chartOptions,
        );
        break;

      case ExampleEnum.ex800EU12CountriesHistoricalPopulation:
        chartOptions = const ChartOptions(
          legendOptions: LegendOptions(
              legendAndItemLayoutEnum:
              LegendAndItemLayoutEnum.legendIsWrappingRowItemIsRowStartTight),
        );

        chartModel = ChartModel(
          dataRows: const [
            [61.9, 69.8, 73.1, 78.3, 82.2, 83.1],
            [39.0, 42.5, 45.4, 53.7, 58.8, 67.4],
            [37.9, 44.0, 50.6, 56.5, 56.9, 59.2],
            [21.3, 26.0, 30.5, 37.6, 40.8, 47.4],
            [25.0, 40.6, 42.4, 50.0, 49.4, 41.9],
            [27.2, 34.8, 29.5, 35.5, 38.6, 38.2],
            [16.0, 19.9, 18.4, 22.2, 22.4, 19.2],
            [06.7, 08.8, 11.0, 14.0, 15.0, 17.0],
            [07.4, 08.3, 09.1, 09.8, 10.2, 11.4],
            [09.9, 11.2, 09.4, 10.2, 10.2, 10.7],
            [05.8, 06.3, 07.4, 08.3, 08.8, 10.3],
            [03.0, 03.5, 03.9, 04.9, 05.4, 05.4],
          ],
          inputUserLabels: const ['1920', '1940', '1960', '1980', '2000', '2020'],
          legendNames: const [
            'Germany',
            'France',
            'Italy',
            'Spain',
            'Ukraine',
            'Poland',
            'Romania',
            'Netherlands',
            'Belgium',
            'Czechia',
            'Sweden',
            'Slovakia',
          ],
          legendColors: const [
            Colors.black,
            Colors.blue,
            Colors.cyan,
            Colors.brown,
            Colors.yellow,
            Colors.red,
            Colors.lightGreen,
            Colors.deepPurple,
            Colors.black12,
            Colors.black26,
            Colors.black38,
            Colors.black45,
          ],

          chartOptions: chartOptions,
        );

        break;

      case ExampleEnum.ex900ErrorFixUserDataAllZero:

        /// Bug Fix: Add default legend to ChartData constructor AND fix extrapolating util_dart.dart extrapolateValue.
        chartModel = ChartModel(
          dataRows: const [
            [0.0, 0.0, 0.0],
          ],
          // Note: When ChartData is defined,
          //       ALL OF  inputUserLabels,  byRowLegends, byRowColors
          //       must be set by client
          inputUserLabels: const ['Wolf', 'Deer', 'Mouse'],
          legendNames: const [
            'Row 1',
          ],
          legendColors: const [
            Colors.blue,
          ],
          chartOptions: chartOptions,
        );
        break;
    }

    // LineChart or BarChart depending on what is set in environment.
    Widget chartToRun;

    switch (chartType) {
      case ChartType.lineChart:
        SwitchChartViewModel lineChartViewModel = SwitchChartViewModel.lineChartViewModelFactory(
          chartModel: chartModel,
          chartType: chartType,
          // transpose column/row is set in env var CHART_ORIENTATION
          chartOrientation: chartOrientation,
          // stacking/sideBySide is set in env var CHART_STACKING. OLD LineChart always nonStacked
          chartStacking: chartLayouter == ChartLayouter.oldManualLayouter ? ChartStacking.nonStacked : chartStacking,
          chartLayouter: chartLayouter,
          liveOrTesting: LiveOrTesting.testing,
          inputLabelLayoutStrategy: inputLabelLayoutStrategy,
        );

        LineChart lineChart = LineChart(
          // [lineChartViewModel] makes instance of [LineChartRootContainer]
          chartViewModel: lineChartViewModel,
          flutterChartPainter: FlutterChartPainter(),
        );
        chartToRun = lineChart;
        break;
      case ChartType.barChart:
        SwitchChartViewModel barChartViewModel = SwitchChartViewModel.barChartViewModelFactory(
          chartModel: chartModel,
          chartType: chartType,
          chartOrientation: chartOrientation, // transpose column/row is set in env var CHART_ORIENTATION
          chartStacking: chartStacking, // stacking/sideBySide is set in env var CHART_STACKING
          chartLayouter: chartLayouter,
          liveOrTesting: LiveOrTesting.testing,
          inputLabelLayoutStrategy: inputLabelLayoutStrategy,
        );

        BarChart barChart = BarChart(
          // [barChartViewModel] makes instance of [BarChartRootContainer]
          chartViewModel: barChartViewModel,
          flutterChartPainter: FlutterChartPainter(),
        );

        chartToRun = barChart;
        break;
    }
    // Returns the configured LineChart or BarChart that will be added to the [_ExampleHomePageState],
    //   depending on the chart type requested by [requestedExampleToRun]
    return chartToRun;
  }

}

/// Wrapper for the application's state.
///
/// The state consists of two items:
///   - currently running example
///   - all examples list
///   - index of currently running example in all examples list
///
class ExampleRunState {

  ExampleRunState({
    required this.examplesToRun,
  }) {
    if (examplesToRun.isEmpty) {
      throw StateError('At least one example must be specified.');
    }
    runningExample = examplesToRun.first;
    indexOfRunningExampleInExamplesToRun = 0;
  }

  List<ExampleDescriptor> examplesToRun;
  late ExampleDescriptor runningExample;
  late int indexOfRunningExampleInExamplesToRun;

  bool get isConfiguredForSingleExample => examplesToRun.length == 1;
  bool get isConfiguredForMultiExample => !isConfiguredForSingleExample;
  bool get isRunningExampleLast => indexOfRunningExampleInExamplesToRun == examplesToRun.length - 1;
  bool get isFloatingButtonDisabled => isConfiguredForMultiExample && isRunningExampleLast;

  ExampleDescriptor moveToNextExample() {

    if (isRunningExampleLast) {
      // On last example, stay on it.
      // throw StateError('Should never be called when on last example.');
      return runningExample;
    }

    // On not-last example, move to next
    indexOfRunningExampleInExamplesToRun++;
    runningExample = examplesToRun[indexOfRunningExampleInExamplesToRun];

    return runningExample;
  }

}
