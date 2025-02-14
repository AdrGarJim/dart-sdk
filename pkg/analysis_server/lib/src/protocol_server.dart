// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/plugin/protocol/protocol_dart.dart';
import 'package:analysis_server/protocol/protocol_generated.dart';
import 'package:analysis_server/src/computer/computer_color.dart';
import 'package:analysis_server/src/services/search/search_engine.dart'
    as engine;
import 'package:analysis_server/src/utilities/extensions/element.dart';
import 'package:analyzer/dart/analysis/results.dart' as engine;
import 'package:analyzer/dart/ast/ast.dart' as engine;
import 'package:analyzer/dart/element/element2.dart' as engine;
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/diagnostic/diagnostic.dart' as engine;
import 'package:analyzer/error/error.dart' as engine;
import 'package:analyzer/source/error_processor.dart';
import 'package:analyzer/source/source.dart' as engine;
import 'package:analyzer/source/source_range.dart' as engine;
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart';

export 'package:analysis_server/plugin/protocol/protocol_dart.dart';
export 'package:analysis_server/protocol/protocol.dart';
export 'package:analysis_server/protocol/protocol_generated.dart';
export 'package:analyzer_plugin/protocol/protocol_common.dart';

/// Returns a list of AnalysisErrors corresponding to the given list of Engine
/// errors.
List<AnalysisError> doAnalysisError_listFromEngine(
  engine.AnalysisResultWithErrors result,
) {
  return mapEngineErrors(result, result.errors, newAnalysisError_fromEngine);
}

/// Adds [edit] to the file containing the given [fragment].
void doSourceChange_addFragmentEdit(
  SourceChange change,
  engine.Fragment fragment,
  SourceEdit edit,
) {
  var source = fragment.libraryFragment!.source;
  doSourceChange_addSourceEdit(change, source, edit);
}

/// Adds [edit] for the given [source] to the [change].
void doSourceChange_addSourceEdit(
  SourceChange change,
  engine.Source source,
  SourceEdit edit, {
  bool isNewFile = false,
}) {
  var file = source.fullName;
  change.addEdit(file, isNewFile ? -1 : 0, edit);
}

String? getAliasedTypeString2(engine.Element2 element) {
  if (element is engine.TypeAliasElement2) {
    var aliasedType = element.aliasedType;
    return aliasedType.getDisplayString();
  }
  return null;
}

/// Returns a color hex code (in the form '#FFFFFF')  if [element] represents
/// a color.
String? getColorHexString2(engine.Element2? element) {
  if (element is engine.VariableElement2) {
    var dartValue = element.computeConstantValue();
    if (dartValue != null) {
      var color = ColorComputer.getColorForObject(dartValue);
      if (color != null) {
        return '#'
                '${color.red.toRadixString(16).padLeft(2, '0')}'
                '${color.green.toRadixString(16).padLeft(2, '0')}'
                '${color.blue.toRadixString(16).padLeft(2, '0')}'
            .toUpperCase();
      }
    }
  }
  return null;
}

String? getReturnTypeString2(engine.Element2 element) {
  if (element is engine.ExecutableElement2) {
    if (element.kind == engine.ElementKind.SETTER) {
      return null;
    } else {
      return element.returnType.getDisplayString();
    }
  } else if (element is engine.VariableElement2) {
    var type = element.type;
    return type.getDisplayString();
  } else if (element is engine.TypeAliasElement2) {
    var aliasedType = element.aliasedType;
    if (aliasedType is FunctionType) {
      var returnType = aliasedType.returnType;
      return returnType.getDisplayString();
    }
  }
  return null;
}

/// Translates engine errors through the ErrorProcessor.
List<T> mapEngineErrors<T>(
  engine.AnalysisResultWithErrors result,
  List<engine.AnalysisError> errors,
  T Function(
    engine.AnalysisResultWithErrors result,
    engine.AnalysisError error, [
    engine.ErrorSeverity errorSeverity,
  ])
  constructor,
) {
  var analysisOptions = result.session.analysisContext
      .getAnalysisOptionsForFile(result.file);
  var serverErrors = <T>[];
  for (var error in errors) {
    var processor = ErrorProcessor.getProcessor(analysisOptions, error);
    if (processor != null) {
      var severity = processor.severity;
      // Errors with null severity are filtered out.
      if (severity != null) {
        // Specified severities override.
        serverErrors.add(constructor(result, error, severity));
      }
    } else {
      serverErrors.add(constructor(result, error));
    }
  }
  return serverErrors;
}

