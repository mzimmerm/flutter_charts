/// Example app for flutter_charts.
///
/// All classes without prefix in this code are either
///       - from material.dart or
///       - from flutter_charts.dart exports (this library)
///       Also, material.dart exports many dart files, including widgets.dart,
///         so Widget classes are referred to without prefix
import 'package:flutter/material.dart';

// provides: data.dart, random_chart_data.dart, line_chart_options.dart
import 'package:flutter_charts/flutter_charts.dart';
import 'package:flutter_charts/src/util/string_extension.dart' show StringExtension;
import 'package:tuple/tuple.dart' show Tuple2;

import 'src/util/examples_descriptor.dart';
import 'dart:io' show exit;

import 'package:flutter/material.dart' as material show Colors; // any color we can use is from here, more descriptive


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
    exit(0);
  }

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

  /// Stateful widgets must implement the [createState()] method.
  ///
  /// The [createState()] method will typically return the
  /// new state of the widget.
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

/// State of the page. todo-00-now documents this, this is wrong and outdated
///
/// This state object is created in the stateful widget's [MyHomePage] call to
/// [MyHomePage.createState()]. In the rest of the lifecycle,
/// this state object holds on objects which are needed for the chart,
/// - [_lineChartOptions]
/// - [_verticalBarChartOptions]
/// - [_chartData]
/// - [_xContainerLabelLayoutStrategy].
///
/// The first three members are required, as they are, in turn, required by the
/// chart constructors.
///
/// While this home page state object is created only once (hence, the above
/// state's members [_lineChartOptions], [_verticalBarChartOptions], [_chartData],
/// and [_xContainerLabelLayoutStrategy] are created only once, the charts shown
/// in this demo, the [LineChart] and the [VerticalBarChart], are recreated
/// in this object's [build()] method - so, **the chart objects are created over
/// and over**.
///
/// Note: The (each [build()]) recreated chart objects reuse the state's members
/// [_lineChartOptions], [_verticalBarChartOptions], [_chartData],
/// and [_xContainerLabelLayoutStrategy], so they could be considered
/// "expensive to create". This "expensive" not be true (except [_chartData], which
/// may be obtained remotely).
///
/// Note: At the same time, because the [defineOptionsAndData()] is called in
/// this state's [build()] can recreate the the state's members
/// [_lineChartOptions], [_verticalBarChartOptions], [_chartData],
/// and [_xContainerLabelLayoutStrategy], the core of this state object (all members)
/// is effectively recreated on each state's [build()] call.
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

