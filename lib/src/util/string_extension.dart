/// Library of extensions on the [String] class.
/// 

import 'package:flutter/foundation.dart' as flutter_foundation show describeEnum;

extension StringExtension on String {
  
  /// Convert this string to enum.
  /// 
  /// In more detail:
  ///   - If this string is a valid enum name in the passed enumValues, returns the enum value 
  ///     represented by this string.
  ///   - If this string does not represent an enum in the passed enumValues, 
  ///     a StateError is thrown, indicating the values that failed.
  T asEnum<T extends Enum>(List<T> enumValues) {
    try {
      return enumValues.singleWhere((v) => this == flutter_foundation.describeEnum(v));
    } on Error catch (e) {
      throw StateError('String $this is not in enum list $enumValues.');
    }
  }
  
  
}


