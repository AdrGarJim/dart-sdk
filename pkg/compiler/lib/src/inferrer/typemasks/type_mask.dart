// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of 'masks.dart';

/// An implementation of a [UniverseSelectorConstraints] that is consists if an
/// only increasing set of [TypeMask]s, that is, once a mask is added it cannot
/// be removed.
class IncreasingTypeMaskSet extends UniverseSelectorConstraints {
  final CommonMasks domain;

  IncreasingTypeMaskSet(this.domain);

  bool isAll = false;
  Set<TypeMask>? _masks;

  @override
  bool canHit(MemberEntity element, Name name, JClosedWorld world) {
    if (isAll) return true;
    if (_masks == null) return false;
    for (TypeMask mask in _masks!) {
      if (mask.canHit(element, name, domain)) return true;
    }
    return false;
  }

  @override
  bool needsNoSuchMethodHandling(Selector selector, JClosedWorld world) {
    if (isAll) {
      TypeMask mask = TypeMask.subclass(
        world.commonElements.objectClass,
        domain,
      );
      return mask.needsNoSuchMethodHandling(selector, world);
    }
    for (TypeMask mask in _masks!) {
      if (mask.needsNoSuchMethodHandling(selector, world)) {
        return true;
      }
    }
    return false;
  }

  @override
  bool addReceiverConstraint(TypeMask? mask) {
    if (isAll) return false;
    if (mask == null) {
      isAll = true;
      _masks = null;
      return true;
    }
    return (_masks ??= {}).add(mask);
  }

  @override
  String toString() {
    if (isAll) {
      return '<all>';
    } else if (_masks != null) {
      return '$_masks';
    } else {
      return '<none>';
    }
  }
}

class TypeMaskStrategy implements AbstractValueStrategy<CommonMasks> {
  const TypeMaskStrategy();

  @override
  CommonMasks createDomain(JClosedWorld closedWorld) =>
      CommonMasks(closedWorld);

  @override
  SelectorConstraintsStrategy createSelectorStrategy(CommonMasks domain) =>
      TypeMaskSelectorStrategy(domain);
}

class TypeMaskSelectorStrategy implements SelectorConstraintsStrategy {
  final CommonMasks domain;

  const TypeMaskSelectorStrategy(this.domain);

  @override
  UniverseSelectorConstraints createSelectorConstraints(
    Selector selector,
    covariant TypeMask? initialConstraint,
  ) {
    return IncreasingTypeMaskSet(domain)
      ..addReceiverConstraint(initialConstraint);
  }

  @override
  bool appliedUnnamed(
    DynamicUse dynamicUse,
    MemberEntity member,
    covariant JClosedWorld world,
  ) {
    Selector selector = dynamicUse.selector;
    final mask = dynamicUse.receiverConstraint as TypeMask?;
    return selector.appliesUnnamed(member) &&
        (mask == null || mask.canHit(member, selector.memberName, domain));
  }
}

/// Enum used for identifying [TypeMask] subclasses in serialization.
enum TypeMaskKind {
  flat,
  union,
  container,
  set,
  map,
  dictionary,
  record,
  value,
}

/// Specific values that are independently tracked.
enum TypeMaskSpecialValue { null_, lateSentinel }

final _specialValueDomain = EnumSetDomain<TypeMaskSpecialValue>(
  0,
  TypeMaskSpecialValue.values,
);

final _powersetDomains = ComposedEnumSetDomains([_specialValueDomain]);

/// A type mask represents a set of contained classes, but the
/// operations on it are not guaranteed to be precise and they may
/// yield conservative answers that contain too many classes.
abstract class TypeMask implements AbstractValue {
  const TypeMask();

  factory TypeMask.empty(CommonMasks domain, {bool hasLateSentinel = false}) =>
      FlatTypeMask.empty(domain, hasLateSentinel: hasLateSentinel);

  factory TypeMask.exact(
    ClassEntity base,
    CommonMasks domain, {
    bool hasLateSentinel = false,
  }) {
    assert(
      domain.classHierarchy.isInstantiated(base),
      failedAt(
        base,
        "Cannot create exact type mask for uninstantiated "
        "class $base.\n${domain.classHierarchy.dump(base)}",
      ),
    );
    return FlatTypeMask.exact(base, domain, hasLateSentinel: hasLateSentinel);
  }

  factory TypeMask.exactOrEmpty(
    ClassEntity base,
    CommonMasks domain, {
    bool hasLateSentinel = false,
  }) {
    if (domain.classHierarchy.isInstantiated(base)) {
      return FlatTypeMask.exact(base, domain, hasLateSentinel: hasLateSentinel);
    }
    return TypeMask.empty(domain, hasLateSentinel: hasLateSentinel);
  }

