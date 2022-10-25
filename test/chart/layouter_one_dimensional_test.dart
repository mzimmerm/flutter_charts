import 'package:flutter_charts/src/chart/layouter_one_dimensional.dart'
    show Packing, Lineup, LengthsLayouter, LayedOutLineSegments, OneDimLayoutProperties;
import 'package:flutter_charts/src/util/util_dart.dart' show LineSegment;

// Needed if we want to use isAssertionError or throwsAssertionError, otherwise same as test.dart.
import 'package:flutter_test/flutter_test.dart' as flutter_test show throwsAssertionError;
import 'package:test/test.dart';

main() {
  List<double> lengths = [5.0, 10.0, 15.0];

  // ### Packing.matrjoska

  group('LengthsLayouter.layout() Matrjoska Left,', () {
    var matrjoskaLeftNoTotalLength = LengthsLayouter(
      lengths: lengths,
      oneDimLayoutProperties: OneDimLayoutProperties(packing: Packing.matrjoska, lineup: Lineup.start),
    );
    // Testing exception so create in test : var matrjoskaLeftTotalLength10Exception
    var matrjoskaLeftTotalLength15 = LengthsLayouter(
      lengths: lengths,
      oneDimLayoutProperties: OneDimLayoutProperties(packing: Packing.matrjoska, lineup: Lineup.start, totalLength: 15.0),
    );
    var matrjoskaLeftTotalLength27Added12 = LengthsLayouter(
      lengths: lengths,
      oneDimLayoutProperties: OneDimLayoutProperties(packing: Packing.matrjoska, lineup: Lineup.start, totalLength: 27.0),
    );

    test('LengthsLayouter.layout() Matrjoska Left, no total length enforced', () {
      LayedOutLineSegments segments = matrjoskaLeftNoTotalLength.layoutLengths();

      expect(segments.lineSegments.length, 3);
      expect(segments.lineSegments[0], LineSegment(0.0, 5.0));
      expect(segments.lineSegments[1], LineSegment(0.0, 10.0));
      expect(segments.lineSegments[2], LineSegment(0.0, 15.0));
      expect(segments.totalLayedOutLength, 15.0);
    });

    test('LengthsLayouter.layout() Matrjoska Left, total length same as required', () {
      LayedOutLineSegments segments = matrjoskaLeftTotalLength15.layoutLengths();

      expect(segments.lineSegments.length, 3);
      // Result should be same as with no total length enforced
      expect(segments.lineSegments[0], LineSegment(0.0, 5.0));
      expect(segments.lineSegments[1], LineSegment(0.0, 10.0));
      expect(segments.lineSegments[2], LineSegment(0.0, 15.0));
      expect(segments.totalLayedOutLength, 15.0);
    });

    test('LengthsLayouter.layout() Matrjoska Left, total length less than needed, should Exception', () {
      expect(
          () => LengthsLayouter(
                lengths: lengths,
                oneDimLayoutProperties:
                    OneDimLayoutProperties(packing: Packing.matrjoska, lineup: Lineup.start, totalLength: 10.0),
              ),
          flutter_test.throwsAssertionError);
    });

    test('LengthsLayouter.layout() Matrjoska Left, total length more than required', () {
      LayedOutLineSegments segments = matrjoskaLeftTotalLength27Added12.layoutLengths();

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

  group('LengthsLayouter.layout() Matrjoska Right,', () {
    var matrjoskaRightNoTotalLength = LengthsLayouter(
      lengths: lengths,
      oneDimLayoutProperties: OneDimLayoutProperties(packing: Packing.matrjoska, lineup: Lineup.end),
    );
    var matrjoskaRightTotalLength27Added12 = LengthsLayouter(
      lengths: lengths,
      oneDimLayoutProperties: OneDimLayoutProperties(packing: Packing.matrjoska, lineup: Lineup.end, totalLength: 27.0),
    );

    test('LengthsLayouter.layout() Matrjoska Right, no total length enforced', () {
      LayedOutLineSegments segments = matrjoskaRightNoTotalLength.layoutLengths();

      expect(segments.lineSegments.length, 3);
      expect(segments.lineSegments[0], LineSegment(10.0, 15.0));
      expect(segments.lineSegments[1], LineSegment(5.0, 15.0));
      expect(segments.lineSegments[2], LineSegment(0.0, 15.0));
      expect(segments.totalLayedOutLength, 15.0);
    });

    test('LengthsLayouter.layout() Matrjoska Right, total length more than required', () {
      LayedOutLineSegments segments = matrjoskaRightTotalLength27Added12.layoutLengths();
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

  group('LengthsLayouter.layout() Snap Left,', () {
    var snapLeftNoTotalLength = LengthsLayouter(
      lengths: lengths,
      oneDimLayoutProperties: OneDimLayoutProperties(packing: Packing.snap, lineup: Lineup.start),
    );
    // Testing exception so create in test : var snapLeftTotalLength10Exception
    var snapLeftTotalLength30 = LengthsLayouter(
      lengths: lengths,
      oneDimLayoutProperties: OneDimLayoutProperties(packing: Packing.snap, lineup: Lineup.start, totalLength: 30.0),
    );
    var snapLeftTotalLength42Added12 = LengthsLayouter(
      lengths: lengths,
      oneDimLayoutProperties: OneDimLayoutProperties(packing: Packing.snap, lineup: Lineup.start, totalLength: 42.0),
    );

    test('LengthsLayouter.layout() Snap Left, no total length enforced', () {
      LayedOutLineSegments segments = snapLeftNoTotalLength.layoutLengths();

      expect(segments.lineSegments.length, 3);
      expect(segments.lineSegments[0], LineSegment(0.0, 5.0));
      expect(segments.lineSegments[1], LineSegment(5.0, 15.0));
      expect(segments.lineSegments[2], LineSegment(15.0, 30.0));
      expect(segments.totalLayedOutLength, 30.0);
    });

    test('LengthsLayouter.layout() Snap Left, total length same as required', () {
      LayedOutLineSegments segments = snapLeftTotalLength30.layoutLengths();

      expect(segments.lineSegments.length, 3);
      // Result should be same as with no total length enforced
      expect(segments.lineSegments[0], LineSegment(0.0, 5.0));
      expect(segments.lineSegments[1], LineSegment(5.0, 15.0));
      expect(segments.lineSegments[2], LineSegment(15.0, 30.0));
      expect(segments.totalLayedOutLength, 30.0);
    });

    test('LengthsLayouter.layout() Snap Left, total length less than needed, should Exception', () {
      expect(
          () => LengthsLayouter(
                lengths: lengths,
                oneDimLayoutProperties: OneDimLayoutProperties(packing: Packing.snap, lineup: Lineup.start, totalLength: 10.0),
              ),
          flutter_test.throwsAssertionError);
    });

    test('LengthsLayouter.layout() Snap Left, total length more than required', () {
      LayedOutLineSegments segments = snapLeftTotalLength42Added12.layoutLengths();

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
      // As in Snap Left
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

  group('LengthsLayouter.layout() Snap Right,', () {
    var snapRightNoTotalLength = LengthsLayouter(
      lengths: lengths,
      oneDimLayoutProperties: OneDimLayoutProperties(packing: Packing.snap, lineup: Lineup.end),
    );
    var snapRightTotalLength42Added12 = LengthsLayouter(
      lengths: lengths,
      oneDimLayoutProperties: OneDimLayoutProperties(packing: Packing.snap, lineup: Lineup.end, totalLength: 42.0),
    );

    test('LengthsLayouter.layout() Snap Right, no total length enforced', () {
      LayedOutLineSegments segments = snapRightNoTotalLength.layoutLengths();

      expect(segments.lineSegments.length, 3);
      // As in Snap Left, and as in SnapCenter
      expect(segments.lineSegments[0], LineSegment(0.0, 5.0));
      expect(segments.lineSegments[1], LineSegment(5.0, 15.0));
      expect(segments.lineSegments[2], LineSegment(15.0, 30.0));
      expect(segments.totalLayedOutLength, 30.0);
    });

    test('LengthsLayouter.layout() Snap Right, total length more than required', () {
      LayedOutLineSegments segments = snapRightTotalLength42Added12.layoutLengths();
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

  group('LengthsLayouter.layout() Loose Left,', () {
    var looseLeftNoTotalLength = LengthsLayouter(
      lengths: lengths,
      oneDimLayoutProperties: OneDimLayoutProperties(packing: Packing.loose, lineup: Lineup.start),
    );
    // Testing exception so create in test : var looseLeftTotalLength10Exception
    var looseLeftTotalLength30 = LengthsLayouter(
      lengths: lengths,
      oneDimLayoutProperties: OneDimLayoutProperties(packing: Packing.loose, lineup: Lineup.start, totalLength: 30.0),
    );
    var looseLeftTotalLength42Added12 = LengthsLayouter(
      lengths: lengths,
      oneDimLayoutProperties: OneDimLayoutProperties(packing: Packing.loose, lineup: Lineup.start, totalLength: 42.0),
    );

    test('LengthsLayouter.layout() Loose Left, no total length enforced', () {
      LayedOutLineSegments segments = looseLeftNoTotalLength.layoutLengths();

      expect(segments.lineSegments.length, 3);
      expect(segments.lineSegments[0], LineSegment(0.0, 5.0));
      expect(segments.lineSegments[1], LineSegment(5.0, 15.0));
      expect(segments.lineSegments[2], LineSegment(15.0, 30.0));
      expect(segments.totalLayedOutLength, 30.0);
    });

    test('LengthsLayouter.layout() Loose Left, total length same as required', () {
      LayedOutLineSegments segments = looseLeftTotalLength30.layoutLengths();

      expect(segments.lineSegments.length, 3);
      // Result should be same as with no total length enforced
      expect(segments.lineSegments[0], LineSegment(0.0, 5.0));
      expect(segments.lineSegments[1], LineSegment(5.0, 15.0));
      expect(segments.lineSegments[2], LineSegment(15.0, 30.0));
      expect(segments.totalLayedOutLength, 30.0);
    });

    test('LengthsLayouter.layout() Loose Left, total length less than needed, should Exception', () {
      expect(
          () => LengthsLayouter(
                lengths: lengths,
                oneDimLayoutProperties: OneDimLayoutProperties(packing: Packing.loose, lineup: Lineup.start, totalLength: 10.0),
              ),
          flutter_test.throwsAssertionError);
    });

    test('LengthsLayouter.layout() Loose Left, total length more than required', () {
      LayedOutLineSegments segments = looseLeftTotalLength42Added12.layoutLengths();
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
      // As in Loose Left
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

  group('LengthsLayouter.layout() Loose Right,', () {
    var looseRightNoTotalLength = LengthsLayouter(
      lengths: lengths,
      oneDimLayoutProperties: OneDimLayoutProperties(packing: Packing.loose, lineup: Lineup.end),
    );
    var looseRightTotalLength42Added12 = LengthsLayouter(
      lengths: lengths,
      oneDimLayoutProperties: OneDimLayoutProperties(packing: Packing.loose, lineup: Lineup.end, totalLength: 42.0),
    );

    test('LengthsLayouter.layout() Loose Right, no total length enforced', () {
      LayedOutLineSegments segments = looseRightNoTotalLength.layoutLengths();

      expect(segments.lineSegments.length, 3);
      // Aligns first element to max, then adds left padding freePadding long after every element,
      // so the rightmost element has a padding freePadding long.
      expect(segments.lineSegments[0], LineSegment(0.0, 5.0));
      expect(segments.lineSegments[1], LineSegment(5.0, 15.0));
      expect(segments.lineSegments[2], LineSegment(15.0, 30.0));
      expect(segments.totalLayedOutLength, 30.0);
    });

    test('LengthsLayouter.layout() Loose Right, total length more than required', () {
      LayedOutLineSegments segments = looseRightTotalLength42Added12.layoutLengths();
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
