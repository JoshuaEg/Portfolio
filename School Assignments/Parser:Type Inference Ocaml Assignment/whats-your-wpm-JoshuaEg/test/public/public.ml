open TestUtils
open P5.Ast
open P5.Sanalysis
open P5.Utils
module A = Alcotest
let ast = A.testable pp_stmt (=)

let test_identities _ = 
  (* int main(){
        y = 0 * read()
    } *)
  let input1 = Assign("x",Int_Type,Binop(Mult,Int(0),Value)) in
  let expected1 = Assign("x",Int_Type,Int(0))
  in
  (* int main(){
        x = read() && false
    } *)
  let input2 = Assign("x",Bool_Type,Binop(And,Value,Bool(false))) in
  let expected2 = Assign("x",Bool_Type,Bool(false))
  in
  (* int main(){
        x = read() || true
    } *)
  let input3 = Assign("x",Bool_Type,Binop(Or,Value,Bool(true))) in
  let expected3 = Assign("x",Bool_Type,Bool(true))
  in
  (* int main(){
        x = !!read();
        y = !!!read();
    } *)
  let input4 = Seq(Assign("x",Bool_Type,Not(Not(Value))),Assign("y",Bool_Type,Not(Not(Not(Value))))) in
  let expected4 = Seq(Assign("x",Bool_Type,Value),Assign("y",Bool_Type,Not(Value)))
  in
  (* int main(){
        x = read() != read(); //sanity check
    } *)
  let input5 = Assign("x",Bool_Type,Binop(NotEqual,Value,Value)) in
  let expected5 = input5
  in
  let test_list = [input1,expected1;input2,expected2;input3,expected3;input4,expected4;input5,expected5] in
  List.fold_left (fun _ (i,e) -> Alcotest.(check ast) "" e (optimize i)) () test_list

let test_basic_read _ = 
  (* int main(){
    x = read();
  } *)
  let input1 = Assign("x",Unknown_Type(0),Value) in
  let expected1 = input1 
  in
  (* int main(){
        x = read() + read()
    } *)
  let input2 = Assign("x",Int_Type,Binop(Add,Value,Value)) in
  let expected2 = input2 
  in
  (* int main(){
        x = read() && read()
    } *)
  let input3 = Assign("x",Bool_Type,Binop(And,Value,Value)) in
  let expected3 = input3 
  in
  (* int main(){
        x = read() + read() + read()
    } *)
  let input4 = Assign("x",Int_Type,Binop(And,Value,Binop(And,Value,Value))) in
  let expected4 = input4 
  in
  (* int main(){
        x = read() * read() + read()
    } *)
  let input5 = Assign("x",Int_Type,Binop(Mult,Binop(And,Value,Value),Value)) in
  let expected5 = input5 
  in 
  let test_list = [(input1,expected1);(input2,expected2);(input3,expected3);input4,expected4;input5,expected5] in
  List.fold_left (fun _ (i,e) -> Alcotest.(check ast) "" e (optimize i)) () test_list

