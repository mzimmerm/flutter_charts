/// Tests the methods in the `string_extension` package.

import 'package:test/test.dart';

// tested package
import 'package:flutter_charts/src/util/extension_string.dart' show StringExtension;

enum TestedEnum { enum1, enum2 }

void main() {
  // enum related string extensions.
  group('enum', () {
    test('Convert string literal (representing a valid enum name) to enum', () {
      final TestedEnum testedEnum = 'enum1'.asEnum(TestedEnum.values);
      expect(testedEnum, TestedEnum.enum1);
    });

    test('Convert string object (representing a valid enum name) to enum', () {
      const String enum1 = 'enum1';
      final TestedEnum testedEnum = enum1.asEnum(TestedEnum.values);
      expect(testedEnum, TestedEnum.enum1);
    });

    test('Convert string which does not have representation should cause exception', () {
      // Checking error thrown requires first argument to be a Function,
      //   NOT a function call such as just "NOT_IN_ENUM".asEnum(TestedEnum.values).
      expect(() => 'NOT_IN_ENUM'.asEnum(TestedEnum.values), throwsStateError);
    });

    test('Convert string which does not have representation should cause exception. Test the exception string.', () {
      String errorText = '';
      try {
        'NOT_IN_ENUM'.asEnum(TestedEnum.values);
      } on Error catch (e) {
        errorText = e.toString();
      }
      expect(errorText.contains('String NOT_IN_ENUM is not in enum list [TestedEnum.enum1, TestedEnum.enum2]'), true);
    });
  });

  // next group
}
