open Ast
open Utils



(* Order of Operations for Optomize, (Declare error)-> 
                Var Check -> (Foldable ->)Constant propagate
                -> Constant Fold -> Loop Fold -> Branch Fold *)

let rec union a b = (* helper function for concatenated list while filtering out duplicates*)
  let rec elem x a =
    match a with
    | h::t -> (h = x) || (elem x t)
    | [] -> false in
  let rec insert x a =
    if not (elem x a) then x::a else a in

    match a with
      | h::t -> insert h (union t b)
      | [] ->
       (match b with
         | h::t -> insert h (union [] t)
        | [] -> [])


let rec type_of e (env : environment) = (*helper function that finds the type of an expression*)
  match e with 
                | Int(_) -> Int_Type
                | Bool(_) -> Bool_Type
                | ID(x) -> (try( match List.assoc x env with
                                |Int_Val(_) -> Int_Type
                                |Bool_Val(_) -> Bool_Type
                                |Unknown_Val-> Unknown_Type(0) ) with Not_found -> raise (DeclareError("Type_of [ID]")))
                | Binop(x,a,b)-> (match x with 
                                  | Add | Sub | Mult | Div | Pow -> 
                                          (match type_of a env, type_of b env with 
                                            |Int_Type, Int_Type -> Int_Type
                                            |Int_Type, Unknown_Type(_) | Unknown_Type(_), Int_Type -> Int_Type
                                            |Unknown_Type(_), Unknown_Type(_) -> Int_Type
                                            |_-> raise (TypeError("Type_of [ARITHMATIC]")) ) 
                                  | Greater | GreaterEqual | Less | LessEqual | Equal | NotEqual -> 
                                          (match type_of a env, type_of b env with 
                                            |Int_Type, Int_Type | Bool_Type, Bool_Type -> Bool_Type
                                            |Int_Type, Unknown_Type(_) | Unknown_Type(_), Int_Type -> Bool_Type
                                            |Bool_Type, Unknown_Type(_) | Unknown_Type(_), Bool_Type -> Bool_Type
                                            |Unknown_Type(_), Unknown_Type(_) -> Bool_Type
                                            |_-> raise (TypeError("Type_of [COMPARISON]")) ) 
                                  |And | Or -> (match type_of a env, type_of b env with 
                                      |Bool_Type, Bool_Type -> Bool_Type
                                      |Unknown_Type(_), Unknown_Type(_) -> Bool_Type
                                      |Bool_Type, Unknown_Type(_) |  Unknown_Type(_), Bool_Type -> Bool_Type
                                      |_-> raise (TypeError("Type_of [AND | OR]") ) ) )
                | Not(x) -> (match type_of x env with
                              | Bool_Type -> Bool_Type
                              | Unknown_Type(_) -> Bool_Type
                              | _ -> raise (TypeError("Type_of [NOT]")))
                | Value -> Unknown_Type(0)  

let declare_check e = (*helper function that handles declare checks*)
  let rec declare_loop e lst = match e with
    | Seq(x,y) -> let a = declare_loop x lst in declare_loop y (a @ lst) 
    | Assign(a,_,exp) -> let _ = exp_check exp lst in a :: lst
    | If(exp, x, y) -> let _ = exp_check exp lst in let a = declare_loop x lst in declare_loop y (a @ lst)
    | For(s, e1, e2, x) -> let _ = exp_check e1 (s::lst) in let _ = exp_check e2 (s::lst) in
                          declare_loop x (s::lst)
    | While(ex,x) -> let _ = exp_check ex lst in declare_loop x lst
    | Print(x) -> let _ = exp_check x lst in lst
    | NoOp -> lst
  and exp_check e lst = match e with
    | ID(x) -> if (not (List.exists (fun a -> a = x) lst)) then raise (DeclareError("exp_check"))
                  else ()
    | Binop(_,x,y) -> let _ = exp_check x lst in let _ = exp_check y lst in ()
    | Not(x) -> let _ = exp_check x lst in ()
    | _ -> () in

    declare_loop e []




(* Order of Operations for Optomize,
                (Declare error)-> 
                Var Check -> (Folding ->)Constant propagate
                -> Constant Fold -> Loop Fold -> Branch Fold *)

