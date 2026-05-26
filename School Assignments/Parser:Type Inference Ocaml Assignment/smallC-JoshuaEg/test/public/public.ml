open P4
open OUnit2
open SmallCTypes
open TestUtils
open Lexer
open Parser
open Eval
open Utils

(**********************************
 *     Lexer and Parse Tests      *
 **********************************)

let parse_assign1 = create_system_test ["assign1.c"]
  (Seq(Declare(Int_Type, "a"), Seq(Assign("a", Int 100), NoOp)))
let parse_assign_exp = create_system_test ["assign-exp.c"]
  (Seq(Declare(Int_Type, "a"), Seq(Assign("a", Mult(Int 100, ID "a")), Seq(Print(ID "a"), NoOp))))
let parse_define1 = create_system_test ["define1.c"]
  (Seq(Declare(Int_Type, "a"), NoOp))
let parse_equal = create_system_test ["equal.c"]
  (Seq(Declare(Int_Type, "a"), Seq(Assign("a", Int 100), Seq(If(Equal(ID "a", Int 100), Seq(Assign("a", Int 200), Seq(Print(ID "a"), NoOp)), NoOp), NoOp))))
let parse_exp1 = create_system_test ["exp1.c"]
  (Seq(Declare(Int_Type, "a"), Seq(Assign("a", Add(Int 2, Mult(Int 5, Pow(Int 4, Int 3)))), Seq(Print(ID "a"), NoOp))))
let parse_exp2 = create_system_test ["exp2.c"]
  (Seq(Declare(Int_Type, "a"), Seq(Assign("a", Add(Int 2, Pow(Mult(Int 5, Int 4), Int 3))), Seq(Print(ID "a"), NoOp))))
let parse_greater = create_system_test ["greater.c"]
  (Seq(Declare(Int_Type, "a"), Seq(Assign("a", Int 100), Seq(If(Greater(ID "a", Int 10), Seq(Assign("a", Int 200), Seq(Print(ID "a"), NoOp)), NoOp), NoOp))))
let parse_if = create_system_test ["if.c"]
  (Seq(Declare(Int_Type, "a"), Seq(Assign("a", Int 100), Seq(If(Greater(ID "a", Int 10), Seq(Assign("a", Int 200), NoOp), NoOp), NoOp))))
let parse_ifelse = create_system_test ["ifelse.c"]
  (Seq(Declare(Int_Type, "a"), Seq(Assign("a", Int 100), Seq(If(Greater(ID "a", Int 10), Seq(Assign("a", Int 200), NoOp), Seq(Assign("a", Int 300), NoOp)), NoOp))))
let parse_if_else_while = create_system_test ["if-else-while.c"]
  (Seq(Declare(Int_Type, "a"), Seq(Assign("a", Int 100), Seq(Declare(Int_Type, "b"), Seq(If(Greater(ID "a", Int 10), Seq(Assign("a", Int 200), NoOp), Seq(Assign("b", Int 10), Seq(While(Less(Mult(ID "b", Int 2), ID "a"), Seq(Assign("b", Add(ID "b", Int 2)), Seq(Print(ID "b"), NoOp))), Seq(Assign("a", Int 300), NoOp)))), NoOp)))))
let parse_less = create_system_test ["less.c"]
  (Seq(Declare(Int_Type, "a"), Seq(Assign("a", Int 100), Seq(If(Less(ID "a", Int 200), Seq(Assign("a", Int 200), Seq(Print(ID "a"), NoOp)), NoOp), NoOp))))
let parse_main = create_system_test ["main.c"]
  NoOp
let parse_nested_if = create_system_test ["nested-if.c"]
  (Seq(Declare(Int_Type, "a"), Seq(Assign("a", Int 100), Seq(If(Greater(ID "a", Int 10), Seq(Assign("a", Int 200), Seq(If(Less(ID "a", Int 20), Seq(Assign("a", Int 300), NoOp), Seq(Assign("a", Int 400), NoOp)), NoOp)), NoOp), NoOp))))
