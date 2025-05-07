// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/member.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:meta/meta.dart';

class MockLibraryImportElement implements Element, PrefixFragment {
  final LibraryImportElementImpl import;

  MockLibraryImportElement(LibraryImport import)
    : import = import as LibraryImportElementImpl;

  @override
  LibraryElement get enclosingElement2 => library2;

  @override
  ElementKind get kind => ElementKind.IMPORT;

  @override
  LibraryElementImpl get library2 => libraryFragment.element;

  @override
  LibraryFragmentImpl get libraryFragment => import.libraryFragment;

  @override
  String? get name3 => import.prefix2?.name2;

  @override
  noSuchMethod(invocation) => super.noSuchMethod(invocation);
}

extension BindPatternVariableElementImpl2Extension
    on BindPatternVariableElementImpl2 {
  BindPatternVariableFragmentImpl get asElement {
    return firstFragment;
  }
}

extension BindPatternVariableElementImplExtension
    on BindPatternVariableFragmentImpl {
  BindPatternVariableElementImpl2 get asElement2 {
    return element;
  }
}

extension ClassElementImpl2Extension on ClassElementImpl2 {
  ClassFragmentImpl get asElement {
    return firstFragment;
  }
}

extension ClassElementImplExtension on ClassFragmentImpl {
  ClassElementImpl2 get asElement2 {
    return element;
  }
}

extension CompilationUnitElementImplExtension on LibraryFragmentImpl {
  /// Returns this library fragment, and all its enclosing fragments.
  List<LibraryFragmentImpl> get withEnclosing {
    var result = <LibraryFragmentImpl>[];
    var current = this;
    while (true) {
      result.add(current);
      if (current.enclosingElement3 case var enclosing?) {
        current = enclosing;
      } else {
        break;
      }
    }
    return result;
  }
}

extension ConstructorElementImpl2Extension on ConstructorElementImpl2 {
  ConstructorFragmentImpl get asElement {
    return lastFragment;
  }
}

extension ConstructorElementImplExtension on ConstructorFragmentImpl {
  ConstructorElementImpl2 get asElement2 {
    return element;
  }
}

extension ConstructorElementMixin2Extension on ConstructorElementMixin2 {
  ConstructorElementMixin get asElement {
    if (this case ConstructorMember member) {
      return member;
    }
    return (this as ConstructorElementImpl2).lastFragment;
  }
}

extension ConstructorElementMixinExtension on ConstructorElementMixin {
  ConstructorElementMixin2 get asElement2 {
    return switch (this) {
      ConstructorFragmentImpl(:var element) => element,
      ConstructorMember member => member,
      _ => throw UnsupportedError('Unsupported type: $runtimeType'),
    };
  }
}

extension Element2Extension on Element {
  /// Whether the element is effectively [internal].
  bool get isInternal {
    if (this case Annotatable annotatable) {
      if (annotatable.metadata2.hasInternal) {
        return true;
      }
    }
    if (this case PropertyAccessorElement accessor) {
      var variable = accessor.variable3;
      if (variable != null && variable.metadata2.hasInternal) {
        return true;
      }
    }
    return false;
  }

  /// Whether the element is effectively [protected].
  bool get isProtected {
    var self = this;
    if (self is PropertyAccessorElement &&
        self.enclosingElement2 is InterfaceElement) {
      if (self.metadata2.hasProtected) {
        return true;
      }
      var variable = self.variable3;
      if (variable != null && variable.metadata2.hasProtected) {
        return true;
      }
    }
    if (self is MethodElement &&
        self.enclosingElement2 is InterfaceElement &&
        self.metadata2.hasProtected) {
      return true;
    }
    return false;
  }

  /// Whether the element is effectively [visibleForTesting].
  bool get isVisibleForTesting {
    if (this case Annotatable annotatable) {
      if (annotatable.metadata2.hasVisibleForTesting) {
        return true;
      }
    }
    if (this case PropertyAccessorElement accessor) {
      var variable = accessor.variable3;
      if (variable != null && variable.metadata2.hasVisibleForTesting) {
        return true;
      }
    }
    return false;
  }

