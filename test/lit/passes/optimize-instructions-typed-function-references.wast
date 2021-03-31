;; NOTE: Assertions have been generated by update_lit_checks.py and should not be edited.
;; RUN: wasm-opt %s --optimize-instructions --enable-reference-types \
;; RUN:   --enable-typed-function-references -S -o - | filecheck %s

(module
  (type $i32-i32 (func (param i32) (result i32)))
  ;; this function has a reference parameter. we analyze parameters, and should
  ;; not be confused by a type that has no bit size, in particular. this test
  ;; just verifies that we do not crash on that.
  ;; CHECK:      (func $call_from-param (param $f (ref null $i32-i32)) (result i32)
  ;; CHECK-NEXT:  (unreachable)
  ;; CHECK-NEXT: )
  (func $call_from-param (param $f (ref null $i32-i32)) (result i32)
    (unreachable)
  )
)
