import 'package:test/test.dart';

// tested package
import 'package:flutter_charts/src/util/string_extension.dart';

// todo-00 document

enum MyEnum { enum1, enum2 }

void main() {
  
  // enum related string extensions.
  group("enum", () {
    test('Convert string literal (representing a valid enum name) to enum', () {
      final MyEnum myEnum = 'enum1'.asEnum(MyEnum.values);
      expect(myEnum, MyEnum.enum1);
    });

    test('Convert string object (representing a valid enum name) to enum', () {
      final String enum1 = 'enum1';
      final MyEnum myEnum = enum1.asEnum(MyEnum.values);
      expect(myEnum, MyEnum.enum1);
    });

    test('Convert string which does not have representation should cause exception', () {
      expect(() => "NOT_IN_ENUM".asEnum(MyEnum.values), throwsStateError);
    });
    
    test('Convert string which does not have representation should cause exception. Test the exception string.', () {
      String errorText = "";
      try {
        "NOT_IN_ENUM".asEnum(MyEnum.values);
      } on Error catch(e) {
        errorText = e.toString();
      }
      expect(errorText.contains('String NOT_IN_ENUM is not in enum list [MyEnum.enum1, MyEnum.enum2]'), true);
    });
  });
  
  // next group
}