/* todo-00-new remove
  /// Define options for line chart, if used in the demo.
  LineChartOptions _lineChartOptions = LineChartOptions();

  /// Define options for vertical bar chart, if used in the demo
  ChartOptions _verticalBarChartOptions = VerticalBarChartOptions();

  // If you were to use your own extension of
  //   DefaultIterativeLabelLayoutStrategy or LayoutStrategy,
  //   this is how to create an instance.
  // If _xContainerLabelLayoutStrategy
  //   is not set (remains null), the charts instantiate
  //   the DefaultIterativeLabelLayoutStrategy.

  /// Define Layout strategy go labels. todo-null-safety : this can be null here
  LabelLayoutStrategy? _xContainerLabelLayoutStrategy = DefaultIterativeLabelLayoutStrategy(
    options: VerticalBarChartOptions(),
  );

  /// Define data to be displayed
  ChartData _chartData = RandomChartData();
*/

  /// Get the example to run from environment variable.
  Tuple2<ExamplesEnum, ExamplesChartTypeEnum> descriptorOfExampleToRun = requestedExampleToRun();

  /// Default constructor uses member defaults for all options and data.
  _MyHomePageState();
  
  /* unused examples
      case ExamplesEnum.ex_2_1_AnimalCountBySeason:
        // Same as 2_0 above, but this demonstrates order of painting lines on the line chart,
        //   controlled by DataRowsPaintingOrder.
        //  This has benefits when dataRows lines are on top of each other

        _lineChartOptions.dataRowsPaintingOrder = DataRowsPaintingOrder.LastToFirst;
        _chartData = new ChartData();
        _chartData.dataRowsLegends = [
          "Spring",
          "Summer",
          "Fall",
          "Winter",
        ];
        _chartData.dataRows = [
          [10.0, 20.0,  5.0,  30.0,  5.0,  20.0 ],
          [10.0, 20.0,  5.0,  30.0,  5.0,  30.0 ],
          [25.0, 40.0, 20.0,  80.0, 12.0,  90.0 ],
          [25.0, 40.0, 20.0,  80.0, 12.0, 100.0 ],
        ];
        _chartData.xLabels =  ["Wolf", "Deer", "Owl", "Mouse", "Hawk", "Vole"];
        _chartData.assignDataRowsDefaultColors();

        break;

      case ExamplesEnum.ex_4_0_SunnyDaysPerWeek_ExplicitLabelLayoutStrategy:
        // Shows: 
        //   - Explicit use of DefaultIterativeLabelLayoutStrategy
        //   - User defined values and labels.
        //   - Also tests a bug reported by Lonenzo Tejera
        _lineChartOptions = new LineChartOptions();
        _verticalBarChartOptions = new VerticalBarChartOptions();
        _xContainerLabelLayoutStrategy = new DefaultIterativeLabelLayoutStrategy(
          options: _verticalBarChartOptions,
        );
        _chartData = new ChartData();
        _chartData.dataRowsLegends = [
          "Spring",
          "Summer",
        ];
        _chartData.dataRows = [
          [1.0, 2.0, 3.0, 4.0, 6.0],
          [4.0, 3.0, 5.0, 6.0, 1.0],
        ];
        _chartData.xLabels = ["Seattle", "Toronto", "London", "Prague", "Vancouver"];
        _chartData.assignDataRowsDefaultColors();
        // Note: ChartOptions.useUserProvidedYLabels default is still used (false);
        break;  
   */

  void _chartStateChanger() {
    setState(() {
      // This call to setState tells the Flutter framework that
      // something has changed in this State, which causes it to rerun
      // the build method below so that the display can reflect the
      // updated values. If we changed state without calling
      // setState(), then the build method would not be called again,
      // and so nothing would appear to happen.

      /// here we create new random data to illustrate state change
      // defineOptionsAndData();
    });
  }

  /// Builds the widget that is the home page state.
  @override
  Widget build(BuildContext context) {
    // General notes on Windows and sizing

    // The (singleton?) window object is available anywhere using ui.
    // From window, we can get ui.window.devicePixelRatio, and also
    //   ui.Size windowLogicalSize = ui.window.physicalSize / devicePixelRatio
    // Note: Do not use ui.window for any sizing: see
    //       https://github.com/flutter/flutter/issues/11697

    // MediaQueryData mediaQueryData = MediaQuery.of(context);
    // Use MediaQuery.of(context) for any sizing.
    // Note: mediaQueryData can still return 0 size,
    //       but if MediaQuery.of(context) is used, Flutter will guarantee
    //       the build(context) will be called again !
    //        (once non 0 size becomes available)

    // Note: windowLogicalSize = size of the media (screen) in logical pixels
    // Note: same as ui.window.physicalSize / ui.window.devicePixelRatio;
    // ui.Size windowLogicalSize = mediaQueryData.size;

    // devicePixelRatio = number of device pixels for each logical pixel.
    // Note: in all known hardware, size(logicalPixel) > size(devicePixel)
    // Note: this is also, practically, never needed
    // double logicalToDevicePixelSize = mediaQueryData.devicePixelRatio;

    // textScaleFactor = number of font pixels for each logical pixel.
    // Note: with some fontSize, if text scale factor is 1.5
    //       => text font is 1.5x larger than the font size.
    // double fontScale = mediaQueryData.textScaleFactor;

    // To give the LineChart full width and half of height of window.
    // final ui.Size chartLogicalSize =
    //     new Size(windowLogicalSize.width, windowLogicalSize.height / 2);
    //
    // print(" ### Size: ui.window.physicalSize=${ui.window.physicalSize}, "
    //     "windowLogicalSize = mediaQueryData.size = $windowLogicalSize,"
    //     "chartLogicalSize=$chartLogicalSize");

    _ExampleDefiner definer = _ExampleDefiner(descriptorOfExampleToRun);
    Widget chartToRun = definer.createRequestedChart();

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
              // style would need a custom MaterialStateColor extension.
              // style: ButtonStyle(backgroundColor: MyMaterialStateColor.resolve(() => Set(Colors))),
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
                  const Text('>>>'),
                  // LineChart is CustomPaint:
                  // A widget that provides a canvas on which to draw
                  // during the paint phase.

                  // Row -> Expanded -> Chart expands chart horizontally <-->
                  Expanded(
                    // #### Core chart
                    child: chartToRun, // verticalBarChart, lineChart
                  ),
                  const Text('<<'),
                  // labels fit horizontally
                  // new Text('<<<<<<'), // default, labels tilted, all present
                  // new Text('<<<<<<<<<<<'),   // labels skipped (shows 3 labels, legend present)
                  // new Text('<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<'), // labels skipped (shows 2 labels, legend present but text vertical)
                  // new Text('<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<'),// labels do overlap, legend NOT present
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

/// Defines which example to run.
///
/// Collects all 'variables' that are needed for each example: chart data, labels, colors and so on.
/// Makes available the verticalBarChart and the lineChart constructed from the 'variables'.
class _ExampleDefiner {
  Tuple2<ExamplesEnum, ExamplesChartTypeEnum> descriptorOfExampleToRun;

  _ExampleDefiner(this.descriptorOfExampleToRun);

  Widget createRequestedChart() {

    // To use a specific, client defined extension of DefaultIterativeLabelLayoutStrategy or LayoutStrategy,
    //   just create the extension instance similar to the DefaultIterativeLabelLayoutStrategy below.
    // If xContainerLabelLayoutStrategy is not set (remains null), the charts instantiate
    //   the DefaultIterativeLabelLayoutStrategy as we do here.
    LabelLayoutStrategy? xContainerLabelLayoutStrategy;
    
    ChartData chartData;
    
    ChartOptions chartOptions;

    ExamplesEnum exampleComboToRun = descriptorOfExampleToRun.item1;
    ExamplesChartTypeEnum chartTypeToShow = descriptorOfExampleToRun.item2;

    // Set chartOptions defaults here, so we do not repeat it in every example section. 
    // Some sections may override this default.
    switch (chartTypeToShow) {
      case ExamplesChartTypeEnum.lineChart:
        chartOptions = LineChartOptions();
        // example of overwriting defaults of LineChartOptions:
        //    chartOptions = LineChartOptions(
        //      chartOptions: const ChartOptions(
        //        labelCommonOptions: LabelCommonOptions(
        //          labelTextColor: material.Colors.yellow,
        //        ),
        //      ),
        //      hotspotInnerPaintColor: material.Colors.blue,
        //    );
        break;
      case ExamplesChartTypeEnum.verticalBarChart:
        chartOptions = VerticalBarChartOptions();
        break;
    }

    switch (exampleComboToRun) {
      
      case ExamplesEnum.ex10RandomData:
        chartData = RandomChartData();
        break;

      case ExamplesEnum.ex20RandomDataWithLabelLayoutStrategy:
        xContainerLabelLayoutStrategy = DefaultIterativeLabelLayoutStrategy(
          options: chartOptions,
        );
        chartData = RandomChartData();
        break;

      case ExamplesEnum.ex30AnimalsBySeasonWithLabelLayoutStrategy:
      // Shows explicit use of DefaultIterativeLabelLayoutStrategy with Random values and labels.
      // The xContainerLabelLayoutStrategy, if set to null or not set at all, defaults to DefaultIterativeLabelLayoutStrategy
      // Clients can also create their own LayoutStrategy.
        xContainerLabelLayoutStrategy = DefaultIterativeLabelLayoutStrategy(
          options: chartOptions,
        );
        chartData = ChartData();
        chartData.dataRowsLegends = [
          'Spring',
          'Summer',
          'Fall',
          'Winter',
        ];
        chartData.dataRows = [
          [10.0, 20.0, 5.0, 30.0, 5.0, 20.0],
          [30.0, 60.0, 16.0, 100.0, 12.0, 120.0],
          [25.0, 40.0, 20.0, 80.0, 12.0, 90.0],
          [12.0, 30.0, 18.0, 40.0, 10.0, 30.0],
        ];
        chartData.xLabels = ['Wolf', 'Deer', 'Owl', 'Mouse', 'Hawk', 'Vole'];
        chartData.assignDataRowsDefaultColors();
        break;

      case ExamplesEnum.ex31AnimalsBySeasonNoLabelsShown:
        // Set non-default chart options to show no labels
        switch (chartTypeToShow) {
          case ExamplesChartTypeEnum.lineChart:
            chartOptions = LineChartOptions.noLabels();
            break;
          case ExamplesChartTypeEnum.verticalBarChart:
            chartOptions = VerticalBarChartOptions.noLabels();
            break;
        }
        chartData = ChartData();
        chartData.dataRowsLegends = [
          'Spring',
          'Summer',
          'Fall',
          'Winter',
        ];
        chartData.dataRows = [
          [10.0, 20.0, 5.0, 30.0, 5.0, 20.0],
          [30.0, 60.0, 16.0, 100.0, 12.0, 120.0],
          [25.0, 40.0, 20.0, 80.0, 12.0, 90.0],
          [12.0, 30.0, 18.0, 40.0, 10.0, 30.0],
        ];
        chartData.xLabels = ['Wolf', 'Deer', 'Owl', 'Mouse', 'Hawk', 'Vole'];
        chartData.assignDataRowsDefaultColors();
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

      // Set non-default chart options to show no labels in this example
        switch (chartTypeToShow) {
          case ExamplesChartTypeEnum.lineChart:
            chartOptions = LineChartOptions(
              chartOptions: const ChartOptions(
                yContainerOptions: YContainerOptions(useUserProvidedYLabels: true), // use Y labels below
              ),
            );
            break;
          case ExamplesChartTypeEnum.verticalBarChart:
            chartOptions = VerticalBarChartOptions(
              chartOptions: const ChartOptions(
                yContainerOptions: YContainerOptions(useUserProvidedYLabels: true), // use Y labels below
              ),
            );
            break;
        }
        chartData = ChartData();
        chartData.yLabels = [
          'Low',
          'Medium',
          'High',
        ];

        chartData.dataRowsLegends = ['Java', 'Dart', 'Python', 'Newspeak'];
        chartData.dataRows = [
          [9.0, 4.0, 3.0, 9.0],
          [7.0, 6.0, 7.0, 6.0],
          [4.0, 9.0, 6.0, 8.0],
          [3.0, 9.0, 10.0, 1.0],
        ];
        chartData.xLabels = ['Speed', 'Readability', 'Level of Novel', 'Usage'];
        chartData.dataRowsColors = [
          Colors.blue,
          Colors.yellow,
          Colors.green,
          Colors.amber,
        ];
        
        break;

      case ExamplesEnum.ex50StocksWithNegativesWithUserColors:
        // User-Provided Data (Y values), User-Provided X Labels, User-Provided Data Rows Legends, Data-Based Y Labels, User-Provided Colors,
        //        This shows a bug where negatives go below X axis.
        // If we want the chart to show User-Provided textual Y labels with
        // In each column, adding it's absolute values should add to same number:
        // todo-11-examples 100 would make more sense, to represent 100% of stocks in each category.

        chartData = ChartData();
        chartData.dataRowsLegends = [
          '-2% or less',
          '-2% to 0%',
          '0% to +2%',
          'more than +2%',
        ];
        // each column should add to same number. everything else is relative. todo-11-examples maybe no need to add to same number.
        chartData.dataRows = [
          [-9.0, -8.0, -8.0, -5.0, -8.0],
          [-1.0, -2.0, -4.0, -1.0, -1.0],
          [7.0, 8.0, 7.0, 11.0, 9.0],
          [3.0, 2.0, 1.0, 3.0, 3.0],
        ];
        chartData.xLabels = ['Energy', 'Health', 'Finance', 'Chips', 'Oil'];
        chartData.dataRowsColors = [
          Colors.red,
          Colors.grey,
          Colors.greenAccent,
          Colors.black,
        ];
        break;
    }

    // LineChart or VerticalBarChart depending on what is set in environment.
    Widget chartToRun;
    
    switch (chartTypeToShow) {
      case ExamplesChartTypeEnum.lineChart:
      // construct line chart
        LineChartTopContainer lineChartContainer = LineChartTopContainer(
          chartData: chartData,
          chartOptions: chartOptions,
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
        VerticalBarChartTopContainer verticalBarChartContainer = VerticalBarChartTopContainer(
          chartData: chartData,
          chartOptions: chartOptions,
          xContainerLabelLayoutStrategy: xContainerLabelLayoutStrategy,
        );

        // construct bar chart
        VerticalBarChart verticalBarChart = VerticalBarChart(
          painter: VerticalBarChartPainter(
            verticalBarChartContainer: verticalBarChartContainer,
          ),
        );

        chartToRun = verticalBarChart;
        break;
    }
    // Returns a configured LineChart or VerticalBarChart
    return chartToRun;
  }
}
