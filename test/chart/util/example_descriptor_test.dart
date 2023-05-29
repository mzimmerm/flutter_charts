import 'package:flutter_charts/src/chart/util/example_descriptor.dart';
import 'package:flutter_charts/src/morphic/container/chart_support/chart_style.dart';
import 'package:test/test.dart';

main() {
  group('Single exact descriptor string', () {
    test('Valid descriptor String 1', () {
      var descriptor = 'ex10RandomData_barChart_column_stacked_oldManualLayouter';
      var exampleDescriptors = ExampleDescriptor.parseExampleDescriptorsFrom([descriptor]);

      expect(exampleDescriptors.length, 1);
      expect(exampleDescriptors[0].exampleEnum, ExampleEnum.ex10RandomData);
      expect(exampleDescriptors[0].chartType, ChartType.barChart);
      expect(exampleDescriptors[0].chartOrientation, ChartOrientation.column);
      expect(exampleDescriptors[0].chartStacking, ChartStacking.stacked);
      expect(exampleDescriptors[0].chartLayouter,  ChartLayouter.oldManualLayouter);

    });
  });
}