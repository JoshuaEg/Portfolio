open OUnit2
open P4
open Utils
open Lexer
open Parser
open Eval
open SmallCTypes
open TokenTypes

(* Assertion wrappers for convenience and readability *)
let assert_true b = assert_equal true b
let assert_false b = assert_equal false b
let assert_succeed () = assert_true true

(* Parse utils *)

let input_handler f =
  try
    let _ = f () in assert_failure "Expected InvalidInputException, none received" with
  | InvalidInputException(_) -> assert_succeed ()
  | ex -> assert_failure ("Got " ^ (Printexc.to_string ex) ^ ", expected InvalidInputException")

let assert_stmt_fail (s : string) =
  input_handler (fun _ ->
    let toks = tokenize s in
    parse_main toks)

let assert_expr_fail s =
  assert_stmt_fail ("int main() { printf(" ^ s ^ "); }")

let assert_ast_equal
    (es : string)
    (output : stmt) : unit =
  let toks = tokenize_from_file es in
  let ast = parse_main toks in
  assert_equal ast output

let build_data_filename p =
    let rec aux = function
        | [] -> ""
        | h :: [] -> h
        | h :: p -> h ^ Filename.dir_sep ^ (aux p) in
    (Filename.dirname Sys.argv.(0)) ^ Filename.dir_sep ^ "data" ^ Filename.dir_sep ^ aux p

let create_system_test
    (es : string list)
    (output : stmt) : (test_ctxt -> unit) =
  (fun _ -> assert_ast_equal (build_data_filename es) output)

(* Parse tools *)

let parse_from_string (input : string) : stmt =
  (* Parse the tokens *)
  input |> tokenize |> parse_main

let parse_expr_from_string es =
    let (_, e) = parse_expr (tokenize es) in e
  
let parse_stmt_from_string s =
    let (_, s) = parse_stmt (tokenize s) in s

(* Open file, read, lex, parse *)
let parse_from_file (input_filename : string) : stmt =
  (* Pass string off *)
  parse_from_string (read_from_file input_filename)

(* Eval Utils *)

(* Constants pertaining to error case tests *)
let stmt_env : environment = [("x", Int_Val(1)); ("p", Bool_Val(false))]
let expr_env : environment = stmt_env @ [("y", Int_Val(6)); ("q", Bool_Val(true))]

let equiv_environments (xs : environment) (ys : environment) : bool =
  (prune_env xs) = (prune_env ys)

let assert_stmt_success'
    ?output:(output="")
    (env : environment)
    (finEnv : environment)
    (ast : stmt) : unit =
  flush_print_buffer ();
  assert_true (equiv_environments (eval_stmt env ast) finEnv);
  assert_buffer_equal output

let assert_stmt_success
    ?output:(output="")
    (env : environment)
    (finEnv : environment)
    (s : string) : unit =
  let toks = tokenize s in
  let ast = parse_main toks in
  assert_stmt_success' ~output:output env finEnv ast

let create_eval_system_test
    ?output:(output="")
    (env : environment)
    (finEnv : environment)
    (es : string list) : (test_ctxt -> unit) =
  (fun ctx ->
    let toks = tokenize_from_file (in_testdata_dir ctx es) in
    let ast = parse_main toks in
    assert_stmt_success' env finEnv ast  ~output:output)

let type_handler f =
  try
    let _ = f () in assert_failure "Expected TypeError, none received" with
  | TypeError(_) -> assert_succeed ()
  | ex -> assert_failure ("Got " ^ (Printexc.to_string ex) ^ ", expected TypeError")

let declaration_handler f =
  try
    let _ = f () in assert_failure "Expected DeclareError, none received" with
  | DeclareError(_) -> assert_succeed ()
  | ex -> assert_failure ("Got " ^ (Printexc.to_string ex) ^ ", expected DeclareError")

let div_by_zero_handler f =
  try
    let _ = f () in assert_failure "Expected DivByZeroError, none received" with
  | DivByZeroError -> assert_succeed ()
  | ex -> assert_failure ("Got " ^ (Printexc.to_string ex) ^ ", expected DivByZeroError")

type expected_exception = TypeExpect | DeclareExpect | DivByZeroExpect

let assert_eval_fail env ast expect parse_fun eval_fun =
  let e = parse_fun ast in
  let expect_function = begin match expect with
    | TypeExpect -> type_handler
    | DeclareExpect -> declaration_handler
    | DivByZeroExpect -> div_by_zero_handler
  end in
  expect_function (fun () -> eval_fun env e)

let assert_eval_expr_fail ?expect:(expect=TypeExpect) env es =
  assert_eval_fail env es expect parse_expr_from_string eval_expr

let assert_eval_stmt_fail ?expect:(expect=TypeExpect) env smt =
  assert_eval_fail env smt expect parse_stmt_from_string eval_stmt