/// Construct based on error information from the analyzer engine.
///
/// If an [errorSeverity] is specified, it will override the one in [error].
AnalysisError newAnalysisError_fromEngine(
  engine.AnalysisResultWithErrors result,
  engine.AnalysisError error, [
  engine.ErrorSeverity? errorSeverity,
]) {
  var errorCode = error.errorCode;
  // prepare location
  Location location;
  {
    var file = error.source.fullName;
    var offset = error.offset;
    var length = error.length;
    var lineInfo = result.lineInfo;

    var startLocation = lineInfo.getLocation(offset);
    var startLine = startLocation.lineNumber;
    var startColumn = startLocation.columnNumber;

    var endLocation = lineInfo.getLocation(offset + length);
    var endLine = endLocation.lineNumber;
    var endColumn = endLocation.columnNumber;

    location = Location(
      file,
      offset,
      length,
      startLine,
      startColumn,
      endLine: endLine,
      endColumn: endColumn,
    );
  }

  // Default to the error's severity if none is specified.
  errorSeverity ??= errorCode.errorSeverity;

  // done
  var severity = AnalysisErrorSeverity.values.byName(errorSeverity.name);
  var type = AnalysisErrorType.values.byName(errorCode.type.name);
  var message = error.message;
  var code = errorCode.name.toLowerCase();
  List<DiagnosticMessage>? contextMessages;
  if (error.contextMessages.isNotEmpty) {
    contextMessages =
        error.contextMessages
            .map((message) => newDiagnosticMessage(result, message))
            .toList();
  }
  var correction = error.correction;
  var url = errorCode.url;
  return AnalysisError(
    severity,
    type,
    location,
    message,
    code,
    contextMessages: contextMessages,
    correction: correction,
    // This parameter is only necessary for deprecated IDE support.
    // Whether the error actually has a fix or not is not important to report
    // here.
    // TODO(srawlins): Remove it.
    hasFix: false,
    url: url,
  );
}

/// Create a DiagnosticMessage based on an [engine.DiagnosticMessage].
DiagnosticMessage newDiagnosticMessage(
  engine.AnalysisResultWithErrors result,
  engine.DiagnosticMessage message,
) {
  var file = message.filePath;
  var offset = message.offset;
  var length = message.length;

  var startLocation = result.lineInfo.getLocation(offset);
  var startLine = startLocation.lineNumber;
  var startColumn = startLocation.columnNumber;

  var endLocation = result.lineInfo.getLocation(offset + length);
  var endLine = endLocation.lineNumber;
  var endColumn = endLocation.columnNumber;

  return DiagnosticMessage(
    message.messageText(includeUrl: true),
    Location(
      file,
      offset,
      length,
      startLine,
      startColumn,
      endLine: endLine,
      endColumn: endColumn,
    ),
  );
}

/// Create a Location based on an [engine.Element2].
Location? newLocation_fromElement2(engine.Element2? element) {
  if (element == null) {
    return null;
  }
  if (element is engine.FormalParameterElement &&
      element.enclosingElement2 == null) {
    return null;
  }
  var fragment = element.firstFragment;
  var (offset, length) = switch (fragment) {
    // For unnamed constructors, treat the type name as the element location
    // instead of using 0,0.
    engine.ConstructorFragment(:var typeNameOffset, :var typeName) =>
      fragment.nameOffset2 != null
          ? (fragment.nameOffset2 ?? 0, fragment.name2.length)
          : (typeNameOffset ?? 0, typeName?.length ?? 0),
    _ => (fragment.nameOffset2 ?? 0, fragment.name2?.length ?? 0),
  };
  var range = engine.SourceRange(offset, length);
  return _locationForArgs2(fragment, range);
}

/// Creates a location based on the [fragment].
Location? newLocation_fromFragment(engine.Fragment? fragment) {
  if (fragment == null) {
    return null;
  }
  if (fragment is engine.FormalParameterFragment &&
      fragment.enclosingFragment == null) {
    return null;
  }
  var offset = fragment.nameOffset2 ?? 0;
  var length = fragment.name2?.length ?? 0;
  var range = engine.SourceRange(offset, length);
  return _locationForArgs2(fragment, range);
}

/// Create a Location based on an [engine.SearchMatch].
Location newLocation_fromMatch(engine.SearchMatch match) {
  var libraryFragment = _getUnitElement(match.element2);
  return _locationForArgs(libraryFragment, match.sourceRange);
}

