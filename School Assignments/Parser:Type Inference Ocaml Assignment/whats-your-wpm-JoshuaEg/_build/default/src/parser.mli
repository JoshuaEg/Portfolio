
(* The type of tokens. *)

type token = 
  | WHILE
  | TO
  | SEMI
  | RPAREN
  | READ
  | RBRACE
  | PRINT
  | POW
  | PLUS
  | OR
  | NOT
  | NE
  | MULT
  | MINUS
  | MAIN
  | LT
  | LPAREN
  | LE
  | LBRACE
  | INTTYPE
  | INT of (int)
  | IF
  | IDENT of (string)
  | GT
  | GE
  | FROM
  | FOR
  | EQUALS
  | EOF
  | ELSE
  | DIV
  | BOOL of (bool)
  | ASSIGNS
  | AND

(* This exception is raised by the monolithic API functions. *)

exception Error

(* The monolithic API. *)

val prog: (Lexing.lexbuf -> token) -> Lexing.lexbuf -> (Ast.stmt)
