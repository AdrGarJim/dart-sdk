// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
// ignore: implementation_imports
import 'package:analyzer/src/dart/element/element.dart';

import '../analyzer.dart';
import '../extensions.dart';

const _desc =
    r'If-elements testing for null can be replaced with null-aware elements.';

class UseNullAwareElements extends LintRule {
  UseNullAwareElements()
    : super(name: LintNames.use_null_aware_elements, description: _desc);

  @override
  LintCode get lintCode => LinterLintCode.use_null_aware_elements;

  @override
  void registerNodeProcessors(
    NodeLintRegistry registry,
    LinterContext context,
  ) {
    if (!context.isEnabled(Feature.null_aware_elements)) return;
    var visitor = _Visitor(this);
    registry.addIfElement(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final LintRule rule;

  _Visitor(this.rule);

  @override
  void visitIfElement(IfElement node) {
    if (node case IfElement(:var thenElement, elseKeyword: null)) {
      Element? nullCheckTarget;
      if (node.expression case BinaryExpression(
        :var operator,
        :var leftOperand,
        :var rightOperand,
      ) when operator.isOperator && operator.lexeme == '!=') {
        // Case of non-pattern null checks of the form `if (x != null) x`.
        if (leftOperand is NullLiteral) {
          // Cases of the form `if (null != x) x`.
          nullCheckTarget = rightOperand.canonicalElement;
        } else if (rightOperand is NullLiteral) {
          // Cases of the form `if (x != null) x`.
          nullCheckTarget = leftOperand.canonicalElement;
        }
      } else if (node.caseClause?.guardedPattern.pattern case NullCheckPattern(
        pattern: DeclaredVariablePattern(:var declaredElement2),
      )) {
        // Case of pattern null checks of the form `if (x case var y?) y`.
        nullCheckTarget = declaredElement2;
      }

      if (nullCheckTarget is PromotableElementImpl2) {
        if (thenElement is SimpleIdentifier &&
            nullCheckTarget == thenElement.canonicalElement) {
          // List and set elements, such as the following:
          //
          //     [if (x != null) x]
          //     {if (x != null) x}
          rule.reportAtToken(node.ifKeyword);
        } else if (thenElement case MapLiteralEntry(:var key, :var value)) {
          if (key is SimpleIdentifier &&
              nullCheckTarget == key.canonicalElement) {
            // Map keys, such as the following:
            //
            //     {if (x != null) x: value}
            rule.reportAtToken(node.ifKeyword);
          } else if (value is SimpleIdentifier &&
              nullCheckTarget == value.canonicalElement) {
            // Map keys, such as the following:
            //
            //     {if (x != null) key: x}
            rule.reportAtToken(node.ifKeyword);
          }
        }
      }
    }
  }
}
