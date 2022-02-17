import 'package:flutter_charts/src/chart/layouter_one_dimensional.dart'
    show Packing, Lineup, LengthsLayouter, LayedOutLineSegments, OneDimLayoutProperties;
import 'package:flutter_charts/src/util/util_dart.dart' show LineSegment;

// Needed if we want to use isAssertionError or throwsAssertionError, otherwise same as test.dart.
import 'package:flutter_test/flutter_test.dart' as flutter_test show throwsAssertionError;
import 'package:test/test.dart';

main() {
  List<double> lengths = [5.0, 10.0, 15.0];

  // ### Packing.matrjoska

  group('LengthsLayouter.layout() Matrjoska Min,', () {
    var matrjoskaMinNoTotalLength = LengthsLayouter(
      lengths: lengths,
      oneDimLayoutProperties: OneDimLayoutProperties(packing: Packing.matrjoska, lineup: Lineup.left),
    );
    // Testing exception so create in test : var matrjoskaMinTotalLength10Exception
    var matrjoskaMinTotalLength15 = LengthsLayouter(
      lengths: lengths,
      oneDimLayoutProperties: OneDimLayoutProperties(packing: Packing.matrjoska, lineup: Lineup.left, totalLength: 15.0),
    );
    var matrjoskaMinTotalLength27Added12 = LengthsLayouter(
      lengths: lengths,
      oneDimLayoutProperties: OneDimLayoutProperties(packing: Packing.matrjoska, lineup: Lineup.left, totalLength: 27.0),
    );

    test('LengthsLayouter.layout() Matrjoska Min, no total length enforced', () {
      LayedOutLineSegments segments = matrjoskaMinNoTotalLength.layoutLengths();

      expect(segments.lineSegments.length, 3);
      expect(segments.lineSegments[0], LineSegment(0.0, 5.0));
      expect(segments.lineSegments[1], LineSegment(0.0, 10.0));
      expect(segments.lineSegments[2], LineSegment(0.0, 15.0));
      expect(segments.totalLayedOutLength, 15.0);
    });

    test('LengthsLayouter.layout() Matrjoska Min, total length same as required', () {
      LayedOutLineSegments segments = matrjoskaMinTotalLength15.layoutLengths();

      expect(segments.lineSegments.length, 3);
      // Result should be same as with no total length enforced
      expect(segments.lineSegments[0], LineSegment(0.0, 5.0));
      expect(segments.lineSegments[1], LineSegment(0.0, 10.0));
      expect(segments.lineSegments[2], LineSegment(0.0, 15.0));
      expect(segments.totalLayedOutLength, 15.0);
    });

    test('LengthsLayouter.layout() Matrjoska Min, total length less than needed, should Exception', () {
      expect(
          () => LengthsLayouter(
                lengths: lengths,
                oneDimLayoutProperties:
                    OneDimLayoutProperties(packing: Packing.matrjoska, lineup: Lineup.left, totalLength: 10.0),
              ),
          flutter_test.throwsAssertionError);
    });

    test('LengthsLayouter.layout() Matrjoska Min, total length more than required', () {
      LayedOutLineSegments segments = matrjoskaMinTotalLength27Added12.layoutLengths();

      expect(segments.lineSegments.length, 3);
      // Result should be same as with no total length enforced. 
      // The whole padding of 12 is on the right.
      expect(segments.lineSegments[0], LineSegment(0.0, 5.0));
      expect(segments.lineSegments[1], LineSegment(0.0, 10.0));
      expect(segments.lineSegments[2], LineSegment(0.0, 15.0));
      expect(segments.totalLayedOutLength, 27.0);
    });
  });

  group('LengthsLayouter.layout() Matrjoska Center,', () {
    var matrjoskaCenterNoTotalLength = LengthsLayouter(
      lengths: lengths,
      oneDimLayoutProperties: OneDimLayoutProperties(packing: Packing.matrjoska, lineup: Lineup.center),
    );
    var matrjoskaCenterTotalLength27Added12 = LengthsLayouter(
      lengths: lengths,
      oneDimLayoutProperties: OneDimLayoutProperties(packing: Packing.matrjoska, lineup: Lineup.center, totalLength: 27.0),
    );

    test('LengthsLayouter.layout() Matrjoska Center, no total length enforced', () {
      LayedOutLineSegments segments = matrjoskaCenterNoTotalLength.layoutLengths();

      expect(segments.lineSegments.length, 3);
      expect(segments.lineSegments[0], LineSegment(5.0, 10.0));
      expect(segments.lineSegments[1], LineSegment(2.5, 12.5));
      expect(segments.lineSegments[2], LineSegment(0.0, 15.0));
      expect(segments.totalLayedOutLength, 15.0);
    });

    test('LengthsLayouter.layout() Matrjoska Center, total length more than required', () {
      LayedOutLineSegments segments = matrjoskaCenterTotalLength27Added12.layoutLengths();
      double halfOfFreePadding = 6.0;

      expect(segments.lineSegments.length, 3);
      // Compared to no total length enforced, move everything by halfOfFreePadding to the right.
      // The padding of 12 is half on the left (6) and half on the right (6)
      expect(segments.lineSegments[0], LineSegment(5.0 + halfOfFreePadding, 10.0 + halfOfFreePadding));
      expect(segments.lineSegments[1], LineSegment(2.5 + halfOfFreePadding, 12.5 + halfOfFreePadding));
      expect(segments.lineSegments[2], LineSegment(0.0 + halfOfFreePadding, 15.0 + halfOfFreePadding));
      expect(segments.totalLayedOutLength, 27.0);
    });
  });

  group('LengthsLayouter.layout() Matrjoska Max,', () {
    var matrjoskaMaxNoTotalLength = LengthsLayouter(
      lengths: lengths,
      oneDimLayoutProperties: OneDimLayoutProperties(packing: Packing.matrjoska, lineup: Lineup.right),
    );
    var matrjoskaMaxTotalLength27Added12 = LengthsLayouter(
      lengths: lengths,
      oneDimLayoutProperties: OneDimLayoutProperties(packing: Packing.matrjoska, lineup: Lineup.right, totalLength: 27.0),
    );

    test('LengthsLayouter.layout() Matrjoska Max, no total length enforced', () {
      LayedOutLineSegments segments = matrjoskaMaxNoTotalLength.layoutLengths();

      expect(segments.lineSegments.length, 3);
      expect(segments.lineSegments[0], LineSegment(10.0, 15.0));
      expect(segments.lineSegments[1], LineSegment(5.0, 15.0));
      expect(segments.lineSegments[2], LineSegment(0.0, 15.0));
      expect(segments.totalLayedOutLength, 15.0);
    });

    test('LengthsLayouter.layout() Matrjoska Max, total length more than required', () {
      LayedOutLineSegments segments = matrjoskaMaxTotalLength27Added12.layoutLengths();
      double fullFreePadding = 12.0;

      expect(segments.lineSegments.length, 3);
      // Compared to no total length enforced, move everything by fullFreePadding to the right.
      // The whole padding of 12 is on the left.
      expect(segments.lineSegments[0], LineSegment(10.0 + fullFreePadding, 15.0 + fullFreePadding));
      expect(segments.lineSegments[1], LineSegment(5.0 + fullFreePadding, 15.0 + fullFreePadding));
      expect(segments.lineSegments[2], LineSegment(0.0 + fullFreePadding, 15.0 + fullFreePadding));
      expect(segments.totalLayedOutLength, 27.0);
    });
  });

  // ### Packing.snap

  group('LengthsLayouter.layout() Snap Min,', () {
    var snapMinNoTotalLength = LengthsLayouter(
      lengths: lengths,
      oneDimLayoutProperties: OneDimLayoutProperties(packing: Packing.snap, lineup: Lineup.left),
    );
    // Testing exception so create in test : var snapMinTotalLength10Exception
    var snapMinTotalLength30 = LengthsLayouter(
      lengths: lengths,
      oneDimLayoutProperties: OneDimLayoutProperties(packing: Packing.snap, lineup: Lineup.left, totalLength: 30.0),
    );
    var snapMinTotalLength42Added12 = LengthsLayouter(
      lengths: lengths,
      oneDimLayoutProperties: OneDimLayoutProperties(packing: Packing.snap, lineup: Lineup.left, totalLength: 42.0),
    );

    test('LengthsLayouter.layout() Snap Min, no total length enforced', () {
      LayedOutLineSegments segments = snapMinNoTotalLength.layoutLengths();

      expect(segments.lineSegments.length, 3);
      expect(segments.lineSegments[0], LineSegment(0.0, 5.0));
      expect(segments.lineSegments[1], LineSegment(5.0, 15.0));
      expect(segments.lineSegments[2], LineSegment(15.0, 30.0));
      expect(segments.totalLayedOutLength, 30.0);
    });

    test('LengthsLayouter.layout() Snap Min, total length same as required', () {
      LayedOutLineSegments segments = snapMinTotalLength30.layoutLengths();

      expect(segments.lineSegments.length, 3);
      // Result should be same as with no total length enforced
      expect(segments.lineSegments[0], LineSegment(0.0, 5.0));
      expect(segments.lineSegments[1], LineSegment(5.0, 15.0));
      expect(segments.lineSegments[2], LineSegment(15.0, 30.0));
      expect(segments.totalLayedOutLength, 30.0);
    });

    test('LengthsLayouter.layout() Snap Min, total length less than needed, should Exception', () {
      expect(
          () => LengthsLayouter(
                lengths: lengths,
                oneDimLayoutProperties: OneDimLayoutProperties(packing: Packing.snap, lineup: Lineup.left, totalLength: 10.0),
              ),
          flutter_test.throwsAssertionError);
    });

    test('LengthsLayouter.layout() Snap Min, total length more than required', () {
      LayedOutLineSegments segments = snapMinTotalLength42Added12.layoutLengths();

      expect(segments.lineSegments.length, 3);
      // Result should be same as with no total length enforced
      expect(segments.lineSegments[0], LineSegment(0.0, 5.0));
      expect(segments.lineSegments[1], LineSegment(5.0, 15.0));
      expect(segments.lineSegments[2], LineSegment(15.0, 30.0));
      expect(segments.totalLayedOutLength, 42.0);
    });
  });

  group('LengthsLayouter.layout() Snap Center,', () {
    var snapCenterNoTotalLength = LengthsLayouter(
      lengths: lengths,
      oneDimLayoutProperties: OneDimLayoutProperties(packing: Packing.snap, lineup: Lineup.center),
    );
    var snapCenterTotalLength42Added12 = LengthsLayouter(
      lengths: lengths,
      oneDimLayoutProperties: OneDimLayoutProperties(packing: Packing.snap, lineup: Lineup.center, totalLength: 42.0),
    );

    test('LengthsLayouter.layout() Snap Center, no total length enforced', () {
      LayedOutLineSegments segments = snapCenterNoTotalLength.layoutLengths();

      expect(segments.lineSegments.length, 3);
      // As in Snap Min
      expect(segments.lineSegments[0], LineSegment(0.0, 5.0));
      expect(segments.lineSegments[1], LineSegment(5.0, 15.0));
      expect(segments.lineSegments[2], LineSegment(15.0, 30.0));
      expect(segments.totalLayedOutLength, 30.0);
    });

    test('LengthsLayouter.layout() Snap Center, total length more than required', () {
      LayedOutLineSegments segments = snapCenterTotalLength42Added12.layoutLengths();
      double halfOfFreePadding = 6.0;

      expect(segments.lineSegments.length, 3);
      // Compared to no total length enforced, move everything by halfOfFreePadding to the right,
      // to center the whole group (which is snapped together)
      expect(segments.lineSegments[0], LineSegment(0.0 + halfOfFreePadding, 5.0 + halfOfFreePadding));
      expect(segments.lineSegments[1], LineSegment(5.0 + halfOfFreePadding, 15.0 + halfOfFreePadding));
      expect(segments.lineSegments[2], LineSegment(15.0 + halfOfFreePadding, 30.0 + halfOfFreePadding));
      expect(segments.totalLayedOutLength, 42.0);
    });
  });

  group('LengthsLayouter.layout() Snap Max,', () {
    var snapMaxNoTotalLength = LengthsLayouter(
      lengths: lengths,
      oneDimLayoutProperties: OneDimLayoutProperties(packing: Packing.snap, lineup: Lineup.right),
    );
    var snapMaxTotalLength42Added12 = LengthsLayouter(
      lengths: lengths,
      oneDimLayoutProperties: OneDimLayoutProperties(packing: Packing.snap, lineup: Lineup.right, totalLength: 42.0),
    );

    test('LengthsLayouter.layout() Snap Max, no total length enforced', () {
      LayedOutLineSegments segments = snapMaxNoTotalLength.layoutLengths();

      expect(segments.lineSegments.length, 3);
      // As in Snap Min, and as in SnapCenter
      expect(segments.lineSegments[0], LineSegment(0.0, 5.0));
      expect(segments.lineSegments[1], LineSegment(5.0, 15.0));
      expect(segments.lineSegments[2], LineSegment(15.0, 30.0));
      expect(segments.totalLayedOutLength, 30.0);
    });

    test('LengthsLayouter.layout() Snap Max, total length more than required', () {
      LayedOutLineSegments segments = snapMaxTotalLength42Added12.layoutLengths();
      double fullFreePadding = 12.0;

      expect(segments.lineSegments.length, 3);
      // Compared to no total length enforced, move everything by fullFreePadding to the right
      expect(segments.lineSegments[0], LineSegment(0.0 + fullFreePadding, 5.0 + fullFreePadding));
      expect(segments.lineSegments[1], LineSegment(5.0 + fullFreePadding, 15.0 + fullFreePadding));
      expect(segments.lineSegments[2], LineSegment(15.0 + fullFreePadding, 30.0 + fullFreePadding));
      expect(segments.totalLayedOutLength, 42.0);
    });
  });

  // ### Packing.loose

  group('LengthsLayouter.layout() Loose Min,', () {
    var looseMinNoTotalLength = LengthsLayouter(
      lengths: lengths,
      oneDimLayoutProperties: OneDimLayoutProperties(packing: Packing.loose, lineup: Lineup.left),
    );
    // Testing exception so create in test : var looseMinTotalLength10Exception
    var looseMinTotalLength30 = LengthsLayouter(
      lengths: lengths,
      oneDimLayoutProperties: OneDimLayoutProperties(packing: Packing.loose, lineup: Lineup.left, totalLength: 30.0),
    );
    var looseMinTotalLength42Added12 = LengthsLayouter(
      lengths: lengths,
      oneDimLayoutProperties: OneDimLayoutProperties(packing: Packing.loose, lineup: Lineup.left, totalLength: 42.0),
    );

    test('LengthsLayouter.layout() Loose Min, no total length enforced', () {
      LayedOutLineSegments segments = looseMinNoTotalLength.layoutLengths();

      expect(segments.lineSegments.length, 3);
      expect(segments.lineSegments[0], LineSegment(0.0, 5.0));
      expect(segments.lineSegments[1], LineSegment(5.0, 15.0));
      expect(segments.lineSegments[2], LineSegment(15.0, 30.0));
      expect(segments.totalLayedOutLength, 30.0);
    });

    test('LengthsLayouter.layout() Loose Min, total length same as required', () {
      LayedOutLineSegments segments = looseMinTotalLength30.layoutLengths();

      expect(segments.lineSegments.length, 3);
      // Result should be same as with no total length enforced
      expect(segments.lineSegments[0], LineSegment(0.0, 5.0));
      expect(segments.lineSegments[1], LineSegment(5.0, 15.0));
      expect(segments.lineSegments[2], LineSegment(15.0, 30.0));
      expect(segments.totalLayedOutLength, 30.0);
    });

    test('LengthsLayouter.layout() Loose Min, total length less than needed, should Exception', () {
      expect(
          () => LengthsLayouter(
                lengths: lengths,
                oneDimLayoutProperties: OneDimLayoutProperties(packing: Packing.loose, lineup: Lineup.left, totalLength: 10.0),
              ),
          flutter_test.throwsAssertionError);
    });

    test('LengthsLayouter.layout() Loose Min, total length more than required', () {
      LayedOutLineSegments segments = looseMinTotalLength42Added12.layoutLengths();
      int lengthsCount = 3;
      double freePadding = 12.0 / lengthsCount;

      expect(segments.lineSegments.length, 3);
      // Aligns first element to min, then adds left padding freePadding long after every element,
      // so the rightmost element has a padding freePadding long.
      expect(segments.lineSegments[0], LineSegment(0.0, 5.0));
      expect(segments.lineSegments[1], LineSegment(5.0 + freePadding * 1, 15.0 + freePadding * 1));
      expect(segments.lineSegments[2], LineSegment(15.0 + freePadding * 2, 30.0 + freePadding * 2));
      expect(segments.totalLayedOutLength, 42.0);
    });
  });

  group('LengthsLayouter.layout() Loose Center,', () {
    var looseCenterNoTotalLength = LengthsLayouter(
      lengths: lengths,
      oneDimLayoutProperties: OneDimLayoutProperties(packing: Packing.loose, lineup: Lineup.center),
    );
    var looseCenterTotalLength42Added12 = LengthsLayouter(
      lengths: lengths,
      oneDimLayoutProperties: OneDimLayoutProperties(packing: Packing.loose, lineup: Lineup.center, totalLength: 42.0),
    );

    test('LengthsLayouter.layout() Loose Center, no total length enforced', () {
      LayedOutLineSegments segments = looseCenterNoTotalLength.layoutLengths();

      expect(segments.lineSegments.length, 3);
      // As in Loose Min
      expect(segments.lineSegments[0], LineSegment(0.0, 5.0));
      expect(segments.lineSegments[1], LineSegment(5.0, 15.0));
      expect(segments.lineSegments[2], LineSegment(15.0, 30.0));
      expect(segments.totalLayedOutLength, 30.0);
    });

    test('LengthsLayouter.layout() Loose Center, total length more than required', () {
      LayedOutLineSegments segments = looseCenterTotalLength42Added12.layoutLengths();
      int lengthsCount = 3;
      double freePadding = 12.0 / (lengthsCount + 1); // 3.0

      expect(segments.lineSegments.length, 3);
      // Aligns last element end to max, then adds left padding freePadding long after every element,
      // and the first element has a padding freePadding long.
      expect(segments.lineSegments[0], LineSegment(0.0 + freePadding * 1, 5.0 + freePadding * 1));
      expect(segments.lineSegments[1], LineSegment(5.0 + freePadding * 2, 15.0 + freePadding * 2));
      expect(segments.lineSegments[2], LineSegment(15.0 + freePadding * 3, 30.0 + freePadding * 3));
      expect(segments.totalLayedOutLength, 42.0);
    });
  });

  group('LengthsLayouter.layout() Loose Max,', () {
    var looseMaxNoTotalLength = LengthsLayouter(
      lengths: lengths,
      oneDimLayoutProperties: OneDimLayoutProperties(packing: Packing.loose, lineup: Lineup.right),
    );
    var looseMaxTotalLength42Added12 = LengthsLayouter(
      lengths: lengths,
      oneDimLayoutProperties: OneDimLayoutProperties(packing: Packing.loose, lineup: Lineup.right, totalLength: 42.0),
    );

    test('LengthsLayouter.layout() Loose Max, no total length enforced', () {
      LayedOutLineSegments segments = looseMaxNoTotalLength.layoutLengths();

      expect(segments.lineSegments.length, 3);
      // Aligns first element to max, then adds left padding freePadding long after every element,
      // so the rightmost element has a padding freePadding long.
      expect(segments.lineSegments[0], LineSegment(0.0, 5.0));
      expect(segments.lineSegments[1], LineSegment(5.0, 15.0));
      expect(segments.lineSegments[2], LineSegment(15.0, 30.0));
      expect(segments.totalLayedOutLength, 30.0);
    });

    test('LengthsLayouter.layout() Loose Max, total length more than required', () {
      LayedOutLineSegments segments = looseMaxTotalLength42Added12.layoutLengths();
      int lengthsCount = 3;
      double freePadding = 12.0 / lengthsCount; // 4.0

      expect(segments.lineSegments.length, 3);
      // Aligns last element end to max, then adds left padding freePadding long after every element,
      // and the first element has a padding freePadding long.
      expect(segments.lineSegments[0], LineSegment(0.0 + freePadding * 1, 5.0 + freePadding * 1));
      expect(segments.lineSegments[1], LineSegment(5.0 + freePadding * 2, 15.0 + freePadding * 2));
      expect(segments.lineSegments[2], LineSegment(15.0 + freePadding * 3, 30.0 + freePadding * 3));
      expect(segments.totalLayedOutLength, 42.0);
    });
  });
}
