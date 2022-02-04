import 'package:flutter_charts/src/chart/new/container_base_new.dart' show Packing, Align, LengthsLayouter, LayedOutLineSegments;
import 'package:flutter_charts/src/util/util_dart.dart' show Interval, LineSegment;

// Needed if we want to use isAssertionError or throwsAssertionError, otherwise same as test.dart.
import 'package:flutter_test/flutter_test.dart' as flutter_test show throwsAssertionError;
import 'package:test/test.dart';

main() {
  
  List<double> lengths = [5.0, 10.0, 15.0];

  group('LengthsLayouter.layout() Matrjoska Min,', () {
    var matrjoskaMinNoTotalLength = LengthsLayouter(lengths: lengths, packing: Packing.matrjoska, align: Align.min);
    // Testing exception so create in test : var matrjoskaMinTotalLength10Exception
    var matrjoskaMinTotalLength15 = LengthsLayouter(
        lengths: lengths, packing: Packing.matrjoska, align: Align.min, totalLength: 15.0);
    var matrjoskaMinTotalLength27Added12 = LengthsLayouter(
        lengths: lengths, packing: Packing.matrjoska, align: Align.min, totalLength: 27.0);


    test('LengthsLayouter.layout() Matrjoska Min, no total length enforced', () {
      LayedOutLineSegments segments = matrjoskaMinNoTotalLength.layout();

      expect(segments.lineSegments.length, 3);
      expect(segments.lineSegments[0], LineSegment(0.0, 5.0));
      expect(segments.lineSegments[1], LineSegment(0.0, 10.0));
      expect(segments.lineSegments[2], LineSegment(0.0, 15.0));
    });

    test('LengthsLayouter.layout() Matrjoska Min, total length less than needed, should Exception', () {
      expect(() => LengthsLayouter(lengths: lengths, packing: Packing.matrjoska, align: Align.min, totalLength: 10.0),
          flutter_test.throwsAssertionError);
    });

    test('LengthsLayouter.layout() Matrjoska Min, total length same as required', () {
      LayedOutLineSegments segments = matrjoskaMinTotalLength15.layout();

      expect(segments.lineSegments.length, 3);
      expect(segments.lineSegments[0], LineSegment(0.0, 5.0));
      expect(segments.lineSegments[1], LineSegment(0.0, 10.0));
      expect(segments.lineSegments[2], LineSegment(0.0, 15.0));
    });

    test('LengthsLayouter.layout() Matrjoska Min, total length more than required', () {
      LayedOutLineSegments segments = matrjoskaMinTotalLength27Added12.layout();

      expect(segments.lineSegments.length, 3);
      expect(segments.lineSegments[0], LineSegment(0.0, 5.0));
      expect(segments.lineSegments[1], LineSegment(0.0, 10.0));
      expect(segments.lineSegments[2], LineSegment(0.0, 15.0));
    });
  });

  group('LengthsLayouter.layout() Matrjoska Center,', () {
    var matrjoskaCenterNoTotalLength = LengthsLayouter(lengths: lengths, packing: Packing.matrjoska, align: Align.center);
    var matrjoskaCenterTotalLength27Added12 = LengthsLayouter(
        lengths: lengths, packing: Packing.matrjoska, align: Align.center, totalLength: 27.0);
    double halfOfAddedLength = 6.0;
    
    test('LengthsLayouter.layout() Matrjoska Center, no total length enforced', () {
      LayedOutLineSegments segments = matrjoskaCenterNoTotalLength.layout();

      expect(segments.lineSegments.length, 3);
      expect(segments.lineSegments[0], LineSegment(5.0, 10.0));
      expect(segments.lineSegments[1], LineSegment(2.5, 12.5));
      expect(segments.lineSegments[2], LineSegment(0.0, 15.0));
    });

    test('LengthsLayouter.layout() Matrjoska Center, total length more than required', () {
      LayedOutLineSegments segments = matrjoskaCenterTotalLength27Added12.layout();

      expect(segments.lineSegments.length, 3);
      // Compared to no total length enforced, move everything by halfOfAddedLength to the right
      expect(segments.lineSegments[0], LineSegment(5.0+halfOfAddedLength, 10.0+halfOfAddedLength));
      expect(segments.lineSegments[1], LineSegment(2.5+halfOfAddedLength, 12.5+halfOfAddedLength));
      expect(segments.lineSegments[2], LineSegment(0.0+halfOfAddedLength, 15.0+halfOfAddedLength));
    });
  });

  group('LengthsLayouter.layout() Matrjoska Max,', () {
    var matrjoskaMaxNoTotalLength = LengthsLayouter(lengths: lengths, packing: Packing.matrjoska, align: Align.max);
    var matrjoskaMaxTotalLength27Added12 = LengthsLayouter(
        lengths: lengths, packing: Packing.matrjoska, align: Align.max, totalLength: 27.0);
    double halfOfAddedLength = 6.0;
    double fullAddedLength = 12.0;

    test('LengthsLayouter.layout() Matrjoska Max, no total length enforced', () {
      LayedOutLineSegments segments = matrjoskaMaxNoTotalLength.layout();

      expect(segments.lineSegments.length, 3);
      expect(segments.lineSegments[0], LineSegment(10.0, 15.0));
      expect(segments.lineSegments[1], LineSegment(5.0, 15.0));
      expect(segments.lineSegments[2], LineSegment(0.0, 15.0));
    });

    test('LengthsLayouter.layout() Matrjoska Max, total length more than required', () {
      LayedOutLineSegments segments = matrjoskaMaxTotalLength27Added12.layout();

      expect(segments.lineSegments.length, 3);
      // Compared to no total length enforced, move everything by fullAddedLength to the right
      expect(segments.lineSegments[0], LineSegment(10.0+fullAddedLength, 15.0+fullAddedLength));
      expect(segments.lineSegments[1], LineSegment(5.0+fullAddedLength, 15.0+fullAddedLength));
      expect(segments.lineSegments[2], LineSegment(0.0+fullAddedLength, 15.0+fullAddedLength));
    });
  });
}