open SmallCTypes
open Utils
open TokenTypes

(* Parsing helpers (you don't need to modify these) *)

(* Return types for parse_stmt and parse_expr *)
type stmt_result = token list * stmt
type expr_result = token list * expr

(* Return the next token in the token list, throwing an error if the list is empty *)
let lookahead (toks : token list) : token =
  match toks with
  | [] -> raise (InvalidInputException "No more tokens")
  | h::_ -> h

(* Matches the next token in the list, throwing an error if it doesn't match the given token *)
let match_token (toks : token list) (tok : token) : token list =
  match toks with
  | [] -> raise (InvalidInputException(string_of_token tok))
  | h::t when h = tok -> t
  | h::_ -> raise (InvalidInputException(
      Printf.sprintf "Expected %s from input %s, got %s"
        (string_of_token tok)
        (string_of_list string_of_token toks)
        (string_of_token h)
    ))

(* Parsing (TODO: implement your code below) *)

let if_bracket t =  (lookahead t) = Tok_RBrace

let rec parse_expr toks : expr_result =
  let rec parseO tokens = 
    let t1, e1 = parseA tokens in
    match lookahead t1 with 
    |Tok_Or ->let t2 = match_token t1 Tok_Or in
              let t3, e2 = parseO t2 in
              (t3, (Or(e1,e2)))
    |_ -> (t1,e1)

  and parseA tokens = let t1, e1 = parseE tokens in
  match lookahead t1 with 
  |Tok_And ->let t2 = match_token t1 Tok_And in
            let t3, e2 = parseA t2 in
            (t3, (And(e1,e2)))
  |_ -> (t1,e1)

  and parseE tokens = let t1, e1 = parseR tokens in
  match lookahead t1 with 
  |Tok_Equal ->let t2 = match_token t1 Tok_Equal in
            let t3, e2 = parseE t2 in
            (t3, (Equal(e1,e2)))
  |Tok_NotEqual ->let t2 = match_token t1 Tok_NotEqual in
            let t3, e2 = parseE t2 in
            (t3, (NotEqual(e1,e2)))
  |_ -> (t1,e1)

  and parseR tokens = let t1, e1 = parseAdd tokens in
  match lookahead t1 with 
  |Tok_Greater ->let t2 = match_token t1 Tok_Greater in
            let t3, e2 = parseR t2 in
            (t3, (Greater(e1,e2)))
  |Tok_Less ->let t2 = match_token t1 Tok_Less in
            let t3, e2 = parseR t2 in
            (t3, (Less(e1,e2)))
  |Tok_LessEqual ->let t2 = match_token t1 Tok_LessEqual in
            let t3, e2 = parseR t2 in
            (t3, (LessEqual(e1,e2)))
  |Tok_GreaterEqual ->let t2 = match_token t1 Tok_GreaterEqual in
            let t3, e2 = parseR t2 in
            (t3, (GreaterEqual(e1,e2)))
  |_ -> (t1,e1)

  and parseAdd tokens = let t1, e1 = parseM tokens in
  match lookahead t1 with 
  |Tok_Add ->let t2 = match_token t1 Tok_Add in
            let t3, e2 = parseAdd t2 in
            (t3, (Add(e1,e2)))
  |Tok_Sub ->let t2 = match_token t1 Tok_Sub in
            let t3, e2 = parseAdd t2 in
            (t3, (Sub(e1,e2)))
  |_ -> (t1,e1)

  and parseM tokens = let t1, e1 = parseP tokens in
  match lookahead t1 with 
  |Tok_Mult ->let t2 = match_token t1 Tok_Mult in
            let t3, e2 = parseM t2 in
            (t3, (Mult(e1,e2)))
  |Tok_Div ->let t2 = match_token t1 Tok_Div in
            let t3, e2 = parseM t2 in
            (t3, (Div(e1,e2)))
  |_ -> (t1,e1)

  and parseP tokens = let t1, e1 = parseU tokens in
  match lookahead t1 with 
  |Tok_Pow ->let t2 = match_token t1 Tok_Pow in
            let t3, e2 = parseP t2 in
                  (t3, (Pow(e1,e2)))
  |_ -> (t1,e1)

  and parseU tokens = (*idk*)
  match lookahead tokens with 
  |Tok_Not ->let t2 = match_token tokens Tok_Not in
            let t3, e2 = parseU t2 in
            (t3, (Not(e2)))
  |_ -> parsePr tokens 

  and parsePr tokens = match lookahead tokens with 
  |Tok_Bool(x) ->let t = match_token tokens (Tok_Bool(x)) in
                (t, Bool(x))
  |Tok_Int(x) ->let t = match_token tokens (Tok_Int(x)) in
                (t, Int(x))
  |Tok_ID(x) ->let t = match_token tokens (Tok_ID(x)) in
                (t, ID(x))
  |Tok_LParen ->let t = match_token tokens (Tok_LParen) in
                let t, e = parseO t in
                let t = match_token t (Tok_RParen) in
                (t,e)
  |_ -> raise (InvalidInputException (string_of_list string_of_token tokens)) in

  parseO toks

let rec parse_stmt toks : stmt_result =

  match lookahead toks with
  | Tok_ID(x) -> let t2 = match_token toks (Tok_ID(x)) in
                let t2 = match_token t2 (Tok_Assign) in
                let t3, e2 = parse_expr t2 in
                let t5 = match_token t3 (Tok_Semi) in
                if if_bracket t5 then (t5, Seq(Assign(x,e2), NoOp)) else
                let t4, e3 = parse_stmt t5 in
                (t4, Seq(Assign(x,e2), e3))
  | Tok_Int_Type -> let t1 = match_token toks (Tok_Int_Type) in
                (match lookahead t1 with
                  Tok_ID(x)-> let t2 = match_token t1 (Tok_ID(x)) in
                              let t2 = match_token t2 (Tok_Semi) in
                              if if_bracket t2 then (t2, Seq(Declare(Int_Type, x), NoOp))
                              else
                              let t3, e = parse_stmt t2 in
                              (t3, Seq(Declare(Int_Type, x), e))
                  | _ -> raise (InvalidInputException "wrong token (int_type)")    )
  | Tok_Bool_Type  -> let t1 = match_token toks (Tok_Bool_Type) in
                  (match lookahead t1 with
                  Tok_ID(x)-> let t2 = match_token t1 (Tok_ID(x)) in
                              let t2 = match_token t2 (Tok_Semi) in
                              if if_bracket t2 then (t2, Seq(Declare(Bool_Type, x), NoOp)) else
                              let t3, e = parse_stmt t2 in
                              (t3, Seq(Declare(Bool_Type, x), e))
                  |_ -> raise (InvalidInputException  "wrong token (bool type)")    )
  | Tok_Print -> let t1 = match_token toks (Tok_Print) in
                let t2 = match_token t1 (Tok_LParen) in 
                let t3, e1 = parse_expr t2 in
                let t4 = match_token t3 (Tok_RParen) in
                let t5 = match_token t4 (Tok_Semi) in
                if if_bracket t5 then (t5, Seq(Print(e1), NoOp)) else
                let t6, e2 = parse_stmt t5 in 
                (t6, Seq(Print(e1), e2))
  | Tok_If -> let t1 = match_token toks (Tok_If) in
              let t1 = match_token t1 (Tok_LParen) in
              let t1, e1 = parse_expr t1 in
              let t1 = match_token t1 (Tok_RParen) in
              let t1 = match_token t1 (Tok_LBrace) in
              let t1, e2 = if if_bracket t1 then (t1, NoOp) else parse_stmt t1 in
              let t1 = match_token t1 (Tok_RBrace) in
              (match lookahead t1 with
                Tok_Else -> let t1 = match_token t1 (Tok_Else) in
                            let t1 = match_token t1 (Tok_LBrace) in
                            let t1, e3 = if if_bracket t1 then (t1, NoOp) else parse_stmt t1 in
                            let t1 = match_token t1 (Tok_RBrace) in

                            if if_bracket t1 then (t1, Seq(If(e1,e2,e3), NoOp)) else
                            let t1, e4 = parse_stmt t1 in
                             (t1, Seq(If(e1,e2,e3), e4))
                |_ -> if if_bracket t1 then (t1, Seq(If(e1,e2,NoOp), NoOp)) else
                      let t1, e3 = parse_stmt t1 in
                      (t1, Seq( If(e1,e2,NoOp), e3))      )
  | Tok_For-> let t = match_token toks (Tok_For) in
              let t = match_token t (Tok_LParen) in 
              begin 
              match lookahead t with
              Tok_ID(x) ->let t = match_token t (Tok_ID(x)) in
                          let t = match_token t (Tok_From) in
                          let t, e1 = parse_expr t in
                          let t = match_token t (Tok_To) in
                          let t, e2 = parse_expr t in
                          let t = match_token t (Tok_RParen) in
                          let t = match_token t (Tok_LBrace) in 
                          let t, e3 = if if_bracket t then (t, NoOp) else parse_stmt t in
                          let t = match_token t (Tok_RBrace) in
                          if if_bracket t then (t, Seq(For(x,e1,e2,e3), NoOp)) else
                          let t, e4 = parse_stmt t in
                          (t, Seq(For(x,e1,e2,e3), e4))
              |_ -> raise (InvalidInputException  "wrong token (For)")
              end
  | Tok_While ->let t = match_token toks (Tok_While) in
                let t = match_token t (Tok_LParen) in
                let t, e1 = parse_expr t in
                let t = match_token t (Tok_RParen) in
                let t = match_token t (Tok_LBrace) in
                let t, e2 = if if_bracket t then (t, NoOp) else parse_stmt t in
                let t = match_token t (Tok_RBrace) in
                if if_bracket t then (t, Seq(While(e1,e2), NoOp)) else
                let t, e3 = parse_stmt t in
                (t, Seq(While(e1,e2), e3))
  | EOF -> (toks, NoOp)
  | _ -> raise (InvalidInputException  "wrong token (stmt end)")

let parse_main toks : stmt =
  let t = match_token toks (Tok_Int_Type) in
  let t = match_token t (Tok_Main) in
  let t = match_token t (Tok_LParen) in
  let t = match_token t (Tok_RParen) in
  let t = match_token t (Tok_LBrace) in
  if if_bracket t then NoOp else
  let t, e = parse_stmt t in
  let t = match_token t (Tok_RBrace) in
  let _ = match_token t (EOF) in
  e
