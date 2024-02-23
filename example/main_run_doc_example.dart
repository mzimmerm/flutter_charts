import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:logger/logger.dart';

import 'package:flutter_charts/src/chart/cartesian/chart_type/line/chart.dart';
import 'package:flutter_charts/src/chart/painter.dart';
import 'package:flutter_charts/src/chart/model/data_model.dart';
import 'package:flutter_charts/src/switch_view_model/view_model.dart';
import 'package:flutter_charts/src/switch_view_model/auto_layout/line/view_model.dart';
import 'package:flutter_charts/src/chart/options.dart';
import 'package:flutter_charts/src/morphic/container/chart_support/chart_style.dart';

/// Example app for flutter_charts, which shows one concrete chart,
/// the widget returned from [chartToRun].
///
/// Intended as a simple app that runs example code from README.md,
/// by replacing the contents of [chartToRun] with example code pasted from README.md.
///
/// Note that there is another example app 'test_main.dart' in 'lib/test/src/test_main.dart' which is similar,
/// but it's [chartToRun] allows to run multiple examples.
///
void main() {
  // Set logging level. There should be some kind of configuration for this.
  Logger.level = Level.warning;

  // If using a client-specific font, such as GoogleFonts, this is needed, in conjunction with
  // installing the fonts in pubspec.yaml.
  // But these 2 additions are needed ONLY in integration tests. App works without those 2 additions.
  GoogleFonts.config.allowRuntimeFetching = false;

  runApp(const ExampleApp());
}

/// Returns a [FlutterChart] widget that is plugged in the [ExampleHomePageState]
/// of this sample app.
///
/// This code can be replaced with any sample code snippets in README.md.
/// See README.md headings named such as
/// ```md
///   ex10RandomData_lineChart
/// ```
Widget chartToRun() {
  // Example requested to run
  ChartType chartType = ChartType.lineChart;
  ChartOrientation chartOrientation = ChartOrientation.column;
  ChartStacking chartStacking = ChartStacking.nonStacked;

  // Declare chartModel; the data object will be different in every examples.
  ChartModel chartModel;

  // Create chartOptions defaults here, so we do not repeat it in every example section,
  //   unless specific examples need to override this chartOptions default.
  ChartOptions chartOptions = const ChartOptions(
           legendOptions: LegendOptions(
              legendAndItemLayoutEnum:
              LegendAndItemLayoutEnum.legendIsWrappingRowItemIsRowStartTight),

  );

  // Using a null inputLabelLayoutStrategy.
  // To use a specific, client defined extension of DefaultIterativeLabelLayoutStrategy or LayoutStrategy,
  //   just create the extension instance similar to the DefaultIterativeLabelLayoutStrategy below.
  // If inputLabelLayoutStrategy is not set in an example (remains null), the charts instantiate
  //   a DefaultIterativeLabelLayoutStrategy.
  // LabelLayoutStrategy? inputLabelLayoutStrategy;

 //  chartOptions = const ChartOptions();

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

  // LineChart or BarChart depending on what is set in environment.
  Widget chartToRun;

  // Uses newChartLayouter
  SwitchChartViewModel lineChartViewModel = SwitchLineChartViewModel(
    chartModel: chartModel,
    chartType: chartType,
    chartOrientation: chartOrientation,
    liveOrTesting: LiveOrTesting.live,
    chartStacking: chartStacking,
  );

  LineChart lineChart = LineChart(
    // [lineChartViewModel] makes instance of [LineChartRootContainer]
    chartViewModel: lineChartViewModel,
    flutterChartPainter: FlutterChartPainter(),
  );
  chartToRun = lineChart;

  // Returns the configured LineChart or BarChart that will be added to the [_ExampleHomePageState],
  //   depending on the chart type requested by [requestedExampleToRun]
  return chartToRun;
}

class ExampleApp extends StatelessWidget {
  const ExampleApp({
    Key? key,
  }) : super(key: key);

  /// Builds the widget which becomes the root of the application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Charts Demo Title',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const ExampleHomePage(
        title: 'Flutter Charts Demo',
      ),
    );
  }
}

class ExampleHomePage extends StatefulWidget {
  const ExampleHomePage({
    Key? key,
    required this.title,
  }) : super(key: key);
  final String title;

  @override
  ExampleHomePageState createState() => ExampleHomePageState();
}

class ExampleHomePageState extends State<ExampleHomePage> {
  ExampleHomePageState();

  void _chartStateChanger() {
    setState(() {});
  }

  /// Builds the widget that is the home page state.
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          children: <Widget>[
            ElevatedButton(
              onPressed: _chartStateChanger,
              child: null,
            ),
            const Text(
              'vvvvvvvv:',
            ),
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('>>>'),
                  Expanded(
                    // #### Core chart
                    child: chartToRun(), // barChart, lineChart
                  ),
                  const Text('<<'),
                ],
              ),
            ),
            const Text('^^^^^^:'),
            ElevatedButton(
              onPressed: _chartStateChanger,
              child: null,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _chartStateChanger,
        tooltip: 'Next set of data',
        child: const Icon(Icons.add),
      ),
    );
  }
}
