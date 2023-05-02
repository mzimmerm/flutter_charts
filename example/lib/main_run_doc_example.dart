import 'package:flutter/material.dart';

import 'package:flutter_charts/flutter_charts.dart';
import 'package:flutter_charts/src/morphic/container/chart_support/chart_style.dart';
import 'package:flutter_charts/src/chart/painter.dart' show FlutterChartPainter;

/// Example app for flutter_charts, which shows one concrete chart,
/// the widget returned from [chartToRun].
///
/// Intended as a simple app that runs example code from README.md,
/// by replacing the contents of [chartToRun] with example code pasted from README.md.
///
/// Note that there is another example app [main.dart](./main.dart) which is similar,
/// but it's [chartToRun] allows to run multiple examples.
///
void main() {
  runApp(const MyApp());
}

/// Returns a [FlutterChart] widget that is plugged in the [MyHomePageState]
/// of this sample app.
///
/// This code can be replaced with any sample code snippets in README.md.
/// See README.md headings named such as
/// ```md
///   ex10RandomData_lineChart
/// ```
Widget chartToRun() {
  LabelLayoutStrategy? inputLabelLayoutStrategy;
  ChartModel chartModel;
  ChartOptions chartOptions = const ChartOptions();
  // Set option which will ask to start Y axis at data minimum.
  // Even though startYAxisAtDataMinRequested set to true, will not be granted on bar chart
  chartOptions = const ChartOptions(
    dataContainerOptions: DataContainerOptions(
      extendAxisToOriginRequested: false, // should have no effect on Stacked charts!
    ),
  );
  chartModel = ChartModel(
    valuesRows: const [
      [20.0, 25.0, 30.0, 35.0, 40.0, 20.0],
      [35.0, 40.0, 20.0, 25.0, 30.0, 20.0],
    ],
    inputUserLabels: const ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun'],
    byRowLegends: const [
      'Off zero 1',
      'Off zero 2',
    ],
    chartOptions: chartOptions,
  );
  var lineChartViewMaker = SwitchLineChartViewMaker(
    chartModel: chartModel,
    chartOrientation: ChartOrientation.column,
    chartStacking: ChartStacking.nonStacked,
    inputLabelLayoutStrategy: inputLabelLayoutStrategy,
  );

  var lineChart = LineChart(
    chartViewMaker: lineChartViewMaker,
    chartPainter: FlutterChartPainter(),
  );
  return lineChart;
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  /// Builds the widget which becomes the root of the application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Charts Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(
        title: 'Flutter Charts Demo',
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);
  final String title;

  @override
  MyHomePageState createState() => MyHomePageState();
}

class MyHomePageState extends State<MyHomePage> {
  MyHomePageState();

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
        tooltip: 'New Random Data',
        child: const Icon(Icons.add),
      ),
    );
  }
}
