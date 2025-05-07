// Copyright (c) 2015, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/plugin/analysis/occurrences/occurrences_core.dart';
import 'package:analysis_server/src/protocol_server.dart' as protocol;
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/src/dart/ast/extensions.dart';

void addDartOccurrences(OccurrencesCollector collector, CompilationUnit unit) {
  var visitor = DartUnitOccurrencesComputerVisitor();
  unit.accept(visitor);
  visitor.elementsOffsetLengths.forEach((engineElement, offsetLengths) {
    // For legacy protocol, we only support occurrences with the same
    // length, so we must filter the offset to only those that match the length
    // from the element.
    var serverElement = protocol.convertElement(engineElement);
    // Prefer the length from the mapped element over the element directly,
    // because 'name3' may contain 'new' for constructors which doesn't match
    // what is in the source.
    var length =
        serverElement.location?.length ?? engineElement.name3?.length ?? 0;
    var offsets =
        offsetLengths
            .where((offsetLength) => offsetLength.$2 == length)
            .map((offsetLength) => offsetLength.$1)
            .toList();

    var occurrences = protocol.Occurrences(serverElement, offsets, length);
    collector.addOccurrences(occurrences);
  });
}

class DartUnitOccurrencesComputerVisitor extends RecursiveAstVisitor<void> {
  final Map<Element, List<(int, int)>> elementsOffsetLengths = {};

  @override
  void visitAssignedVariablePattern(AssignedVariablePattern node) {
    var element = node.element2;
    if (element != null) {
      _addOccurrence(element, node.name);
    }

    super.visitAssignedVariablePattern(node);
  }

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    _addOccurrence(node.declaredFragment!.element, node.name);

