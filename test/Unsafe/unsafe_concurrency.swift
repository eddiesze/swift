// RUN: %empty-directory(%t)
// RUN: %target-swift-frontend -emit-module-path %t/unsafe_swift_decls.swiftmodule %S/Inputs/unsafe_swift_decls.swift -enable-experimental-feature AllowUnsafeAttribute

// RUN: %target-typecheck-verify-swift -enable-experimental-feature WarnUnsafe -enable-experimental-feature StrictConcurrency -I %t

// REQUIRES: concurrency
// REQUIRES: swift_feature_StrictConcurrency
// REQUIRES: swift_feature_WarnUnsafe

@preconcurrency import unsafe_swift_decls // expected-warning{{@preconcurrency import is not memory-safe because it can silently introduce data races; use '@safe(unchecked)' to assert that the code is memory-safe}}{{1-1=@safe(unchecked) }}

class C: @unchecked Sendable {
  var counter: Int = 0
}

nonisolated(unsafe) var globalCounter = 0

func acceptSendable<T: Sendable>(_: T) { }

typealias RequiresSendable<T> = T where T: Sendable

@available(SwiftStdlib 5.1, *)
func f() async { // expected-warning{{global function 'f' involves unsafe code; use '@safe(unchecked)' to assert that the code is memory-safe}}
  nonisolated(unsafe) var counter = 0
  Task.detached {
    counter += 1 // expected-note{{reference to nonisolated(unsafe) var 'counter' is unsafe in concurrently-executing code}}
  }
  counter += 1 // expected-note{{reference to nonisolated(unsafe) var 'counter' is unsafe in concurrently-executing code}}
  print(counter) // expected-note{{reference to nonisolated(unsafe) var 'counter' is unsafe in concurrently-executing code}}
  print(globalCounter) // expected-note{{reference to nonisolated(unsafe) var 'globalCounter' is unsafe in concurrently-executing code}}

  acceptSendable(C()) // expected-note{{@unchecked conformance of 'C' to protocol 'Sendable' involves unsafe code}}
}

// expected-warning@+1{{type alias 'WeirdC' involves unsafe code; use '@unsafe' to indicate that its use is not memory-safe}}
typealias WeirdC = RequiresSendable<C> // expected-note{{@unchecked conformance of 'C' to protocol 'Sendable' involves unsafe code}}
