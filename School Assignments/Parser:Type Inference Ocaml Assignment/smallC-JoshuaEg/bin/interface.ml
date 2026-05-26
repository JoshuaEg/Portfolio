open P4.Utils
open P4.Lexer
open P4.Parser
open P4.Eval
open P4.SmallCTypes

type run_context = {filename : string option; print_report : bool; unparse : bool };;

let print_usage () =
  print_string "\nThis file functions as a driver for interfacing with the SmallC lexer and parser.\n\n";
  print_string "Usage:\n";
  print_string "\tdune exec bin/interface.bc <mode> <filename>: Run your parser and lexer on standard input, or a file if one is provided.\n";
  print_string "Modes:\n";
  print_string "\tlex: Run in lex mode to show the tokens output by your lexer\n";
  print_string "\tparse: Parse a full program, including the function header, using parse_main\n";
  print_string "\teval: Evaluate the program\n\n";
  print_string "\t\teval Flags:\n";
  print_string "\t\t--unparse / -U : Add one of these flags to print the stmt datatype representing the program in <filename> instead of evaluating it\n";
  print_string "\t\t--report / -R : Add one of these flags to add a listing of variable bindings created by your program. Great for debugging!\n\n";
;;


let parse_from_string (input : string) : stmt =
  (* Parse the tokens *)
  input |> tokenize |> parse_main;;

let parse_expr_from_string es =
    let (_, e) = parse_expr (tokenize es) in e;;
  
let parse_stmt_from_string s =
    let (_, s) = parse_stmt (tokenize s) in s;;

(* Open file, read, lex, parse *)
let parse_from_file (input_filename : string) : stmt =
  (* Pass string off *)
  parse_from_string (read_from_file input_filename);;

if Array.length Sys.argv < 2 then begin print_usage (); exit 1 end;;


(* Process command line arguments to set up run context *)
let do_eval args = 
  let ctxt = List.fold_left (fun {filename = f; print_report = r; unparse = u} -> function
      | "--unparse" | "-U" -> {filename = f; print_report = r; unparse = true}
      | "--report" | "-R" -> {filename = f; print_report = true; unparse = u}
      | x -> {filename = Some(x); print_report = r; unparse = u})
      {filename = None; print_report = false; unparse = false} args in
  match ctxt.filename with
  | None -> print_usage ()
  | Some(filename) ->
    let ast = parse_from_file filename in
    if ctxt.unparse then begin
      print_string @@ unparse_stmt ast;
    end else
      let final_env = eval_stmt [] ast in
      if ctxt.print_report then begin print_eval_env_report final_env; print_newline () end
  ;;

(* Make sure there are args given *)
let args = match Array.to_list Sys.argv with
  | _::"lex"::_ -> let ch = if Array.length Sys.argv > 2 then open_in Sys.argv.(2) else stdin in
                  let toks = tokenize_from_channel ch in
                    print_string @@ string_of_list ~newline:true string_of_token toks;
                  if ch != stdin then close_in ch
  | _::"parse"::_ -> let ch = if Array.length Sys.argv > 2 then open_in Sys.argv.(2) else stdin in
                    let toks = tokenize_from_channel ch in
                    (print_string @@ string_of_stmt @@ P4.Parser.parse_main toks;
                    print_newline ());
                  if ch != stdin then close_in ch
  | _::"eval"::t -> do_eval t
  | _ -> print_usage ()
;;
(* This is intentionally physical equality *)
