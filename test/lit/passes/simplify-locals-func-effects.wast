;; NOTE: Assertions have been generated by update_lit_checks.py and should not be edited.
;; RUN: wasm-opt %s --generate-func-effects --simplify-locals --enable-tail-call -S -o - | filecheck %s

(module
  (memory 1 1)

  ;; CHECK:      (import "env" "import" (func $import))
  (import "env" "import" (func $import))

  ;; CHECK:      (global $glob (mut i32) (i32.const 0))
  (global $glob (mut i32) (i32.const 0))

  ;; CHECK:      (func $set-glob
  ;; CHECK-NEXT:  (global.set $glob
  ;; CHECK-NEXT:   (i32.const 1)
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT: )
  (func $set-glob
    ;; Set the global. This is a helper for the subsequent function.
    (global.set $glob
      (i32.const 1)
    )
  )

  ;; CHECK:      (func $call-set-glob (result i32)
  ;; CHECK-NEXT:  (local $x i32)
  ;; CHECK-NEXT:  (local.set $x
  ;; CHECK-NEXT:   (global.get $glob)
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT:  (call $set-glob)
  ;; CHECK-NEXT:  (local.get $x)
  ;; CHECK-NEXT: )
  (func $call-set-glob (result i32)
    (local $x i32)
    (local.set $x
      (global.get $glob)
    )
    (call $set-glob) ;; this sets the global, so we cannot optimize over it
    (local.get $x)
  )

  ;; CHECK:      (func $no-glob
  ;; CHECK-NEXT:  (local $x i32)
  ;; CHECK-NEXT:  (loop $loop
  ;; CHECK-NEXT:   (br_if $loop
  ;; CHECK-NEXT:    (global.get $glob)
  ;; CHECK-NEXT:   )
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT:  (if
  ;; CHECK-NEXT:   (global.get $glob)
  ;; CHECK-NEXT:   (return)
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT:  (nop)
  ;; CHECK-NEXT:  (i32.store
  ;; CHECK-NEXT:   (local.tee $x
  ;; CHECK-NEXT:    (i32.const 42)
  ;; CHECK-NEXT:   )
  ;; CHECK-NEXT:   (local.get $x)
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT: )
  (func $no-glob
    (local $x i32)
    ;; This function has lots of nice side effects, but setting that global is
    ;; not one of them.
    (loop $loop
      (br_if $loop
        (global.get $glob)
      )
    )
    (if
      (global.get $glob)
      (return)
    )
    ;; this is the same local (index and name) as the one that the caller wants
    ;; to optimize, so it tests that we are not confused by local effects in one
    ;; function affecting another.
    (local.set $x
      (i32.const 42)
    )
    ;; Add some gets so that we do not optimize out the local.set entirely.
    (i32.store
      (local.get $x)
      (local.get $x)
    )
  )

  ;; CHECK:      (func $call-no-glob (result i32)
  ;; CHECK-NEXT:  (local $x i32)
  ;; CHECK-NEXT:  (nop)
  ;; CHECK-NEXT:  (call $no-glob)
  ;; CHECK-NEXT:  (global.get $glob)
  ;; CHECK-NEXT: )
  (func $call-no-glob (result i32)
    (local $x i32)
    (local.set $x
      (global.get $glob)
    )
    (call $no-glob) ;; this is ok to optimize over
    (local.get $x)
  )

  ;; CHECK:      (func $call-no-glob-return
  ;; CHECK-NEXT:  (local $x i32)
  ;; CHECK-NEXT:  (local.set $x
  ;; CHECK-NEXT:   (global.get $glob)
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT:  (return_call $no-glob)
  ;; CHECK-NEXT:  (drop
  ;; CHECK-NEXT:   (local.get $x)
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT: )
  (func $call-no-glob-return
    (local $x i32)
    (local.set $x
      (global.get $glob)
    )
    (return_call $no-glob) ;; the called contents are ok to optimize over, but
                           ;; this is a return_call, so it has the effect of
                           ;; branching, which stops us.
    (drop
      (local.get $x)
    )
  )

  ;; CHECK:      (func $call-import (result i32)
  ;; CHECK-NEXT:  (local $x i32)
  ;; CHECK-NEXT:  (local.set $x
  ;; CHECK-NEXT:   (global.get $glob)
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT:  (call $import)
  ;; CHECK-NEXT:  (local.get $x)
  ;; CHECK-NEXT: )
  (func $call-import (result i32)
    (local $x i32)
    (local.set $x
      (global.get $glob)
    )
    (call $import) ;; imports have arbitrary effects, so we cannot optimize here
                   ;; (but in theory as the global is not exported or imported,
                   ;; perhaps we could in the future)
    (local.get $x)
  )

  ;; CHECK:      (func $call-call-set-glob (result i32)
  ;; CHECK-NEXT:  (local $x i32)
  ;; CHECK-NEXT:  (local.set $x
  ;; CHECK-NEXT:   (global.get $glob)
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT:  (drop
  ;; CHECK-NEXT:   (call $call-set-glob)
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT:  (local.get $x)
  ;; CHECK-NEXT: )
  (func $call-call-set-glob (result i32)
    (local $x i32)
    (local.set $x
      (global.get $glob)
    )
    (drop
      (call $call-set-glob) ;; call a function that calls a function that sets
                            ;; the global. we should see that such a nested call
                            ;; prevents optimization.
    )
    (local.get $x)
  )

  ;; CHECK:      (func $call-call-no-glob (result i32)
  ;; CHECK-NEXT:  (local $x i32)
  ;; CHECK-NEXT:  (nop)
  ;; CHECK-NEXT:  (drop
  ;; CHECK-NEXT:   (call $call-no-glob)
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT:  (global.get $glob)
  ;; CHECK-NEXT: )
  (func $call-call-no-glob (result i32)
    (local $x i32)
    (local.set $x
      (global.get $glob)
    )
    (drop
      (call $call-no-glob) ;; call a function that calls a function that has no
                           ;; effect on the global. we can optimize this because
                           ;; we propagate the effects of direct calls through
                           ;; multiple calls.
    )
    (local.get $x)
  )
)