let parse_nested_ifelse = create_system_test ["nested-ifelse.c"]
  (Seq(Declare(Int_Type, "a"), Seq(Assign("a", Int 100), Seq(If(Greater(ID "a", Int 10), Seq(Assign("a", Int 200), Seq(If(Less(ID "a", Int 20), Seq(Assign("a", Int 300), NoOp), Seq(Assign("a", Int 400), NoOp)), NoOp)), Seq(Assign("a", Int 500), NoOp)), NoOp))))
let parse_nested_while = create_system_test ["nested-while.c"]
  (Seq(Declare(Int_Type, "i"), Seq(Declare(Int_Type, "j"), Seq(Assign("i", Int 1), Seq(Declare(Int_Type, "sum"), Seq(Assign("sum", Int 0), Seq(While(Less(ID "i", Int 10), Seq(Assign("j", Int 1), Seq(While(Less(ID "j", Int 10), Seq(Assign("sum", Add(ID "sum", ID "j")), Seq(Assign("j", Add(ID "j", Int 1)), NoOp))), Seq(Assign("i", Add(ID "i", Int 1)), NoOp)))), NoOp)))))))
let parse_print = create_system_test ["print.c"]
  (Seq(Declare(Int_Type, "a"), Seq(Assign("a", Int 100), Seq(Print(ID "a"), NoOp))))
let parse_test1 = create_system_test ["test1.c"]
  (Seq(Declare(Int_Type, "a"), Seq(Assign("a", Int 10), Seq(Declare(Int_Type, "b"), Seq(Assign("b", Int 1), Seq(Declare(Int_Type, "sum"), Seq(Assign("sum", Int 0), Seq(While(Less(ID "b", ID "a"), Seq(Assign("sum", Add(ID "sum", ID "b")), Seq(Assign("b", Add(ID "b", Int 1)), Seq(Print(ID "sum"), Seq(If(Greater(ID "a", ID "b"), Seq(Print(Int 10), NoOp), Seq(Print(Int 20), NoOp)), Seq(Print(ID "sum"), NoOp)))))), NoOp))))))))
let parse_test2 = create_system_test ["test2.c"]
  (Seq(Declare(Int_Type, "a"), Seq(Assign("a", Int 10), Seq(Declare(Int_Type, "b"), Seq(Assign("b", Int 20), Seq(Declare(Int_Type, "c"), Seq(If(Less(ID "a", ID "b"), Seq(If(Less(Pow(ID "a", Int 2), Pow(ID "b", Int 3)), Seq(Print(ID "a"), NoOp), Seq(Print(ID "b"), NoOp)), NoOp), Seq(Assign("c", Int 1), Seq(While(Less(ID "c", ID "a"), Seq(Print(ID "c"), Seq(Assign("c", Add(ID "c", Int 1)), NoOp))), NoOp))), NoOp)))))))
let parse_test3 = create_system_test ["test3.c"]
  (Seq(Declare(Int_Type, "a"), Seq(Assign("a", Int 10), Seq(Declare(Int_Type, "b"), Seq(Assign("b", Int 2), Seq(Declare(Int_Type, "c"), Seq(Assign("c", Add(ID "a", Mult(ID "b", Pow(Int 3, Int 3)))), Seq(Print(Equal(ID "c", Int 1)), NoOp))))))))
let parse_test4 = create_system_test ["test4.c"]
  (Seq(Declare(Int_Type, "x"), Seq(Declare(Int_Type, "y"), Seq(Declare(Int_Type, "a"), Seq(While(Equal(ID "x", ID "y"), Seq(Assign("a", Int 100), NoOp)), Seq(If(Equal(ID "a", ID "b"), Seq(Print(Int 20), NoOp), Seq(Print(Int 10), NoOp)), NoOp))))))
let parse_assoc1 = create_system_test ["test-assoc1.c"]
  (Seq(Declare(Int_Type, "a"), Seq(Assign("a", Add(Int 2, Add(Int 3, Int 4))), Seq(Declare(Int_Type, "b"), Seq(Assign("b", Mult(Int 2, Mult(Int 3, Int 4))), Seq(Declare(Int_Type, "c"), Seq(Assign("c", Pow(Int 2, Pow(Int 3, Int 4))), Seq(Declare(Int_Type, "d"), Seq(If(Greater(Int 5, Greater(Int 6, Int 1)), Seq(Print(Int 10), NoOp), NoOp), Seq(Print(ID "a"), Seq(Print(ID "b"), Seq(Print(ID "c"), NoOp))))))))))))