    super.visitClassDeclaration(node);
  }

  @override
  void visitClassTypeAlias(ClassTypeAlias node) {
    _addOccurrence(node.declaredFragment!.element, node.name);

    super.visitClassTypeAlias(node);
  }

  @override
  void visitConstructorDeclaration(ConstructorDeclaration node) {
    if (node.name case var name?) {
      _addOccurrence(node.declaredFragment!.element, name);
    } else {
      _addOccurrenceAt(
        node.declaredFragment!.element,
        node.returnType.offset,
        node.returnType.length,
      );
    }

    super.visitConstructorDeclaration(node);
  }

  @override
  void visitConstructorName(ConstructorName node) {
    // For unnamed constructors, we add an occurence for the constructor at
    // the location of the returnType.
    if (node.name == null) {
      var element = node.element;
      if (element != null) {
        _addOccurrence(element, node.type.name2);
      }
      return; // skip visitNamedType.
    }

    super.visitConstructorName(node);
  }

  @override
  void visitDeclaredIdentifier(DeclaredIdentifier node) {
    _addOccurrence(node.declaredFragment!.element, node.name);

    super.visitDeclaredIdentifier(node);
  }

  @override
  void visitDeclaredVariablePattern(DeclaredVariablePattern node) {
    if (node.declaredElement2 case BindPatternVariableElement(:var join2?)) {
      _addOccurrence(join2.baseElement, node.name);
    } else {
      _addOccurrence(node.declaredElement2!, node.name);
    }

    super.visitDeclaredVariablePattern(node);
  }

  @override
  void visitEnumConstantDeclaration(EnumConstantDeclaration node) {
    _addOccurrence(node.declaredFragment!.element, node.name);

    super.visitEnumConstantDeclaration(node);
  }

  @override
  void visitEnumDeclaration(EnumDeclaration node) {
    _addOccurrence(node.declaredFragment!.element, node.name);

    super.visitEnumDeclaration(node);
  }

  @override
  void visitExtensionDeclaration(ExtensionDeclaration node) {
    if (node case ExtensionDeclaration(:var declaredFragment?, :var name?)) {
      _addOccurrence(declaredFragment.element, name);
    }

    super.visitExtensionDeclaration(node);
  }

  @override
  void visitExtensionOverride(ExtensionOverride node) {
    _addOccurrence(node.element2, node.name);

    super.visitExtensionOverride(node);
  }

  @override
  void visitExtensionTypeDeclaration(ExtensionTypeDeclaration node) {
    _addOccurrence(node.declaredFragment!.element, node.name);

    super.visitExtensionTypeDeclaration(node);
  }

  @override
  void visitFieldFormalParameter(FieldFormalParameter node) {
    var declaredElement = node.declaredFragment?.element;
    if (declaredElement is FieldFormalParameterElement) {
      var field = declaredElement.field2;
      if (field != null) {
        _addOccurrence(field, node.name);
      }
    }

    super.visitFieldFormalParameter(node);
  }

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) {
    _addOccurrence(node.declaredFragment!.element, node.name);

    super.visitFunctionDeclaration(node);
  }

  @override
  void visitFunctionTypeAlias(FunctionTypeAlias node) {
    _addOccurrence(node.declaredFragment!.element, node.name);

    super.visitFunctionTypeAlias(node);
  }

  @override
  void visitGenericTypeAlias(GenericTypeAlias node) {
    _addOccurrence(node.declaredFragment!.element, node.name);

    super.visitGenericTypeAlias(node);
  }

  @override
  void visitImportPrefixReference(ImportPrefixReference node) {
    _addOccurrence(node.element2!, node.name);

    super.visitImportPrefixReference(node);
  }

  @override
  void visitMethodDeclaration(MethodDeclaration node) {
    _addOccurrence(node.declaredFragment!.element, node.name);

    super.visitMethodDeclaration(node);
  }

  @override
  void visitMixinDeclaration(MixinDeclaration node) {
    _addOccurrence(node.declaredFragment!.element, node.name);

    super.visitMixinDeclaration(node);
  }

  @override
  void visitNamedType(NamedType node) {
    var element = node.element2;
    if (element != null) {
      _addOccurrence(element, node.name2);
    }

    super.visitNamedType(node);
  }

  @override
  void visitPatternField(PatternField node) {
    var element = node.element2;
    var pattern = node.pattern;
    // If no explicit field name, use the variables name.
    var name =
        node.name?.name == null && pattern is VariablePattern
            ? pattern.name
            : node.name?.name;
    if (element != null && name != null) {
      _addOccurrence(element, name);
    }
    super.visitPatternField(node);
  }

  @override
  void visitRepresentationDeclaration(RepresentationDeclaration node) {
    if (node.constructorName case var constructorName?) {
      _addOccurrence(node.constructorFragment!.element, constructorName.name);
    }

    super.visitRepresentationDeclaration(node);
  }

  @override
  void visitSimpleFormalParameter(SimpleFormalParameter node) {
    var nameToken = node.name;
    if (nameToken != null) {
      _addOccurrence(node.declaredFragment!.element, nameToken);
    }

    super.visitSimpleFormalParameter(node);
  }

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    // For unnamed constructors, we don't want to add an occurrence for the
    // class name here because visitConstructorDeclaration will have added one
    // for the constructor (not the type).
    if (node.parent case ConstructorDeclaration(
      :var name,
      :var returnType,
    ) when name == null && node == returnType) {
      return;
    }

    var element = node.writeOrReadElement2;
    if (element != null) {
      _addOccurrence(element, node.token);
    }
    return super.visitSimpleIdentifier(node);
  }

  @override
  void visitSuperFormalParameter(SuperFormalParameter node) {
    _addOccurrence(node.declaredFragment!.element, node.name);
    super.visitSuperFormalParameter(node);
  }

  @override
  void visitTypeParameter(TypeParameter node) {
    if (node case TypeParameter(:var declaredFragment?)) {
      _addOccurrence(declaredFragment.element, node.name);
    }

    super.visitTypeParameter(node);
  }

  @override
  void visitVariableDeclaration(VariableDeclaration node) {
    _addOccurrence(node.declaredFragment!.element, node.name);
    super.visitVariableDeclaration(node);
  }

  void _addOccurrence(Element element, Token token) {
    _addOccurrenceAt(element, token.offset, token.length);
  }

  void _addOccurrenceAt(Element element, int offset, int length) {
    var canonicalElement = _canonicalizeElement(element);
    if (canonicalElement == null) {
      return;
    }
    var offsetLengths = elementsOffsetLengths[canonicalElement];
    if (offsetLengths == null) {
      offsetLengths = <(int, int)>[];
      elementsOffsetLengths[canonicalElement] = offsetLengths;
    }
    offsetLengths.add((offset, length));
  }

  Element? _canonicalizeElement(Element element) {
    Element? canonicalElement = element;
    if (canonicalElement is FieldFormalParameterElement) {
      canonicalElement = canonicalElement.field2;
    } else if (canonicalElement is PropertyAccessorElement) {
      canonicalElement = canonicalElement.variable3;
    }
    return canonicalElement?.baseElement;
  }
}
