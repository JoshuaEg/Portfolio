open P5
open Ast
open Sanalysis
open OUnit2

type run_test_mode = Optimize | Typecheck | Infer

(* Assertion wrappers for convenience and readability *)
let assert_true b = assert_equal true b
let assert_false b = assert_equal false b
let assert_succeed () = assert_true true

(* check for exceptions *)
let div_by_zero_handler ast =
  try
    let _ = (ast |> optimize)  in assert_failure "Expected DivByZeroError, Did not error"
  with
  | DivByZeroError -> assert_succeed ()
  | ex -> assert_failure ("Got " ^ (Printexc.to_string ex) ^ ", expected DivByZeroError")

let type_error_handler f=
  try
    let _ = f ()  in assert_failure "Expected TypeError, Did not get error"
  with
  | TypeError(_) -> assert_succeed ()
  | ex -> assert_failure ("Got " ^ (Printexc.to_string ex) ^ ", expected TypeError")

let declare_error_handler f=
  try
    let _ = f ()  in assert_failure "Expected DeclareError, Did not get error"
  with
  | DeclareError(_) -> assert_succeed ()
  | ex -> assert_failure ("Got " ^ (Printexc.to_string ex) ^ ", expected DeclareError")

type test_input = {typed:stmt;optimized:stmt;should_typecheck:bool;untyped:stmt}

let run_test ~mode {typed=typed; optimized=our_optimize; should_typecheck=our_type; untyped=untyped} _ =
  match mode with
  | Optimize ->
      if our_optimize <> NoOp then
        let student = typed |> optimize in
        assert_equal student our_optimize
          ~msg:
            ("Optimize error:\nexpected: " ^ show_stmt our_optimize
           ^ "\nstudent:  " ^ show_stmt student)
      else
        div_by_zero_handler typed
  | Typecheck ->
      if our_type then
      let student = typed |> typecheck in
        assert_equal student our_type 
        ~msg:("Type error:\nexpected: " 
          ^ if our_type then "true got error" else "error got true")
      else
        type_error_handler (fun () -> typed |> typecheck)
  | Infer ->
      if our_type then
      let student = untyped |> infer in
        assert_equal student typed
        ~msg:("Type error:\nexpected: " 
          ^ if our_type then "true got error" else "error got true")
      else
        type_error_handler (fun () -> untyped |> infer)
