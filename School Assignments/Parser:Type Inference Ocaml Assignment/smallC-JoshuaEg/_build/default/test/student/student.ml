open OUnit2
open P4

open TokenTypes

open SmallCTypes
open TestUtils
open Lexer
open Parser
open Eval
open Utils


let test_sanity _ =
  print_string (string_of_list string_of_token (tokenize "int main(){

    if( 6*6 + (89-4) > (0*(56 - 3))) {
      int f;
      f = 6;
      f = f*f;
      printf(f); 
      }

}"))

  let test_sanity2 _ =
    print_string (string_of_stmt (parse_main (tokenize "int main(){

    if(6*6+(89- 4)>(0*(56+ -3))) {
      int f; int g;
      f = 6;
      f = f*f;
      g = 5;
      printf(f); 
} else {
      int g; int f;
      g = 8;
      g = g*7;
      f = 5;
      printf(g);
  
  }

  printf(g+f);


}")))

let test_sanity3 _ =

  let env = (eval_stmt [] (parse_main (tokenize "int main(){

    if(6*6+(89- 4)>(0*(56+ -3))) {
      int f; int g;
      f = 6;
      f = f*f;
      g = 5;
      printf(f); 
} else {
      int g; int f;
      g = 8;
      g = g*7;
      f = 5;
      printf(g);
  
  } printf(g+f);

}"))) in

  print_eval_env_report env


let suite =
  "student" >::: [
   (* "sanity" >:: test_sanity;*)
   "sanity2" >:: test_sanity2;
    "sanity3" >:: test_sanity3
  ]

let _ = run_test_tt_main suite