let parse_while = create_system_test ["while.c"]
  (Seq(Declare(Int_Type, "a"), Seq(Assign("a", Int 10), Seq(Declare(Int_Type, "b"), Seq(Assign("b", Int 1), Seq(While(Less(ID "b", ID "a"), Seq(Print(ID "b"), Seq(Assign("b", Add(ID "b", Int 2)), NoOp))), NoOp))))))
let parse_for = create_system_test ["for.c"]
  (Seq(Declare(Int_Type, "a"), Seq(For("a", Int 1, Int 10, Seq(Print(ID "a"), NoOp)), NoOp)))

(**********************************
 *        Evaluator Tests         *
 **********************************)

let env1 = [("var1", Int_Val 4); ("var2", Bool_Val false)]

let eval_expr_basic _ =
  let i = 5 in assert_equal (Int_Val i) (eval_expr [] (Int i));
  let i = (-10) in assert_equal (Int_Val i) (eval_expr [] (Int i));
  assert_equal (Bool_Val true) (eval_expr env1 (Bool true));
  assert_equal (Bool_Val false) (eval_expr env1 (Bool false));
  assert_equal (Int_Val 4) (eval_expr env1 (ID "var1"));
  assert_equal (Bool_Val false) (eval_expr env1 (ID "var2"))

let eval_expr_ops _ =
  assert_equal (Int_Val 8) (eval_expr env1 (Add ((ID "var1"), (Int 4))));
  assert_equal (Int_Val (-2)) (eval_expr env1 (Add ((ID "var1"), (Int (-6)))));
  assert_equal (Int_Val 42) (eval_expr [] (Sub (Int 50, Int 8)));
  assert_equal (Int_Val (-2)) (eval_expr env1 (Sub (ID "var1", Int 6)));
  assert_equal (Int_Val 64) (eval_expr [] (Mult (Int 8, Int 8)));
  assert_equal (Int_Val (-10)) (eval_expr [] (Mult (Int 5, Int (-2))));
  assert_equal (Int_Val 10) (eval_expr [] (Div (Int 70, Int 7)));
  assert_equal (Int_Val (50/3)) (eval_expr [] (Div (Int 50, Int 3)));
  assert_equal (Int_Val 9) (eval_expr [] (Pow (Int 3, Int 2)));

  assert_equal (Bool_Val true) (eval_expr [] (Or (Bool false, Bool true)));
  assert_equal (Bool_Val false) (eval_expr env1 (Or (Bool false, ID "var2")));
  assert_equal (Bool_Val false) (eval_expr [] (And (Bool false, Bool true)));
  assert_equal (Bool_Val true) (eval_expr [] (And (Bool true, Bool true)));
  assert_equal (Bool_Val true) (eval_expr [] (Not (Bool false)));
  assert_equal (Bool_Val false) (eval_expr [] (Not (Bool true)));

  assert_equal (Bool_Val false) (eval_expr env1 (Equal (ID "var1", Int 10)));
  assert_equal (Bool_Val true) (eval_expr env1 (Equal (ID "var2", Bool false)));
  assert_equal (Bool_Val true) (eval_expr env1 (NotEqual (ID "var1", Int 10)));
  assert_equal (Bool_Val false) (eval_expr env1 (NotEqual (ID "var2", ID "var2")));

  assert_equal (Bool_Val true) (eval_expr env1 (Greater (ID "var1", Int 2)));
  assert_equal (Bool_Val false) (eval_expr env1 (Greater (Int 2, ID "var1")));
  assert_equal (Bool_Val true) (eval_expr env1 (Less (ID "var1", Int 10)));
  assert_equal (Bool_Val false) (eval_expr env1 (Less (ID "var1", Int 2)));
  assert_equal (Bool_Val true) (eval_expr [] (GreaterEqual (Int 0, Int 0)));
  assert_equal (Bool_Val false) (eval_expr [] (GreaterEqual (Int 0, Int 1)));
  assert_equal (Bool_Val false) (eval_expr [] (LessEqual (Int 1, Int 0)))

