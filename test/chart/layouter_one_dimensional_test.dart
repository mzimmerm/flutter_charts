import 'package:flutter_charts/src/chart/layouter_one_dimensional.dart'
    show Align, LayedoutLengthsPositioner, LayoutDirection, LengthsPositionerProperties, Packing, PositionedLineSegments;
import 'package:flutter_charts/src/util/util_dart.dart' show LineSegment;

// Needed if we want to use isAssertionError or throwsAssertionError, otherwise same as test.dart.
// import 'package:flutter_test/flutter_test.dart' as flutter_test show throwsAssertionError;
import 'package:test/test.dart';

main() {
  List<double> lengths = [5.0, 10.0, 15.0];

  // ### Packing.matrjoska

  group('LayedoutLengthsPositioner.layout() Matrjoska Left,', () {
    var matrjoskaLeftLengthsConstraintLessThanSizes = LayedoutLengthsPositioner(
      lengths: lengths,
      lengthsPositionerProperties: LengthsPositionerProperties(packing: Packing.matrjoska, align: Align.start, layoutDirection: LayoutDirection.alongCoordinates, isPositioningMainAxis: true),
      lengthsConstraint: 0.0,
    );
    // Testing exception so create in test : var matrjoskaLeftTotalLength10Exception
    var matrjoskaLeftTotalLength15 = LayedoutLengthsPositioner(
      lengths: lengths,
      lengthsPositionerProperties: LengthsPositionerProperties(packing: Packing.matrjoska, align: Align.start, layoutDirection: LayoutDirection.alongCoordinates, isPositioningMainAxis: true),
      lengthsConstraint: 15.0,
    );
    var matrjoskaLeftTotalLength27Added12 = LayedoutLengthsPositioner(
      lengths: lengths,
      lengthsPositionerProperties: LengthsPositionerProperties(packing: Packing.matrjoska, align: Align.start, layoutDirection: LayoutDirection.alongCoordinates, isPositioningMainAxis: true),
      lengthsConstraint: 27.0,
    );
    var matrjoskaLeftLengthConstraints10LessThanSizes = LayedoutLengthsPositioner(
      lengths: lengths,
      lengthsPositionerProperties: LengthsPositionerProperties(packing: Packing.matrjoska, align: Align.start, layoutDirection: LayoutDirection.alongCoordinates, isPositioningMainAxis: true),
      lengthsConstraint: 10.0,
    );

    test('LayedoutLengthsPositioner.layout() Matrjoska Left, no total length enforced', () {
      PositionedLineSegments segments = matrjoskaLeftLengthsConstraintLessThanSizes.layoutLengths();

      // no padding added
      expect(segments.lineSegments.length, 3);
      expect(segments.lineSegments[0], const LineSegment(0.0, 5.0));
      expect(segments.lineSegments[1], const LineSegment(0.0, 10.0));
      expect(segments.lineSegments[2], const LineSegment(0.0, 15.0));
      expect(segments.totalPositionedLengthIncludesPadding, 15.0);
      expect(segments.isOverflown, true);
    });

    test('LayedoutLengthsPositioner.layout() Matrjoska Left, total length same as required', () {
      PositionedLineSegments segments = matrjoskaLeftTotalLength15.layoutLengths();

      expect(segments.lineSegments.length, 3);
      // Result should be same as with no total length enforced
      expect(segments.lineSegments[0], const LineSegment(0.0, 5.0));
      expect(segments.lineSegments[1], const LineSegment(0.0, 10.0));
      expect(segments.lineSegments[2], const LineSegment(0.0, 15.0));
      expect(segments.totalPositionedLengthIncludesPadding, 15.0);
      expect(segments.isOverflown, false);
    });


    /* Replacing asserts with setting _freePadding to 0 if negative. Caller should allow this,
                      and if layoutSize exceeds Constraints, deal with it there
    test('LayedoutLengthsPositioner.layout() Matrjoska Left, total length less than needed, should Exception', () {
      expect(
          () => LayedoutLengthsPositioner(
                lengths: lengths,
                lengthsPositionerProperties:
                    LengthsPositionerProperties(packing: Packing.matrjoska, align: Align.start)
                    lengthsConstraint: 10.0,
              ),
          flutter_test.throwsAssertionError);
    });
    */
    test('LayedoutLengthsPositioner.layout() Matrjoska Left, total length less than needed, uses 0 for free space', () {
      PositionedLineSegments segments = matrjoskaLeftLengthConstraints10LessThanSizes.layoutLengths();

      expect(segments.lineSegments.length, 3);
      // Result should be same as with no total length enforced
      expect(segments.lineSegments[0], const LineSegment(0.0, 5.0));
      expect(segments.lineSegments[1], const LineSegment(0.0, 10.0));
      expect(segments.lineSegments[2], const LineSegment(0.0, 15.0));
      expect(segments.totalPositionedLengthIncludesPadding, 15.0);
      expect(segments.isOverflown, true);
    });

    test('LayedoutLengthsPositioner.layout() Matrjoska Left, total length more than required', () {
      PositionedLineSegments segments = matrjoskaLeftTotalLength27Added12.layoutLengths();

      expect(segments.lineSegments.length, 3);
      // Result should be same as with no total length enforced. 
      // The whole padding of 12 is on the right.
      expect(segments.lineSegments[0], const LineSegment(0.0, 5.0));
      expect(segments.lineSegments[1], const LineSegment(0.0, 10.0));
      expect(segments.lineSegments[2], const LineSegment(0.0, 15.0));
      expect(segments.totalPositionedLengthIncludesPadding, 27.0);
      expect(segments.isOverflown, false);
    });
  });

  group('LayedoutLengthsPositioner.layout() Matrjoska Center,', () {
    var matrjoskaCenterLengthsConstraintLessThanSizes = LayedoutLengthsPositioner(
      lengths: lengths,
      lengthsPositionerProperties: LengthsPositionerProperties(packing: Packing.matrjoska, align: Align.center, layoutDirection: LayoutDirection.alongCoordinates, isPositioningMainAxis: true),
      lengthsConstraint: 0.0,
    );
    var matrjoskaCenterTotalLength27Added12 = LayedoutLengthsPositioner(
      lengths: lengths,
      lengthsPositionerProperties: LengthsPositionerProperties(packing: Packing.matrjoska, align: Align.center, layoutDirection: LayoutDirection.alongCoordinates, isPositioningMainAxis: true),
      lengthsConstraint: 27.0,
    );

    test('LayedoutLengthsPositioner.layout() Matrjoska Center, no total length enforced', () {
      PositionedLineSegments segments = matrjoskaCenterLengthsConstraintLessThanSizes.layoutLengths();

      // no padding added
      expect(segments.lineSegments.length, 3);
      expect(segments.lineSegments[0], const LineSegment(5.0, 10.0));
      expect(segments.lineSegments[1], const LineSegment(2.5, 12.5));
      expect(segments.lineSegments[2], const LineSegment(0.0, 15.0));
      expect(segments.totalPositionedLengthIncludesPadding, 15.0);
      expect(segments.isOverflown, true);
    });

    test('LayedoutLengthsPositioner.layout() Matrjoska Center, total length more than required', () {
      PositionedLineSegments segments = matrjoskaCenterTotalLength27Added12.layoutLengths();
      const double halfOfFreePadding = 6.0;

      expect(segments.lineSegments.length, 3);
      // Compared to no total length enforced, move everything by halfOfFreePadding to the right.
      // The padding of 12 is half on the left (6) and half on the right (6)
      expect(segments.lineSegments[0], const LineSegment(5.0 + halfOfFreePadding, 10.0 + halfOfFreePadding));
      expect(segments.lineSegments[1], const LineSegment(2.5 + halfOfFreePadding, 12.5 + halfOfFreePadding));
      expect(segments.lineSegments[2], const LineSegment(0.0 + halfOfFreePadding, 15.0 + halfOfFreePadding));
      expect(segments.totalPositionedLengthIncludesPadding, 27.0);
      expect(segments.isOverflown, false);
    });
  });

  group('LayedoutLengthsPositioner.layout() Matrjoska Right,', () {
    var matrjoskaRightLengthsConstraintLessThanSizes = LayedoutLengthsPositioner(
      lengths: lengths,
      lengthsPositionerProperties: LengthsPositionerProperties(packing: Packing.matrjoska, align: Align.end, layoutDirection: LayoutDirection.alongCoordinates, isPositioningMainAxis: true),
      lengthsConstraint : 0.0,
    );
    var matrjoskaRightTotalLength27Added12 = LayedoutLengthsPositioner(
      lengths: lengths,
      lengthsPositionerProperties: LengthsPositionerProperties(packing: Packing.matrjoska, align: Align.end, layoutDirection: LayoutDirection.alongCoordinates, isPositioningMainAxis: true),
      lengthsConstraint : 27.0,
    );

    test('LayedoutLengthsPositioner.layout() Matrjoska Right, no total length enforced', () {
      PositionedLineSegments segments = matrjoskaRightLengthsConstraintLessThanSizes.layoutLengths();

      // no padding added
      expect(segments.lineSegments.length, 3);
      expect(segments.lineSegments[0], const LineSegment(10.0, 15.0));
      expect(segments.lineSegments[1], const LineSegment(5.0, 15.0));
      expect(segments.lineSegments[2], const LineSegment(0.0, 15.0));
      expect(segments.totalPositionedLengthIncludesPadding, 15.0);
      expect(segments.isOverflown, true);
   });

    test('LayedoutLengthsPositioner.layout() Matrjoska Right, total length more than required', () {
      PositionedLineSegments segments = matrjoskaRightTotalLength27Added12.layoutLengths();
      const double fullFreePadding = 12.0;

      expect(segments.lineSegments.length, 3);
      // Compared to no total length enforced, move everything by fullFreePadding to the right.
      // The whole padding of 12 is on the left.
      expect(segments.lineSegments[0], const LineSegment(10.0 + fullFreePadding, 15.0 + fullFreePadding));
      expect(segments.lineSegments[1], const LineSegment(5.0 + fullFreePadding, 15.0 + fullFreePadding));
      expect(segments.lineSegments[2], const LineSegment(0.0 + fullFreePadding, 15.0 + fullFreePadding));
      expect(segments.totalPositionedLengthIncludesPadding, 27.0);
      expect(segments.isOverflown, false);
    });
  });

  // ### Packing.tight

  group('LayedoutLengthsPositioner.layout() Tight Left,', () {
    var tightLeftLengthsConstraintLessThanSizes = LayedoutLengthsPositioner(
      lengths: lengths,
      lengthsPositionerProperties: LengthsPositionerProperties(packing: Packing.tight, align: Align.start, layoutDirection: LayoutDirection.alongCoordinates, isPositioningMainAxis: true),
      lengthsConstraint: 0.0,
    );
    // Testing exception so create in test : var tightLeftTotalLength10Exception
    var tightLeftTotalLength30 = LayedoutLengthsPositioner(
      lengths: lengths,
      lengthsPositionerProperties: LengthsPositionerProperties(packing: Packing.tight, align: Align.start, layoutDirection: LayoutDirection.alongCoordinates, isPositioningMainAxis: true),
      lengthsConstraint: 30.0,
    );
    var tightLeftTotalLength42Added12 = LayedoutLengthsPositioner(
      lengths: lengths,
      lengthsPositionerProperties: LengthsPositionerProperties(packing: Packing.tight, align: Align.start, layoutDirection: LayoutDirection.alongCoordinates, isPositioningMainAxis: true),
      lengthsConstraint: 42.0,
    );
    var tightLeftTotalLengthsConstraint10LessThanSizes = LayedoutLengthsPositioner(
      lengths: lengths,
      lengthsPositionerProperties: LengthsPositionerProperties(packing: Packing.tight, align: Align.start, layoutDirection: LayoutDirection.alongCoordinates, isPositioningMainAxis: true),
      lengthsConstraint: 10.0,
    );

    test('LayedoutLengthsPositioner.layout() Tight Left, no total length enforced', () {
      PositionedLineSegments segments = tightLeftLengthsConstraintLessThanSizes.layoutLengths();

      // no padding added
      expect(segments.lineSegments.length, 3);
      expect(segments.lineSegments[0], const LineSegment(0.0, 5.0));
      expect(segments.lineSegments[1], const LineSegment(5.0, 15.0));
      expect(segments.lineSegments[2], const LineSegment(15.0, 30.0));
      expect(segments.totalPositionedLengthIncludesPadding, 30.0);
      expect(segments.isOverflown, true);
    });

    test('LayedoutLengthsPositioner.layout() Tight Left, total length same as required', () {
      PositionedLineSegments segments = tightLeftTotalLength30.layoutLengths();

      expect(segments.lineSegments.length, 3);
      // Result should be same as with no total length enforced
      expect(segments.lineSegments[0], const LineSegment(0.0, 5.0));
      expect(segments.lineSegments[1], const LineSegment(5.0, 15.0));
      expect(segments.lineSegments[2], const LineSegment(15.0, 30.0));
      expect(segments.totalPositionedLengthIncludesPadding, 30.0);
      expect(segments.isOverflown, false);
    });

    test('LayedoutLengthsPositioner.layout() Tight Left, total length less than needed, uses 0 for free space', () {
       PositionedLineSegments segments = tightLeftTotalLengthsConstraint10LessThanSizes.layoutLengths();
       expect(segments.lineSegments.length, 3);
       // Result should be same as with no total length enforced
       expect(segments.lineSegments[0], const LineSegment(0.0, 5.0));
       expect(segments.lineSegments[1], const LineSegment(5.0, 15.0));
       expect(segments.lineSegments[2], const LineSegment(15.0, 30.0));
       expect(segments.totalPositionedLengthIncludesPadding, 30.0);
       expect(segments.isOverflown, true);
    });

    /* Replacing asserts with setting _freePadding to 0 if negative. Caller should allow this,
                      and if layoutSize exceeds Constraints, deal with it there
    test('LayedoutLengthsPositioner.layout() Matrjoska Left, total length less than needed, should Exception', () {
       expect(
          () => LayedoutLengthsPositioner(
                lengths: lengths,
                lengthsPositionerProperties: LengthsPositionerProperties(packing: Packing.tight, align: Align.start),
                lengthsConstraint: 10.0,
              ),
          flutter_test.throwsAssertionError);
    });
    */

    test('LayedoutLengthsPositioner.layout() Tight Left, total length more than required', () {
      PositionedLineSegments segments = tightLeftTotalLength42Added12.layoutLengths();

      expect(segments.lineSegments.length, 3);
      // Result should be same as with no total length enforced
      expect(segments.lineSegments[0], const LineSegment(0.0, 5.0));
      expect(segments.lineSegments[1], const LineSegment(5.0, 15.0));
      expect(segments.lineSegments[2], const LineSegment(15.0, 30.0));
      expect(segments.totalPositionedLengthIncludesPadding, 42.0);
      expect(segments.isOverflown, false);
    });
  });

  group('LayedoutLengthsPositioner.layout() Tight Center,', () {
    var tightCenterLengthsConstraintLessThanSizes = LayedoutLengthsPositioner(
      lengths: lengths,
      lengthsPositionerProperties: LengthsPositionerProperties(packing: Packing.tight, align: Align.center, layoutDirection: LayoutDirection.alongCoordinates, isPositioningMainAxis: true),
      lengthsConstraint: 0.0,
    );
    var tightCenterTotalLength42Added12 = LayedoutLengthsPositioner(
      lengths: lengths,
      lengthsPositionerProperties: LengthsPositionerProperties(packing: Packing.tight, align: Align.center, layoutDirection: LayoutDirection.alongCoordinates, isPositioningMainAxis: true),
      lengthsConstraint: 42.0,
    );

    test('LayedoutLengthsPositioner.layout() Tight Center, no total length enforced', () {
      PositionedLineSegments segments = tightCenterLengthsConstraintLessThanSizes.layoutLengths();

      // no padding added
      expect(segments.lineSegments.length, 3);
      // As in Tight Left
      expect(segments.lineSegments[0], const LineSegment(0.0, 5.0));
      expect(segments.lineSegments[1], const LineSegment(5.0, 15.0));
      expect(segments.lineSegments[2], const LineSegment(15.0, 30.0));
      expect(segments.totalPositionedLengthIncludesPadding, 30.0);
      expect(segments.isOverflown, true);
    });

    test('LayedoutLengthsPositioner.layout() Tight Center, total length more than required', () {
      PositionedLineSegments segments = tightCenterTotalLength42Added12.layoutLengths();
      const double halfOfFreePadding = 6.0;

      expect(segments.lineSegments.length, 3);
      // Compared to no total length enforced, move everything by halfOfFreePadding to the right,
      // to center the whole group (which is tightped together)
      expect(segments.lineSegments[0], const LineSegment(0.0 + halfOfFreePadding, 5.0 + halfOfFreePadding));
      expect(segments.lineSegments[1], const LineSegment(5.0 + halfOfFreePadding, 15.0 + halfOfFreePadding));
      expect(segments.lineSegments[2], const LineSegment(15.0 + halfOfFreePadding, 30.0 + halfOfFreePadding));
      expect(segments.totalPositionedLengthIncludesPadding, 42.0);
      expect(segments.isOverflown, false);
    });
  });

  group('LayedoutLengthsPositioner.layout() Tight Right,', () {
    var tightRightLengthsConstraintLessThanSizes = LayedoutLengthsPositioner(
      lengths: lengths,
      lengthsPositionerProperties: LengthsPositionerProperties(packing: Packing.tight, align: Align.end, layoutDirection: LayoutDirection.alongCoordinates, isPositioningMainAxis: true),
        lengthsConstraint: 0.0
    );
    var tightRightTotalLength42Added12 = LayedoutLengthsPositioner(
      lengths: lengths,
      lengthsPositionerProperties: LengthsPositionerProperties(packing: Packing.tight, align: Align.end, layoutDirection: LayoutDirection.alongCoordinates, isPositioningMainAxis: true),
      lengthsConstraint: 42.0
    );

    test('LayedoutLengthsPositioner.layout() Tight Right, no total length enforced', () {
      PositionedLineSegments segments = tightRightLengthsConstraintLessThanSizes.layoutLengths();

      // no padding added
      expect(segments.lineSegments.length, 3);
      // As in Tight Left, and as in TightCenter
      expect(segments.lineSegments[0], const LineSegment(0.0, 5.0));
      expect(segments.lineSegments[1], const LineSegment(5.0, 15.0));
      expect(segments.lineSegments[2], const LineSegment(15.0, 30.0));
      expect(segments.totalPositionedLengthIncludesPadding, 30.0);
      expect(segments.isOverflown, true);
    });

    test('LayedoutLengthsPositioner.layout() Tight Right, total length more than required', () {
      PositionedLineSegments segments = tightRightTotalLength42Added12.layoutLengths();
      const double fullFreePadding = 12.0;

      expect(segments.lineSegments.length, 3);
      // Compared to no total length enforced, move everything by fullFreePadding to the right
      expect(segments.lineSegments[0], const LineSegment(0.0 + fullFreePadding, 5.0 + fullFreePadding));
      expect(segments.lineSegments[1], const LineSegment(5.0 + fullFreePadding, 15.0 + fullFreePadding));
      expect(segments.lineSegments[2], const LineSegment(15.0 + fullFreePadding, 30.0 + fullFreePadding));
      expect(segments.totalPositionedLengthIncludesPadding, 42.0);
      expect(segments.isOverflown, false);
    });
  });

  // ### Packing.loose

  group('LayedoutLengthsPositioner.layout() Loose Left,', () {
    var looseLeftLengthsConstraintLessThanSizes = LayedoutLengthsPositioner(
      lengths: lengths,
      lengthsPositionerProperties: LengthsPositionerProperties(packing: Packing.loose, align: Align.start, layoutDirection: LayoutDirection.alongCoordinates, isPositioningMainAxis: true),
      lengthsConstraint: 0.0
    );
    // Testing exception so create in test : var looseLeftTotalLength10Exception
    var looseLeftTotalLength30 = LayedoutLengthsPositioner(
      lengths: lengths,
      lengthsPositionerProperties: LengthsPositionerProperties(packing: Packing.loose, align: Align.start, layoutDirection: LayoutDirection.alongCoordinates, isPositioningMainAxis: true),
      lengthsConstraint: 30.0
    );
    var looseLeftTotalLength42Added12 = LayedoutLengthsPositioner(
      lengths: lengths,
      lengthsPositionerProperties: LengthsPositionerProperties(packing: Packing.loose, align: Align.start, layoutDirection: LayoutDirection.alongCoordinates, isPositioningMainAxis: true),
      lengthsConstraint: 42.0,
    );
    var looseLeftTotalLength30MakesFreeSpaceNegativeForcingFreeSpaceTo0 = LayedoutLengthsPositioner(
      lengths: lengths,
      lengthsPositionerProperties: LengthsPositionerProperties(packing: Packing.loose, align: Align.start, layoutDirection: LayoutDirection.alongCoordinates, isPositioningMainAxis: true),
      lengthsConstraint: 30.0,
    );

    test('LayedoutLengthsPositioner.layout() Loose Left, no total length enforced', () {
      PositionedLineSegments segments = looseLeftLengthsConstraintLessThanSizes.layoutLengths();

      // no padding added
      expect(segments.lineSegments.length, 3);
      expect(segments.lineSegments[0], const LineSegment(0.0, 5.0));
      expect(segments.lineSegments[1], const LineSegment(5.0, 15.0));
      expect(segments.lineSegments[2], const LineSegment(15.0, 30.0));
      expect(segments.totalPositionedLengthIncludesPadding, 30.0);
      expect(segments.isOverflown, true);
    });

    test('LayedoutLengthsPositioner.layout() Loose Left, total length same as required', () {
      PositionedLineSegments segments = looseLeftTotalLength30.layoutLengths();

      expect(segments.lineSegments.length, 3);
      // Result should be same as with no total length enforced
      expect(segments.lineSegments[0], const LineSegment(0.0, 5.0));
      expect(segments.lineSegments[1], const LineSegment(5.0, 15.0));
      expect(segments.lineSegments[2], const LineSegment(15.0, 30.0));
      expect(segments.totalPositionedLengthIncludesPadding, 30.0);
      expect(segments.isOverflown, false);
    });

    /*  Replacing asserts with setting _freePadding to 0 if negative. Caller should allow this,
                      and if layoutSize exceeds Constraints, deal with it there
    test('LayedoutLengthsPositioner.layout() Loose Left, total length less than needed, should Exception', () {
      expect(
          () => LayedoutLengthsPositioner(
                lengths: lengths,
                lengthsPositionerProperties: LengthsPositionerProperties(packing: Packing.loose, align: Align.start),
                lengthsConstraint: 10.0,
              ),
          flutter_test.throwsAssertionError);
    });
    */

    test('LayedoutLengthsPositioner.layout() Loose Left, total length less than needed, uses 0 for free space', () {
      PositionedLineSegments segments = looseLeftTotalLength30MakesFreeSpaceNegativeForcingFreeSpaceTo0.layoutLengths();
      expect(segments.lineSegments.length, 3);
      // Result should be same as with no total length enforced
      expect(segments.lineSegments[0], const LineSegment(0.0, 5.0));
      expect(segments.lineSegments[1], const LineSegment(5.0, 15.0));
      expect(segments.lineSegments[2], const LineSegment(15.0, 30.0));
      expect(segments.totalPositionedLengthIncludesPadding, 30.0);
      expect(segments.isOverflown, false);
    });

    test('LayedoutLengthsPositioner.layout() Loose Left, total length more than required', () {
      PositionedLineSegments segments = looseLeftTotalLength42Added12.layoutLengths();
      const int lengthsCount = 3;
      const double freePadding = 12.0 / lengthsCount;

      expect(segments.lineSegments.length, 3);
      // Aligns first element to min, then adds left padding freePadding long after every element,
      // so the rightmost element has a padding freePadding long.
      expect(segments.lineSegments[0], const LineSegment(0.0, 5.0));
      expect(segments.lineSegments[1], const LineSegment(5.0 + freePadding * 1, 15.0 + freePadding * 1));
      expect(segments.lineSegments[2], const LineSegment(15.0 + freePadding * 2, 30.0 + freePadding * 2));
      expect(segments.totalPositionedLengthIncludesPadding, 42.0);
      expect(segments.isOverflown, false);
    });
  });

  group('LayedoutLengthsPositioner.layout() Loose Center,', () {
    var looseCenterLengthsConstraintLessThanSizes = LayedoutLengthsPositioner(
      lengths: lengths,
      lengthsPositionerProperties: LengthsPositionerProperties(packing: Packing.loose, align: Align.center, layoutDirection: LayoutDirection.alongCoordinates, isPositioningMainAxis: true),
        lengthsConstraint: 0.0
    );
    var looseCenterTotalLength42Added12 = LayedoutLengthsPositioner(
      lengths: lengths,
      lengthsPositionerProperties: LengthsPositionerProperties(packing: Packing.loose, align: Align.center, layoutDirection: LayoutDirection.alongCoordinates, isPositioningMainAxis: true),
      lengthsConstraint: 42.0
    );

    test('LayedoutLengthsPositioner.layout() Loose Center, no total length enforced', () {
      PositionedLineSegments segments = looseCenterLengthsConstraintLessThanSizes.layoutLengths();

      // no padding added
      expect(segments.lineSegments.length, 3);
      // As in Loose Left
      expect(segments.lineSegments[0], const LineSegment(0.0, 5.0));
      expect(segments.lineSegments[1], const LineSegment(5.0, 15.0));
      expect(segments.lineSegments[2], const LineSegment(15.0, 30.0));
      expect(segments.totalPositionedLengthIncludesPadding, 30.0);
      expect(segments.isOverflown, true);
    });

    test('LayedoutLengthsPositioner.layout() Loose Center, total length more than required', () {
      PositionedLineSegments segments = looseCenterTotalLength42Added12.layoutLengths();
      const int lengthsCount = 3;
      const double freePadding = 12.0 / (lengthsCount + 1); // 3.0

      expect(segments.lineSegments.length, 3);
      // Aligns last element end to max, then adds left padding freePadding long after every element,
      // and the first element has a padding freePadding long.
      expect(segments.lineSegments[0], const LineSegment(0.0 + freePadding * 1, 5.0 + freePadding * 1));
      expect(segments.lineSegments[1], const LineSegment(5.0 + freePadding * 2, 15.0 + freePadding * 2));
      expect(segments.lineSegments[2], const LineSegment(15.0 + freePadding * 3, 30.0 + freePadding * 3));
      expect(segments.totalPositionedLengthIncludesPadding, 42.0);
      expect(segments.isOverflown, false);
    });
  });

  group('LayedoutLengthsPositioner.layout() Loose Right,', () {
    var looseRightLengthsConstraintLessThanSizes = LayedoutLengthsPositioner(
      lengths: lengths,
      lengthsPositionerProperties: LengthsPositionerProperties(packing: Packing.loose, align: Align.end, layoutDirection: LayoutDirection.alongCoordinates, isPositioningMainAxis: true),
      lengthsConstraint: 0.0,
    );
    var looseRightTotalLength42Added12 = LayedoutLengthsPositioner(
      lengths: lengths,
      lengthsPositionerProperties: LengthsPositionerProperties(packing: Packing.loose, align: Align.end, layoutDirection: LayoutDirection.alongCoordinates, isPositioningMainAxis: true),
      lengthsConstraint: 42.0,
    );

    test('LayedoutLengthsPositioner.layout() Loose Right, no total length enforced', () {
      PositionedLineSegments segments = looseRightLengthsConstraintLessThanSizes.layoutLengths();

      // no padding added
      expect(segments.lineSegments.length, 3);
      expect(segments.lineSegments[0], const LineSegment(0.0, 5.0));
      expect(segments.lineSegments[1], const LineSegment(5.0, 15.0));
      expect(segments.lineSegments[2], const LineSegment(15.0, 30.0));
      expect(segments.totalPositionedLengthIncludesPadding, 30.0);
      expect(segments.isOverflown, true);
    });

    test('LayedoutLengthsPositioner.layout() Loose Right, total length more than required', () {
      PositionedLineSegments segments = looseRightTotalLength42Added12.layoutLengths();
      const int lengthsCount = 3;
      const double freePadding = 12.0 / lengthsCount; // 4.0

      expect(segments.lineSegments.length, 3);
      // Aligns last element end to max, then adds left padding freePadding long after every element,
      // and the first element has a padding freePadding long.
      expect(segments.lineSegments[0], const LineSegment(0.0 + freePadding * 1, 5.0 + freePadding * 1));
      expect(segments.lineSegments[1], const LineSegment(5.0 + freePadding * 2, 15.0 + freePadding * 2));
      expect(segments.lineSegments[2], const LineSegment(15.0 + freePadding * 3, 30.0 + freePadding * 3));
      expect(segments.totalPositionedLengthIncludesPadding, 42.0);
      expect(segments.isOverflown, false);
    });
  });
}
