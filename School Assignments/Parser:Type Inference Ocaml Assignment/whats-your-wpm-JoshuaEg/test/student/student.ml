open TestUtils
open P5.Ast
open P5.Sanalysis
open P5.Utils
module A = Alcotest
let ast = A.testable pp_stmt (=)

let test_student_ex1 = 
  {typed = NoOp;
   untyped = NoOp;
   should_typecheck= false;
   optimized = NoOp}

(* check if typed ast can be optimized *)
let test_student_ex2 _ = 
  let typed = NoOp in
  let expected = NoOp in                        
  Alcotest.(check ast) "" expected (optimize typed)

(* check if typed ast cannot be optimized *)
let test_student_ex3 _ = 
  let typed = NoOp in
  div_by_zero_handler typed

(* check if typed ast can be typechecked *)
let test_student_ex4 _ =
  let typed = NoOp in
  let expected = true in                        
  Alcotest.(check bool) "" expected (typecheck typed)

(* check if untyped ast cannot be typechecked *)
let test_student_ex5 _ =
  let typed = NoOp in
  type_error_handler (fun () -> typed |> typecheck |> ignore)

(* check if untyped ast can be infered *)
let test_student_ex6 _ =
  let untyped = parse_expr "int main(){}" in
  let expected = NoOp in                        
  Alcotest.(check ast) "" expected (infer untyped)

(* check if untyped ast cannot be infered *)
let test_student_ex7 _ =
  let untyped = parse_expr "int main(){}" in
  type_error_handler (fun () -> untyped |> infer |> ignore)

let _ = let open Alcotest in
  run 
  ~argv: [|
    "";
    "--compact";
  |]
  "student" [
    (* optimizer tests *)
    "optimize", [ test_case "student_opt_ex1" `Quick (run_test ~mode:Optimize test_student_ex1);
                  test_case "student_opt_ex2" `Quick test_student_ex2;
                  test_case "student_opt_ex3" `Quick test_student_ex3;
                ];
    (* typecheck tests *)
    "typecheck",[ test_case "student_tc_ex1"  `Quick (run_test ~mode:Typecheck test_student_ex1);
                  test_case "student_tc_ex4"  `Quick test_student_ex4;
                  test_case "student_tc_ex5"  `Quick test_student_ex5;
                ];
    (* inference tests *)
    "infer",    [ test_case "student_inf_ex1" `Quick (run_test ~mode:Infer test_student_ex1);
                  test_case "student_inf_ex6" `Quick test_student_ex6;
                  test_case "student_inf_ex7" `Quick test_student_ex7;
                ];
  ]