let eval_expr_fail _ =
  assert_eval_expr_fail expr_env "1 + p";
  assert_eval_expr_fail expr_env "false * y";
  assert_eval_expr_fail expr_env "q - 1";
  assert_eval_expr_fail expr_env "y / false";
  assert_eval_expr_fail expr_env "x ^ true";
  assert_eval_expr_fail expr_env "1 || q";
  assert_eval_expr_fail expr_env "p && 0";
  assert_eval_expr_fail expr_env "!x";
  assert_eval_expr_fail expr_env "x > p";
  assert_eval_expr_fail expr_env "q < y";
  assert_eval_expr_fail expr_env "q >= x";
  assert_eval_expr_fail expr_env "x <= q";
  assert_eval_expr_fail expr_env "p == x";
  assert_eval_expr_fail expr_env "p != x";
  assert_eval_expr_fail expr_env "x + (y + true)";
  assert_eval_expr_fail expr_env "(x * false) * y";
  assert_eval_expr_fail expr_env "x - (false - 1)";
  assert_eval_expr_fail expr_env "y / (true / x)";
  assert_eval_expr_fail expr_env "x ^ (false ^ y)";
  assert_eval_expr_fail expr_env "(q || 1) || p";
  assert_eval_expr_fail expr_env "q && (1 && q)";
  assert_eval_expr_fail expr_env "!p && !1";
  assert_eval_expr_fail expr_env "p == (y > false)";
  assert_eval_expr_fail expr_env "q && (true < y)";
  assert_eval_expr_fail expr_env "(y >= true) || q";
  assert_eval_expr_fail expr_env "(x <= true) != q";
  assert_eval_expr_fail expr_env "(x == false) == q";
  assert_eval_expr_fail expr_env "(y == true) == p"

(* Simple sequence *)
let eval_stmt_basic _ =
  let env = [("a", Bool_Val true); ("b", Int_Val 7)] in
  assert_stmt_success env env "int main(){}";
  assert_stmt_success [] [("a", Int_Val 0); ("b", Int_Val 0); ("x", Bool_Val false); ("y", Bool_Val false)] "int main() {int a;int b;bool x; bool y;}";
  assert_stmt_success [] [("a", Int_Val 0)] "int main() {int a; printf(a);}"
    ~output:"0\n";
  assert_stmt_success [] [("a", Bool_Val false)] "int main() {bool a; printf(a);}"
    ~output:"false\n"

(* Simple if true and if false *)
let eval_stmt_control _ =
  assert_stmt_success [("a", Bool_Val true)] [("a", Bool_Val true); ("b", Int_Val 5)] "int main() {int b;if(a) { b=5;} else { b=10;}}";
  assert_stmt_success [("a", Bool_Val false)] [("a", Bool_Val false); ("b", Int_Val 10)] "int main() {int b;if(a) { b=5;} else { b=10;}}"

(* Simple define int/ bool - test defaults *)
let eval_define_1 = create_eval_system_test [] [("a", Int_Val 0)] ["define1.c"]
let eval_define_2 = create_eval_system_test [] [("a", Bool_Val false)] ["define2.c"]

(* Simple assign int/bool/exp*)
let eval_assign_1 = create_eval_system_test [] [("a", Int_Val 100)] ["assign1.c"]
let eval_assign_2 = create_eval_system_test [] [("a", Bool_Val true)] ["assign2.c"]
let eval_assign_exp = create_eval_system_test [] [("a", Int_Val 0)] ["assign-exp.c"]
    ~output:"0\n"

(* equal & not equal & less *)
let eval_notequal = create_eval_system_test [] [("a", Int_Val 100)] ["notequal.c"]
    ~output:"100\n"
let eval_equal = create_eval_system_test [] [("a", Int_Val 200)] ["equal.c"]
    ~output:"200\n"
