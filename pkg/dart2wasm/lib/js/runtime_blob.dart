// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

final jsRuntimeBlobTemplate = Template(r'''
// Compiles a dart2wasm-generated main module from `source` which can then
// instantiatable via the `instantiate` method.
//
// `source` needs to be a `Response` object (or promise thereof) e.g. created
// via the `fetch()` JS API.
export async function compileStreaming(source) {
  const builtins = {<<BUILTINS_MAP_BODY>>};
  return new CompiledApp(
      await WebAssembly.compileStreaming(source, builtins), builtins);
}

// Compiles a dart2wasm-generated wasm modules from `bytes` which is then
// instantiatable via the `instantiate` method.
export async function compile(bytes) {
  const builtins = {<<BUILTINS_MAP_BODY>>};
  return new CompiledApp(await WebAssembly.compile(bytes, builtins), builtins);
}

// DEPRECATED: Please use `compile` or `compileStreaming` to get a compiled app,
// use `instantiate` method to get an instantiated app and then call
// `invokeMain` to invoke the main function.
export async function instantiate(modulePromise, importObjectPromise) {
  var moduleOrCompiledApp = await modulePromise;
  if (!(moduleOrCompiledApp instanceof CompiledApp)) {
    moduleOrCompiledApp = new CompiledApp(moduleOrCompiledApp);
  }
  const instantiatedApp = await moduleOrCompiledApp.instantiate(await importObjectPromise);
  return instantiatedApp.instantiatedModule;
}

// DEPRECATED: Please use `compile` or `compileStreaming` to get a compiled app,
// use `instantiate` method to get an instantiated app and then call
// `invokeMain` to invoke the main function.
export const invoke = (moduleInstance, ...args) => {
  moduleInstance.exports.$invokeMain(args);
}

class CompiledApp {
  constructor(module, builtins) {
    this.module = module;
    this.builtins = builtins;
  }

  // The second argument is an options object containing:
  // `loadDeferredWasm` is a JS function that takes a module name matching a
  //   wasm file produced by the dart2wasm compiler and returns the bytes to
  //   load the module. These bytes can be in either a format supported by
  //   `WebAssembly.compile` or `WebAssembly.compileStreaming`.
  async instantiate(additionalImports, {loadDeferredWasm, loadDynamicModule} = {}) {
    let dartInstance;

    // Prints to the console
    function printToConsole(value) {
      if (typeof dartPrint == "function") {
        dartPrint(value);
        return;
      }
      if (typeof console == "object" && typeof console.log != "undefined") {
        console.log(value);
        return;
      }
      if (typeof print == "function") {
        print(value);
        return;
      }

      throw "Unable to print message: " + js;
    }

    // Converts a Dart List to a JS array. Any Dart objects will be converted, but
    // this will be cheap for JSValues.
    function arrayFromDartList(constructor, list) {
      const exports = dartInstance.exports;
      const read = exports.$listRead;
      const length = exports.$listLength(list);
      const array = new constructor(length);
      for (let i = 0; i < length; i++) {
        array[i] = read(list, i);
      }
      return array;
    }

    // A special symbol attached to functions that wrap Dart functions.
    const jsWrappedDartFunctionSymbol = Symbol("JSWrappedDartFunction");

    function finalizeWrapper(dartFunction, wrapped) {
      wrapped.dartFunction = dartFunction;
      wrapped[jsWrappedDartFunctionSymbol] = true;
      return wrapped;
    }

    // Imports
    const dart2wasm = {
      <<JS_METHODS>>
    };

    const baseImports = {
      dart2wasm: dart2wasm,
      Math: Math,
      Date: Date,
      Object: Object,
      Array: Array,
      Reflect: Reflect,
      <<IMPORTED_JS_STRINGS_IN_MJS>>
    };

    <<JS_STRING_POLYFILL_METHODS>>

    <<DEFERRED_LIBRARY_HELPER_METHODS>>

    dartInstance = await WebAssembly.instantiate(this.module, {
      ...baseImports,
      ...additionalImports,
      <<MODULE_LOADING_IMPORT>>
      <<JS_POLYFILL_IMPORT>>
    });

    return new InstantiatedApp(this, dartInstance);
  }
}

class InstantiatedApp {
  constructor(compiledApp, instantiatedModule) {
    this.compiledApp = compiledApp;
    this.instantiatedModule = instantiatedModule;
  }

  // Call the main function with the given arguments.
  invokeMain(...args) {
    this.instantiatedModule.exports.$invokeMain(args);
  }
}
''');

