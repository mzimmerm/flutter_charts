import 'package:flutter_charts/src/chart/layouter_one_dimensional.dart'
    show Packing, Lineup, LayoutLengthsLayouter, LayedOutLineSegments, OneDimLayoutProperties;
import 'package:flutter_charts/src/util/util_dart.dart' show LineSegment;

// Needed if we want to use isAssertionError or throwsAssertionError, otherwise same as test.dart.
// import 'package:flutter_test/flutter_test.dart' as flutter_test show throwsAssertionError;
import 'package:test/test.dart';

main() {
  List<double> lengths = [5.0, 10.0, 15.0];

  // ### Packing.matrjoska

  group('LayoutLengthsLayouter.layout() Matrjoska Left,', () {
    var matrjoskaLeftLengthsConstraintLessThanSizes = LayoutLengthsLayouter(
      lengths: lengths,
      oneDimLayoutProperties: OneDimLayoutProperties(packing: Packing.matrjoska, lineup: Lineup.start),
      lengthsConstraint: 0.0,
    );
    // Testing exception so create in test : var matrjoskaLeftTotalLength10Exception
    var matrjoskaLeftTotalLength15 = LayoutLengthsLayouter(
      lengths: lengths,
      oneDimLayoutProperties: OneDimLayoutProperties(packing: Packing.matrjoska, lineup: Lineup.start),
      lengthsConstraint: 15.0,
    );
    var matrjoskaLeftTotalLength27Added12 = LayoutLengthsLayouter(
      lengths: lengths,
      oneDimLayoutProperties: OneDimLayoutProperties(packing: Packing.matrjoska, lineup: Lineup.start),
      lengthsConstraint: 27.0,
    );
    var matrjoskaLeftLengthConstraints10LessThanSizes = LayoutLengthsLayouter(
      lengths: lengths,
      oneDimLayoutProperties: OneDimLayoutProperties(packing: Packing.matrjoska, lineup: Lineup.start),
      lengthsConstraint: 10.0,
    );

    test('LayoutLengthsLayouter.layout() Matrjoska Left, no total length enforced', () {
      LayedOutLineSegments segments = matrjoskaLeftLengthsConstraintLessThanSizes.layoutLengths();

      // no padding added
      expect(segments.lineSegments.length, 3);
      expect(segments.lineSegments[0], const LineSegment(0.0, 5.0));
      expect(segments.lineSegments[1], const LineSegment(0.0, 10.0));
      expect(segments.lineSegments[2], const LineSegment(0.0, 15.0));
      expect(segments.totalLayedOutLengthIncludesPadding, 15.0);
      expect(segments.isOverflown, true);
    });

    test('LayoutLengthsLayouter.layout() Matrjoska Left, total length same as required', () {
      LayedOutLineSegments segments = matrjoskaLeftTotalLength15.layoutLengths();

      expect(segments.lineSegments.length, 3);
      // Result should be same as with no total length enforced
      expect(segments.lineSegments[0], const LineSegment(0.0, 5.0));
      expect(segments.lineSegments[1], const LineSegment(0.0, 10.0));
      expect(segments.lineSegments[2], const LineSegment(0.0, 15.0));
      expect(segments.totalLayedOutLengthIncludesPadding, 15.0);
      expect(segments.isOverflown, false);
    });


    /* Replacing asserts with setting _freePadding to 0 if negative. Caller should allow this,
                      and if layoutSize exceeds Constraints, deal with it there
    test('LayoutLengthsLayouter.layout() Matrjoska Left, total length less than needed, should Exception', () {
      expect(
          () => LayoutLengthsLayouter(
                lengths: lengths,
                oneDimLayoutProperties:
                    OneDimLayoutProperties(packing: Packing.matrjoska, lineup: Lineup.start)
                    lengthsConstraint: 10.0,
              ),
          flutter_test.throwsAssertionError);
    });
    */
    test('LayoutLengthsLayouter.layout() Matrjoska Left, total length less than needed, uses 0 for free space', () {
      LayedOutLineSegments segments = matrjoskaLeftLengthConstraints10LessThanSizes.layoutLengths();

      expect(segments.lineSegments.length, 3);
      // Result should be same as with no total length enforced
      expect(segments.lineSegments[0], const LineSegment(0.0, 5.0));
      expect(segments.lineSegments[1], const LineSegment(0.0, 10.0));
      expect(segments.lineSegments[2], const LineSegment(0.0, 15.0));
      expect(segments.totalLayedOutLengthIncludesPadding, 15.0);
      expect(segments.isOverflown, true);
    });

    test('LayoutLengthsLayouter.layout() Matrjoska Left, total length more than required', () {
      LayedOutLineSegments segments = matrjoskaLeftTotalLength27Added12.layoutLengths();

      expect(segments.lineSegments.length, 3);
      // Result should be same as with no total length enforced. 
      // The whole padding of 12 is on the right.
      expect(segments.lineSegments[0], const LineSegment(0.0, 5.0));
      expect(segments.lineSegments[1], const LineSegment(0.0, 10.0));
      expect(segments.lineSegments[2], const LineSegment(0.0, 15.0));
      expect(segments.totalLayedOutLengthIncludesPadding, 27.0);
      expect(segments.isOverflown, false);
    });
  });

  group('LayoutLengthsLayouter.layout() Matrjoska Center,', () {
    var matrjoskaCenterLengthsConstraintLessThanSizes = LayoutLengthsLayouter(
      lengths: lengths,
      oneDimLayoutProperties: OneDimLayoutProperties(packing: Packing.matrjoska, lineup: Lineup.center),
      lengthsConstraint: 0.0,
    );
    var matrjoskaCenterTotalLength27Added12 = LayoutLengthsLayouter(
      lengths: lengths,
      oneDimLayoutProperties: OneDimLayoutProperties(packing: Packing.matrjoska, lineup: Lineup.center),
      lengthsConstraint: 27.0,
    );

    test('LayoutLengthsLayouter.layout() Matrjoska Center, no total length enforced', () {
      LayedOutLineSegments segments = matrjoskaCenterLengthsConstraintLessThanSizes.layoutLengths();

      // no padding added
      expect(segments.lineSegments.length, 3);
      expect(segments.lineSegments[0], const LineSegment(5.0, 10.0));
      expect(segments.lineSegments[1], const LineSegment(2.5, 12.5));
      expect(segments.lineSegments[2], const LineSegment(0.0, 15.0));
      expect(segments.totalLayedOutLengthIncludesPadding, 15.0);
      expect(segments.isOverflown, true);
    });

    test('LayoutLengthsLayouter.layout() Matrjoska Center, total length more than required', () {
      LayedOutLineSegments segments = matrjoskaCenterTotalLength27Added12.layoutLengths();
      const double halfOfFreePadding = 6.0;

      expect(segments.lineSegments.length, 3);
      // Compared to no total length enforced, move everything by halfOfFreePadding to the right.
      // The padding of 12 is half on the left (6) and half on the right (6)
      expect(segments.lineSegments[0], const LineSegment(5.0 + halfOfFreePadding, 10.0 + halfOfFreePadding));
      expect(segments.lineSegments[1], const LineSegment(2.5 + halfOfFreePadding, 12.5 + halfOfFreePadding));
      expect(segments.lineSegments[2], const LineSegment(0.0 + halfOfFreePadding, 15.0 + halfOfFreePadding));
      expect(segments.totalLayedOutLengthIncludesPadding, 27.0);
      expect(segments.isOverflown, false);
    });
  });

  group('LayoutLengthsLayouter.layout() Matrjoska Right,', () {
    var matrjoskaRightLengthsConstraintLessThanSizes = LayoutLengthsLayouter(
      lengths: lengths,
      oneDimLayoutProperties: OneDimLayoutProperties(packing: Packing.matrjoska, lineup: Lineup.end),
      lengthsConstraint : 0.0,
    );
    var matrjoskaRightTotalLength27Added12 = LayoutLengthsLayouter(
      lengths: lengths,
      oneDimLayoutProperties: OneDimLayoutProperties(packing: Packing.matrjoska, lineup: Lineup.end),
      lengthsConstraint : 27.0,
    );

    test('LayoutLengthsLayouter.layout() Matrjoska Right, no total length enforced', () {
      LayedOutLineSegments segments = matrjoskaRightLengthsConstraintLessThanSizes.layoutLengths();

      // no padding added
      expect(segments.lineSegments.length, 3);
      expect(segments.lineSegments[0], const LineSegment(10.0, 15.0));
      expect(segments.lineSegments[1], const LineSegment(5.0, 15.0));
      expect(segments.lineSegments[2], const LineSegment(0.0, 15.0));
      expect(segments.totalLayedOutLengthIncludesPadding, 15.0);
      expect(segments.isOverflown, true);
   });

    test('LayoutLengthsLayouter.layout() Matrjoska Right, total length more than required', () {
      LayedOutLineSegments segments = matrjoskaRightTotalLength27Added12.layoutLengths();
      const double fullFreePadding = 12.0;

      expect(segments.lineSegments.length, 3);
      // Compared to no total length enforced, move everything by fullFreePadding to the right.
      // The whole padding of 12 is on the left.
      expect(segments.lineSegments[0], const LineSegment(10.0 + fullFreePadding, 15.0 + fullFreePadding));
      expect(segments.lineSegments[1], const LineSegment(5.0 + fullFreePadding, 15.0 + fullFreePadding));
      expect(segments.lineSegments[2], const LineSegment(0.0 + fullFreePadding, 15.0 + fullFreePadding));
      expect(segments.totalLayedOutLengthIncludesPadding, 27.0);
      expect(segments.isOverflown, false);
    });
  });

  // ### Packing.snap

  group('LayoutLengthsLayouter.layout() Snap Left,', () {
    var snapLeftLengthsConstraintLessThanSizes = LayoutLengthsLayouter(
      lengths: lengths,
      oneDimLayoutProperties: OneDimLayoutProperties(packing: Packing.snap, lineup: Lineup.start),
      lengthsConstraint: 0.0,
    );
    // Testing exception so create in test : var snapLeftTotalLength10Exception
    var snapLeftTotalLength30 = LayoutLengthsLayouter(
      lengths: lengths,
      oneDimLayoutProperties: OneDimLayoutProperties(packing: Packing.snap, lineup: Lineup.start),
      lengthsConstraint: 30.0,
    );
    var snapLeftTotalLength42Added12 = LayoutLengthsLayouter(
      lengths: lengths,
      oneDimLayoutProperties: OneDimLayoutProperties(packing: Packing.snap, lineup: Lineup.start),
      lengthsConstraint: 42.0,
    );
    var snapLeftTotalLengthsConstraint10LessThanSizes = LayoutLengthsLayouter(
      lengths: lengths,
      oneDimLayoutProperties: OneDimLayoutProperties(packing: Packing.snap, lineup: Lineup.start),
      lengthsConstraint: 10.0,
    );

    test('LayoutLengthsLayouter.layout() Snap Left, no total length enforced', () {
      LayedOutLineSegments segments = snapLeftLengthsConstraintLessThanSizes.layoutLengths();

      // no padding added
      expect(segments.lineSegments.length, 3);
      expect(segments.lineSegments[0], const LineSegment(0.0, 5.0));
      expect(segments.lineSegments[1], const LineSegment(5.0, 15.0));
      expect(segments.lineSegments[2], const LineSegment(15.0, 30.0));
      expect(segments.totalLayedOutLengthIncludesPadding, 30.0);
      expect(segments.isOverflown, true);
    });

    test('LayoutLengthsLayouter.layout() Snap Left, total length same as required', () {
      LayedOutLineSegments segments = snapLeftTotalLength30.layoutLengths();

      expect(segments.lineSegments.length, 3);
      // Result should be same as with no total length enforced
      expect(segments.lineSegments[0], const LineSegment(0.0, 5.0));
      expect(segments.lineSegments[1], const LineSegment(5.0, 15.0));
      expect(segments.lineSegments[2], const LineSegment(15.0, 30.0));
      expect(segments.totalLayedOutLengthIncludesPadding, 30.0);
      expect(segments.isOverflown, false);
    });

    test('LayoutLengthsLayouter.layout() Snap Left, total length less than needed, uses 0 for free space', () {
       LayedOutLineSegments segments = snapLeftTotalLengthsConstraint10LessThanSizes.layoutLengths();
       expect(segments.lineSegments.length, 3);
       // Result should be same as with no total length enforced
       expect(segments.lineSegments[0], const LineSegment(0.0, 5.0));
       expect(segments.lineSegments[1], const LineSegment(5.0, 15.0));
       expect(segments.lineSegments[2], const LineSegment(15.0, 30.0));
       expect(segments.totalLayedOutLengthIncludesPadding, 30.0);
       expect(segments.isOverflown, true);
    });

    /* Replacing asserts with setting _freePadding to 0 if negative. Caller should allow this,
                      and if layoutSize exceeds Constraints, deal with it there
    test('LayoutLengthsLayouter.layout() Matrjoska Left, total length less than needed, should Exception', () {
       expect(
          () => LayoutLengthsLayouter(
                lengths: lengths,
                oneDimLayoutProperties: OneDimLayoutProperties(packing: Packing.snap, lineup: Lineup.start),
                lengthsConstraint: 10.0,
              ),
          flutter_test.throwsAssertionError);
    });
    */

    test('LayoutLengthsLayouter.layout() Snap Left, total length more than required', () {
      LayedOutLineSegments segments = snapLeftTotalLength42Added12.layoutLengths();

      expect(segments.lineSegments.length, 3);
      // Result should be same as with no total length enforced
      expect(segments.lineSegments[0], const LineSegment(0.0, 5.0));
      expect(segments.lineSegments[1], const LineSegment(5.0, 15.0));
      expect(segments.lineSegments[2], const LineSegment(15.0, 30.0));
      expect(segments.totalLayedOutLengthIncludesPadding, 42.0);
      expect(segments.isOverflown, false);
    });
  });

  group('LayoutLengthsLayouter.layout() Snap Center,', () {
    var snapCenterLengthsConstraintLessThanSizes = LayoutLengthsLayouter(
      lengths: lengths,
      oneDimLayoutProperties: OneDimLayoutProperties(packing: Packing.snap, lineup: Lineup.center),
      lengthsConstraint: 0.0,
    );
    var snapCenterTotalLength42Added12 = LayoutLengthsLayouter(
      lengths: lengths,
      oneDimLayoutProperties: OneDimLayoutProperties(packing: Packing.snap, lineup: Lineup.center),
      lengthsConstraint: 42.0,
    );

    test('LayoutLengthsLayouter.layout() Snap Center, no total length enforced', () {
      LayedOutLineSegments segments = snapCenterLengthsConstraintLessThanSizes.layoutLengths();

      // no padding added
      expect(segments.lineSegments.length, 3);
      // As in Snap Left
      expect(segments.lineSegments[0], const LineSegment(0.0, 5.0));
      expect(segments.lineSegments[1], const LineSegment(5.0, 15.0));
      expect(segments.lineSegments[2], const LineSegment(15.0, 30.0));
      expect(segments.totalLayedOutLengthIncludesPadding, 30.0);
      expect(segments.isOverflown, true);
    });

    test('LayoutLengthsLayouter.layout() Snap Center, total length more than required', () {
      LayedOutLineSegments segments = snapCenterTotalLength42Added12.layoutLengths();
      const double halfOfFreePadding = 6.0;

      expect(segments.lineSegments.length, 3);
      // Compared to no total length enforced, move everything by halfOfFreePadding to the right,
      // to center the whole group (which is snapped together)
      expect(segments.lineSegments[0], const LineSegment(0.0 + halfOfFreePadding, 5.0 + halfOfFreePadding));
      expect(segments.lineSegments[1], const LineSegment(5.0 + halfOfFreePadding, 15.0 + halfOfFreePadding));
      expect(segments.lineSegments[2], const LineSegment(15.0 + halfOfFreePadding, 30.0 + halfOfFreePadding));
      expect(segments.totalLayedOutLengthIncludesPadding, 42.0);
      expect(segments.isOverflown, false);
    });
  });

  group('LayoutLengthsLayouter.layout() Snap Right,', () {
    var snapRightLengthsConstraintLessThanSizes = LayoutLengthsLayouter(
      lengths: lengths,
      oneDimLayoutProperties: OneDimLayoutProperties(packing: Packing.snap, lineup: Lineup.end),
        lengthsConstraint: 0.0
    );
    var snapRightTotalLength42Added12 = LayoutLengthsLayouter(
      lengths: lengths,
      oneDimLayoutProperties: OneDimLayoutProperties(packing: Packing.snap, lineup: Lineup.end),
      lengthsConstraint: 42.0
    );

    test('LayoutLengthsLayouter.layout() Snap Right, no total length enforced', () {
      LayedOutLineSegments segments = snapRightLengthsConstraintLessThanSizes.layoutLengths();

      // no padding added
      expect(segments.lineSegments.length, 3);
      // As in Snap Left, and as in SnapCenter
      expect(segments.lineSegments[0], const LineSegment(0.0, 5.0));
      expect(segments.lineSegments[1], const LineSegment(5.0, 15.0));
      expect(segments.lineSegments[2], const LineSegment(15.0, 30.0));
      expect(segments.totalLayedOutLengthIncludesPadding, 30.0);
      expect(segments.isOverflown, true);
    });

    test('LayoutLengthsLayouter.layout() Snap Right, total length more than required', () {
      LayedOutLineSegments segments = snapRightTotalLength42Added12.layoutLengths();
      const double fullFreePadding = 12.0;

      expect(segments.lineSegments.length, 3);
      // Compared to no total length enforced, move everything by fullFreePadding to the right
      expect(segments.lineSegments[0], const LineSegment(0.0 + fullFreePadding, 5.0 + fullFreePadding));
      expect(segments.lineSegments[1], const LineSegment(5.0 + fullFreePadding, 15.0 + fullFreePadding));
      expect(segments.lineSegments[2], const LineSegment(15.0 + fullFreePadding, 30.0 + fullFreePadding));
      expect(segments.totalLayedOutLengthIncludesPadding, 42.0);
      expect(segments.isOverflown, false);
    });
  });

  // ### Packing.loose

  group('LayoutLengthsLayouter.layout() Loose Left,', () {
    var looseLeftLengthsConstraintLessThanSizes = LayoutLengthsLayouter(
      lengths: lengths,
      oneDimLayoutProperties: OneDimLayoutProperties(packing: Packing.loose, lineup: Lineup.start),
      lengthsConstraint: 0.0
    );
    // Testing exception so create in test : var looseLeftTotalLength10Exception
    var looseLeftTotalLength30 = LayoutLengthsLayouter(
      lengths: lengths,
      oneDimLayoutProperties: OneDimLayoutProperties(packing: Packing.loose, lineup: Lineup.start),
      lengthsConstraint: 30.0
    );
    var looseLeftTotalLength42Added12 = LayoutLengthsLayouter(
      lengths: lengths,
      oneDimLayoutProperties: OneDimLayoutProperties(packing: Packing.loose, lineup: Lineup.start),
      lengthsConstraint: 42.0,
    );
    var looseLeftTotalLength30MakesFreeSpaceNegativeForcingFreeSpaceTo0 = LayoutLengthsLayouter(
      lengths: lengths,
      oneDimLayoutProperties: OneDimLayoutProperties(packing: Packing.loose, lineup: Lineup.start),
      lengthsConstraint: 30.0,
    );

    test('LayoutLengthsLayouter.layout() Loose Left, no total length enforced', () {
      LayedOutLineSegments segments = looseLeftLengthsConstraintLessThanSizes.layoutLengths();

      // no padding added
      expect(segments.lineSegments.length, 3);
      expect(segments.lineSegments[0], const LineSegment(0.0, 5.0));
      expect(segments.lineSegments[1], const LineSegment(5.0, 15.0));
      expect(segments.lineSegments[2], const LineSegment(15.0, 30.0));
      expect(segments.totalLayedOutLengthIncludesPadding, 30.0);
      expect(segments.isOverflown, true);
    });

    test('LayoutLengthsLayouter.layout() Loose Left, total length same as required', () {
      LayedOutLineSegments segments = looseLeftTotalLength30.layoutLengths();

      expect(segments.lineSegments.length, 3);
      // Result should be same as with no total length enforced
      expect(segments.lineSegments[0], const LineSegment(0.0, 5.0));
      expect(segments.lineSegments[1], const LineSegment(5.0, 15.0));
      expect(segments.lineSegments[2], const LineSegment(15.0, 30.0));
      expect(segments.totalLayedOutLengthIncludesPadding, 30.0);
      expect(segments.isOverflown, false);
    });

    /*  Replacing asserts with setting _freePadding to 0 if negative. Caller should allow this,
                      and if layoutSize exceeds Constraints, deal with it there
    test('LayoutLengthsLayouter.layout() Loose Left, total length less than needed, should Exception', () {
      expect(
          () => LayoutLengthsLayouter(
                lengths: lengths,
                oneDimLayoutProperties: OneDimLayoutProperties(packing: Packing.loose, lineup: Lineup.start),
                lengthsConstraint: 10.0,
              ),
          flutter_test.throwsAssertionError);
    });
    */

    test('LayoutLengthsLayouter.layout() Loose Left, total length less than needed, uses 0 for free space', () {
      LayedOutLineSegments segments = looseLeftTotalLength30MakesFreeSpaceNegativeForcingFreeSpaceTo0.layoutLengths();
      expect(segments.lineSegments.length, 3);
      // Result should be same as with no total length enforced
      expect(segments.lineSegments[0], const LineSegment(0.0, 5.0));
      expect(segments.lineSegments[1], const LineSegment(5.0, 15.0));
      expect(segments.lineSegments[2], const LineSegment(15.0, 30.0));
      expect(segments.totalLayedOutLengthIncludesPadding, 30.0);
      expect(segments.isOverflown, false);
    });

    test('LayoutLengthsLayouter.layout() Loose Left, total length more than required', () {
      LayedOutLineSegments segments = looseLeftTotalLength42Added12.layoutLengths();
      const int lengthsCount = 3;
      const double freePadding = 12.0 / lengthsCount;

      expect(segments.lineSegments.length, 3);
      // Aligns first element to min, then adds left padding freePadding long after every element,
      // so the rightmost element has a padding freePadding long.
      expect(segments.lineSegments[0], const LineSegment(0.0, 5.0));
      expect(segments.lineSegments[1], const LineSegment(5.0 + freePadding * 1, 15.0 + freePadding * 1));
      expect(segments.lineSegments[2], const LineSegment(15.0 + freePadding * 2, 30.0 + freePadding * 2));
      expect(segments.totalLayedOutLengthIncludesPadding, 42.0);
      expect(segments.isOverflown, false);
    });
  });

  group('LayoutLengthsLayouter.layout() Loose Center,', () {
    var looseCenterLengthsConstraintLessThanSizes = LayoutLengthsLayouter(
      lengths: lengths,
      oneDimLayoutProperties: OneDimLayoutProperties(packing: Packing.loose, lineup: Lineup.center),
        lengthsConstraint: 0.0
    );
    var looseCenterTotalLength42Added12 = LayoutLengthsLayouter(
      lengths: lengths,
      oneDimLayoutProperties: OneDimLayoutProperties(packing: Packing.loose, lineup: Lineup.center),
      lengthsConstraint: 42.0
    );

    test('LayoutLengthsLayouter.layout() Loose Center, no total length enforced', () {
      LayedOutLineSegments segments = looseCenterLengthsConstraintLessThanSizes.layoutLengths();

      // no padding added
      expect(segments.lineSegments.length, 3);
      // As in Loose Left
      expect(segments.lineSegments[0], const LineSegment(0.0, 5.0));
      expect(segments.lineSegments[1], const LineSegment(5.0, 15.0));
      expect(segments.lineSegments[2], const LineSegment(15.0, 30.0));
      expect(segments.totalLayedOutLengthIncludesPadding, 30.0);
      expect(segments.isOverflown, true);
    });

    test('LayoutLengthsLayouter.layout() Loose Center, total length more than required', () {
      LayedOutLineSegments segments = looseCenterTotalLength42Added12.layoutLengths();
      const int lengthsCount = 3;
      const double freePadding = 12.0 / (lengthsCount + 1); // 3.0

      expect(segments.lineSegments.length, 3);
      // Aligns last element end to max, then adds left padding freePadding long after every element,
      // and the first element has a padding freePadding long.
      expect(segments.lineSegments[0], const LineSegment(0.0 + freePadding * 1, 5.0 + freePadding * 1));
      expect(segments.lineSegments[1], const LineSegment(5.0 + freePadding * 2, 15.0 + freePadding * 2));
      expect(segments.lineSegments[2], const LineSegment(15.0 + freePadding * 3, 30.0 + freePadding * 3));
      expect(segments.totalLayedOutLengthIncludesPadding, 42.0);
      expect(segments.isOverflown, false);
    });
  });

  group('LayoutLengthsLayouter.layout() Loose Right,', () {
    var looseRightLengthsConstraintLessThanSizes = LayoutLengthsLayouter(
      lengths: lengths,
      oneDimLayoutProperties: OneDimLayoutProperties(packing: Packing.loose, lineup: Lineup.end),
      lengthsConstraint: 0.0,
    );
    var looseRightTotalLength42Added12 = LayoutLengthsLayouter(
      lengths: lengths,
      oneDimLayoutProperties: OneDimLayoutProperties(packing: Packing.loose, lineup: Lineup.end),
      lengthsConstraint: 42.0,
    );

    test('LayoutLengthsLayouter.layout() Loose Right, no total length enforced', () {
      LayedOutLineSegments segments = looseRightLengthsConstraintLessThanSizes.layoutLengths();

      // no padding added
      expect(segments.lineSegments.length, 3);
      expect(segments.lineSegments[0], const LineSegment(0.0, 5.0));
      expect(segments.lineSegments[1], const LineSegment(5.0, 15.0));
      expect(segments.lineSegments[2], const LineSegment(15.0, 30.0));
      expect(segments.totalLayedOutLengthIncludesPadding, 30.0);
      expect(segments.isOverflown, true);
    });

    test('LayoutLengthsLayouter.layout() Loose Right, total length more than required', () {
      LayedOutLineSegments segments = looseRightTotalLength42Added12.layoutLengths();
      const int lengthsCount = 3;
      const double freePadding = 12.0 / lengthsCount; // 4.0

      expect(segments.lineSegments.length, 3);
      // Aligns last element end to max, then adds left padding freePadding long after every element,
      // and the first element has a padding freePadding long.
      expect(segments.lineSegments[0], const LineSegment(0.0 + freePadding * 1, 5.0 + freePadding * 1));
      expect(segments.lineSegments[1], const LineSegment(5.0 + freePadding * 2, 15.0 + freePadding * 2));
      expect(segments.lineSegments[2], const LineSegment(15.0 + freePadding * 3, 30.0 + freePadding * 3));
      expect(segments.totalLayedOutLengthIncludesPadding, 42.0);
      expect(segments.isOverflown, false);
    });
  });
}