let test_pure_constants _ = 
  (* int main(){
        w = 1 + 2 * 9;
        x = true && false;
        y = true != false;
        z = !(15 <= 20-3) && (5 ^ 7 >=  1 + 2) && ((10/2 > 7 || 4 * 7 < 100) == (true != false));
    } *)
  let input1 = 
     (Seq(Assign ("w", Int_Type,
                      Binop (Add, Int 1, 
                                  Binop (Mult, Int 2, 
                                               Int 9))),
      Seq (Assign ("x", Bool_Type, Binop (And, Bool true, Bool false)),
      Seq (Assign ("y", Bool_Type, Binop (NotEqual, Bool true, Bool false)),
           Assign ("z", Bool_Type,
                        Not(Binop (And, 
                                   Binop (LessEqual, 
                                          Int 15, 
                                          Binop (Sub, 
                                                 Int 20, 
                                                 Int 3)),
                                   Binop (And, 
                                          Binop (GreaterEqual, 
                                                 Binop (Pow, 
                                                        Int 5, 
                                                        Int 7),
                                                 Binop (Add, 
                                                        Int 1, 
                                                        Int 2)),
                                          Binop (Equal, 
                                                 Binop (Or, 
                                                        Binop (Greater, 
                                                               Binop (Div, 
                                                                      Int 10, 
                                                                      Int 2), 
                                                               Int 7),
                                                        Binop (Less, 
                                                               Binop (Mult, 
                                                                      Int 4, 
                                                                      Int 7), 
                                                               Int 100)),
                                                 Binop (NotEqual, 
                                                        Bool true, 
                                                        Bool false)))))))))) in
  let expected1 = Seq(Assign("w",Int_Type,Int 19),
                  Seq(Assign("x",Bool_Type,Bool(false)),
                  Seq(Assign("y",Bool_Type,Bool(true)),
                      Assign("z",Bool_Type,Bool(false)))))
  in 
  (* int main(){
      x = 1;
      y = x + 3;
    } *)
  let input2 = Seq(Assign("x",Int_Type,Int(1)),Assign("y",Int_Type,Binop(Add,ID("x"),Int(3)))) in
  let expected2 = Seq(Assign("x",Int_Type,Int(1)),Assign("y",Int_Type,Int(4)))
  in 
  (* int main(){
        x = 5;
        y = true;
        if(y){
          a = x + 1;
        }else{
          b = x * 9;
        }
        printf(x);
    } *)
  let input3 = Seq(Assign("x",Int_Type,Int(5)),Seq(Assign("y",Bool_Type,Bool(true)),Seq(If(ID("y"),Assign("a",Int_Type,Binop(Add,ID("x"),Int(1))),Assign("b",Int_Type,Binop(Mult,ID("x"),Int(9)))),Print(ID("x"))))) in
  let expected3 = Seq(Assign("x",Int_Type,Int(5)),Seq(Assign("y",Bool_Type,Bool(true)),Seq(Assign("a",Int_Type,Int(6)),Print(Int(5)))))
  in 
  (* int main(){
        x = false;
        while(x){
          print(x);
        }
        Print(x);
    } *)
  let input4 = Seq(Assign("x",Bool_Type,Bool(false)),Seq(While(ID("x"),Print(ID("x"))),Print(ID("x")))) in
  let expected4 = Seq(Assign("x",Bool_Type,Bool(false)),Seq(NoOp,Print(Bool(false))))
  in 
  (* int main(){

    } *)
  let input5 = NoOp in
  let expected5 = input5
  in 
  let test_list = [(input1,expected1);(input2,expected2);(input3,expected3);input4,expected4;input5,expected5] in
  List.fold_left (fun _ (i,e) -> Alcotest.(check ast) "" e (optimize i)) () test_list

let test_optimize_branches1 _ = 
  (* int main(){
       while(false){
        print(true);
       }
     } *)
  let input1 = While(Bool(false),Print(Bool(true))) in
  let expected1 = NoOp
  in
  (* int main(){
       x = true;
       if (!x) {
         x = false;
       }
     }*)
  let input2 = Seq(Assign("x",Bool_Type,Bool(true)),If(Not(ID("x")),Assign("x",Bool_Type,Bool(false)),NoOp)) in
  let expected2 =Seq(Assign("x",Bool_Type,Bool(true)),NoOp)
  in
  (* int main(){ 
       for (x from 10 to 6){ // p4 semantics says to still assign x to 10
          printf(true);
       }
     } *)
  let input3 = For("x",Int(10),Int(6),Print(Bool(true))) in
  let expected3 = Assign("x",Int_Type,Int(10))
  in
  (* int main(){
       x = read();
       if (x){
         print(x);
       }else{
         print(x);
       }
     }*)
  let input4 = Seq(Assign("x",Unknown_Type(0),Value),If(ID("x"),Print(ID("x")),Print(ID("x")))) in
  let expected4 = Seq(Assign("x",Unknown_Type(0),Value),Print(ID("x")))
  in
  (* int main(){
       x = read();
       if (x){
         print(6);
       }else{
         print(2 + 4);
       }
     }*)
  let input5 = Seq(Assign("x",Unknown_Type(0),Value),If(ID("x"),Print(Int(6)),Print(Binop(Add,Int(2),Int(4))))) in
  let expected5 = Seq(Assign("x",Unknown_Type(0),Value),Print(Int(6)))
  in
  let test_list = [(input1,expected1);(input2,expected2);(input3,expected3);input4,expected4;input5,expected5] in
  List.fold_left (fun _ (i,e) -> Alcotest.(check ast) "" e (optimize i)) () test_list

