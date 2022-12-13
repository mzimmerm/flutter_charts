import 'package:flutter/foundation.dart' show immutable;
import 'package:flutter_charts/src/chart/container_layouter_base.dart';

/// [ContainerKey] is a unique identifier of a [BoxContainer].
///
/// The meaning of 'unique' depends on the 'context'.
///
/// In the current implementation, the only supported 'context' is 'siblings of container hierarchy'.
/// As such, the [ContainerKey] implementations are currently supporting ability to identify [BoxContainer]
/// uniquely among it's children in the [BoxContainerHierarchy].
///
/// In the future context uniqueness may support 'application', or other well-defined subsets of it.
@immutable
abstract class ContainerKey {

  /// Default generative constructor constructs Key without value,
  /// allows extensions to define `const` constructor.
  ///
  /// This trick ensures the default constructor [Key()] is not used,
  /// replaced with this const constructor. Simply trying to use
  ///   `Key();`
  /// or
  ///   `const Key();`
  /// causes a compile error 'the unnamed constructor is already defined'
  ///
  const ContainerKey._simple();

  /// Default way to create instance of [ContainerKey] extension.
  ///
  /// Note this creates a siblings unique key.
  /// Must override if uniqueness in other context key is needed.
  const factory ContainerKey(String value) = SiblingsValueKey<String>;

  /// Checks uniqueness in a set of existing keys.
  void ensureUniqueWith(Iterable<ContainerKey> keys) {
    if (keys.contains(this)) {
      Iterable match = keys.where((element) => element == this);
      if (match.isEmpty) {
        throw StateError('Not match for $this found in $keys despite contains.');
      }
      throw StateError('ensureUniqueWith: This object\' s key ${match.toList()[0]} already used in one of $keys');
    }
  }

  /// Checks uniqueness in a set of existing keys.
  static void ensureUnique(Iterable<ContainerKey> keys) {
    // toSet converts to set using ==. If lengths do not match, there are at least two == keys in [keys].
    Set toSet = keys.toSet();
    if (toSet.length != keys.length) {
      throw StateError('ensureUnique:  keys $keys are not unique');

    }
  }

  ContainerKey uniqueNextWith(Iterable<ContainerKey> keys) {
    throw UnimplementedError('todo implement');
  }
}

/// [SiblingsKey] is a [ContainerKey] intended to be unique among siblings
/// of the same parent in the [BoxContainerHierarchy].
///
@immutable
abstract class SiblingsKey extends ContainerKey {
  /// Default constructor.
  ///
  /// Must be [const] to enable extensions' [const] constructors.
  const SiblingsKey() : super._simple();

}

/// A [SiblingsKey] extension using a parametrized [value] as identifier.
///
/// It is assumed to be created and set on [BoxContainer] during construction, unique
/// among siblings. That means, the creator of [BoxContainer]s must be aware
/// of any future siblings, or generate the key sufficiently randomly. todo-00 check this commanr
@immutable
class SiblingsValueKey<T> extends SiblingsKey {
  final T value;

  const SiblingsValueKey(this.value) : super();

  @override
  String toString() {
    return 'Key: value=$value';
  }

  @override
  bool operator ==(Object other) =>
      other is SiblingsValueKey<T> && other.runtimeType == runtimeType && other.value == value;

  @override
  int get hashCode => value.hashCode * 17;
}


// todo-00 remove
/*
class TestSome {

  main() {

    BoxContainer xContainer      = BoxContainer(key: SiblingsValueKey(RootContainers.xContainer.name));
    BoxContainer yContainer      = BoxContainer(key: SiblingsValueKey(RootContainers.yContainer.name));
    BoxContainer dataContainer   = BoxContainer(key: SiblingsValueKey(RootContainers.dataContainer.name));
    BoxContainer legendContainer = BoxContainer(key: SiblingsValueKey(RootContainers.legendContainer.name));
  }
}

enum RootContainers {
  xContainer,
  yContainer,
  dataContainer,
  legendContainer,
}
*/

abstract class Keyed {
  ContainerKey get key;
}

/// Manages members [Keyed] with [ContainerKey] ,
/// allows to add members, and ensures any added member's
/// [ContainerKey] remains unique with existing members.
///
/// The [Keyed] members are:
///   - Kept in [keyedMembers]
///   - Added using [addUniquelyKeyedMember] and [addAllUniquelyKeyedMembers]
///   - Retrieved by [ContainerKey] using [memberForKey].
///
/// For example, for a hierarchy where siblings should be unique, the
/// [UniqueKeyedObjectsManager] instance would be the parent OR a member on parent.
abstract class UniqueKeyedObjectsManager {

  /// [Keyed] members holder.
  ///
  /// Serves as a backing [Iterable] of the [Keyed] objects
  /// this holder manages.
  ///
  /// Implementors need to override this
  /// method to start holding uniquely [Keyed] objects.
  List<Keyed> get keyedMembers;

  /// Returns, among this holder's managed [Keyed] members, the member with the passed [containerKey].
  ///
  /// Throws exception if the passed [containerKey] is not found, or multiple are found.
  Keyed memberForKey(ContainerKey containerKey) {
    Iterable<Keyed> matchingMembers = keyedMembers.where((Keyed keyed) => keyed.key == containerKey);
    if (matchingMembers.length > 1) {
      throw StateError('Internal error: Multiple matching members $matchingMembers for key $containerKey');
    }
    if (matchingMembers.isEmpty) {
      throw StateError('No matching member for key $containerKey in _keyedMembers $keyedMembers');
    }
    return matchingMembers.first;
  }

/* todo-00-last-remove
  /// Add a [Keyed] member to this holder of unique [ContainerKey]s.
  /// 
  /// Exception thrown during [addKeyed], if the added member does not have
  /// a unique key within the set of ,
  /// so the [keyedMembers] maintain uniqueness of keys.
  ///
  /// Must be called for todo-00 document
  addUniquelyKeyedMember(Keyed keyed) {
    keyedMembers.add(keyed);
    ensureUnique();
  }

  /// Add all [keyed] members for this holder to manage.
  ///
  /// See [addUniquelyKeyedMember] for details.
  addAllUniquelyKeyedMembers(Iterable<Keyed> keyed) {
    keyedMembers.addAll(keyed);
    ensureUnique();
  }
*/

  Iterable<ContainerKey> get _memberKeys => keyedMembers.map((Keyed keyed) => keyed.key);

  /// Checks uniqueness of all managed [Keyed] members.
  ///
  /// Implementors must call [ensureUnique] every time after the list backing
  /// the [keyedMembers] is modified.
  void ensureUnique() {
    // toSet converts to set using ==. If lengths do not match, there are at least two == keys in [keys].
    Set toSet = _memberKeys.toSet();
    if (toSet.length != _memberKeys.length) {
      throw StateError('ensureUnique:  keys $_memberKeys of members $keyedMembers are not unique');
    }
  }
}