let rec optimize e =  
  let rec constan_fold expr = (* performs early evaluation of constants whereever applicable,
                               eg. Binop(Add, Int(1), Int(1)) simply becoms Int(2) *)
    match expr with
    | Int(x) -> Int(x)
    | Bool(x) -> Bool(x)
    | ID(x) -> ID(x)
    | Value -> Value
    | Binop(binop, e1,e2) -> begin 
                            match binop with
                            |Add ->( match constan_fold e1, constan_fold e2 with  (*make a function for this this is stupid*)
                                    | Int(x),Int(y) -> Int(x+y)
                                    | ID(x), Int(0)-> ID(x)
                                    | Int(0),ID(x) -> ID(x)
                                   
                                    | Binop(Add, Value, Int(y)), Value -> Binop(Add, Int(y),Binop(Add,Value, Value))
                                    | Binop(Add, Int(y), Value), Value -> Binop(Add, Int(y),Binop(Add,Value, Value))
                                    | Value, Binop(Add, Value, Int(y)) -> Binop(Add, Int(y),Binop(Add,Value, Value))
                                    | Value, Binop(Add, Int(y), Value) -> Binop(Add, Int(y),Binop(Add,Value, Value))
                                    
                                    | Binop(Add, Int(y), Value), Int(x) -> Binop(Add, Int(x+y), Value)
                                    | Binop(Add, Value, Int(y)), Int(x) -> Binop(Add, Int(x+y), Value)
                                    | Int(x), Binop(Add, Value, Int(y)) -> Binop(Add, Int(x+y), Value)
                                    | Int(x), Binop(Add, Int(y), Value) -> Binop(Add, Int(x+y), Value)

                                    | Binop(Add, Value, Value), Value -> Binop(Add, Value,Binop(Add,Value, Value))

                                    | Binop(Add, Int(y), a), Int(x) -> Binop(Add, Int(x+y), a)
                                    | Binop(Add, a, Int(y)), Int(x) -> Binop(Add, Int(x+y), a)
                                    | Int(x), Binop(Add, a, Int(y)) -> Binop(Add, Int(x+y), a)
                                    | Int(x), Binop(Add, Int(y), a) -> Binop(Add, Int(x+y), a)

                                    | Binop(Add, Int(y), a), Value -> Binop(Add, Int(y), Binop(Add, Value, a))
                                    | Binop(Add, Int(y), Value), a -> Binop(Add, Int(y), Binop(Add, Value, a))

                                    | Binop(Add, a, Int(y)), b -> Binop(Add, Int(y),Binop(Add,a, b))
                                    | Binop(Add, Int(y), a), b -> Binop(Add, Int(y),Binop(Add,a, b))
                                    | a, Binop(Add, b, Int(y)) -> Binop(Add, Int(y),Binop(Add,a, b))
                                    | a, Binop(Add, Int(y), b) -> Binop(Add, Int(y),Binop(Add,a, b))
                                    | a, Int(y) -> Binop(Add, Int(y),a)
                                    

                                    | x,y-> Binop(binop, x,y) )
                            |Sub ->( match constan_fold e1, constan_fold e2 with 
                                  | Int(x),Int(y) -> Int(x-y)
                                  | ID(x), Int(0)-> ID(x)
                                  | Int(x), Binop(Sub, Int(y), Value) -> Binop(Sub, Int(x-y), Value)
                                  | Binop(Sub, Value, Int(y)), Int(x) -> Binop(Sub, Int(y-x), Value)
                                  | x,y-> Binop(binop, x,y) )
                            |Mult -> (match constan_fold e1, constan_fold e2 with
                                  | Int(0),ID(x) when is_num x e -> Int(0)
                                  | ID(x),Int(0) when is_num x e-> Int(0)
                                  | Int(x),Int(y) -> Int(x*y)
                                  | Int(0),Int(_) | Int(_),Int(0)  -> Int(0)
                                  | Int(0),Value | Value, Int(0)  -> Int(0)
                                  | Int(x), Binop(Mult, Value, Int(y)) -> Binop(Mult, Int(x*y), Value)
                                  | Int(x), Binop(Mult, Int(y), Value) -> Binop(Mult, Int(x*y), Value)
                                  | Binop(Mult, Int(y), Value), Int(x) -> Binop(Mult, Int(x*y), Value)
                                  | Binop(Mult, Value, Int(y)), Int(x) -> Binop(Mult, Int(x*y), Value)


                                  | Binop(Mult, Value, Value), Value -> Binop(Mult, Value,Binop(Mult,Value, Value))


                                  | x,y-> Binop(binop, x,y))
                            |Div -> (match constan_fold e1, constan_fold e2 with
                                  |ID(x), Int(0) when is_num x e -> raise DivByZeroError
                                  |Int(_),Int(0) -> raise DivByZeroError
                                  |Int(x),Int(y) -> Int(x/y)
                                  |Int(0), ID(x) when is_num x e -> Int(0)
                                  |Binop(_), Int(0) -> raise DivByZeroError
                                  |Binop(Div, Value, Int(y)), Int(x) -> Binop(Div, Value, Int(y*x))
                                  | x,y-> Binop(binop, x,y))
                              |Pow -> (match constan_fold e1, constan_fold e2 with
                                    | Int(0),Int(x) when x < 0 -> raise DivByZeroError
                                    | ID(x), Int(0) when is_num x e -> Int(1)
                                    | Int(x), Int(y) -> Int(int_of_float( floor ((float_of_int x) ** (float_of_int y))))
                                    | Binop(Pow, Int(x), Value), Int(y) -> 
                                        Binop(Pow,Int(int_of_float( floor ((float_of_int x) ** (float_of_int y)))) , Value)
                                    | Binop(Pow, Value, Int(x)), Int(y) ->  Binop(Pow, Value, Int(x*y))
                                    | x,y-> Binop(binop, x,y))
                              |Greater -> (match constan_fold e1, constan_fold e2 with
                                    | Int(x),Int(y) -> Bool(x>y)
                                    | Bool(x), Bool(y) -> Bool(x>y)
                                    | x,y-> Binop(binop, x,y))
                              |Less -> (match constan_fold e1, constan_fold e2 with
                                    | Int(x),Int(y) -> Bool(x<y)
                                    | Bool(x), Bool(y) -> Bool(x<y)
                                    | x,y-> Binop(binop, x,y))
                              |GreaterEqual -> (match constan_fold e1, constan_fold e2 with
                                    | Int(x),Int(y)-> Bool(x>=y)
                                    | Bool(x), Bool(y) -> Bool(x>=y)
                                    | x,y-> Binop(binop, x,y))
                              |LessEqual -> (match constan_fold e1, constan_fold e2 with
                                    | Int(x),Int(y)-> Bool(x<=y)
                                    | Bool(x), Bool(y) -> Bool(x<=y)
                                    | x,y-> Binop(binop, x,y))
                              |Equal -> (match constan_fold e1, constan_fold e2 with
                                    | Int(x),Int(y) -> Bool(x=y)
                                    | Bool(x),Bool(y) -> Bool(x=y)
                                    | x,y-> Binop(binop, x,y))
                              |NotEqual -> (match constan_fold e1, constan_fold e2 with
                                    | Int(x),Int(y) -> Bool(x<>y)
                                    | Bool(x),Bool(y) -> Bool(x<>y)
                                    | x,y-> Binop(binop, x,y))
                              |Or -> (match constan_fold e1, constan_fold e2 with
                                    |Bool(x), Bool(y) -> Bool(x||y)
                                    |ID(x), Bool(true) when is_bool x e -> Bool(true)
                                    |Bool(true), ID(x) when is_bool x e -> Bool(true)
                                    |Bool(true), Value |Value, Bool(true) -> Bool(true)
                    |ID(x), Binop(And, ID(z), ID(y)) | Binop(And, ID(y), ID(z)), ID(x)
                    when ((is_bool x e) && (is_bool z e) && (is_bool y e) && (x=z || x = y)) -> ID(x) (*absorbtion law*)
                                    |x,y-> Binop(binop, x,y) )
                              |And -> (match constan_fold e1, constan_fold e2 with
                                    |Bool(x), Bool(y) -> Bool(x&&y)
                                    |ID(x), Bool(false) when is_bool x e -> Bool(false)
                                    |Bool(false), ID(x) when is_bool x e -> Bool(false)
                                    |Bool(false), Value |Value, Bool(false) -> Bool(false)
                    |ID(x), Binop(Or, ID(z), ID(y)) | Binop(Or, ID(y), ID(z)), ID(x) 
                    when ((is_bool x e) && (is_bool y e) && (is_bool z e) && (x=z || x=y)) -> ID(x) (*absorbtion law*)
                                    |Bool(false), a |a, Bool(false) -> Bool(false)

                                    | Binop(And, Value, Value), Value -> Binop(And, Value,Binop(And,Value, Value))

                                    |Bool(true), Binop(And,a, Bool(true)) -> Binop(And, Bool(true), a)
                                    |Bool(true), Binop(And,Bool(true), a) -> Binop(And, Bool(true), a)
                                    |Binop(And,Bool(true), a), Bool(true) -> Binop(And, Bool(true), a)
                                    |Binop(And, a, Bool(true)), Bool(true) -> Binop(And, Bool(true), a)

                                    |Binop(And, a, Bool(true)), Bool(true) -> Binop(And, Bool(true), a)

                                    |a,Bool(true) -> Binop(And, Bool(true), a)  
                                    |x,y-> Binop(binop, x,y) )

                          end
    | Not(x) -> begin
                match constan_fold x with
                |Bool(x) -> Bool(not x)
                |Binop(Or,Bool(a), Bool(b)) -> Binop(And, Bool(not a), Bool(not b))
                |Binop(And,Bool(a), Bool(b)) -> Binop(Or, Bool(not a), Bool(not b))
                |Not(b) -> b
                |x-> Not(x)
              end 

    and is_num id t = 
    match t with
    |Seq(x,y) -> (is_num id x) || (is_num id y)
    |Assign(x,y,_) when id = x -> y = Int_Type
    |If(_,x,y) -> (is_num id x) || (is_num id y)
    |While(_,x) -> (is_num id x)
    |For(_,_,_,x)-> (is_num id x)
    |_-> false
    and is_bool id t = 
    match t with
    |Seq(x,y) -> (is_bool id x) || (is_bool id y)
    |Assign(x,y,_) when id = x -> y = Bool_Type
    |If(_,x,y) -> (is_bool id x) || (is_bool id y)
    |While(_,x) -> (is_bool id x)
    |For(_,_,_,x) -> (is_bool id x)
    |_-> false
    in
  
  let rec set_var x v p = (* Replaces variables with constants if the variable is never mutated, x is the ID(s) *)
    match p with
    | ID(s) when (ID(s)) = x -> v
    | Binop(a,b,c)-> let setB = set_var x v b in
                      let setC = set_var x v c in Binop(a,setB,setC)
    | Not(a) -> Not(set_var x v a)
    |_ -> p
  and set_stmt x v t = (* helper for set var to travers AST *)
    match t with
    | NoOp -> NoOp
    | Seq(a,b) -> Seq(set_stmt x v a, set_stmt x v b)
    | Assign(a,b,c) -> Assign(a,b, set_var x v c)
    | For(a,b,c,d) -> For(a, set_var x v b, set_var x v c, set_stmt x v d)
    | If(a,b,c) -> If(set_var x v a, set_stmt x v b, set_stmt x v c)
    | While(a,b) -> While(set_var x v a, set_stmt x v b)
    | Print(y) -> Print(set_var x v y) in

  let rec loop_fold ast = (* removes loops if never triggered (ex, a while(false) is removed) *)
    match ast with 
    | NoOp -> NoOp
    | Seq(a,b) -> Seq(loop_fold a, loop_fold b)
    | Assign(a,b,c) -> Assign(a,b, c)
    | For(a,b,c,d) -> (match b, c with 
                      | Int(x), Int(y) -> if x > y then (Assign(a, Int_Type, Int(x))) else For(a,b,c, loop_fold d)
                      |_ -> For(a,b,c, loop_fold d)  )
    | If(a,b,c) -> If(a, loop_fold b, loop_fold c)
    | While(a,b) -> ( match a with 
                      | Bool(x) -> if not x then NoOp else While(a, loop_fold b)
                      |_-> While(a, loop_fold b))
    | Print(y) -> Print(y) in

  let rec branch_fold ast = (* Like loop_fold, but for if statements *)
    match ast with 
    | NoOp -> NoOp
    | Seq(a,b) -> Seq(branch_fold a, branch_fold b)
    | Assign(a,b,c) -> Assign(a,b,c)
    | For(a,b,c,d) -> For(a, b, c, branch_fold d)
    | If(a,b,c) -> if b=c then b else ( match a with 
                                        | Bool(a) -> if a then branch_fold b else branch_fold c
                                        |_-> If(a,b,c))
    | While(a,b) -> While(a, branch_fold b)
    | Print(y) -> Print(y) in

  let rec fold_vars ast l = (* finds the first "foldable" varibale (eligiable for set_var)*)
                            (*returns ([variable], constant), the [variable] could've been an Option type, 
                            but i think i did this because [x] and [] is less characters, or more likely,
                            i didnt think of it *)
      let rec fold_confirm e = match e with (* checks if a variable is foldable *)
        | Int(_) -> true
        | Bool(_) -> true 
        | ID(_) -> false
        | Binop(_,a,b) -> (fold_confirm a) &&  (fold_confirm b)
        | Not(x) -> fold_confirm x
        | Value -> false in
        
      match ast with                               
      | Seq(a,b)-> let a,e = fold_vars a l in if a <> [] then (a,e) else fold_vars b l   
      | Assign(s, t, e) -> if (fold_confirm e) && (not (List.exists (fun x -> x = s) l)) then ([s],e) else ([],Value)
      | If(_,a,b) -> let a,e = fold_vars a l in if a <> [] then a,e else fold_vars b l 
      | For(_,_,_, e) -> fold_vars e l
      | While(_,e) -> fold_vars e l                 
      | _ -> ([],Value) in

  let rec stmt_fold ast = match ast with (* traversing AST for constan_fold *)
    | NoOp -> NoOp
    | Seq(a,b) -> Seq(stmt_fold a, stmt_fold b)
    | Assign(a,b,c) -> Assign(a,b, constan_fold c)
    | For(a,b,c,d) -> For(a, constan_fold b, constan_fold c, stmt_fold d)
    | If(a,b,c) -> If(constan_fold a, stmt_fold b, stmt_fold c)
    | While(a,b) -> While(constan_fold a, stmt_fold b)
    | Print(y) -> Print(constan_fold y) in

  
  let rec folder v ast = (*handles traversing for set_var/set_stmt*)
    let var,exp =  fold_vars ast v in
    if var <> [] then match var with
      | [x] -> let newAst = set_stmt (ID(x)) exp ast in folder (var @ v) newAst
      | _-> raise DivByZeroError (*should never trigger, consequence of not using *)
    else ast in

  let _ = declare_check e in
  let e = folder [] e in
  let e = stmt_fold e in
  let e = loop_fold e in
  branch_fold e
  

    

  

