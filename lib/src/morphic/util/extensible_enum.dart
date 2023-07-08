/// Base class for extensible pseudo-enums.
///
abstract class BaseExtensibleEnum {

  const BaseExtensibleEnum(this.i);

  final int i;

  @override
  String toString() => '$runtimeType: instance i=$i';
}