  factory TypeMask.subclass(
    ClassEntity base,
    CommonMasks domain, {
    bool hasLateSentinel = false,
  }) {
    assert(
      domain.classHierarchy.isInstantiated(base),
      failedAt(
        base,
        "Cannot create subclass type mask for uninstantiated "
        "class $base.\n${domain.classHierarchy.dump(base)}",
      ),
    );
    final topmost = domain.closedWorld.getLubOfInstantiatedSubclasses(base);
    if (topmost == null) {
      return TypeMask.empty(domain, hasLateSentinel: hasLateSentinel);
    } else if (domain.classHierarchy.hasAnyStrictSubclass(topmost)) {
      return FlatTypeMask.subclass(
        topmost,
        domain,
        hasLateSentinel: hasLateSentinel,
      );
    } else {
      return TypeMask.exact(topmost, domain, hasLateSentinel: hasLateSentinel);
    }
  }

  factory TypeMask.subtype(
    ClassEntity base,
    CommonMasks domain, {
    bool hasLateSentinel = false,
  }) {
    final topmost = domain.closedWorld.getLubOfInstantiatedSubtypes(base);
    if (topmost == null) {
      return TypeMask.empty(domain, hasLateSentinel: hasLateSentinel);
    }
    if (domain.classHierarchy.hasOnlySubclasses(topmost)) {
      return TypeMask.subclass(
        topmost,
        domain,
        hasLateSentinel: hasLateSentinel,
      );
    }
    if (domain.classHierarchy.hasAnyStrictSubtype(topmost)) {
      return FlatTypeMask.subtype(
        topmost,
        domain,
        hasLateSentinel: hasLateSentinel,
      );
    } else {
      return TypeMask.exact(topmost, domain, hasLateSentinel: hasLateSentinel);
    }
  }

  factory TypeMask.nonNullEmpty(
    CommonMasks domain, {
    bool hasLateSentinel = false,
  }) => FlatTypeMask.nonNullEmpty(domain, hasLateSentinel: hasLateSentinel);

  factory TypeMask.nonNullExact(
    ClassEntity base,
    CommonMasks domain, {
    bool hasLateSentinel = false,
  }) {
    assert(
      domain.classHierarchy.isInstantiated(base),
      failedAt(
        base,
        "Cannot create exact type mask for uninstantiated "
        "class $base.\n${domain.classHierarchy.dump(base)}",
      ),
    );
    return FlatTypeMask.nonNullExact(
      base,
      domain,
      hasLateSentinel: hasLateSentinel,
    );
  }

  factory TypeMask.nonNullExactOrEmpty(
    ClassEntity base,
    CommonMasks domain, {
    bool hasLateSentinel = false,
  }) {
    if (domain.classHierarchy.isInstantiated(base)) {
      return FlatTypeMask.nonNullExact(
        base,
        domain,
        hasLateSentinel: hasLateSentinel,
      );
    }
    return TypeMask.nonNullEmpty(domain, hasLateSentinel: hasLateSentinel);
  }

  factory TypeMask.nonNullSubclass(
    ClassEntity base,
    CommonMasks domain, {
    bool hasLateSentinel = false,
  }) {
    assert(
      domain.classHierarchy.isInstantiated(base),
      failedAt(
        base,
        "Cannot create subclass type mask for uninstantiated "
        "class $base.\n${domain.classHierarchy.dump(base)}",
      ),
    );
    final topmost = domain.closedWorld.getLubOfInstantiatedSubclasses(base);
    if (topmost == null) {
      return TypeMask.nonNullEmpty(domain, hasLateSentinel: hasLateSentinel);
    } else if (domain.classHierarchy.hasAnyStrictSubclass(topmost)) {
      return FlatTypeMask.nonNullSubclass(
        topmost,
        domain,
        hasLateSentinel: hasLateSentinel,
      );
    } else {
      return TypeMask.nonNullExact(
        topmost,
        domain,
        hasLateSentinel: hasLateSentinel,
      );
    }
  }

  factory TypeMask.nonNullSubtype(
    ClassEntity base,
    CommonMasks domain, {
    bool hasLateSentinel = false,
  }) {
    final topmost = domain.closedWorld.getLubOfInstantiatedSubtypes(base);
    if (topmost == null) {
      return TypeMask.nonNullEmpty(domain, hasLateSentinel: hasLateSentinel);
    }
    if (domain.classHierarchy.hasOnlySubclasses(topmost)) {
      return TypeMask.nonNullSubclass(
        topmost,
        domain,
        hasLateSentinel: hasLateSentinel,
      );
    }
    if (domain.classHierarchy.hasAnyStrictSubtype(topmost)) {
      return FlatTypeMask.nonNullSubtype(
        topmost,
        domain,
        hasLateSentinel: hasLateSentinel,
      );
    } else {
      return TypeMask.nonNullExact(
        topmost,
        domain,
        hasLateSentinel: hasLateSentinel,
      );
    }
  }