  List<ElementAnnotation> get metadata {
    if (this case Annotatable annotatable) {
      return annotatable.metadata2.annotations;
    }
    return [];
  }
}

extension ElementImplExtension on FragmentImpl {
  FragmentImpl? get enclosingElementImpl => enclosingElement3;

  AnnotationImpl annotationAst(int index) {
    return metadata[index].annotationAst;
  }
}

extension ElementOrNullExtension on FragmentImpl? {
  Element? get asElement2 {
    var self = this;
    if (self == null) {
      return null;
    } else if (self is DynamicFragmentImpl) {
      return DynamicElementImpl2.instance;
    } else if (self is ExtensionFragmentImpl) {
      return (self as ExtensionFragment).element;
    } else if (self is ExecutableMember) {
      return self as ExecutableElement;
    } else if (self is FieldMember) {
      return self as FieldElement;
    } else if (self is FieldFragmentImpl) {
      return (self as FieldFragment).element;
    } else if (self is FunctionFragmentImpl) {
      return (self as Fragment).element;
    } else if (self is InterfaceFragmentImpl) {
      return self.element;
    } else if (self is LabelFragmentImpl) {
      return self.element2;
    } else if (self is LibraryElementImpl) {
      return self;
    } else if (self is LocalVariableFragmentImpl) {
      return self.element;
    } else if (self is NeverFragmentImpl) {
      return NeverElementImpl2.instance;
    } else if (self is ParameterMember) {
      return (self as FormalParameterFragment).element;
    } else if (self is LibraryImportElementImpl ||
        self is LibraryExportElementImpl ||
        self is PartElementImpl) {
      // There is no equivalent in the new element model.
      return null;
    } else {
      return (self as Fragment?)?.element;
    }
  }
}

extension EnumElementImplExtension on EnumFragmentImpl {
  EnumElementImpl2 get asElement2 {
    return element;
  }
}

extension ExecutableElement2Extension on ExecutableElement {
  ExecutableElementOrMember get asElement {
    if (this case ExecutableMember member) {
      return member;
    }
    return firstFragment as ExecutableElementOrMember;
  }
}

extension ExecutableElementImpl2Extension on ExecutableElementImpl2 {
  ExecutableFragmentImpl get asElement {
    return lastFragment;
  }
}

extension ExecutableElementImplExtension on ExecutableFragmentImpl {
  ExecutableElementImpl2 get asElement2 {
    return element;
  }
}

extension ExecutableElementOrMemberExtension on ExecutableElementOrMember {
  ExecutableElement2OrMember get asElement2 {
    return switch (this) {
      ExecutableFragmentImpl(:var element) => element,
      ExecutableMember member => member,
      _ => throw UnsupportedError('Unsupported type: $runtimeType'),
    };
  }

  ExecutableFragmentImpl get declarationImpl =>
      asElement2.baseElement.firstFragment as ExecutableFragmentImpl;

  FragmentImpl get enclosingElementImpl =>
      asElement2.enclosingElement2!.firstFragment as FragmentImpl;
}

extension ExtensionElementImpl2Extension on ExtensionElementImpl2 {
  ExtensionFragmentImpl get asElement {
    return firstFragment;
  }
}

extension ExtensionElementImplExtension on ExtensionFragmentImpl {
  ExtensionElementImpl2 get asElement2 {
    return element;
  }
}

extension ExtensionTypeElementImpl2Extension on ExtensionTypeElementImpl2 {
  ExtensionTypeFragmentImpl get asElement {
    return firstFragment;
  }
}

extension FieldElementImpl2Extension on FieldElementImpl2 {
  FieldFragmentImpl get asElement {
    return firstFragment;
  }
}

extension FieldElementImplExtension on FieldFragmentImpl {
  FieldElementImpl2 get asElement2 {
    return element;
  }
}

