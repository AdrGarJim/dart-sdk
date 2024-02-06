// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/messages/codes.dart';
import 'package:_fe_analyzer_shared/src/parser/parser.dart';
import 'package:_fe_analyzer_shared/src/scanner/scanner.dart';

abstract class CodeOptimizer {
  /// Returns names exported from the library [uriStr].
  Set<String> getImportedNames(String uriStr);

  List<Edit> optimize(
    String code, {
    bool throwIfHasErrors = false,
  }) {
    List<Edit> edits = [];

    ScannerResult result = scanString(
      code,
      configuration: new ScannerConfiguration(
        enableExtensionMethods: true,
        enableNonNullable: true,
        forAugmentationLibrary: true,
      ),
      includeComments: true,
      languageVersionChanged: (scanner, languageVersion) {
        throw new UnimplementedError();
      },
    );

    if (result.hasErrors) {
      if (throwIfHasErrors) {
        throw new StateError('Has scan errors');
      }
      return [];
    }

    _Listener listener = new _Listener(
      getImportedNames: getImportedNames,
    );

    Parser parser = new Parser(
      listener,
      allowPatterns: true,
    );
    parser.parseUnit(result.tokens);
    listener.verifyEmptyStack();

    if (listener.hasErrors) {
      if (throwIfHasErrors) {
        throw new StateError('Has parse errors');
      }
      return [];
    }

    void walkScopes(_Scope scope) {
      for (_PrefixedName prefixedName in scope.prefixedNames) {
        String name = prefixedName.name.token.lexeme;
        _NameStatus resolution = scope.resolve(name);
        if (resolution is _NameStatusImported) {
          if (resolution.imports.length == 1) {
            int prefixOffset = prefixedName.prefix.token.offset;
            edits.add(
              new Edit(
                offset: prefixOffset,
                length: prefixedName.name.token.offset - prefixOffset,
                replacement: '',
              ),
            );
          }
        }
      }
      for (_Scope child in scope.children) {
        walkScopes(child);
      }
    }

    walkScopes(listener.importScope);

    edits.sort((a, b) => b.offset - a.offset);
    return edits;
  }
}

class Edit {
  final int offset;
  final int length;
  final String replacement;

  Edit({
    required this.offset,
    required this.length,
    required this.replacement,
  });

  static String applyList(List<Edit> edits, String value) {
    for (Edit edit in edits) {
      String before = value.substring(0, edit.offset);
      String after = value.substring(edit.offset + edit.length);
      value = before + edit.replacement + after;
    }
    return value;
  }
}

class _ExtensionNoName {
  const _ExtensionNoName();
}

class _Identifier {
  final Token token;

  _Identifier(this.token);

  @override
  String toString() {
    return token.lexeme;
  }
}

class _Import {
  final String uriStr;
  final String prefix;
  final Set<String> names;

  _Import({
    required this.uriStr,
    required this.prefix,
    required this.names,
  });
}

class _ImportPrefix {
  final _Identifier name;

  _ImportPrefix({
    required this.name,
  });
}

class _ImportScope extends _Scope {
  final List<_Import> imports = [];

  _ImportScope();

  @override
  _NameStatus resolve(String name) {
    return new _NameStatusImported(
      imports: imports.where((import) {
        return import.names.contains(name);
      }).toList(),
    );
  }
}

class _InterpolationString {
  final List<Object?> components;

  _InterpolationString({
    required this.components,
  });

  @override
  String toString() {
    return components.join('');
  }
}

class _LibraryScope extends _NestedScope {
  final Set<String> globalNames = {};

  _LibraryScope({
    required super.parent,
  });

  @override
  _NameStatus resolve(String name) {
    if (globalNames.contains(name)) {
      return const _NameStatusShadowed();
    }

    return super.resolve(name);
  }
}

class _Listener extends Listener {
  Set<String> Function(String uriStr) getImportedNames;

  bool hasErrors = false;

  _ImportScope importScope = new _ImportScope();
  late _LibraryScope libraryScope = new _LibraryScope(parent: importScope);
  late _NestedScope scope = libraryScope;

  final List<Object?> stack = [];

  _Listener({
    required this.getImportedNames,
  });

  @override
  void beginClassOrMixinOrNamedMixinApplicationPrelude(Token token) {
    _scopeEnter();
  }