let rec typecheck e = (* finds every variable an keeps track of their types, makes sure it is consistent with how its used*)
  let rec stmt_of e (env : environment) = match e with
    | Seq(x,y) -> let en = stmt_of x env in stmt_of y en
    | Assign(s,t,exp) -> 
                         ( match type_of exp env with
                          | a when t = a -> (match t with
                            | Int_Type -> (s,Int_Val(0))::env 
                            | Bool_Type -> (s,Bool_Val(false))::env
                            |  Unknown_Type(_) -> (s,Unknown_Val)::env )
                          | Unknown_Type(_) ->(match t with
                            | Int_Type -> (s,Int_Val(0))::env 
                            | Bool_Type -> (s,Bool_Val(false))::env
                            |  Unknown_Type(_) -> (s,Unknown_Val)::env )
                          |_-> (match t with
                                |Unknown_Type(_) -> (s,Unknown_Val)::env 
                                |_ -> raise (TypeError("stmt_of [Assign]"))))
    | If(b,s1,s2) -> if Bool_Type = type_of b env || (Unknown_Type(0)) = type_of b env then 
                    let e1 = stmt_of s1 env in
                    let e2 = stmt_of s2 e1 in e2
                    else raise (TypeError("stmt_of [If]"))
    | While(b, st) -> if Bool_Type = type_of b env || (Unknown_Type(0)) = type_of b env then  stmt_of st env
                      else raise (TypeError("stmt_of [While]"))
    | For(s, t1, t2, st) -> let nEnv = (try (match List.assoc s env with 
                                          | Bool_Val(_) -> raise (TypeError("stmt_of [For s]"))
                                          | _ -> env) with Not_found -> ((s,Int_Val(0))::env)) in
                            if type_of t1 nEnv = Int_Type || type_of t1 nEnv = (Unknown_Type(0)) then
                            if type_of t2 nEnv = Int_Type || type_of t2 nEnv = (Unknown_Type(0)) 
                                then stmt_of st nEnv
                            else raise (TypeError("stmt_of [For T2]"))
                          else raise (TypeError("stmt_of [For T1]"))
    | Print(e) -> let _ = type_of e env in env
    | NoOp -> env in
  let _ = declare_check e in
  let _ = stmt_of e [] in true

