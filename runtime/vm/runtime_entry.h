// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_RUNTIME_ENTRY_H_
#define RUNTIME_VM_RUNTIME_ENTRY_H_

#include "vm/allocation.h"
#if !defined(DART_PRECOMPILED_RUNTIME)
#include "vm/compiler/runtime_api.h"
#endif
#include "vm/native_arguments.h"
#include "vm/runtime_entry_list.h"

namespace dart {

typedef void (*RuntimeFunction)(NativeArguments arguments);

#if !defined(DART_PRECOMPILED_RUNTIME)
using BaseRuntimeEntry = compiler::RuntimeEntry;
#else
using BaseRuntimeEntry = ValueObject;
#endif

// Class RuntimeEntry is used to encapsulate runtime functions, it includes
// the entry point for the runtime function and the number of arguments expected
// by the function.
class RuntimeEntry : public BaseRuntimeEntry {
 public:
  RuntimeEntry(const char* name,
               const void* function,
               intptr_t argument_count,
               bool is_leaf,
               bool is_float,
               bool can_lazy_deopt)
      :
#if !defined(DART_PRECOMPILED_RUNTIME)
        compiler::RuntimeEntry(this),
#endif
        name_(name),
        function_(function),
        argument_count_(argument_count),
        is_leaf_(is_leaf),
        is_float_(is_float),
        can_lazy_deopt_(can_lazy_deopt) {
  }

  const char* name() const { return name_; }
  const void* function() const { return function_; }
  intptr_t argument_count() const { return argument_count_; }
  bool is_leaf() const { return is_leaf_; }
  bool is_float() const { return is_float_; }
  bool can_lazy_deopt() const { return can_lazy_deopt_; }
  uword GetEntryPoint() const;
  uword GetEntryPointNoRedirect() const {
    return reinterpret_cast<uword>(function());
  }

  static uword InterpretCallEntry();

 private:
  const char* const name_;
  const void* const function_;
  const intptr_t argument_count_;
  const bool is_leaf_;
  const bool is_float_;
  const bool can_lazy_deopt_;

  DISALLOW_COPY_AND_ASSIGN(RuntimeEntry);
};

#define DECLARE_RUNTIME_ENTRY(name)                                            \
  extern const RuntimeEntry k##name##RuntimeEntry;                             \
  extern "C" void DRT_##name(NativeArguments arguments);

#define DEFINE_LEAF_RUNTIME_ENTRY(name, argument_count, func)                  \
  extern const RuntimeEntry k##name##RuntimeEntry(                             \
      "DLRT_" #name, reinterpret_cast<const void*>(func), argument_count,      \
      true, false, /*can_lazy_deopt=*/false)

#define DEFINE_FLOAT_LEAF_RUNTIME_ENTRY(name, argument_count, func)            \
  extern const RuntimeEntry k##name##RuntimeEntry(                             \
      "DLRT_" #name, reinterpret_cast<const void*>(func), argument_count,      \
      true, true, /*can_lazy_deopt=*/false)

#define DECLARE_LEAF_RUNTIME_ENTRY(type, name, ...)                            \
  extern const RuntimeEntry k##name##RuntimeEntry;                             \
  extern "C" type DLRT_##name(__VA_ARGS__);

// Declare all runtime functions here.
RUNTIME_ENTRY_LIST(DECLARE_RUNTIME_ENTRY)
LEAF_RUNTIME_ENTRY_LIST(DECLARE_LEAF_RUNTIME_ENTRY)

#undef DECLARE_RUNTIME_ENTRY
#undef DECLARE_LEAF_RUNTIME_ENTRY

// See StubCode::GenerateFfiCallbackTrampolineStub.
extern "C" Thread* DLRT_GetFfiCallbackMetadata(uword trampoline,
                                               uword* out_entry_point,
                                               uword* out_callback_kind);
extern "C" void DLRT_ExitTemporaryIsolate();
extern "C" void DLRT_ExitIsolateGroupSharedIsolate();

const char* DeoptReasonToCString(ICData::DeoptReasonId deopt_reason);

void DeoptimizeAt(Thread* mutator_thread,
                  const Code& optimized_code,
                  StackFrame* frame);
void DeoptimizeFunctionsOnStack();

}  // namespace dart

#endif  // RUNTIME_VM_RUNTIME_ENTRY_H_
