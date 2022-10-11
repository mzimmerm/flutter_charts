/// Example app for flutter_charts.
///
/// All classes without prefix in this code are either
/// - from material.dart or
/// - from flutter_charts.dart exports (this library)
/// Also, material.dart exports many dart files, including widgets.dart,
/// so Widget classes are referred to without prefix
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tuple/tuple.dart' show Tuple2;
import 'dart:io' as io show exit;

// provides: data.dart, random_chart_data.dart, line_chart_options.dart
import 'package:flutter_charts/flutter_charts.dart';
import 'package:flutter_charts/src/util/string_extension.dart' show StringExtension;

import 'src/util/examples_descriptor.dart';

import 'dart:ui' as ui show Color;


// import 'package:flutter/material.dart' as material show Colors; // any color we can use is from here, more descriptive

/// Example of simple line chart usage in an application.
///
/// Library note: This file is on the same level as _lib_, so everything from _lib_ must
/// be imported using the "package:" scheme, e.g.
/// ```dart
///    import 'package:flutter_charts/flutter_charts.dart';
/// ```
void main() {
  // runApp is function (not method) in PROJ/packages/flutter/lib/src/widgets/binding.dart.
  //
  // Why we do not have to import binding.dart?
  //
  // In brief, because it is imported through another file, material.dart.
  //
  // Longer reason
  //
  //      - Because Any Flutter app must have:
  //        1) main() { runApp(MyApp()) } // entry point
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
  //  in MyApp is achieved this way:
  //    1) This file (example/lib/main.dart) has
  //        - import 'package:flutter/material.dart' (references PROJ/packages/flutter/lib/material.dart)
  //    2) material.dart has
  //        - export 'widgets.dart'; (references same dir        PROJ/packages/flutter/lib/widgets.dart)
  //    3) widgets.dart has
  //        - export 'src/widgets/binding.dart'; (references dir PROJ/packages/flutter/lib/src/widgets/binding.dart)
  //    4) binding.dart has
  //        - the runApp() function
  //
  // This process achieves importing (heh via exports) the file
  //    packages/flutter/lib/src/widgets/binding.dart
  //    which has the runApp() function.
  //
  var exampleComboToRun = requestedExampleToRun();
  if (!ExamplesDescriptor().exampleComboIsAllowed(exampleComboToRun)) {
    // Better: SystemChannels.platform.invokeMethod('SystemNavigator.pop');
    io.exit(0);
  }
  
  // If using a client-specific font, such as GoogleFonts, this is needed, in conjunction with 
  // installing the fonts in pubspec.yaml. 
  // But these 2 additions are needed ONLY in integration tests. App works without those 2 additions.
  GoogleFonts.config.allowRuntimeFetching = false;

  runApp(const MyApp());
}