extension FieldElementOrMemberExtension on FieldElementOrMember {
  FieldElement2OrMember get asElement2 {
    return switch (this) {
      FieldFragmentImpl(:var element) => element,
      FieldMember member => member,
      _ => throw UnsupportedError('Unsupported type: $runtimeType'),
    };
  }
}

extension FormalParameterElementExtension on FormalParameterElement {
  void appendToWithoutDelimiters(
    StringBuffer buffer, {
    @Deprecated('Only non-nullable by default mode is supported')
    bool withNullability = true,
  }) {
    buffer.write(
      type.getDisplayString(
        // ignore:deprecated_member_use_from_same_package
        withNullability: withNullability,
      ),
    );
    buffer.write(' ');
    buffer.write(displayName);
    if (defaultValueCode != null) {
      buffer.write(' = ');
      buffer.write(defaultValueCode);
    }
  }
}

extension FormalParameterElementImplExtension on FormalParameterElementImpl {
  FormalParameterFragmentImpl get asElement {
    return firstFragment;
  }
}

extension FormalParameterElementMixinExtension on FormalParameterElementMixin {
  ParameterElementMixin get asElement {
    return switch (this) {
      FormalParameterElementImpl(:var firstFragment) => firstFragment,
      ParameterMember member => member,
      _ => throw UnsupportedError('Unsupported type: $runtimeType'),
    };
  }
}

extension GetterElementImplExtension on GetterElementImpl {
  PropertyAccessorFragmentImpl get asElement {
    return lastFragment;
  }
}

extension InstanceElementImpl2Extension on InstanceElementImpl2 {
  InstanceFragmentImpl get asElement {
    return firstFragment;
  }
}

extension InstanceElementImplExtension on InstanceFragmentImpl {
  InstanceElementImpl2 get asElement2 {
    return element;
  }
}

extension InterfaceElementImpl2Extension on InterfaceElementImpl2 {
  InterfaceFragmentImpl get asElement {
    return firstFragment;
  }
}

extension InterfaceElementImplExtension on InterfaceFragmentImpl {
  InterfaceElementImpl2 get asElement2 {
    return element;
  }
}

extension InterfaceTypeImplExtension on InterfaceTypeImpl {
  InterfaceFragmentImpl get elementImpl => element3.firstFragment;
}

extension JoinPatternVariableElementImplExtension
    on JoinPatternVariableFragmentImpl {
  JoinPatternVariableElementImpl2 get asElement2 {
    return element;
  }
}

extension LibraryFragmentExtension on LibraryFragment {
  /// Returns a list containing this library fragment and all of its enclosing
  /// fragments.
  List<LibraryFragment> get withEnclosing2 {
    var result = <LibraryFragment>[];
    var current = this;
    while (true) {
      result.add(current);
      if (current.enclosingFragment case var enclosing?) {
        current = enclosing;
      } else {
        break;
      }
    }
    return result;
  }
}

extension ListOfTypeParameterElement2Extension on List<TypeParameterElement> {
  List<TypeParameterType> instantiateNone() {
    return map((e) {
      return e.instantiate(nullabilitySuffix: NullabilitySuffix.none);
    }).toList();
  }
}

extension LocalVariableElementImplExtension on LocalVariableFragmentImpl {
  LocalVariableElementImpl2 get asElement2 {
    return element;
  }
}

extension MethodElement2OrMemberExtension on MethodElement2OrMember {
  MethodElementOrMember get asElement {
    if (this case MethodMember member) {
      return member;
    }
    return (this as MethodElementImpl2).lastFragment;
  }
}

extension MethodElementImpl2Extension on MethodElementImpl2 {
  MethodFragmentImpl get asElement {
    return lastFragment;
  }
}

extension MethodElementImplExtension on MethodFragmentImpl {
  MethodElementImpl2 get asElement2 {
    return element;
  }
}

extension MethodElementOrMemberExtension on MethodElementOrMember {
  MethodElement2OrMember get asElement2 {
    return switch (this) {
      MethodFragmentImpl(:var element) => element,
      MethodMember member => member,
      _ => throw UnsupportedError('Unsupported type: $runtimeType'),
    };
  }
}

