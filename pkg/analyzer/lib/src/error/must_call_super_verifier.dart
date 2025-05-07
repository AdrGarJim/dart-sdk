// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:collection';

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/error/codes.g.dart';

class MustCallSuperVerifier {
  final ErrorReporter _errorReporter;

  MustCallSuperVerifier(this._errorReporter);

  void checkMethodDeclaration(MethodDeclaration node) {
    if (node.isStatic || node.isAbstract) {
      return;
    }
    var element = node.declaredFragment!.element;

    var overridden = _findOverriddenMemberWithMustCallSuper(element);
    if (overridden == null) {
      return;
    }

    var overriddenName = overridden.name3;
    if (overriddenName == null) {
      return;
    }

    if (element is MethodElement && _hasConcreteSuperMethod(element)) {
      _verifySuperIsCalled(
        node,
        overriddenName,
        overridden.enclosingElement2?.name3,
      );
      return;
    }

    var enclosingElement = element.enclosingElement2;
    if (enclosingElement is! ClassElement) {
      return;
    }

    if (element is GetterElement) {
      var inheritedConcreteGetter = enclosingElement
          .lookupInheritedConcreteMember(element);
      if (inheritedConcreteGetter is GetterElement) {
        _verifySuperIsCalled(
          node,
          overriddenName,
          overridden.enclosingElement2?.name3,
        );
      }
      return;
    }

    if (element is SetterElement) {
      var inheritedConcreteSetter = enclosingElement
          .lookupInheritedConcreteMember(element);
      if (inheritedConcreteSetter is SetterElement) {
        var name = overriddenName;
        // For a setter, give the name without the trailing '=' to the verifier,
        // in order to check against property access.
        if (name.endsWith('=')) {
          name = name.substring(0, name.length - 1);
        }
        _verifySuperIsCalled(node, name, overridden.enclosingElement2?.name3);
      }
    }
  }

  /// Finds a method which is overridden by [element] and which is annotated
  /// with `@mustCallSuper`.
  ///
  /// As per the definition of `mustCallSuper` [1], every method which overrides
  /// a method annotated with `@mustCallSuper` is implicitly annotated with
  /// `@mustCallSuper`.
  ///
  /// [1]: https://pub.dev/documentation/meta/latest/meta/mustCallSuper-constant.html
  ExecutableElement? _findOverriddenMemberWithMustCallSuper(
    ExecutableElement element,
  ) {
    var classElement = element.enclosingElement2;
    if (classElement is! InterfaceElement) {
      return null;
    }

    var name = element.name3;
    if (name == null) {
      return null;
    }

    // Walk up the type hierarchy from [classElement], ignoring direct
    // interfaces.
    var superclasses = Queue<InterfaceElement?>();

    void addToQueue(InterfaceElement element) {
      superclasses.addAll(element.mixins.map((i) => i.element3));
      superclasses.add(element.supertype?.element3);
      if (element is MixinElement) {
        superclasses.addAll(
          element.superclassConstraints.map((i) => i.element3),
        );
      }
    }

    var visitedClasses = <InterfaceElement>{};
    addToQueue(classElement);
    while (superclasses.isNotEmpty) {
      var ancestor = superclasses.removeFirst();
      if (ancestor == null || !visitedClasses.add(ancestor)) {
        continue;
      }

      ExecutableElement? member;
      switch (element) {
        case MethodElement():
          member = ancestor.getMethod2(name);
        case GetterElement():
          member = ancestor.getMethod2(name) ?? ancestor.getGetter2(name);
        case SetterElement():
          member = ancestor.getSetter2(name);
      }

      if (member is MethodElement && member.metadata2.hasMustCallSuper) {
        return member;
      }
      if (member is PropertyAccessorElement &&
          member.metadata2.hasMustCallSuper) {
        return member;
      }
      // TODO(srawlins): What about a field annotated with `@mustCallSuper`?
      // This might seem a legitimate case, but is not called out in the
      // documentation of [mustCallSuper].
      addToQueue(ancestor);
    }
    return null;
  }

  /// Returns whether [element] overrides a concrete method.
  bool _hasConcreteSuperMethod(ExecutableElement element) {
    var classElement = element.enclosingElement2 as InterfaceElement;

    var name = element.name3;
    if (name == null) {
      return true;
    }

    if (classElement.supertype.isConcrete(name)) {
      return true;
    }

    if (classElement.mixins.any((m) => m.isConcrete(name))) {
      return true;
    }

    if (classElement is MixinElement &&
        classElement.superclassConstraints.any((c) => c.isConcrete(name))) {
      return true;
    }

    return false;
  }

  void _verifySuperIsCalled(
    MethodDeclaration node,
    String? methodName,
    String? overriddenEnclosingName,
  ) {
    var declaredFragment = node.declaredFragment!;
    var declaredElement = declaredFragment.element as ExecutableElementImpl2;
    if (!declaredElement.invokesSuperSelf) {
      // Overridable elements are always enclosed in named elements, so it is
      // safe to assume [overriddenEnclosingName] is non-`null`.
      _errorReporter.atToken(
        node.name,
        WarningCode.MUST_CALL_SUPER,
        arguments: [overriddenEnclosingName!],
      );
    }
    return;
  }
}

extension on InterfaceElement {
  ExecutableElement? lookupInheritedConcreteMember(ExecutableElement element) {
    var nameObj = Name.forElement(element);
    if (nameObj == null) {
      return null;
    }

    var library = element.library2 as LibraryElementImpl;
    var inheritanceManager = library.session.inheritanceManager;
    return inheritanceManager.getMember4(this, nameObj, forSuper: true);
  }
}

extension on InterfaceType? {
  bool isConcrete(String name) {
    var self = this;
    if (self == null) return false;
    var element = self.element3;

    var library = element.library2 as LibraryElementImpl;
    var inheritanceManager = library.session.inheritanceManager;

    var concrete = inheritanceManager.getMember4(
      element,
      Name.forLibrary(library, name),
      concrete: true,
    );

    return concrete != null;
  }
}
