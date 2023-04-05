// Needed if we want to use isAssertionError or throwsAssertionError, otherwise same as test.dart.
// import 'package:flutter_test/flutter_test.dart' as flutter_test show throwsAssertionError;
import 'package:test/test.dart';

import 'package:flutter_charts/src/morphic/container/layouter_one_dimensional.dart'
    show Align, LayedoutLengthsPositioner, LengthsPositionerProperties, Packing, PositionedLineSegments;
import 'package:flutter_charts/src/util/util_dart.dart' show LineSegment;


main() {
  List<double> lengths = [5.0, 10.0, 15.0];

  // ### Packing.matrjoska

  group('LayedoutLengthsPositioner.layout() Matrjoska Start,', () {
    var matrjoskaStartLengthsConstraintLessThanSizes = LayedoutLengthsPositioner(
      lengths: lengths,
      lengthsPositionerProperties: const LengthsPositionerProperties(packing: Packing.matrjoska, align: Align.start),
      lengthsConstraint: 0.0,
    );
    // Testing exception so create in test : var matrjoskaStartTotalLength10Exception
    var matrjoskaStartTotalLength15 = LayedoutLengthsPositioner(
      lengths: lengths,
      lengthsPositionerProperties: const LengthsPositionerProperties(packing: Packing.matrjoska, align: Align.start),
      lengthsConstraint: 15.0,
    );
    var matrjoskaStartTotalLength27Added12 = LayedoutLengthsPositioner(
      lengths: lengths,
      lengthsPositionerProperties: const LengthsPositionerProperties(packing: Packing.matrjoska, align: Align.start),
      lengthsConstraint: 27.0,
    );
    var matrjoskaStartLengthConstraints10LessThanSizes = LayedoutLengthsPositioner(
      lengths: lengths,
      lengthsPositionerProperties: const LengthsPositionerProperties(packing: Packing.matrjoska, align: Align.start),
      lengthsConstraint: 10.0,
    );

    test('LayedoutLengthsPositioner.layout() Matrjoska Start, no total length enforced', () {
      PositionedLineSegments segments = matrjoskaStartLengthsConstraintLessThanSizes.positionLengths();

      // no padding added
      expect(segments.lineSegments.length, 3);
      expect(segments.lineSegments[0], const LineSegment(0.0, 5.0));
      expect(segments.lineSegments[1], const LineSegment(0.0, 10.0));
      expect(segments.lineSegments[2], const LineSegment(0.0, 15.0));
      expect(segments.totalPositionedLengthIncludesPadding, 15.0);
      expect(segments.isOverflown, true);
    });

    test('LayedoutLengthsPositioner.layout() Matrjoska Start, total length same as required', () {
      PositionedLineSegments segments = matrjoskaStartTotalLength15.positionLengths();

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
    test('LayedoutLengthsPositioner.layout() Matrjoska Start, total length less than needed, should Exception', () {
      expect(
          () => LayedoutLengthsPositioner(
                lengths: lengths,
                lengthsPositionerProperties:
                    const LengthsPositionerProperties(packing: Packing.matrjoska, align: Align.start)
                    lengthsConstraint: 10.0,
              ),
          flutter_test.throwsAssertionError);
    });
    */
    test('LayedoutLengthsPositioner.layout() Matrjoska Start, total length less than needed, uses 0 for free space', () {
      PositionedLineSegments segments = matrjoskaStartLengthConstraints10LessThanSizes.positionLengths();

      expect(segments.lineSegments.length, 3);
      // Result should be same as with no total length enforced
      expect(segments.lineSegments[0], const LineSegment(0.0, 5.0));
      expect(segments.lineSegments[1], const LineSegment(0.0, 10.0));
      expect(segments.lineSegments[2], const LineSegment(0.0, 15.0));
      expect(segments.totalPositionedLengthIncludesPadding, 15.0);
      expect(segments.isOverflown, true);
    });

    test('LayedoutLengthsPositioner.layout() Matrjoska Start, total length more than required', () {
      PositionedLineSegments segments = matrjoskaStartTotalLength27Added12.positionLengths();

      expect(segments.lineSegments.length, 3);
      // Result should be same as with no total length enforced. 
      // The whole padding of 12 is on the end.
      expect(segments.lineSegments[0], const LineSegment(0.0, 5.0));
      expect(segments.lineSegments[1], const LineSegment(0.0, 10.0));
      expect(segments.lineSegments[2], const LineSegment(0.0, 15.0));
      // todo-00-last-last-done : expect(segments.totalPositionedLengthIncludesPadding, 27.0);
      expect(segments.totalPositionedLengthIncludesPadding, 15.0);
      expect(segments.isOverflown, false);
    });
  });

  group('LayedoutLengthsPositioner.layout() Matrjoska Center,', () {
    var matrjoskaCenterLengthsConstraintLessThanSizes = LayedoutLengthsPositioner(
      lengths: lengths,
      lengthsPositionerProperties: const LengthsPositionerProperties(packing: Packing.matrjoska, align: Align.center),
      lengthsConstraint: 0.0,
    );
    var matrjoskaCenterTotalLength27Added12 = LayedoutLengthsPositioner(
      lengths: lengths,
      lengthsPositionerProperties: const LengthsPositionerProperties(packing: Packing.matrjoska, align: Align.center),
      lengthsConstraint: 27.0,
    );

    test('LayedoutLengthsPositioner.layout() Matrjoska Center, no total length enforced', () {
      PositionedLineSegments segments = matrjoskaCenterLengthsConstraintLessThanSizes.positionLengths();

      // no padding added
      expect(segments.lineSegments.length, 3);
      expect(segments.lineSegments[0], const LineSegment(5.0, 10.0));
      expect(segments.lineSegments[1], const LineSegment(2.5, 12.5));
      expect(segments.lineSegments[2], const LineSegment(0.0, 15.0));
      expect(segments.totalPositionedLengthIncludesPadding, 15.0);
      expect(segments.isOverflown, true);
    });

    test('LayedoutLengthsPositioner.layout() Matrjoska Center, total length more than required', () {
      PositionedLineSegments segments = matrjoskaCenterTotalLength27Added12.positionLengths();
      const double halfOfFreePadding = 6.0;

      expect(segments.lineSegments.length, 3);
      // Compared to no total length enforced, move everything by halfOfFreePadding to the end.
      // The padding of 12 is half on the start (6) and half on the end (6)
      expect(segments.lineSegments[0], const LineSegment(5.0 + halfOfFreePadding, 10.0 + halfOfFreePadding));
      expect(segments.lineSegments[1], const LineSegment(2.5 + halfOfFreePadding, 12.5 + halfOfFreePadding));
      expect(segments.lineSegments[2], const LineSegment(0.0 + halfOfFreePadding, 15.0 + halfOfFreePadding));
      expect(segments.totalPositionedLengthIncludesPadding, 27.0);
      expect(segments.isOverflown, false);
    });
  });

  group('LayedoutLengthsPositioner.layout() Matrjoska End,', () {
    var matrjoskaEndLengthsConstraintLessThanSizes = LayedoutLengthsPositioner(
      lengths: lengths,
      lengthsPositionerProperties: const LengthsPositionerProperties(packing: Packing.matrjoska, align: Align.end),
      lengthsConstraint : 0.0,
    );
    var matrjoskaEndTotalLength27Added12 = LayedoutLengthsPositioner(
      lengths: lengths,
      lengthsPositionerProperties: const LengthsPositionerProperties(packing: Packing.matrjoska, align: Align.end),
      lengthsConstraint : 27.0,
    );

    test('LayedoutLengthsPositioner.layout() Matrjoska End, no total length enforced', () {
      PositionedLineSegments segments = matrjoskaEndLengthsConstraintLessThanSizes.positionLengths();

      // no padding added
      expect(segments.lineSegments.length, 3);
      expect(segments.lineSegments[0], const LineSegment(10.0, 15.0));
      expect(segments.lineSegments[1], const LineSegment(5.0, 15.0));
      expect(segments.lineSegments[2], const LineSegment(0.0, 15.0));
      expect(segments.totalPositionedLengthIncludesPadding, 15.0);
      expect(segments.isOverflown, true);
   });

    // todo-00-last-last : problem: It looks like Matrjoska + End, when given loose constraints, creates padding. I THINK MATRJOCKA SHOULD ALWAYS BE TIGHT - NO PADDING ADDED
    test('LayedoutLengthsPositioner.layout() Matrjoska End, total length more than required', () {
      PositionedLineSegments segments = matrjoskaEndTotalLength27Added12.positionLengths();
      // todo-00-last-last-done : matrjoska does not do any padding, ever : const double fullFreePadding = 12.0;
      const double fullFreePadding = 0.0;

      expect(segments.lineSegments.length, 3);
      // Compared to no total length enforced, move everything by fullFreePadding to the end.
      // The whole padding of 12 is on the start.
      expect(segments.lineSegments[0], const LineSegment(10.0 + fullFreePadding, 15.0 + fullFreePadding));
      expect(segments.lineSegments[1], const LineSegment(5.0 + fullFreePadding, 15.0 + fullFreePadding));
      expect(segments.lineSegments[2], const LineSegment(0.0 + fullFreePadding, 15.0 + fullFreePadding));
      // todo-00-last-last-done : no free padding used for Matrjoska+Start or + End : expect(segments.totalPositionedLengthIncludesPadding, 27.0);
      expect(segments.totalPositionedLengthIncludesPadding, 15.0);
      expect(segments.isOverflown, false);
    });
  });

  // ### Packing.tight

  group('LayedoutLengthsPositioner.layout() Tight Start,', () {
    var tightStartLengthsConstraintLessThanSizes = LayedoutLengthsPositioner(
      lengths: lengths,
      lengthsPositionerProperties: const LengthsPositionerProperties(packing: Packing.tight, align: Align.start),
      lengthsConstraint: 0.0,
    );
    // Testing exception so create in test : var tightStartTotalLength10Exception
    var tightStartTotalLength30 = LayedoutLengthsPositioner(
      lengths: lengths,
      lengthsPositionerProperties: const LengthsPositionerProperties(packing: Packing.tight, align: Align.start),
      lengthsConstraint: 30.0,
    );
    var tightStartTotalLength42Added12 = LayedoutLengthsPositioner(
      lengths: lengths,
      lengthsPositionerProperties: const LengthsPositionerProperties(packing: Packing.tight, align: Align.start),
      lengthsConstraint: 42.0,
    );
    var tightStartTotalLengthsConstraint10LessThanSizes = LayedoutLengthsPositioner(
      lengths: lengths,
      lengthsPositionerProperties: const LengthsPositionerProperties(packing: Packing.tight, align: Align.start),
      lengthsConstraint: 10.0,
    );

    test('LayedoutLengthsPositioner.layout() Tight Start, no total length enforced', () {
      PositionedLineSegments segments = tightStartLengthsConstraintLessThanSizes.positionLengths();

      // no padding added
      expect(segments.lineSegments.length, 3);
      expect(segments.lineSegments[0], const LineSegment(0.0, 5.0));
      expect(segments.lineSegments[1], const LineSegment(5.0, 15.0));
      expect(segments.lineSegments[2], const LineSegment(15.0, 30.0));
      expect(segments.totalPositionedLengthIncludesPadding, 30.0);
      expect(segments.isOverflown, true);
    });

    test('LayedoutLengthsPositioner.layout() Tight Start, total length same as required', () {
      PositionedLineSegments segments = tightStartTotalLength30.positionLengths();

      expect(segments.lineSegments.length, 3);
      // Result should be same as with no total length enforced
      expect(segments.lineSegments[0], const LineSegment(0.0, 5.0));
      expect(segments.lineSegments[1], const LineSegment(5.0, 15.0));
      expect(segments.lineSegments[2], const LineSegment(15.0, 30.0));
      expect(segments.totalPositionedLengthIncludesPadding, 30.0);
      expect(segments.isOverflown, false);
    });

    test('LayedoutLengthsPositioner.layout() Tight Start, total length less than needed, uses 0 for free space', () {
       PositionedLineSegments segments = tightStartTotalLengthsConstraint10LessThanSizes.positionLengths();
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
    test('LayedoutLengthsPositioner.layout() Matrjoska Start, total length less than needed, should Exception', () {
       expect(
          () => LayedoutLengthsPositioner(
                lengths: lengths,
                lengthsPositionerProperties: const LengthsPositionerProperties(packing: Packing.tight, align: Align.start),
                lengthsConstraint: 10.0,
              ),
          flutter_test.throwsAssertionError);
    });
    */

    test('LayedoutLengthsPositioner.layout() Tight Start, total length more than required', () {
      PositionedLineSegments segments = tightStartTotalLength42Added12.positionLengths();

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
      lengthsPositionerProperties: const LengthsPositionerProperties(packing: Packing.tight, align: Align.center),
      lengthsConstraint: 0.0,
    );
    var tightCenterTotalLength42Added12 = LayedoutLengthsPositioner(
      lengths: lengths,
      lengthsPositionerProperties: const LengthsPositionerProperties(packing: Packing.tight, align: Align.center),
      lengthsConstraint: 42.0,
    );

    test('LayedoutLengthsPositioner.layout() Tight Center, no total length enforced', () {
      PositionedLineSegments segments = tightCenterLengthsConstraintLessThanSizes.positionLengths();

      // no padding added
      expect(segments.lineSegments.length, 3);
      // As in Tight Start
      expect(segments.lineSegments[0], const LineSegment(0.0, 5.0));
      expect(segments.lineSegments[1], const LineSegment(5.0, 15.0));
      expect(segments.lineSegments[2], const LineSegment(15.0, 30.0));
      expect(segments.totalPositionedLengthIncludesPadding, 30.0);
      expect(segments.isOverflown, true);
    });

    test('LayedoutLengthsPositioner.layout() Tight Center, total length more than required', () {
      PositionedLineSegments segments = tightCenterTotalLength42Added12.positionLengths();
      const double halfOfFreePadding = 6.0;

      expect(segments.lineSegments.length, 3);
      // Compared to no total length enforced, move everything by halfOfFreePadding to the end,
      // to center the whole group (which is tightped together)
      expect(segments.lineSegments[0], const LineSegment(0.0 + halfOfFreePadding, 5.0 + halfOfFreePadding));
      expect(segments.lineSegments[1], const LineSegment(5.0 + halfOfFreePadding, 15.0 + halfOfFreePadding));
      expect(segments.lineSegments[2], const LineSegment(15.0 + halfOfFreePadding, 30.0 + halfOfFreePadding));
      expect(segments.totalPositionedLengthIncludesPadding, 42.0);
      expect(segments.isOverflown, false);
    });
  });

  group('LayedoutLengthsPositioner.layout() Tight End,', () {
    // todo-023 : Column with mainAxisAlign: Align.end behaves weird in CrossPointsContainer.  Add to a test, Align.end, Packing.tight.
    var tightEndLengthsConstraintLessThanSizes = LayedoutLengthsPositioner(
      lengths: lengths,
      lengthsPositionerProperties: const LengthsPositionerProperties(packing: Packing.tight, align: Align.end),
        lengthsConstraint: 0.0
    );
    var tightEndTotalLength42Added12 = LayedoutLengthsPositioner(
      lengths: lengths,
      lengthsPositionerProperties: const LengthsPositionerProperties(packing: Packing.tight, align: Align.end),
      lengthsConstraint: 42.0
    );

    test('LayedoutLengthsPositioner.layout() Tight End, no total length enforced', () {
      PositionedLineSegments segments = tightEndLengthsConstraintLessThanSizes.positionLengths();

      // no padding added
      expect(segments.lineSegments.length, 3);
      // As in Tight Start, and as in TightCenter
      expect(segments.lineSegments[0], const LineSegment(0.0, 5.0));
      expect(segments.lineSegments[1], const LineSegment(5.0, 15.0));
      expect(segments.lineSegments[2], const LineSegment(15.0, 30.0));
      expect(segments.totalPositionedLengthIncludesPadding, 30.0);
      expect(segments.isOverflown, true);
    });

    test('LayedoutLengthsPositioner.layout() Tight End, total length more than required', () {
      PositionedLineSegments segments = tightEndTotalLength42Added12.positionLengths();
      const double fullFreePadding = 12.0;

      expect(segments.lineSegments.length, 3);
      // Compared to no total length enforced, move everything by fullFreePadding to the end
      expect(segments.lineSegments[0], const LineSegment(0.0 + fullFreePadding, 5.0 + fullFreePadding));
      expect(segments.lineSegments[1], const LineSegment(5.0 + fullFreePadding, 15.0 + fullFreePadding));
      expect(segments.lineSegments[2], const LineSegment(15.0 + fullFreePadding, 30.0 + fullFreePadding));
      expect(segments.totalPositionedLengthIncludesPadding, 42.0);
      expect(segments.isOverflown, false);
    });
  });

  // ### Packing.loose

  group('LayedoutLengthsPositioner.layout() Loose Start,', () {
    var looseStartLengthsConstraintLessThanSizes = LayedoutLengthsPositioner(
      lengths: lengths,
      lengthsPositionerProperties: const LengthsPositionerProperties(packing: Packing.loose, align: Align.start),
      lengthsConstraint: 0.0
    );
    // Testing exception so create in test : var looseStartTotalLength10Exception
    var looseStartTotalLength30 = LayedoutLengthsPositioner(
      lengths: lengths,
      lengthsPositionerProperties: const LengthsPositionerProperties(packing: Packing.loose, align: Align.start),
      lengthsConstraint: 30.0
    );
    var looseStartTotalLength42Added12 = LayedoutLengthsPositioner(
      lengths: lengths,
      lengthsPositionerProperties: const LengthsPositionerProperties(packing: Packing.loose, align: Align.start),
      lengthsConstraint: 42.0,
    );
    var looseStartTotalLength30MakesFreeSpaceNegativeForcingFreeSpaceTo0 = LayedoutLengthsPositioner(
      lengths: lengths,
      lengthsPositionerProperties: const LengthsPositionerProperties(packing: Packing.loose, align: Align.start),
      lengthsConstraint: 30.0,
    );

    test('LayedoutLengthsPositioner.layout() Loose Start, no total length enforced', () {
      PositionedLineSegments segments = looseStartLengthsConstraintLessThanSizes.positionLengths();

      // no padding added
      expect(segments.lineSegments.length, 3);
      expect(segments.lineSegments[0], const LineSegment(0.0, 5.0));
      expect(segments.lineSegments[1], const LineSegment(5.0, 15.0));
      expect(segments.lineSegments[2], const LineSegment(15.0, 30.0));
      expect(segments.totalPositionedLengthIncludesPadding, 30.0);
      expect(segments.isOverflown, true);
    });

    test('LayedoutLengthsPositioner.layout() Loose Start, total length same as required', () {
      PositionedLineSegments segments = looseStartTotalLength30.positionLengths();

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
    test('LayedoutLengthsPositioner.layout() Loose Start, total length less than needed, should Exception', () {
      expect(
          () => LayedoutLengthsPositioner(
                lengths: lengths,
                lengthsPositionerProperties: const LengthsPositionerProperties(packing: Packing.loose, align: Align.start),
                lengthsConstraint: 10.0,
              ),
          flutter_test.throwsAssertionError);
    });
    */

    test('LayedoutLengthsPositioner.layout() Loose Start, total length less than needed, uses 0 for free space', () {
      PositionedLineSegments segments = looseStartTotalLength30MakesFreeSpaceNegativeForcingFreeSpaceTo0.positionLengths();
      expect(segments.lineSegments.length, 3);
      // Result should be same as with no total length enforced
      expect(segments.lineSegments[0], const LineSegment(0.0, 5.0));
      expect(segments.lineSegments[1], const LineSegment(5.0, 15.0));
      expect(segments.lineSegments[2], const LineSegment(15.0, 30.0));
      expect(segments.totalPositionedLengthIncludesPadding, 30.0);
      expect(segments.isOverflown, false);
    });

    test('LayedoutLengthsPositioner.layout() Loose Start, total length more than required', () {
      PositionedLineSegments segments = looseStartTotalLength42Added12.positionLengths();
      const int lengthsCount = 3;
      const double freePadding = 12.0 / lengthsCount;

      expect(segments.lineSegments.length, 3);
      // Aligns first element to min, then adds start padding freePadding long after every element,
      // so the endmost element has a padding freePadding long.
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
      lengthsPositionerProperties: const LengthsPositionerProperties(packing: Packing.loose, align: Align.center),
        lengthsConstraint: 0.0
    );
    var looseCenterTotalLength42Added12 = LayedoutLengthsPositioner(
      lengths: lengths,
      lengthsPositionerProperties: const LengthsPositionerProperties(packing: Packing.loose, align: Align.center),
      lengthsConstraint: 42.0
    );

    test('LayedoutLengthsPositioner.layout() Loose Center, no total length enforced', () {
      PositionedLineSegments segments = looseCenterLengthsConstraintLessThanSizes.positionLengths();

      // no padding added
      expect(segments.lineSegments.length, 3);
      // As in Loose Start
      expect(segments.lineSegments[0], const LineSegment(0.0, 5.0));
      expect(segments.lineSegments[1], const LineSegment(5.0, 15.0));
      expect(segments.lineSegments[2], const LineSegment(15.0, 30.0));
      expect(segments.totalPositionedLengthIncludesPadding, 30.0);
      expect(segments.isOverflown, true);
    });

    test('LayedoutLengthsPositioner.layout() Loose Center, total length more than required', () {
      PositionedLineSegments segments = looseCenterTotalLength42Added12.positionLengths();
      const int lengthsCount = 3;
      const double freePadding = 12.0 / (lengthsCount + 1); // 3.0

      expect(segments.lineSegments.length, 3);
      // Aligns last element end to max, then adds start padding freePadding long after every element,
      // and the first element has a padding freePadding long.
      expect(segments.lineSegments[0], const LineSegment(0.0 + freePadding * 1, 5.0 + freePadding * 1));
      expect(segments.lineSegments[1], const LineSegment(5.0 + freePadding * 2, 15.0 + freePadding * 2));
      expect(segments.lineSegments[2], const LineSegment(15.0 + freePadding * 3, 30.0 + freePadding * 3));
      expect(segments.totalPositionedLengthIncludesPadding, 42.0);
      expect(segments.isOverflown, false);
    });
  });

  group('LayedoutLengthsPositioner.layout() Loose End,', () {
    var looseEndLengthsConstraintLessThanSizes = LayedoutLengthsPositioner(
      lengths: lengths,
      lengthsPositionerProperties: const LengthsPositionerProperties(packing: Packing.loose, align: Align.end),
      lengthsConstraint: 0.0,
    );
    var looseEndTotalLength42Added12 = LayedoutLengthsPositioner(
      lengths: lengths,
      lengthsPositionerProperties: const LengthsPositionerProperties(packing: Packing.loose, align: Align.end),
      lengthsConstraint: 42.0,
    );

    test('LayedoutLengthsPositioner.layout() Loose End, no total length enforced', () {
      PositionedLineSegments segments = looseEndLengthsConstraintLessThanSizes.positionLengths();

      // no padding added
      expect(segments.lineSegments.length, 3);
      expect(segments.lineSegments[0], const LineSegment(0.0, 5.0));
      expect(segments.lineSegments[1], const LineSegment(5.0, 15.0));
      expect(segments.lineSegments[2], const LineSegment(15.0, 30.0));
      expect(segments.totalPositionedLengthIncludesPadding, 30.0);
      expect(segments.isOverflown, true);
    });

    test('LayedoutLengthsPositioner.layout() Loose End, total length more than required', () {
      PositionedLineSegments segments = looseEndTotalLength42Added12.positionLengths();
      const int lengthsCount = 3;
      const double freePadding = 12.0 / lengthsCount; // 4.0

      expect(segments.lineSegments.length, 3);
      // Aligns last element end to max, then adds start padding freePadding long after every element,
      // and the first element has a padding freePadding long.
      expect(segments.lineSegments[0], const LineSegment(0.0 + freePadding * 1, 5.0 + freePadding * 1));
      expect(segments.lineSegments[1], const LineSegment(5.0 + freePadding * 2, 15.0 + freePadding * 2));
      expect(segments.lineSegments[2], const LineSegment(15.0 + freePadding * 3, 30.0 + freePadding * 3));
      expect(segments.totalPositionedLengthIncludesPadding, 42.0);
      expect(segments.isOverflown, false);
    });
  });
}