extension MixinElementImplExtension on MixinFragmentImpl {
  MixinElementImpl2 get asElement2 {
    return element;
  }
}

extension ParameterElementImplExtension on FormalParameterFragmentImpl {
  FormalParameterElementImpl get asElement2 {
    return element;
  }
}

extension ParameterElementMixinExtension on ParameterElementMixin {
  FormalParameterElementMixin get asElement2 {
    return switch (this) {
      FormalParameterFragmentImpl(:var element) => element,
      ParameterMember member => member,
      _ => throw UnsupportedError('Unsupported type: $runtimeType'),
    };
  }
}

extension PatternVariableElementImpl2Extension on PatternVariableElementImpl2 {
  PatternVariableFragmentImpl get asElement {
    return firstFragment;
  }
}

extension PatternVariableElementImplExtension on PatternVariableFragmentImpl {
  PatternVariableElementImpl2 get asElement2 {
    return element;
  }
}

extension PropertyAccessorElement2OrMemberExtension
    on PropertyAccessorElement2OrMember {
  PropertyAccessorElementOrMember get asElement {
    if (this case PropertyAccessorMember member) {
      return member;
    }
    return (this as PropertyAccessorElementImpl2).lastFragment;
  }
}

extension PropertyAccessorElementImplExtension on PropertyAccessorFragmentImpl {
  PropertyAccessorElementImpl2 get asElement2 {
    return element;
  }
}

extension PropertyAccessorElementOrMemberExtension
    on PropertyAccessorElementOrMember {
  PropertyAccessorElement2OrMember get asElement2 {
    return switch (this) {
      PropertyAccessorFragmentImpl(:var element) => element,
      PropertyAccessorMember member => member,
      _ => throw UnsupportedError('Unsupported type: $runtimeType'),
    };
  }
}

extension PropertyInducingElementExtension on PropertyInducingElement {
  bool get definesSetter {
    if (isConst) {
      return false;
    }
    if (isFinal) {
      return isLate && !hasInitializer;
    } else {
      return true;
    }
  }
}

extension PropertyInducingElementOrMemberExtension
    on PropertyInducingElementOrMember {
  PropertyInducingElement2OrMember get asElement2 {
    return switch (this) {
      PropertyInducingElementImpl(:var element) => element,
      FieldMember member => member,
      _ => throw UnsupportedError('Unsupported type: $runtimeType'),
    };
  }
}

extension SetterElementImplExtension on SetterElementImpl {
  PropertyAccessorFragmentImpl get asElement {
    return lastFragment;
  }
}

extension TopLevelFunctionElementImplExtension on TopLevelFunctionElementImpl {
  FunctionFragmentImpl get asElement {
    return lastFragment;
  }
}

extension TopLevelVariableElementImpl2Extension
    on TopLevelVariableElementImpl2 {
  TopLevelVariableFragmentImpl get asElement {
    return firstFragment;
  }
}

extension TypeAliasElementImpl2Extension on TypeAliasElementImpl2 {
  TypeAliasFragmentImpl get asElement {
    return firstFragment;
  }
}

extension TypeAliasElementImplExtension on TypeAliasFragmentImpl {
  TypeAliasElementImpl2 get asElement2 {
    return element;
  }
}

extension TypeParameterElement2Extension on TypeParameterElement {
  TypeParameterElementImpl2 freshCopy() {
    var fragment = TypeParameterFragmentImpl(name3 ?? '', -1);
    fragment.bound = bound;
    return TypeParameterElementImpl2(firstFragment: fragment, name3: name3);
  }
}

extension TypeParameterElementImpl2Extension on TypeParameterElementImpl2 {
  TypeParameterFragmentImpl get asElement {
    return firstFragment;
  }
}

extension TypeParameterElementImplExtension on TypeParameterFragmentImpl {
  TypeParameterElementImpl2 get asElement2 {
    return element;
  }
}
