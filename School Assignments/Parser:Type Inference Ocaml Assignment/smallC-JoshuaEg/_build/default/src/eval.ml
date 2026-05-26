open SmallCTypes
open Utils
open TokenTypes

exception TypeError of string
exception DeclareError of string
exception DivByZeroError



let rec eval_expr env t =
  match t with
  |Bool(x)-> Bool_Val(x)
  |Int(x)-> Int_Val(x)
  |ID(x)-> (try List.assoc x env with Not_found -> raise (DeclareError("womp womp (ID)")) )
  |Add(x,y) ->( match (eval_expr env x, eval_expr env y) with
              (Int_Val(x), Int_Val(y))-> Int_Val(x+y)
              |_-> raise (TypeError("womp womp (Add)"))  )
  |Sub(x,y) ->( match (eval_expr env x, eval_expr env y) with
              (Int_Val(x), Int_Val(y))-> Int_Val(x-y)
              |_-> raise (TypeError("womp womp (Sub)"))  )
  |Mult(x,y) ->( match (eval_expr env x, eval_expr env y) with
              (Int_Val(x), Int_Val(y))-> Int_Val(x*y)
              |_-> raise (TypeError("womp womp (Mult)"))  )
  |Div(x,y) ->( match (eval_expr env x, eval_expr env y) with
              (Int_Val(x), Int_Val(y))-> if y <> 0 then Int_Val(x/y) else raise (DivByZeroError)
              |_-> raise (TypeError("womp womp (Div)"))  )
  |Pow(x,y) ->( match (eval_expr env x, eval_expr env y) with
              (Int_Val(x), Int_Val(y))-> Int_Val(int_of_float( floor ((float_of_int x) ** (float_of_int y))))
              |_-> raise (TypeError("womp womp (Pow)"))  )
  |And(x,y) ->( match (eval_expr env x, eval_expr env y) with
              (Bool_Val(x),Bool_Val(y)) -> Bool_Val(x && y)
              |_-> raise (TypeError("womp womp (And)"))  )
  |Or(x,y) ->( match (eval_expr env x, eval_expr env y) with
              (Bool_Val(x),Bool_Val(y)) -> Bool_Val(x || y)
              |_-> raise (TypeError("womp womp (Or)"))  )
  |Not(x) ->( match eval_expr env x with
              | Bool_Val(x) -> Bool_Val(not x)
              | _-> raise (TypeError("womp womp (Not)"))  )
  |Greater(x,y)-> ( match (eval_expr env x, eval_expr env y) with
                  (Int_Val(x), Int_Val(y))-> Bool_Val(x > y)
                  |_-> raise (TypeError("womp womp (Great)"))      )
  |Less(x,y)->( match (eval_expr env x, eval_expr env y) with
                  (Int_Val(x), Int_Val(y))-> Bool_Val(x < y)
                  |_-> raise (TypeError("womp womp (Less)"))      )
  |GreaterEqual(x,y)-> ( match (eval_expr env x, eval_expr env y) with
                  (Int_Val(x), Int_Val(y))-> Bool_Val(x >= y)
                  |_-> raise (TypeError("womp womp (GreatEq)"))      )
  |LessEqual(x,y)->( match (eval_expr env x, eval_expr env y) with
                  (Int_Val(x), Int_Val(y))-> Bool_Val(x <= y)
                  |_-> raise (TypeError("womp womp (LessEq)"))      )
  |Equal(x,y)->( match (eval_expr env x, eval_expr env y) with
                (Int_Val(x), Int_Val(y))-> Bool_Val(x == y)
                |(Bool_Val(x), Bool_Val(y))-> Bool_Val(x == y)
                |_-> raise (TypeError("womp womp (Equal)"))      )
  |NotEqual(x,y)->( match (eval_expr env x, eval_expr env y) with
                (Int_Val(x), Int_Val(y))-> Bool_Val(x <> y)
                |(Bool_Val(x), Bool_Val(y))-> Bool_Val(x <> y)
                |_-> raise (TypeError("womp womp (Not equal)"))      )

  

let rec eval_stmt env s =
  let rec eval_for id x e2 fenv t =
   
    if x <= e2 then
      let newEnv = eval_stmt fenv t in
      match List.assoc id newEnv with
      Int_Val(i) -> let newEnv = (id, Int_Val(i+1)) :: (List.remove_assoc id newEnv) in
        eval_for id (i+1) e2 newEnv t 
      |Bool_Val(i) -> fenv
    else
      match List.assoc id fenv with
      Int_Val(i) ->(id, Int_Val(i)) :: (List.remove_assoc id fenv)
      |_ -> fenv
  in

    (*
    if x <= e2 then eval_for id (x+1) e2 ((id, Int_Val(x+1)) ::  (List.remove_assoc id (eval_stmt fenv t))) t 
                else (id, Int_Val(x)) :: (List.remove_assoc id fenv) *) 

  match s with
  NoOp -> env
  |Seq(a,b) -> let uenv = (eval_stmt env a) in eval_stmt uenv b
  |Declare(a,b)-> (try let _ = List.assoc b env in raise (DeclareError("womp womp (Declare)")) with Not_found ->
                    (match a with
                    |Int_Type-> (b, Int_Val(0)) :: env
                    |Bool_Type-> (b, Bool_Val(false)) :: env   ))
  |Assign(a,b)-> (try let vtype = List.assoc a env in
                      let e = eval_expr env b in
                      (match vtype, e with
                      |Int_Val(_), Int_Val(x)-> (a,e) :: (List.remove_assoc a env)
                      |Bool_Val(_), Bool_Val(x)-> (a,e) :: (List.remove_assoc a env)
                      | _ -> raise (TypeError("womp womp (assign (exp))"))  )
                with Not_found -> raise (DeclareError("womp womp (assign (not found))")) )
  |If(e,a,b)-> (match eval_expr env e with
                Bool_Val(x)-> if x then (eval_stmt env a) else (eval_stmt env b)
                |_ -> raise (TypeError("womp womp (if)"))  )
  |While(e,b)-> (match eval_expr env e with
                 Bool_Val(x) -> if not x then env else 
                  let newEnv = eval_stmt env b in eval_stmt newEnv s
                |_ -> raise (TypeError("womp womp (while)")) )
  |For(y,e1,  e2, a) -> (try (match List.assoc y env with  (*most complicated one*)
                         Int_Val(x)-> (match eval_expr env e1, eval_expr env e2 with
                          |Int_Val(i), Int_Val(j)-> eval_for y i j ((y,Int_Val(i)) :: (List.remove_assoc y env)) a  
                          |_-> raise (TypeError("womp womp (for (exp))")) )
                        |_-> raise (TypeError("womp womp (for [ID])")) )
                        with Not_found -> raise (DeclareError("womp womp (for)") ))
  |Print(x) -> match eval_expr env x with (*not sure if im meant to return env*)
            |Int_Val(i) -> let _ = print_output_int i in 
                            let _ = print_output_newline () in env
            |Bool_Val(i) -> let _ = print_output_bool i in 
                            let _ = print_output_newline () in env
        