(* should all optimize to "x = true;" *)
let test_optimize_branches2 _ = 
  (*int main(){
      if (true) {
        x = true;
    } else {
      x = false;
      }
    } 
  *)
  let input1 = If(Bool(true),Assign("x",Bool_Type,Bool(true)),Assign("x",Bool_Type,Bool(false))) in
  (*
    int main(){
      if (true){
        if (true) {
          x = true;
        }
    } else {
      x = false;
      }                  
    }
  *)
  let input2 = If(Bool(true),If(Bool(true),Assign("x",Bool_Type,Bool(true)),NoOp),Assign("x",Bool_Type,Bool(false))) in
  (* int main(){
       x = true;
     } *)
  let input3 = Assign("x",Bool_Type,Bool(true)) in
  (* int main(){
      if (false) {
        if (true) {
          x = false;
        }
      } else {
        if (false) {
          x = false;
        } else {
          x = true;
        }
      } *)  
  let input4 = If(Bool(false),If(Bool(true),Assign("x",Bool_Type,Bool(false)),NoOp),If(Bool(false),Assign("x",Bool_Type,Bool(false)),Assign("x",Bool_Type,Bool(true)))) in
  let expected = Assign("x",Bool_Type,Bool(true)) in
  let test_list = [input1,expected;input2,expected;input3,expected;input4,expected] in
  List.fold_left (fun _ (i,e) -> Alcotest.(check ast) "" e (optimize i)) () test_list

let test_add_chain _ =  
  let expected = Assign("x",Unknown_Type(0),Binop(Add,Int(4),Value)) in 
  let asts = [(let _ = reset() in parse_expr "int main(){x = 1 + 3 + read();}");
              (let _ = reset() in parse_expr "int main(){x = 1 + read() + 3;}"); 
              (let _ = reset() in parse_expr "int main(){x = read() + 1 + 3;}"); 
              (let _ = reset() in parse_expr "int main(){x = 1 + 1 + 2 + read();}"); 
              (let _ = reset() in parse_expr "int main(){x = 1 + 1 + read() + 2;}");
              (let _ = reset() in parse_expr "int main(){x = 1 + read() + 1 + 2;}");
              (let _ = reset() in parse_expr "int main(){x = read() + 1 + 1 + 2;}");] in
  List.fold_left (fun _ x -> (run_test ~mode:Optimize {untyped=x;optimized=expected;should_typecheck=true;typed=x}) ()) () asts;

  let expected = Assign("x",Unknown_Type(0),Binop(Add,Int(4),Binop(Add,Value,Value))) in 
  let asts = [(let _ = reset() in parse_expr "int main(){x = 1 + 3 + read() + read();}");
              (let _ = reset() in parse_expr "int main(){x = 1 + read() + 3 + read();}"); 
              (let _ = reset() in parse_expr "int main(){x = read() + 1 + 3 + read();}"); 
              (let _ = reset() in parse_expr "int main(){x = 1 + read() + read() + 3;}"); 
              (let _ = reset() in parse_expr "int main(){x = read() + 1 + read() + 3;}"); 
              (let _ = reset() in parse_expr "int main(){x = read() + read() + 1 + 3;}"); 
              (let _ = reset() in parse_expr "int main(){x = 1 + read() + 1 + 2 + read();}"); 
              (let _ = reset() in parse_expr "int main(){x = 1 + 1 + read() + read() + 2;}");
              (let _ = reset() in parse_expr "int main(){x = 1 + read() + 1 + read() + 2;}");
              (let _ = reset() in parse_expr "int main(){x = read() + 1 + 1 + 2 + read();}");] in
  List.fold_left (fun _ x -> (run_test ~mode:Optimize {untyped=x;optimized=expected;should_typecheck=true;typed=x}) ()) () asts;
  
  let expected = Assign("x",Unknown_Type(0),Binop(Add,Int(4),Binop(Add,Value,Binop(Add,Value,Value)))) in 
  let asts = [(let _ = reset() in parse_expr "int main(){x = read() + 1 + read() + 3 + read();}"); 
              (let _ = reset() in parse_expr "int main(){x = read() + 1 + read() + 1 + 2 + read();}"); 
              (let _ = reset() in parse_expr "int main(){x = read() + 1 + 1 + read() + 2 + read();}"); 
              (let _ = reset() in parse_expr "int main(){x = read() + read()+ read() + 4;}");
              (let _ = reset() in parse_expr "int main(){x = read() + read()+ 4 + read();}");
              (let _ = reset() in parse_expr "int main(){x = read() + 4 + read()+ read();}");
              (let _ = reset() in parse_expr "int main(){x = 4 + read() + read()+ read();}";)] in
  List.fold_left (fun _ x -> (run_test ~mode:Optimize {untyped=x;optimized=expected;should_typecheck=true;typed=x}) ()) () asts

let test_typecheck1 _ = 
  (* int main(){
        x = true; 
        if(x){
          x = true && false;
        };
    } *)
  let input = Seq(Assign("x",Bool_Type,Bool(true)),
                If(ID("x"),
                  Assign("x",Bool_Type,Binop(And,Bool(true),Bool(false))),
                  NoOp)) in
  Alcotest.(check bool) "" true (typecheck input)

let test_typecheck2 _ = 
  (* int main(){
        x = true; 
        x = 3;
    } *)
    let ast = Seq(Assign("x",Bool_Type,Bool(true)),
  Assign("x",Bool_Type,Int(3))) in
type_error_handler (fun () -> ast |> typecheck |> ignore)



let test_infer1 _ = 
  (* int main(){
        x = read(); 
        if(x){
          printf(true);
        }
    } *)
  let input = Seq(Assign("x",Unknown_Type(0),Value),
                  If(ID("x"),
                     Print(Bool(true)),
                     NoOp)) in
  let expected = Seq(Assign("x",Bool_Type,Value),
                If(ID("x"),
                  Print(Bool(true)),
                  NoOp)) in
  Alcotest.(check ast) "" expected (infer input)

let test_infer2 _ = 
  (* int main(){
        x = read(); 
        if(x){
          print(x + 1);
      }
    } *)
  let ast = Seq(Assign("x",Unknown_Type(0),Value),
                If(ID("x"),
                  Print(Binop(Add,ID("x"),Int(1))),
                  NoOp)) in
  type_error_handler (fun () -> ast |> infer |> ignore)


(* int main(){x = 1 + 2;} *)
let test_add= {typed=Assign("x",Int_Type,Binop(Add,Int(1),Int(2)));
                       untyped=(Assign("x",Int_Type,Binop(Add,Int(1),Int(2))));
                       optimized=(Assign("x",Int_Type,Int(3)));
                       should_typecheck=true;}

(* int main(){x=3/0;} *)
let test_errors _ = 
  (* int main(){
       x=3/0;
     } *)
  let input1 = Assign("x",Int_Type,Binop(Div,Int(3),Int(0)))
  in
  (* int main(){
       x=3/(-4 + 4);
     } *)
  let input2 = Assign("x",Int_Type,Binop(Div,Int(3),Binop(Add,Int(-4),Int(4))))
  in
  (* int main(){
       x=0;
       y = 100/x;
     } *)
  let input3 = Seq(Assign("x",Int_Type,Int(0)),Assign("y",Int_Type,Binop(Div,Int(100),ID("x"))))
  in
  (* int main(){
       x=0/0;
     } *)
  let input4 = Assign("x",Int_Type,Binop(Div,Int(0),Int(0)))
  in
  let test_list = [input1;input2;input3;input4;]
  in
  List.fold_left (fun _ x -> (run_test ~mode:Optimize {untyped=x;optimized=NoOp;should_typecheck=false;typed=x}) ()) () test_list;
  (* int main(){
       x = y + 4;
    }
  *)
  let input5 = Assign("x",Int_Type,Binop(Add,ID("y"),Int(4)))
  in
  (* int main(){
      if(x){
        printf(true);
      }
    }
  *)
  let input6 = If(ID("x"),Print(Bool(true)),NoOp)
  in
  (* int main(){
      while(x){
        printf(true);
      }
    }
  *)
  let input7 = While(ID("x"),Print(Bool(true)))
  in
  let test_list = [input5;input6;input7]
  in
  List.fold_left (fun _ x -> declare_error_handler (fun () -> x |> optimize |> ignore)) () test_list

let _ = let open Alcotest in
  run 
  ~argv: [|
    "";
    "--show-errors";
  |]
  "public" [
    (* optimizer tests *)
    "optimize", [ test_case "opt_identities"  `Quick test_identities;
                  test_case "opt_read"        `Quick test_basic_read;
                  test_case "opt_constants"   `Quick test_pure_constants;
                  test_case "opt_branches1"   `Quick test_optimize_branches1;
                  test_case "opt_branches2"   `Quick test_optimize_branches2;
                  test_case "opt_add_chain"   `Quick test_add_chain;
                  test_case "opt_add2"        `Quick (run_test ~mode:Optimize test_add);
                  test_case "opt_errors"      `Quick test_errors;
                ];
    (* typecheck tests *)
    "typecheck",[ test_case "tc_bool"         `Quick test_typecheck1;
                  test_case "tc_err"          `Quick test_typecheck2;
                  test_case "tc_add"          `Quick (run_test ~mode:Typecheck test_add);
                ];
    (* inference tests *)
    "infer",    [ test_case "inf_bool"        `Quick test_infer1;
                  test_case "inf_add1"        `Quick test_infer2;
                  test_case "inf_add2"        `Quick (run_test ~mode:Infer test_add);
                ];
  ]