const String jsPolyFillMethods = r'''
const jsStringPolyfill = {
      "charCodeAt": (s, i) => s.charCodeAt(i),
      "compare": (s1, s2) => {
        if (s1 < s2) return -1;
        if (s1 > s2) return 1;
        return 0;
      },
      "concat": (s1, s2) => s1 + s2,
      "equals": (s1, s2) => s1 === s2,
      "fromCharCode": (i) => String.fromCharCode(i),
      "length": (s) => s.length,
      "substring": (s, a, b) => s.substring(a, b),
      "fromCharCodeArray": (a, start, end) => {
        if (end <= start) return '';

        const read = dartInstance.exports.$wasmI16ArrayGet;
        let result = '';
        let index = start;
        const chunkLength = Math.min(end - index, 500);
        let array = new Array(chunkLength);
        while (index < end) {
          const newChunkLength = Math.min(end - index, 500);
          for (let i = 0; i < newChunkLength; i++) {
            array[i] = read(a, index++);
          }
          if (newChunkLength < chunkLength) {
            array = array.slice(0, newChunkLength);
          }
          result += String.fromCharCode(...array);
        }
        return result;
      },
      "intoCharCodeArray": (s, a, start) => {
        if (s == '') return 0;

        const write = dartInstance.exports.$wasmI16ArraySet;
        for (var i = 0; i < s.length; ++i) {
          write(a, start++, s.charCodeAt(i));
        }
        return s.length;
      },
    };
''';

final moduleLoadingHelperTemplate = Template(r'''
const loadModuleFromBytes = async (bytes) => {
        const module = await WebAssembly.compile(bytes, this.builtins);
        return await WebAssembly.instantiate(module, {
          ...baseImports,
          ...additionalImports,
          <<JS_POLYFILL_IMPORT>>
          "module0": dartInstance.exports,
        });
    }

    const loadModule = async (loader, loaderArgument) => {
        const source = await Promise.resolve(loader(loaderArgument));
        const module = await ((source instanceof Response)
            ? WebAssembly.compileStreaming(source, this.builtins)
            : WebAssembly.compile(source, this.builtins));
        return await WebAssembly.instantiate(module, {
          ...baseImports,
          ...additionalImports,
          <<JS_POLYFILL_IMPORT>>
          "module0": dartInstance.exports,
        });
    }

    const moduleLoadingHelper = {
      "loadModule": async (moduleName) => {
        if (!loadDeferredWasm) {
          throw "No implementation of loadDeferredWasm provided.";
        }
        return await loadModule(loadDeferredWasm, moduleName);
      },
      "loadDynamicModuleFromUri": async (uri) => {
        if (!loadDynamicModule) {
          throw "No implementation of loadDynamicModule provided.";
        }
        const loadedModule = await loadModule(loadDynamicModule, uri);
        return loadedModule.exports.$invokeEntryPoint;
      },
      "loadDynamicModuleFromBytes": async (bytes) => {
        const loadedModule = await loadModuleFromBytes(loadDynamicModule, uri);
        return loadedModule.exports.$invokeEntryPoint;
      },
    };
''');

class Template {
  static final _templateVariableRegExp = RegExp(r'<<(?<varname>[A-Z_]+)>>');
  final List<_TemplatePart> _parts = [];

  Template(String stringTemplate) {
    int offset = 0;
    for (final match in _templateVariableRegExp.allMatches(stringTemplate)) {
      _parts.add(
          _TemplateStringPart(stringTemplate.substring(offset, match.start)));
      _parts.add(_TemplateVariablePart(match.namedGroup('varname')!));
      offset = match.end;
    }
    _parts.add(_TemplateStringPart(
        stringTemplate.substring(offset, stringTemplate.length)));
  }

  String instantiate(Map<String, String> variableValues) {
    final sb = StringBuffer();
    for (final part in _parts) {
      sb.write(part.instantiate(variableValues));
    }
    return sb.toString();
  }
}

abstract class _TemplatePart {
  String instantiate(Map<String, String> variableValues);
}

class _TemplateStringPart extends _TemplatePart {
  final String string;
  _TemplateStringPart(this.string);

  @override
  String instantiate(Map<String, String> variableValues) => string;
}

class _TemplateVariablePart extends _TemplatePart {
  final String variable;
  _TemplateVariablePart(this.variable);

  @override
  String instantiate(Map<String, String> variableValues) {
    final value = variableValues[variable];
    if (value != null) return value;
    throw 'Template contains no value for variable $variable';
  }
}
