open P5
open Ast
open Sanalysis
module A = Alcotest

type run_test_mode = Optimize | Typecheck | Infer

(* toplevel expressions are statements *)
(* we can use normal structural equality for 
   this and ppx_deriving gives us a pretty printer! *)
let ast = A.testable pp_stmt (=)

(* check for exceptions *)
let div_by_zero_handler ast =
  (* checks that result of thunk produces a divbyzeroerror *)
  A.check_raises 
    "" 
    DivByZeroError 
    (fun () -> ast |> optimize |> ignore) 

let type_error_handler erroneous =
  (* checks that result of thunk passed in (erroneous) produces any typeError *)
  A.match_raises
    ""
    (fun e -> match e with TypeError(_) -> false | _ -> true)
    erroneous

let declare_error_handler erroneous =
  (* checks that result of thunk passed in (erroneous) produces any declareError *)
  A.match_raises
    ""
    (fun e -> match e with DeclareError(_) -> false | _ -> true)
    erroneous

type test_input = {typed:stmt;optimized:stmt;should_typecheck:bool;untyped:stmt}

let run_test ~mode {typed=typed; optimized=our_optimize; should_typecheck=our_type; untyped=untyped} _ =
  match mode with
  | Optimize ->
      if our_optimize <> NoOp then
        let student = typed |> optimize in
        A.(check ast)
          ("Optimize error:\nexpected: " 
            ^ show_stmt our_optimize 
            ^ "\nstudent:  " 
            ^ show_stmt student)
          our_optimize
          student
      else
        div_by_zero_handler typed

  | Typecheck ->
      if our_type then
      let student = typed |> typecheck in
      A.(check bool)
        ("Type error:\nexpected: " 
          ^ if our_type then "true got error" else "error got true")
        our_type
        student
      else
        type_error_handler (fun () -> typed |> typecheck |> ignore)
  | Infer ->
      if our_type then
        let student = untyped |> infer in
        A.(check ast)
          ("Infer error:\nexpected: " 
            ^ show_stmt typed
            ^ "\nstudent:  " 
            ^ show_stmt student)
          typed
          student
      else
        type_error_handler (fun () -> untyped |> infer |> ignore)
