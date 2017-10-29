import 'dart:ui' as ui show Size;

import 'package:flutter_charts/src/chart/options.dart';
import 'package:flutter_charts/src/chart/data.dart';
import '../layouters.dart';

import 'presenters.dart';


/// todo -1 document
class LineChartLayouter extends ChartLayouter {
  LineChartLayouter({
    ui.Size chartArea,
    ChartData chartData,
    ChartOptions chartOptions,
  })
      : super(
          chartArea: chartArea,
          chartData: chartData,
          chartOptions: chartOptions,
        ) {
    presenterCreator = new LineAndHotspotLeafCreator(layouter: this);
  }
}