/// Create a Location based on an [engine.AstNode].
Location newLocation_fromNode(engine.AstNode node) {
  var unit = node.thisOrAncestorOfType<engine.CompilationUnit>()!;
  var libraryFragment = unit.declaredFragment!;
  var range = engine.SourceRange(node.offset, node.length);
  return _locationForArgs(libraryFragment, range);
}

/// Create a Location based on an [engine.CompilationUnit].
Location newLocation_fromUnit(
  engine.CompilationUnit unit,
  engine.SourceRange range,
) {
  return _locationForArgs(unit.declaredFragment!, range);
}

/// Construct based on an element from the analyzer engine.
OverriddenMember newOverriddenMember_fromEngine(engine.Element2 member) {
  var element = convertElement(member);
  var className = member.enclosingElement2!.displayName;
  return OverriddenMember(element, className);
}

/// Construct based on a value from the search engine.
SearchResult newSearchResult_fromMatch(engine.SearchMatch match) {
  var kind = newSearchResultKind_fromEngine(match.kind);
  var location = newLocation_fromMatch(match);
  var path = _computePath(match.element2);
  return SearchResult(location, kind, !match.isResolved, path);
}

/// Construct based on a value from the search engine.
SearchResultKind newSearchResultKind_fromEngine(engine.MatchKind kind) {
  if (kind == engine.MatchKind.DECLARATION) {
    return SearchResultKind.DECLARATION;
  }
  if (kind == engine.MatchKind.READ) {
    return SearchResultKind.READ;
  }
  if (kind == engine.MatchKind.READ_WRITE) {
    return SearchResultKind.READ_WRITE;
  }
  if (kind == engine.MatchKind.WRITE) {
    return SearchResultKind.WRITE;
  }
  if (kind == engine.MatchKind.INVOCATION ||
      kind == engine.MatchKind.INVOCATION_BY_ENUM_CONSTANT_WITHOUT_ARGUMENTS) {
    return SearchResultKind.INVOCATION;
  }
  if (kind.isReference) {
    return SearchResultKind.REFERENCE;
  }
  return SearchResultKind.UNKNOWN;
}

/// Construct based on a SourceRange.
SourceEdit newSourceEdit_range(
  engine.SourceRange range,
  String replacement, {
  String? id,
}) {
  return SourceEdit(range.offset, range.length, replacement, id: id);
}

List<Element> _computePath(engine.Element2 element) {
  var path = <Element>[];
  for (var fragment in element.firstFragment.withAncestors) {
    if (fragment is engine.LibraryFragment) {
      path.add(convertLibraryFragment(fragment as CompilationUnitElementImpl));
    }
    path.add(convertElement(fragment.element));
  }
  return path;
}

engine.LibraryFragment _getUnitElement(engine.Element2 element) {
  if (element is engine.LibraryElement2) {
    return element.firstFragment;
  }
  var fragment = element.firstFragment.libraryFragment;
  if (fragment == null) {
    throw StateError('No unit: $element');
  }
  return fragment;
}

/// Returns a new [Location] based on a source [range] with a [libraryFragment].
Location _locationForArgs(
  engine.LibraryFragment libraryFragment,
  engine.SourceRange range,
) {
  var lineInfo = libraryFragment.lineInfo;

  var startLocation = lineInfo.getLocation(range.offset);
  var endLocation = lineInfo.getLocation(range.end);

  var startLine = startLocation.lineNumber;
  var startColumn = startLocation.columnNumber;
  var endLine = endLocation.lineNumber;
  var endColumn = endLocation.columnNumber;

  return Location(
    libraryFragment.source.fullName,
    range.offset,
    range.length,
    startLine,
    startColumn,
    endLine: endLine,
    endColumn: endColumn,
  );
}

/// Creates a new [Location].
Location? _locationForArgs2(
  engine.Fragment fragment,
  engine.SourceRange range,
) {
  var libraryFragment = fragment.libraryFragment;
  if (libraryFragment == null) {
    return null;
  }
  var lineInfo = libraryFragment.lineInfo;

  var startLocation = lineInfo.getLocation(range.offset);
  var endLocation = lineInfo.getLocation(range.end);

  var startLine = startLocation.lineNumber;
  var startColumn = startLocation.columnNumber;
  var endLine = endLocation.lineNumber;
  var endColumn = endLocation.columnNumber;

  return Location(
    fragment.libraryFragment!.source.fullName,
    range.offset,
    range.length,
    startLine,
    startColumn,
    endLine: endLine,
    endColumn: endColumn,
  );
}