/// Pull values of environment variables named ['EXAMPLE_TO_RUN'] and ['CHART_TYPE_TO_SHOW']
///   passed to the program by `--dart-define` options.
///
/// Converts the dart-define(d) environment variables passed to 'flutter run', 'flutter test', or 'flutter driver',
///   to a tuple of enums which describe the example to run, and the chart type to show.
///
Tuple2<ExamplesEnum, ExamplesChartTypeEnum> requestedExampleToRun() {
  // Pickup what example to run, and which chart to show (line, vertical bar).
  const String exampleToRunStr = String.fromEnvironment('EXAMPLE_TO_RUN', defaultValue: 'ex10RandomData');
  ExamplesEnum exampleComboToRun = exampleToRunStr.asEnum(ExamplesEnum.values);

  const String chartTypeToShowStr = String.fromEnvironment('CHART_TYPE_TO_SHOW', defaultValue: 'lineChart');
  ExamplesChartTypeEnum chartTypeToShow = chartTypeToShowStr.asEnum(ExamplesChartTypeEnum.values);

  return Tuple2(exampleComboToRun, chartTypeToShow);
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  /// Builds the widget which becomes the root of the application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Charts Demo Title',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Flutter Charts Demo'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  // This widget is the home page of your application. It is stateful,
  // meaning that it has a State object (defined below) that contains
  // fields that affect how it looks.

  // This class is the configuration for the state. It holds the
  // values (in this case the title) provided by the parent (in this
  // case the App widget) and used by the build method of the State.
  // Fields in a Widget subclass are always marked "final".

  final String title;

  /// Stateful widgets must implement the [createState] method.
  ///
  /// The [createState] method will typically return the
  /// new state of the widget.
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

/// This state object is created in the stateful widget's [MyHomePage] call to
/// [MyHomePage.createState].
///
/// In the rest of the lifecycle, this state object holds on one object,
/// - [descriptorOfExampleToRun]
///
/// The rest of the objects (options, data, etc) are created during the build.
///
/// While this home page state object is created only once (hence, the above
/// state's member [descriptorOfExampleToRun], is created only once, the charts shown
/// in this demo, the [LineChart] and the [VerticalBarChart], are recreated
/// in this object's [build] method - so, **the chart objects are created over
/// and over**.
///
/// Note: The (each [build]) recreated chart objects reuse the state's members
/// [descriptorOfExampleToRun], so this could be considered
/// "expensive to create".
///
/// Note: At the same time, because the this state's [build] calls
///    _ExampleDefiner definer = _ExampleDefiner(descriptorOfExampleToRun);
//     Widget chartToRun = definer.createRequestedChart();
/// recreates lineChartOptions, verticalBarChartOptions, chartData,
/// and xContainerLabelLayoutStrategy, the core of this state object (all members)
/// is effectively recreated on each state's [build] call.
///
class _MyHomePageState extends State<MyHomePage> {
  // Note (on null safety):
  //     To be able to have non-nullable types on members
  //     such as _lineChartOptions (and all others here), 2 things need be done:
  //   1. The member must be initialized with some non-null value,
  //      either in the definition or in constructor initializer list
  //   2. If a member is passed to a constructor (see  _MyHomePageState.fromOptionsAndData)
  //      the constructor value must still be marked "required".
  //      This serves as a lasso that enforces callers to set the non-null.
  //      But why Dart would not use the initialized value?

  /// Get the example to run from environment variable.
  Tuple2<ExamplesEnum, ExamplesChartTypeEnum> descriptorOfExampleToRun = requestedExampleToRun();

  /// Default constructor uses member defaults for all options and data.
  _MyHomePageState();

  void _chartStateChanger() {
    setState(() {
      // This call to setState tells the Flutter framework that
      // something has changed in this State, which causes it to rerun
      // the build method below so that the display can reflect the
      // updated values. If we changed state without calling
      // setState(), then the build method would not be called again,
      // and so nothing would appear to happen.

      /// here we create new random data to illustrate state change
      // _ExampleDefiner.createRequestedChart();
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
    _ExampleDefiner definer = _ExampleDefiner(descriptorOfExampleToRun);
    Widget chartToRun = definer.createRequestedChart();
    _ExampleSideEffects exampleSpecific = definer.exampleSideEffects;

    // [MyHomePage] extends [StatefulWidget].
    // [StatefulWidget] calls build(context) every time setState is called,
    // for instance as done by the _chartStateChanger method above.
    // The Flutter framework has been optimized to make rerunning
    // build methods fast, so that you can just rebuild anything that
    // needs updating rather than having to individually change
    // instances of widgets.
    return Scaffold(
      appBar: AppBar(
        // Here we take the value from the MyHomePage object that
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
                    child: chartToRun, // verticalBarChart, lineChart
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
        onPressed: _chartStateChanger,
        tooltip: 'New Random Data',
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

/// The enabler of widget changes in the main test app by the code in [_ExampleDefiner].
/// 
/// This enables support for each example ability to manipulate it's environment
/// (by environment we mean the widgets in main.dart outside the chart).
/// 
/// Some examples need to change widgets of the main test app that are not part of the Chart.
/// For example, some test examples need to run in an increasingly 'squeezed' space available for the chart,
/// to test label changes with available space.
/// 
/// This class allows to carry such changes from the [_ExampleDefiner] to the widgets in the main app.
/// 
class _ExampleSideEffects {
  String leftSqueezeText = '>>>';
  String rightSqueezeText = '<<';
}

/// Defines which example to run.
///
/// Collects all 'variables' that are needed for each example: chart data, labels, colors and so on.
/// Makes available the verticalBarChart and the lineChart constructed from the 'variables'.
class _ExampleDefiner {

  /// Construct the definer object for the example.
  _ExampleDefiner(this.descriptorOfExampleToRun);

  /// Tuple which describes the example
  Tuple2<ExamplesEnum, ExamplesChartTypeEnum> descriptorOfExampleToRun;

  /// Support for each example manipulate it's environment - the widgets in main.dart outside the chart.
  _ExampleSideEffects exampleSideEffects = _ExampleSideEffects();

  /// Creates the example chart with name given in [exampleComboToRun] 
  /// through command line parameter --dart-define.
  ///
  /// Example assumes Android emulator is running or an Android/iOS device is connected:
  /// - Running:
  ///   ```sh
  ///     flutter run example/lib/main.dart \
  ///       --dart-define=EXAMPLE_TO_RUN=ex10RandomData \
  ///       --dart-define=CHART_TYPE_TO_SHOW=lineChart
  ///   ```
  /// will set [exampleComboToRun] to a concrete Tuple of [ExamplesEnum] and [ExamplesChartTypeEnum], 
  /// such as `Tuple(ex10RandomData, lineChart)`
  Widget createRequestedChart() {
    // Example requested to run
    ExamplesEnum exampleComboToRun = descriptorOfExampleToRun.item1;
    ExamplesChartTypeEnum chartTypeToShow = descriptorOfExampleToRun.item2;

    // Declare chartData; the data object will be different in every examples.
    ChartData chartData;
    
    // Create chartOptions defaults here, so we do not repeat it in every example section,
    //   unless specific examples need to override this chartOptions default.
    ChartOptions chartOptions = const ChartOptions();

    // Declare a null xContainerLabelLayoutStrategy.
    // To use a specific, client defined extension of DefaultIterativeLabelLayoutStrategy or LayoutStrategy,
    //   just create the extension instance similar to the DefaultIterativeLabelLayoutStrategy below.
    // If xContainerLabelLayoutStrategy is not set in an example (remains null), the charts instantiate
    //   a DefaultIterativeLabelLayoutStrategy.
    LabelLayoutStrategy? xContainerLabelLayoutStrategy;
    
    /// Main switch that includes code to all examples.
    /// The example which [ExamplesEnum] and [ExamplesChartTypeEnum] is passed in the combo is returned.
    /// Each example can also generate side effects in [exampleSideEffects], which allow the code in this 
    /// [createRequestedChart] method to influence the returned chart's surrounding widgets in the main app.
    switch (exampleComboToRun) {
      case ExamplesEnum.ex10RandomData:
        // Example shows a demo-type data generated randomly in a range.
        chartData = RandomChartData.generated(chartOptions: chartOptions);
        break;

      case ExamplesEnum.ex30AnimalsBySeasonWithLabelLayoutStrategy:
        // Example shows an explicit use of the DefaultIterativeLabelLayoutStrategy.
        // The xContainerLabelLayoutStrategy, if set to null or not set at all, 
        //   defaults to DefaultIterativeLabelLayoutStrategy
        // Clients can also create their own LayoutStrategy.
        xContainerLabelLayoutStrategy = DefaultIterativeLabelLayoutStrategy(
          options: chartOptions,
        );
        chartData = ChartData(
          dataRows: const [
            [10.0, 20.0, 5.0, 30.0, 5.0, 20.0],
            [30.0, 60.0, 16.0, 100.0, 12.0, 120.0],
            [25.0, 40.0, 20.0, 80.0, 12.0, 90.0],
            [12.0, 30.0, 18.0, 40.0, 10.0, 30.0],
          ],
          xUserLabels: const ['Wolf', 'Deer', 'Owl', 'Mouse', 'Hawk', 'Vole'],
          dataRowsLegends: const [
            'Spring',
            'Summer',
            'Fall',
            'Winter',
          ],
          chartOptions: chartOptions,
        );
        // chartData.dataRowsDefaultColors(); // if not set, called in constructor
        break;

      case ExamplesEnum.ex31SomeNegativeValues:
        // Example shows a mix of positive and negative data values.
        chartData = ChartData(
          dataRows: const [
            [2000.0, 1800.0, 2200.0, 2300.0, 1700.0, 1800.0],
            [1100.0, 1000.0, 1200.0, 800.0, 700.0, 800.0],
            [0.0, 100.0, -200.0, 150.0, -100.0, -150.0],
            [-800.0, -400.0, -300.0, -400.0, -200.0, -250.0],
          ],
          xUserLabels: const ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun'],
          dataRowsLegends: const [
            'Big Corp',
            'Medium Corp',
            'Print Shop',
            'Bar',
          ],
          chartOptions: chartOptions,
        );
        break;

      case ExamplesEnum.ex32AllPositiveYsYAxisStartsAbove0:
        // Example shows how to create ChartOptions instance 
        //   which will request to start Y axis at data minimum.
        // Even though startYAxisAtDataMinRequested is set to true, this will not be granted on bar chart,
        //   as it does not make sense there.
        chartOptions = const ChartOptions(
          dataContainerOptions: DataContainerOptions(
            startYAxisAtDataMinRequested: true,
          ),
        );
        chartData = ChartData(
          dataRows: const [
            [20.0, 25.0, 30.0, 35.0, 40.0, 20.0],
            [35.0, 40.0, 20.0, 25.0, 30.0, 20.0],
          ],
          xUserLabels: const ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun'],
          dataRowsLegends: const [
            'Off zero 1',
            'Off zero 2',
          ],
          chartOptions: chartOptions,
        );
        break;

      case ExamplesEnum.ex33AllNegativeYsYAxisEndsBelow0:
        // Example shows how to create ChartOptions instance
        //   which will request to end Y axis at maximum data (as all data negative).
        // Even though startYAxisAtDataMinRequested is set to true, this will not be granted on bar chart,
        //   as it does not make sense there.
        chartOptions = const ChartOptions(
          dataContainerOptions: DataContainerOptions(
            startYAxisAtDataMinRequested: true,
          ),
        );
        chartData = ChartData(
          dataRows: const [
            [-20.0, -25.0, -30.0, -35.0, -40.0, -20.0],
            [-35.0, -40.0, -20.0, -25.0, -30.0, -20.0],
          ],
          xUserLabels: const ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun'],
          dataRowsLegends: const [
            'Off zero 1',
            'Off zero 2',
          ],
          chartOptions: chartOptions,
        );
        break;
      case ExamplesEnum.ex34OptionsDefiningUserTextStyleOnLabels:
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
        chartData = ChartData(
          dataRows: const [
            [20.0, 25.0, 30.0, 35.0, 40.0, 20.0],
            [35.0, 40.0, 20.0, 25.0, 30.0, 20.0],
          ],
          xUserLabels: const ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun'],
          dataRowsLegends: const [
            'Font Test Series1',
            'Font Test Series2',
          ],
          chartOptions: chartOptions,
        );
        break;
      case ExamplesEnum.ex35AnimalsBySeasonNoLabelsShown:
        // Set chart options to show no labels
        chartOptions = const ChartOptions.noLabels();

        chartData = ChartData(
          dataRows: const [
            [10.0, 20.0, 5.0, 30.0, 5.0, 20.0],
            [30.0, 60.0, 16.0, 100.0, 12.0, 120.0],
            [25.0, 40.0, 20.0, 80.0, 12.0, 90.0],
            [12.0, 30.0, 18.0, 40.0, 10.0, 30.0],
          ],
          xUserLabels: const ['Wolf', 'Deer', 'Owl', 'Mouse', 'Hawk', 'Vole'],
          dataRowsLegends: const [
            'Spring',
            'Summer',
            'Fall',
            'Winter',
          ],
          chartOptions: chartOptions,
        );
        break;

      case ExamplesEnum.ex40LanguagesWithYOrdinalUserLabelsAndUserColors:
        // User-Provided Data (Y values), User-Provided X Labels, User-Provided Data Rows Legends, User-Provided Y Labels, User-Provided Colors
        // This example shows user defined Y Labels that derive order from data.
        //   When setting Y labels by user, the dataRows value scale
        //   is irrelevant. User can use for example interval <0, 1>,
        //   <0, 10>, or any other, even negative ranges. Here we use <0-10>.
        //   The only thing that matters is  the relative values in the data Rows.
        // Current implementation sets
        //   the minimum of dataRows range (1.0 in this example)
        //     on the level of the first Y Label ("Low" in this example),
        //   and the maximum  of dataRows range (10.0 in this example)
        //     on the level of the last Y Label ("High" in this example).
        chartData = ChartData(
          dataRows: const [
            [9.0, 4.0, 3.0, 9.0],
            [7.0, 6.0, 7.0, 6.0],
            [4.0, 9.0, 6.0, 8.0],
            [3.0, 9.0, 10.0, 1.0],
          ],
          xUserLabels: const ['Speed', 'Readability', 'Level of Novel', 'Usage'],
          dataRowsColors: const [
            Colors.blue,
            Colors.yellow,
            Colors.green,
            Colors.amber,
          ],
          dataRowsLegends: const ['Java', 'Dart', 'Python', 'Newspeak'],
          yUserLabels: const [
            'Low',
            'Medium',
            'High',
          ],
          chartOptions: chartOptions,
        );

        break;

      case ExamplesEnum.ex50StocksWithNegativesWithUserColors:
        // User-Provided Data (Y values), User-Provided X Labels, User-Provided Data Rows Legends, Data-Based Y Labels, User-Provided Colors,
        //        This shows a bug where negatives go below X axis.
        // If we want the chart to show User-Provided textual Y labels with
        // In each column, adding it's absolute values should add to same number:
        // todo-04-examples 100 would make more sense, to represent 100% of stocks in each category. Also columns should add to the same number?

        chartData = ChartData(
          // each column should add to same number. everything else is relative.
          dataRows: const [
            [-9.0, -8.0, -8.0, -5.0, -8.0],
            [-1.0, -2.0, -4.0, -1.0, -1.0],
            [7.0, 8.0, 7.0, 11.0, 9.0],
            [3.0, 2.0, 1.0, 3.0, 3.0],
          ],
          xUserLabels: const ['Energy', 'Health', 'Finance', 'Chips', 'Oil'],
          dataRowsLegends: const [
            '-2% or less',
            '-2% to 0%',
            '0% to +2%',
            'more than +2%',
          ],
          dataRowsColors: const [
            Colors.red,
            Colors.grey,
            Colors.greenAccent,
            Colors.black,
          ],
          chartOptions: chartOptions,
        );
        break;

      case ExamplesEnum.ex52AnimalsBySeasonLogarithmicScale:
        chartOptions = const ChartOptions(
          dataContainerOptions: DataContainerOptions(
            yTransform: log10,
            yInverseTransform: inverseLog10,
          ),
        );
        chartData = ChartData(
          dataRows: const [
            [10.0, 600.0, 1000000.0],
            [20.0, 1000.0, 1500000.0],
          ],
          xUserLabels: const ['Wolf', 'Deer', 'Mouse'],
          dataRowsLegends: const [
            'Spring',
            'Summer',
          ],
          chartOptions: chartOptions,
        );
        break;

      case ExamplesEnum.ex60LabelsIteration1:
        // Example with side effects cannot be simply pasted to your code, as the _ExampleSideEffects is private
        // This example shows the result with sufficient space to show all labels
        chartData = ChartData(
          dataRows: const [
            [200.0, 190.0, 180.0, 200.0, 250.0, 300.0],
            [300.0, 280.0, 260.0, 240.0, 300.0, 350.0],
          ],
          xUserLabels: const ['January', 'February', 'March', 'April', 'May', 'June'],
          dataRowsLegends: const [
            'Owl count',
            'Hawk count',
          ],
          chartOptions: chartOptions,
        );
        exampleSideEffects = _ExampleSideEffects()..leftSqueezeText=''.. rightSqueezeText='';
        break;

      case ExamplesEnum.ex60LabelsIteration2:
        // Example with side effects cannot be simply pasted to your code, as the _ExampleSideEffects is private
        // This example shows the result with sufficient space to show all labels, but not enough to be horizontal;
        // The iterative layout strategy makes the labels to tilt but show fully.
        chartData = ChartData(
          dataRows: const [
            [200.0, 190.0, 180.0, 200.0, 250.0, 300.0],
            [300.0, 280.0, 260.0, 240.0, 300.0, 350.0],
          ],
          xUserLabels: const ['January', 'February', 'March', 'April', 'May', 'June'],
          dataRowsLegends: const [
            'Owl count',
            'Hawk count',
          ],
          chartOptions: chartOptions,
        );
        exampleSideEffects = _ExampleSideEffects()..leftSqueezeText='>>'.. rightSqueezeText='<' * 3;
        break;

      case ExamplesEnum.ex60LabelsIteration3:
        // Example with side effects cannot be simply pasted to your code, as the _ExampleSideEffects is private
        // This example shows the result with sufficient space to show all labels, not even tilted;
        // The iterative layout strategy causes some labels to be skipped.
        chartData = ChartData(
          dataRows: const [
            [200.0, 190.0, 180.0, 200.0, 250.0, 300.0],
            [300.0, 280.0, 260.0, 240.0, 300.0, 350.0],
          ],
          xUserLabels: const ['January', 'February', 'March', 'April', 'May', 'June'],
          dataRowsLegends: const [
            'Owl count',
            'Hawk count',
          ],
          chartOptions: chartOptions,
        );
        exampleSideEffects = _ExampleSideEffects()..leftSqueezeText='>>'.. rightSqueezeText='<' * 6;
        break;

      case ExamplesEnum.ex60LabelsIteration4:
      // Example with side effects cannot be simply pasted to your code, as the _ExampleSideEffects is private
      // This example shows the result with sufficient space to show all labels, not even tilted;
      // The iterative layout strategy causes more labels to be skipped.
        chartData = ChartData(
          dataRows: const [
            [200.0, 190.0, 180.0, 200.0, 250.0, 300.0],
            [300.0, 280.0, 260.0, 240.0, 300.0, 350.0],
          ],
          xUserLabels: const ['January', 'February', 'March', 'April', 'May', 'June'],
          dataRowsLegends: const [
            'Owl count',
            'Hawk count',
          ],
          chartOptions: chartOptions,
        );
        exampleSideEffects = _ExampleSideEffects()..leftSqueezeText='>>'.. rightSqueezeText='<' * 30;
        break;

      case ExamplesEnum.ex900ErrorFixUserDataAllZero:

        /// Currently, setting [ChartDate.dataRows] requires to also set all of
        /// [chartData.xUserLabels], [chartData.dataRowsLegends], [chartData.dataRowsColors]
        // Fix was: Add default legend to ChartData constructor AND fix scaling util_dart.dart scaleValue.
        chartData = ChartData(
          dataRows: const [
            [0.0, 0.0, 0.0],
          ],
          // Note: When ChartData is defined,
          //       ALL OF  xUserLabels,  dataRowsLegends, dataRowsColors
          //       must be set by client
          xUserLabels: const ['Wolf', 'Deer', 'Mouse'],
          dataRowsLegends: const [
            'Row 1',
          ],
          dataRowsColors: const [
            Colors.blue,
          ],
          chartOptions: chartOptions,
        );
        break;
    }

    // LineChart or VerticalBarChart depending on what is set in environment.
    Widget chartToRun;

    switch (chartTypeToShow) {
      case ExamplesChartTypeEnum.lineChart:
        LineChartRootContainer lineChartContainer = LineChartRootContainer(
          chartData: chartData,
          xContainerLabelLayoutStrategy: xContainerLabelLayoutStrategy,
        );

        LineChart lineChart = LineChart(
          painter: LineChartPainter(
            lineChartContainer: lineChartContainer,
          ),
        );
        chartToRun = lineChart;
        break;
      case ExamplesChartTypeEnum.verticalBarChart:
        VerticalBarChartRootContainer verticalBarChartContainer = VerticalBarChartRootContainer(
          chartData: chartData,
          xContainerLabelLayoutStrategy: xContainerLabelLayoutStrategy,
        );

        VerticalBarChart verticalBarChart = VerticalBarChart(
          painter: VerticalBarChartPainter(
            verticalBarChartContainer: verticalBarChartContainer,
          ),
        );

        chartToRun = verticalBarChart;
        break;
    }
    // Returns the configured LineChart or VerticalBarChart that will be added to the [_MyHomePageState],
    //   depending on the chart type requested by [requestedExampleToRun]
    return chartToRun;
  }
}