  factory TypeMask.unionOf(Iterable<TypeMask> masks, CommonMasks domain) {
    return UnionTypeMask.unionOf(masks, domain);
  }

  /// Deserializes a [TypeMask] object from [source].
  factory TypeMask.readFromDataSource(
    DataSourceReader source,
    CommonMasks domain,
  ) {
    TypeMaskKind kind = source.readEnum(TypeMaskKind.values);
    switch (kind) {
      case TypeMaskKind.flat:
        return FlatTypeMask.readFromDataSource(source, domain);
      case TypeMaskKind.union:
        return UnionTypeMask.readFromDataSource(source, domain);
      case TypeMaskKind.container:
        return ContainerTypeMask.readFromDataSource(source, domain);
      case TypeMaskKind.set:
        return SetTypeMask.readFromDataSource(source, domain);
      case TypeMaskKind.map:
        return MapTypeMask.readFromDataSource(source, domain);
      case TypeMaskKind.dictionary:
        return DictionaryTypeMask.readFromDataSource(source, domain);
      case TypeMaskKind.record:
        return RecordTypeMask.readFromDataSource(source, domain);
      case TypeMaskKind.value:
        return ValueTypeMask.readFromDataSource(source, domain);
    }
  }

  /// Serializes this [TypeMask] to [sink].
  void writeToDataSink(DataSinkWriter sink);

  /// If [mask] is forwarding, returns the first non-forwarding [TypeMask] in
  /// [mask]'s forwarding chain.
  static TypeMask nonForwardingMask(TypeMask mask) {
    while (mask is ForwardingTypeMask) {
      mask = mask.forwardTo;
    }
    return mask;
  }

  /// Asserts that this mask uses the smallest possible representation for
  /// its types. Currently, we normalize subtype and subclass to exact if no
  /// subtypes or subclasses are present and subtype to subclass if only
  /// subclasses exist. We also normalize exact to empty if the corresponding
  /// baseclass was never instantiated.
  static bool assertIsNormalized(TypeMask mask, JClosedWorld closedWorld) {
    final reason = getNotNormalizedReason(mask, closedWorld);
    assert(
      reason == null,
      failedAt(noLocationSpannable, '$mask is not normalized: $reason'),
    );
    return true;
  }

  static String? getNotNormalizedReason(
    TypeMask mask,
    JClosedWorld closedWorld,
  ) {
    mask = nonForwardingMask(mask);
    if (mask is FlatTypeMask) {
      if (mask.isEmptyOrSpecial) return null;
      if (mask.base == closedWorld.commonElements.nullClass) {
        return 'The class ${mask.base} is not canonicalized.';
      }
      if (mask.isExact) {
        if (!closedWorld.classHierarchy.isInstantiated(mask.base!)) {
          return 'Exact ${mask.base} is not instantiated.';
        }
        return null;
      }
      if (mask.isSubclass) {
        if (!closedWorld.classHierarchy.hasAnyStrictSubclass(mask.base!)) {
          return 'Subclass ${mask.base} does not have any subclasses.';
        }
        return null;
      }
      assert(mask.isSubtype);
      if (!closedWorld.classHierarchy.hasAnyStrictSubtype(mask.base!)) {
        return 'Subtype ${mask.base} does not have any subtypes.';
      }
      if (closedWorld.classHierarchy.hasOnlySubclasses(mask.base!)) {
        return 'Subtype ${mask.base} only has subclasses.';
      }
      return null;
    } else if (mask is UnionTypeMask) {
      for (TypeMask submask in mask.disjointMasks) {
        final submaskReason = getNotNormalizedReason(submask, closedWorld);
        if (submaskReason != null) {
          return 'Submask $submask in $mask: $submaskReason.';
        }
      }
      return null;
    } else if (mask is RecordTypeMask) {
      for (TypeMask submask in mask.types) {
        final submaskReason = getNotNormalizedReason(submask, closedWorld);
        if (submaskReason != null) {
          return 'Submask $submask in $mask: $submaskReason.';
        }
      }
      return null;
    }
    return 'Unknown type mask $mask.';
  }

  Bitset get powerset;

  TypeMask withPowerset(Bitset powerset, CommonMasks domain);

  /// Returns a variant of this [TypeMask] whose value is neither `null` nor
  /// the late sentinel.
  TypeMask withoutSpecialValues(CommonMasks domain) =>
      withPowerset(_specialValueDomain.clear(powerset), domain);