let eval_less = create_eval_system_test [] [("a", Int_Val 200)] ["less-eval.c"]
    ~output:"200\n"

(* Some expressions *)
let eval_exp_1 = create_eval_system_test [] [("a", Int_Val 322)] ["exp1.c"]
    ~output:"322\n"
let eval_exp_2 = create_eval_system_test [] [("a", Int_Val 8002)] ["exp2.c"]
    ~output:"8002\n"
let eval_exp_3 = create_eval_system_test [] [("a", Int_Val (-1))] ["exp3.c"]
    ~output:"-1\n"

(* If/ Else/ While *)
let eval_ifelse = create_eval_system_test [] [("a", Int_Val 200)] ["ifelse.c"]
let eval_if_else_while = create_eval_system_test [] [("b", Int_Val 0);("a", Int_Val 200)] ["if-else-while.c"]
let eval_while = create_eval_system_test [] [("a", Int_Val 10); ("b", Int_Val 11)] ["while.c"]
                   ~output:"1\n3\n5\n7\n9\n"
let eval_for = create_eval_system_test [] [("a", Int_Val 51); ("b", Int_Val 41)] ["for-eval.c"]
let eval_nested_ifelse = create_eval_system_test [] [("a", Int_Val 400)] ["nested-ifelse.c"]
let eval_nested_while = create_eval_system_test [] [("sum", Int_Val 405);("j", Int_Val 10); ("i", Int_Val 10)] ["nested-while.c"]

(* NoOp *)
let eval_main = create_eval_system_test [] [] ["main.c"]

(* More Comprehensive *)
let eval_test_1 = 
  create_eval_system_test [] [("a", Int_Val 10);("sum", Int_Val 45); ("b", Int_Val 10)] ["test1.c"]
    ~output:"1\n10\n1\n3\n10\n3\n6\n10\n6\n10\n10\n10\n15\n10\n15\n21\n10\n21\n28\n10\n28\n36\n10\n36\n45\n20\n45\n"
let eval_test_2 = 
  create_eval_system_test [] [("a", Int_Val 10);("c", Int_Val 0); ("b", Int_Val 20)] ["test2.c"]
    ~output:"10\n"
let eval_test_3 = 
  create_eval_system_test [] [("a", Int_Val 10);("c", Int_Val 64); ("b", Int_Val 2)] ["test3-eval.c"]
    ~output:"64\nfalse\n"

let eval_stmt_fail_basic _ =
  assert_eval_stmt_fail stmt_env "printf((x + y) > false);" ~expect:DeclareExpect;
  assert_eval_stmt_fail stmt_env "printf(!(p || q));" ~expect:DeclareExpect;
  assert_eval_stmt_fail stmt_env "int y; int x;" ~expect:DeclareExpect;
  assert_eval_stmt_fail stmt_env "bool q; bool p;" ~expect:DeclareExpect;
  assert_eval_stmt_fail stmt_env "int y; bool x;" ~expect:DeclareExpect;
  assert_eval_stmt_fail stmt_env "bool q; int p;" ~expect:DeclareExpect;
  assert_eval_stmt_fail stmt_env "x = false;";
  assert_eval_stmt_fail expr_env "x = y + (p && q);";
  assert_eval_stmt_fail stmt_env "y = 1;" ~expect:DeclareExpect;
  assert_eval_stmt_fail expr_env "x = (y + x) > z;" ~expect:DeclareExpect;
  assert_eval_stmt_fail stmt_env "p = 1;";
  assert_eval_stmt_fail expr_env "q = p || (x && q);";
  assert_eval_stmt_fail stmt_env "q = false;" ~expect:DeclareExpect;
  assert_eval_stmt_fail expr_env "q = q || !(p && r);" ~expect:DeclareExpect