  @override
  void beginEnum(Token enumKeyword) {
    _scopeEnter();
  }

  @override
  void beginExtensionDeclaration(Token extensionKeyword, Token? name) {
    if (name != null) {
      stack.add(
        new _Identifier(name),
      );
    } else {
      stack.add(
        const _ExtensionNoName(),
      );
    }
  }

  @override
  void beginExtensionDeclarationPrelude(Token extensionKeyword) {
    _scopeEnter();
  }

  @override
  void beginExtensionTypeDeclaration(Token extensionKeyword, Token name) {
    stack.add(
      new _Identifier(name),
    );
  }

  @override
  void beginLiteralString(Token token) {
    push(
      new _StringLiteral(
        token: token,
      ),
    );
  }

  @override
  void beginMethod(
    DeclarationKind declarationKind,
    Token? augmentToken,
    Token? externalToken,
    Token? staticToken,
    Token? covariantToken,
    Token? varFinalOrConst,
    Token? getOrSet,
    Token name,
  ) {
    _scopeEnter();
  }

  @override
  void beginTypedef(Token token) {
    _scopeEnter();
  }

  @override
  void endArguments(int count, Token beginToken, Token endToken) {
    _popList(count);
  }

  @override
  void endClassConstructor(
    Token? getOrSet,
    Token beginToken,
    Token beginParam,
    Token? beginInitializers,
    Token endToken,
  ) {
    pop(); // name
  }

  @override
  void endClassDeclaration(Token beginToken, Token endToken) {
    _popNameGlobal();
    _scopeExit();
  }

  @override
  void endClassMethod(
    Token? getOrSet,
    Token beginToken,
    Token beginParam,
    Token? beginInitializers,
    Token endToken,
  ) {
    _popNameGlobal();
    _scopeExit();
  }

  @override
  void endEnum(
    Token beginToken,
    Token enumKeyword,
    Token leftBrace,
    int memberCount,
    Token endToken,
  ) {
    _popNameGlobal();
    _scopeExit();
  }

  @override
  void endExtensionDeclaration(
    Token beginToken,
    Token extensionKeyword,
    Token onKeyword,
    Token endToken,
  ) {
    _popNameGlobal();
    _scopeExit();
  }

  @override
  void endExtensionTypeDeclaration(
    Token beginToken,
    Token extensionKeyword,
    Token typeKeyword,
    Token endToken,
  ) {
    _popNameGlobal();
    _scopeExit();
  }

  @override
  void endFieldInitializer(Token assignment, Token token) {
    _popNameGlobal();
  }

  @override
  void endFormalParameter(
    Token? thisKeyword,
    Token? superKeyword,
    Token? periodAfterThisOrSuper,
    Token nameToken,
    Token? initializerStart,
    Token? initializerEnd,
    FormalParameterKind kind,
    MemberKind memberKind,
  ) {
    _popNameLocal();
  }

  @override
  void endImport(Token importKeyword, Token? augmentToken, Token? semicolon) {
    _ImportPrefix prefix = pop() as _ImportPrefix;
    _StringLiteral uri = pop() as _StringLiteral;

    String uriStr = uri.token.lexeme;
    if (uriStr.startsWith('\'') && uriStr.endsWith('\'')) {
      uriStr = uriStr.substring(1, uriStr.length - 1);
    } else {
      throw new UnimplementedError();
    }

    importScope.imports.add(
      new _Import(
        uriStr: uriStr,
        prefix: prefix.name.token.lexeme,
        names: getImportedNames(uriStr),
      ),
    );
  }

  @override
  void endLiteralString(int interpolationCount, Token endToken) {
    if (interpolationCount == 0) {
      return;
    }

    push(
      new _InterpolationString(
        components: _popList(1 + interpolationCount + 1),
      ),
    );
  }

  @override
  void endMixinDeclaration(Token beginToken, Token endToken) {
    _popNameGlobal();
    _scopeExit();
  }

  @override
  void endTopLevelMethod(Token beginToken, Token? getOrSet, Token endToken) {
    _popNameGlobal();
  }

  @override
  void endTypedef(Token typedefKeyword, Token? equals, Token endToken) {
    _popNameGlobal();
    _scopeExit();
  }

