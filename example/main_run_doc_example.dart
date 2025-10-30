import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:logger/logger.dart';

import 'package:flutter_charts/src/chart/cartesian/chart_type/line/chart.dart';
import 'package:flutter_charts/src/chart/painter.dart';
import 'package:flutter_charts/src/chart/model/data_model.dart';
import 'package:flutter_charts/src/switch_view_model/view_model_UNUSED.dart';
import 'package:flutter_charts/src/switch_view_model/auto_layout/line/view_model.dart';
import 'package:flutter_charts/src/chart/options.dart';
import 'package:flutter_charts/src/morphic/container/chart_support/chart_style.dart';

// todo-0000 changed:
import 'package:flutter_charts/src/chart/layout_alternatives/options.dart' as layout_alternative_options show LegendAndItemLayoutEnum;
import 'package:flutter_charts/src/chart/model/random_chart_data.dart';
// todo-0000: DIFFERENCE: The testing_view_model is using the testing Legend enums; the NON-testing(LIFE)_view_Model is using the LIFE legend enums
// todo-00-done-2: import 'package:flutter_charts/test/src/switch_view_model/coded_layout/line/view_model_UNUSED.dart' as testing_line_view_model;
import 'package:flutter_charts/src/switch_view_model/auto_layout/line/view_model.dart' as switch_auto_layout_line_view_model;
import 'package:flutter_charts/src/switch_view_model/auto_layout/bar/view_model.dart' as switch_auto_layout_bar_view_model;

// todo-00-done
import 'package:flutter_charts/src/chart/view_model/view_model.dart';


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

  // main_run_doc_example.dart runs ExampleEnum.ex10RandomData.

  // Create chartOptions defaults here, so we do not repeat it in every example section,
  //   unless specific examples need to override this chartOptions default.
  ChartOptions chartOptions = const ChartOptions(
    legendOptions: LegendOptions(
        legendAndItemLayoutEnum:
        layout_alternative_options.LegendAndItemLayoutEnum.legendIsRowStartTightItemIsRowStartTightItemChildrenPadded),
  );
  chartModel = RandomChartModel.generated(
    chartOptions: chartOptions,
  );

  // LineChart or BarChart depending on what is set in environment.
  Widget chartToRun;

  // Uses newChartLayouter
  // todo-0000: this fails because it is using the non-test version: ChartViewModelCL lineChartViewModel = LineChartViewModelCL(
  // todo-00-done: ChartViewModelCL lineChartViewModel = testing_line_view_model.LineChartViewModelCL(
  // todo-00-done-2: ChartViewModel lineChartViewModel = testing_line_view_model.LineChartViewModelCL(
  ChartViewModel lineChartViewModel = switch_auto_layout_line_view_model.LineChartViewModelCL(
    chartModel: chartModel,
    chartType: chartType,
    chartOrientation: chartOrientation,
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
