import 'package:flutter_charts/src/chart/util/example_descriptor.dart';
import 'package:flutter_charts/src/morphic/container/chart_support/chart_style.dart';
import 'package:test/test.dart';

main() {
  group('Single valid descriptor string', () {

    test('Valid descriptor: Fully descriptive single-ex-matching String', () {
      var descriptor = 'ex10RandomData_barChart_column_stacked_oldManualLayouter';
      var exampleDescriptors = ExampleDescriptor.parseDescriptors([descriptor]);

      expect(exampleDescriptors.length, 1);
      expect(exampleDescriptors[0].exampleEnum, ExampleEnum.ex10RandomData);
      expect(exampleDescriptors[0].chartType, ChartType.barChart);
      expect(exampleDescriptors[0].chartOrientation, ChartOrientation.column);
      expect(exampleDescriptors[0].chartStacking, ChartStacking.stacked);
      expect(exampleDescriptors[0].chartLayouter,  ChartLayouter.oldManualLayouter);

    });

    test('Valid descriptor: Partially descriptive single-ex-matching String', () {
      var descriptor = 'ex10_barChart_column_stacked_oldManualLayouter';
      var exampleDescriptors = ExampleDescriptor.parseDescriptors([descriptor]);

      expect(exampleDescriptors.length, 1);
      expect(exampleDescriptors[0].exampleEnum, ExampleEnum.ex10RandomData);
      expect(exampleDescriptors[0].chartType, ChartType.barChart);
      expect(exampleDescriptors[0].chartOrientation, ChartOrientation.column);
      expect(exampleDescriptors[0].chartStacking, ChartStacking.stacked);
      expect(exampleDescriptors[0].chartLayouter,  ChartLayouter.oldManualLayouter);

    });

    test('Valid descriptor: Partially descriptive multi-ex-matching String', () {
      var descriptor = 'ex_barChart_column_stacked_oldManualLayouter';
      var exampleDescriptors = ExampleDescriptor.parseDescriptors([descriptor]);

      expect(exampleDescriptors.length > 1, true);

      /* not true, although they look the same on toString :
      var sortedExampleDescriptors = List.from(exampleDescriptors)
        ..sort((d1, d2) {
          return d1.exampleEnum.toString().compareTo(d2.exampleEnum.toString());
        });
      print(exampleDescriptors);
      print(sortedExampleDescriptors);
      expect(exampleDescriptors == sortedExampleDescriptors, true);
      */

    });

    test('Valid descriptor: Fuzzy descriptive single-ex-matching String', () {
      var descriptor = 'ex10RandomData_*_column_stacked_oldManualLayouter';
      var exampleDescriptors = ExampleDescriptor.parseDescriptors([descriptor]);

      expect(exampleDescriptors.length, 2);
      expect(exampleDescriptors[0].exampleEnum, ExampleEnum.ex10RandomData);
      expect(exampleDescriptors[0].chartType, ChartType.lineChart);
      expect(exampleDescriptors[0].chartOrientation, ChartOrientation.column);
      expect(exampleDescriptors[0].chartStacking, ChartStacking.stacked);
      expect(exampleDescriptors[0].chartLayouter,  ChartLayouter.oldManualLayouter);

      expect(exampleDescriptors[1].exampleEnum, ExampleEnum.ex10RandomData);
      expect(exampleDescriptors[1].chartType, ChartType.barChart);
      expect(exampleDescriptors[1].chartOrientation, ChartOrientation.column);
      expect(exampleDescriptors[1].chartStacking, ChartStacking.stacked);
      expect(exampleDescriptors[1].chartLayouter,  ChartLayouter.oldManualLayouter);
    });

  });

  group('Invalid descriptor string', () {
    test('Invalid descriptor: throws StateError with appropriate message', () {
      var descriptor = 'ex10_YYYChart_column_stacked_oldManualLayouter';
      // Note: reason does not seem to matter. Not sure how to check for exception text
      expect(
        () => ExampleDescriptor.parseDescriptors([descriptor]),
        throwsStateError,
        reason: 'Invalid (zero based) ChartType field 1',
      );
    });
  });

  group('Multi descriptor string', () {

    test('Valid descriptor: 2 Fully descriptive single-ex-matching Strings', () {
      var descriptor1 = 'ex10RandomData_barChart_column_stacked_oldManualLayouter';
      var descriptor2 = 'ex10RandomData_barChart_column_stacked_newAutoLayouter';
      var exampleDescriptors = ExampleDescriptor.parseDescriptors([descriptor1, descriptor2]);

      expect(exampleDescriptors.length, 2);

      expect(exampleDescriptors[0].exampleEnum, ExampleEnum.ex10RandomData);
      expect(exampleDescriptors[0].chartType, ChartType.barChart);
      expect(exampleDescriptors[0].chartOrientation, ChartOrientation.column);
      expect(exampleDescriptors[0].chartStacking, ChartStacking.stacked);
      expect(exampleDescriptors[0].chartLayouter,  ChartLayouter.oldManualLayouter);

      expect(exampleDescriptors[1].exampleEnum, ExampleEnum.ex10RandomData);
      expect(exampleDescriptors[1].chartType, ChartType.barChart);
      expect(exampleDescriptors[1].chartOrientation, ChartOrientation.column);
      expect(exampleDescriptors[1].chartStacking, ChartStacking.stacked);
      expect(exampleDescriptors[1].chartLayouter,  ChartLayouter.newAutoLayouter);
    });

    test('Valid descriptor: 2 Fully descriptive multi-ex-matching Strings', () {
      var descriptor1 = 'ex10RandomData_*_column_stacked_*';
      var descriptor2 = 'ex10RandomData_barChart_*_*_newAutoLayouter';
      var exampleDescriptors = ExampleDescriptor.parseDescriptors([descriptor1, descriptor2]);

      expect(exampleDescriptors.length, 8);

    });
  });
}