let rec infer e = 
  let rec type_env e env v = (* given a variable, look through the expression to see if you can infer its type (only finds one variable at a time) *)
    match e with
    |ID(x) when x = v -> [(x,Unknown_Val)]
    |Not(x) -> (match type_env x env v with
                 | [(x,Unknown_Val)] -> [(v,Bool_Val(false))]
                 | a -> a  )
    |Binop(x,y,z) -> (match x with
          | Add | Sub | Mult | Div | Pow -> 
            (match type_env y env v, type_env z env v with
              | [(y,Unknown_Val)],_ -> [(v, Int_Val(0))]
              | _,[(z,Unknown_Val)] -> [(v, Int_Val(0))]
              | [(y,a)],_ -> [(v, a)]
              | _,[(z,a)] -> [(v, a)]
              |_->[])
          | And | Or -> (match type_env y env v, type_env z env v with
              | [(y,Unknown_Val)],_ -> [(v, Bool_Val(false))]
              | _,[(z,Unknown_Val)] -> [(v, Bool_Val(false))]
              | [(y,a)],_ -> [(v, a)]
              | _,[(z,a)] -> [(v, a)]
              |_->[])
          | Greater | GreaterEqual | Less | LessEqual | Equal | NotEqual -> 
            (match type_env y env v, type_env z env v with
              |[], [(a,Unknown_Val)] ->  (match type_of y env with
                              |Int_Type -> [(v,Int_Val(0))] 
                              |Bool_Type -> [(v,Bool_Val(false))] 
                              |_ -> [] )
              | [(a,Unknown_Val)], [] ->  (match type_of z env with
                              |Int_Type -> [(v,Int_Val(0))] 
                              |Bool_Type -> [(v,Bool_Val(false))] 
                              |_ -> [] )
              | [(a,Int_Val(0))],_ -> [(v, Int_Val(0))]
              | _, [(a,Int_Val(0))] -> [(v, Int_Val(0))]
              | [(a,Bool_Val(false))],_ -> [(v, Bool_Val(false))]
              | _, [(a,Bool_Val(false))] -> [(v, Bool_Val(false))]
              | [(y,a)],_ -> [(v, a)]
              | _,[(z,a)] -> [(v, a)]
              |_->[]      ))
    |_-> [] in
  let rec still_unknown e = match e with (*finds variables that are still unknown *)
    |Assign(s,Unknown_Type(_),_) -> [s]
    |Seq(x,y) -> (still_unknown x) @ (still_unknown y)
    |If(_,x,y) -> (still_unknown x) @ (still_unknown y)
    |While(_,x) -> (still_unknown x)
    |For(_,_,_,x) -> (still_unknown x)
    |_-> [] in
  let rec infer_exp e env v = (* traverse AST for tpye_env *)
    match e with 
    |Seq(x,y) -> let newEnv = infer_exp x env v in if newEnv = [] then infer_exp y env v else newEnv
    |If(x,y,z) -> let newEnv1 = type_env x env v in if newEnv1 = [] then 
                  (let  newEnv2 = infer_exp y env v in if newEnv2 = [] then
                    infer_exp z env v else newEnv2) else newEnv1
    |Assign(_,_,t) -> type_env t env v
    |While(x,y) ->  let newEnv = type_env x env v in if newEnv = [] then infer_exp y env v else newEnv
    |For(_,x,y,z) -> let newEnv1 = type_env x env v in if newEnv1 = [] then 
                  (let  newEnv2 = type_env y env v in if newEnv2 = [] then
                        infer_exp z env v else newEnv2) else newEnv1
    |Print(x) -> type_env x env v
    |_-> [] in


  let rec inferencer e env = (*Traverses thtough the AST and assigns variables with its inverence kept track using ENV*)
                            (*is careful not to continue inferring if there is a type error*)
    match e with
    | Assign(s,ty,exp) -> let expty = type_of exp env in (match ty with
                  | Unknown_Type(_) ->  if (List.assoc_opt s env) = None then
                                                  (match expty with (*infers based on exp*)
                                                 | Int_Type-> (s,Int_Val(0))::env
                                                 | Bool_Type-> (s,Bool_Val(false))::env
                                                 | Unknown_Type(_)-> (s,Unknown_Val)::env ) else
                                                  (match List.assoc s env with
                                |Int_Val(_)-> if Bool_Type <> expty then env else raise (TypeError("inferencer [U_INT]"))
                                |Bool_Val(_)-> if Int_Type <> expty then env else raise (TypeError("inferencer [U_BOOL]") )
                                |_-> (match expty with (* replaces varibale with inference if possible*)
                                  | Int_Type-> (s,Int_Val(0))::(List.remove_assoc s env)
                                  | Bool_Type-> (s,Bool_Val(false))::(List.remove_assoc s env)
                                  | Unknown_Type(_)-> env )                      )
                  |Int_Type -> let env = (match exp with (*if exp is an ID, infer exp first before s*)
                                |ID(x) -> if List.assoc_opt x env <> (Some(Bool_Val(false)))
                                          then (x,Int_Val(0)) :: (List.remove_assoc x env)
                                      else raise (TypeError("inferencer [Assing IDn]"))
                                |_->  if expty = Bool_Type then raise (TypeError("inferencer [Assign IDn]")) else env) in
                    
                                  let newEnv = (s,Int_Val(0))::env in if (Bool_Type <> expty) then
                                      if  ((List.assoc_opt s env) = None) then newEnv  
                                        else if  (List.assoc_opt s env) = (Some(Int_Val(0)))
                                          then env else if (List.assoc_opt s env) = (Some(Unknown_Val))
                                            then (s,Int_Val(0))::(List.remove_assoc s env)
                                                      else raise (TypeError("inferencer [IN]"))
                                                                    else raise (TypeError("inferencer [IN | <>]"))
                  |Bool_Type -> let env = (match exp with
                                |ID(x) -> if List.assoc_opt x env <> (Some(Int_Val(0)))
                                    then (x,Bool_Val(false)) :: (List.remove_assoc x env)
                                   else raise (TypeError("inferencer [Assign IDb]"))
                                |_->  if expty = Int_Type then raise (TypeError("inferencer [Assign IDb]")) else env) in
                    
                    
                                let newEnv = (s,Bool_Val(false))::env in if (Int_Type <> expty) then
                                     if  ((List.assoc_opt s env) = None) then newEnv  
                                       else if  (List.assoc_opt s env) = (Some(Bool_Val(false)))
                                        then env else if (List.assoc_opt s env) = (Some(Unknown_Val))
                                          then (s,Bool_Val(false))::(List.remove_assoc s env)
                                                      else raise (TypeError("inferencer [BOO]"))
                                                                  else raise (TypeError("inferencer [BOO| <>]")))
    | Seq(x,y)-> let newEnv = inferencer x env in inferencer y newEnv
    | If(a,x, y)-> let v = (match a with
                            |ID(x) -> if List.assoc_opt x env <> (Some(Int_Val(0)))
                                      then (x,Bool_Val(false)) :: (List.remove_assoc x env)
                                          else raise (TypeError("inferencer [IF]"))
                            |_->  if type_of a env = Int_Type then raise (TypeError("inferencer [IF]")) else env  ) in
                    let newEnv = inferencer x v in inferencer y newEnv
    | While(a, x)-> let v = (match a with
                            |ID(x) -> if List.assoc_opt x env <> (Some(Int_Val(0)) )
                                        then (x,Bool_Val(false)) :: (List.remove_assoc x env)
                                          else raise (TypeError("inferencer [While]"))
                            |_->  if type_of a env = Int_Type then raise (TypeError("inferencer [WHILE]")) else env  ) in
                           inferencer x v 
    | For(s,e1,e2,x)-> let env = (try (match List.assoc s env with 
                            | Bool_Val(_) -> raise (TypeError("stmt_of [For s]"))
                            | Int_Val(_) -> env
                            | _ -> (s,Int_Val(0))::(List.remove_assoc s env)) with Not_found -> ((s,Int_Val(0))::env)) in
                        let v1 = (match e1 with
                          |ID(x) ->  if List.assoc_opt x env <> (Some(Bool_Val(false)) )
                                      then (x,Int_Val(0)) :: (List.remove_assoc x env)
                                        else raise (TypeError("inferencer [For]"))
                          |_->  if type_of e1 env = Bool_Type then raise (TypeError("inferencer [FOR]")) else env  ) in
                        let v2 = (match e2 with
                          |ID(x) -> if List.assoc_opt x v1 <> (Some(Bool_Val(false)) )
                                      then (x,Int_Val(0)) :: (List.remove_assoc x v1)
                                        else raise (TypeError("inferencer [For]"))
                          |_->  if type_of e2 v1 = Bool_Type then raise (TypeError("inferencer [FOR]")) else v1  ) in
                    inferencer x (v2)
    | _ -> env in
  let rec updater e env = (*updates AST with inferences, keeping track of unknown type id's's*)
    match e with
        | Assign(a,Unknown_Type(z),b) ->(match List.assoc_opt a env with
                                    |Some(Int_Val(0)) -> (Assign(a, Int_Type, b), (z,Int_Type) :: [])
                                    |Some(Bool_Val(false)) -> (Assign(a,Bool_Type, b), (z,Bool_Type) :: [])
                                    |_-> e, [] )
        |Seq(x,y) -> let t1, z1 = updater x env in
                      let t2,z2 = updater y env in
                      Seq(t1, t2), (z1 @ z2)
        |If(d,x,y) -> let t1, z1 = updater x env in
                        let t2,z2 = updater y env in
                          If(d, t1, t2), (z1 @ z2)
        |While(d,x) -> let t,z = updater x env in (While(d,t),z)
        |For(a,b,c,x)-> let t,z = updater x env in (For(a,b,c, t), z)
        |_-> e, [] in
  let rec updater2 e (z,ty) = (* updates AST with the inferred unknown types along with its id ( handles one id at a time)*)
    match e with
      | Assign(x,Unknown_Type(a), y) when a = z -> Assign(x,ty,y)
      | Seq(x,y) -> Seq(updater2 x (z,ty), updater2 y (z,ty) )
      |If(d,x,y) -> If(d, updater2 x (z,ty), updater2 y (z,ty) )
      |While(d,x) -> While(d, updater2 x (z,ty))
      |For(a,b,c,x) -> For(a,b,c, updater2 x (z,ty))
      |_-> e in
  let rec updater_3 env uns ast =(* tries to find the typrs of the remaining unknowns
                                  (if you need to find one unkown to find another unknown to find another, etc) *)
                                  (* does not update AST *)
    let newEnv = List.fold_left (fun env x -> union (infer_exp ast env x) env) env uns in
    if newEnv = env then env else updater_3 newEnv uns ast in

  let _ = declare_check e in
  let env = inferencer e [] in
  let ast, z1 = updater e env in
  let uns = still_unknown ast in 
    let newEnv = List.fold_left (fun env x -> (infer_exp ast env x) @ env) env uns in
    let newEnv = updater_3 newEnv uns ast in
    let ast, z2 = updater e newEnv  in
    let ast = List.fold_left (fun ast t -> updater2 ast t) ast (z1 @ z2) in
       if typecheck ast then ast else ast