let eval_stmt_fail_control _ =
  assert_eval_stmt_fail stmt_env "if (0) {x = 0;} else {x = 1;}";
  assert_eval_stmt_fail stmt_env "if (p || q) {x = 0;} else {x = 1;}" ~expect:DeclareExpect;
  assert_eval_stmt_fail expr_env "if (x / (y * 2)) {x = 0;} else {x = 1;}";
  assert_eval_stmt_fail stmt_env "if (true) {printf(!p); p = !(p && q);} else {x = x - x;}" ~expect:DeclareExpect;
  assert_eval_stmt_fail expr_env "if (false) {x = y * y;} else {printf(x * (p && x)); x = 1;}";
  assert_eval_stmt_fail stmt_env "if (false) {p = !p;} else {x = (x * x) / y; printf(x);}" ~expect:DeclareExpect;
  assert_eval_stmt_fail stmt_env "while (0) {x = x + 1;}";
  assert_eval_stmt_fail stmt_env "while ((p || q) !=  false) {x = x + 1;}" ~expect:DeclareExpect;
  assert_eval_stmt_fail expr_env "while (x - (x + y)) {x = x + 1; printf(x * x);}";
  assert_eval_stmt_fail expr_env "while (true) {p = p && q; printf(x + (p < q));}"

(* val eval_expr : Types.eval_environment -> Types.expr -> Types.value_type *)
let public =
  "public" >::: [
    "public_parse_assign1"          >:: parse_assign1;
    "public_parse_assign_exp"       >:: parse_assign_exp;
    "public_parse_define1"          >:: parse_define1;
    "public_parse_equal"            >:: parse_equal;
    "public_parse_exp1"             >:: parse_exp1;
    "public_parse_exp2"             >:: parse_exp2;
    "public_parse_greater"          >:: parse_greater;
    "public_parse_if"               >:: parse_if;
    "public_parse_ifelse"           >:: parse_ifelse;
    "public_parse_if_else_while"    >:: parse_if_else_while;
    "public_parse_less"             >:: parse_less;
    "public_parse_main"             >:: parse_main;
    "public_parse_nested_if"        >:: parse_nested_if;
    "public_parse_nested_ifelse"    >:: parse_nested_ifelse;
    "public_parse_nested_while"     >:: parse_nested_while;
    "public_parse_print"            >:: parse_print;
    "public_parse_test1"            >:: parse_test1;
    "public_parse_test2"            >:: parse_test2;
    "public_parse_test3"            >:: parse_test3;
    "public_parse_test4"            >:: parse_test4;
    "public_parse_assoc1"           >:: parse_assoc1;
    "public_parse_while"            >:: parse_while;
    "public_parse_for"              >:: parse_for;
    "public_eval_expr_basic"        >:: eval_expr_basic;
    "public_eval_expr_ops"          >:: eval_expr_ops;
    "public_eval_expr_fail"         >:: eval_expr_fail;
    "public_eval_stmt_basic"        >:: eval_stmt_basic;
    "public_eval_stmt_control"      >:: eval_stmt_control;
    "public_eval_define_1"          >:: eval_define_1;
    "public_eval_define_2"          >:: eval_define_2;
    "public_eval_assign_1"          >:: eval_assign_1;
    "public_eval_assign_2"          >:: eval_assign_2;
    "public_eval_assign_exp"        >:: eval_assign_exp;
    "public_eval_notequal"          >:: eval_notequal;
    "public_eval_equal"             >:: eval_equal;
    "public_eval_less"              >:: eval_less;
    "public_eval_exp_1"             >:: eval_exp_1;
    "public_eval_exp_2"             >:: eval_exp_2;
    "public_eval_exp_3"             >:: eval_exp_3;
    "public_eval_ifelse"            >:: eval_ifelse;
    "public_eval_if_else_while"     >:: eval_if_else_while;
    "public_eval_while"             >:: eval_while;
    "public_eval_for"               >:: eval_for;
    "public_eval_nested_ifelse"     >:: eval_nested_ifelse;
    "public_eval_nested_while"      >:: eval_nested_while;
    "public_eval_main"              >:: eval_main;
    "public_eval_test_1"            >:: eval_test_1;
    "public_eval_test_2"            >:: eval_test_2;
    "public_eval_test_3"            >:: eval_test_3;
    "public_eval_stmt_fail_basic"   >:: eval_stmt_fail_basic;
    "public_eval_stmt_fail_control" >:: eval_stmt_fail_control
  ]

let _ = run_test_tt_main public