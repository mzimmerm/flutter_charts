/// Library of extensions on the [String] class.
///
import 'package:flutter_charts/src/util/util_dart.dart';

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
      return enumValues.singleWhere((v) => this == enumName(v));
    } on Error {
      // on Error catch (e) {
      throw StateError('String $this is not in enum list $enumValues.');
    }
  }
}