  /// Returns a nullable variant of this [TypeMask].
  TypeMask nullable(CommonMasks domain) => withPowerset(
    _specialValueDomain.add(powerset, TypeMaskSpecialValue.null_),
    domain,
  );

  /// Returns a non-nullable variant of this [TypeMask].
  TypeMask nonNullable(CommonMasks domain) => withPowerset(
    _specialValueDomain.remove(powerset, TypeMaskSpecialValue.null_),
    domain,
  );

  TypeMask withLateSentinel(CommonMasks domain) => withPowerset(
    _specialValueDomain.add(powerset, TypeMaskSpecialValue.lateSentinel),
    domain,
  );

  TypeMask withoutLateSentinel(CommonMasks domain) => withPowerset(
    _specialValueDomain.remove(powerset, TypeMaskSpecialValue.lateSentinel),
    domain,
  );

  /// Whether nothing matches this mask, not even null.
  bool get isEmpty;

  /// Whether null is a valid value of this mask.
  bool get isNullable =>
      _specialValueDomain.contains(powerset, TypeMaskSpecialValue.null_);

  /// Whether the only possible value in this mask is Null.
  bool get isNull;

  /// Whether this [TypeMask] is a sentinel for an uninitialized late variable.
  AbstractBool get isLateSentinel;

  /// Whether a late sentinel is a valid value of this mask.
  bool get hasLateSentinel =>
      _specialValueDomain.contains(powerset, TypeMaskSpecialValue.lateSentinel);

  /// Whether this [TypeMask] is empty or only represents
  /// [TypeMaskSpecialValue]s (i.e. `null` and the late sentinel).
  bool get isEmptyOrSpecial;

  /// Whether this mask only includes instances of an exact class, and none of
  /// it's subclasses or subtypes.
  bool get isExact;

  bool containsOnlyInt(JClosedWorld closedWorld);
  bool containsOnlyNum(JClosedWorld closedWorld);
  bool containsOnlyBool(JClosedWorld closedWorld);
  bool containsOnlyString(JClosedWorld closedWorld);
  bool containsOnly(ClassEntity cls);

  /// If this returns `true`, [other] is guaranteed to be a supertype of this
  /// mask, i.e., this mask is in [other]. However, the inverse does not hold.
  /// Enable [UnionTypeMask.performExtraContainsCheck] to be notified of
  /// false negatives.
  bool isInMask(TypeMask other, CommonMasks domain);

  /// If this returns `true`, [other] is guaranteed to be a subtype of this
  /// mask, i.e. this mask contains [other]. However, the inverse does not hold.
  /// Enable [UnionTypeMask.performExtraContainsCheck] to be notified of
  /// false negatives.
  bool containsMask(TypeMask other, CommonMasks domain);

  /// Returns whether this type mask is an instance of [cls].
  bool satisfies(ClassEntity cls, JClosedWorld closedWorld);

  /// Returns whether or not this type mask contains the given class [cls].
  bool contains(ClassEntity cls, JClosedWorld closedWorld);

  /// Returns whether or not this type mask contains all types.
  bool containsAll(JClosedWorld closedWorld);

  /// Returns the [ClassEntity] if this type represents a single class,
  /// otherwise returns `null`.  This method is conservative.
  ClassEntity? singleClass(JClosedWorld closedWorld);

  /// Returns a type mask representing the union of this [TypeMask] and
  /// [other].
  TypeMask union(TypeMask other, CommonMasks domain);

  /// Returns whether the intersection of this and [other] is empty.
  bool isDisjoint(TypeMask other, JClosedWorld closedWorld);

  /// Returns a type mask representing the intersection of this [TypeMask] and
  /// [other].
  TypeMask intersection(TypeMask other, CommonMasks domain);

  /// Returns whether [element] is a potential target when being invoked on this
  /// type mask.
  ///
  ///
  /// [name] is used to ensure library privacy is taken into account.
  bool canHit(MemberEntity element, Name name, CommonMasks domain);

  /// Returns whether this [TypeMask] applied to [selector] can hit a
  /// [noSuchMethod].
  bool needsNoSuchMethodHandling(Selector selector, JClosedWorld world);

  /// Returns the [element] that is known to always be hit at runtime
  /// on this mask. Returns null if there is none.
  MemberEntity? locateSingleMember(Selector selector, CommonMasks domain);

  /// Returns a set of members that are ancestors of all possible targets for
  /// a call targeting [selector] on a receiver with the type represented by
  /// this mask.
  Iterable<DynamicCallTarget> findRootsOfTargets(
    Selector selector,
    MemberHierarchyBuilder memberHierarchyBuilder,
    JClosedWorld closedWorld,
  );

  static String powersetToString(Bitset powerset) => '$powerset';
}