  @override
  void endTypeVariable(
      Token token, int index, Token? extendsOrSuper, Token? variance) {
    _popNameLocal();
  }

  @override
  void handleEnumElements(Token elementsEndToken, int elementsCount) {
    _popList(elementsCount);
  }

  @override
  void handleIdentifier(Token token, IdentifierContext context) {
    push(
      new _Identifier(token),
    );
  }

  @override
  void handleImportPrefix(Token? deferredKeyword, Token? asKeyword) {
    if (asKeyword == null) {
      throw new StateError('All macro imports must be prefixed');
    }

    _Identifier name = pop() as _Identifier;

    push(
      new _ImportPrefix(
        name: name,
      ),
    );
  }

  @override
  void handleNoFieldInitializer(Token token) {
    _popNameGlobal();
  }

  @override
  void handleQualified(Token period) {
    _Identifier name = pop() as _Identifier;
    _Identifier prefix = pop() as _Identifier;
    push(
      new _PrefixedName(
        prefix: prefix,
        name: name,
      ),
    );
  }

  @override
  void handleRecoverableError(
    Message message,
    Token startToken,
    Token endToken,
  ) {
    hasErrors = true;
  }

  @override
  void handleStringPart(Token token) {
    push(
      new _StringLiteral(
        token: token,
      ),
    );
  }

  @override
  void handleType(Token beginToken, Token? questionMark) {
    Object? prefixedName = pop();
    if (prefixedName is _PrefixedName) {
      scope.prefixedNames.add(prefixedName);
    }
  }

  Object? pop() {
    return stack.removeLast();
  }

  void push(Object? value) {
    stack.add(value);
  }

  void verifyEmptyStack() {
    if (stack.isNotEmpty) {
      throw new StateError('Expected empty stack:\n${stack.join('\n')}');
    }
  }

  List<Object?> _popList(int count) {
    List<Object?> result = <Object?>[];
    for (int i = 0; i < count; i++) {
      Object? element = pop();
      result.add(element);
    }
    return result.reversed.toList();
  }

  /// Pop [_Identifier], add the name to [libraryScope].
  void _popNameGlobal() {
    Object? name = pop();
    switch (name) {
      case _ExtensionNoName():
        break; // ignore
      case _Identifier():
        libraryScope.globalNames.add(name.token.lexeme);
      default:
        throw new StateError('${name.runtimeType}');
    }
  }

  /// Pop [_Identifier], add the name to [scope].
  void _popNameLocal() {
    _Identifier name = pop() as _Identifier;
    scope.names.add(name.token.lexeme);
  }

  /// Enter the nested scope.
  void _scopeEnter() {
    scope = scope.nested();
  }

  /// Exit the nested scope.
  void _scopeExit() {
    scope = scope.parent as _NestedScope;
  }
}

sealed class _NameStatus {
  const _NameStatus();
}

class _NameStatusImported extends _NameStatus {
  /// The imports that would provide this name if used without a prefix.
  final List<_Import> imports;

  _NameStatusImported({
    required this.imports,
  });
}

/// The name is shadowed by a local declaration.
///
/// A top-level declaration anywhere in the library.
///
/// A local declaration in the same scope - local variable, method name,
/// type parameters name, formal parameter name, etc.
class _NameStatusShadowed extends _NameStatus {
  const _NameStatusShadowed();
}

class _NestedScope extends _Scope {
  final _Scope parent;
  final Set<String> names = {};

  _NestedScope({
    required this.parent,
  }) {
    parent.children.add(this);
  }

  _NestedScope nested() {
    return new _NestedScope(
      parent: this,
    );
  }

  @override
  _NameStatus resolve(String name) {
    if (names.contains(name)) {
      return const _NameStatusShadowed();
    }
    return parent.resolve(name);
  }
}

class _PrefixedName {
  final _Identifier prefix;
  final _Identifier name;

  _PrefixedName({
    required this.prefix,
    required this.name,
  });

  @override
  String toString() {
    return '$prefix.$name';
  }
}

sealed class _Scope {
  final List<_PrefixedName> prefixedNames = [];
  final List<_Scope> children = [];

  _NameStatus resolve(String name);
}

class _StringLiteral {
  final Token token;

  _StringLiteral({
    required this.token,
  });

  @override
  String toString() {
    return token.lexeme;
  }
}
