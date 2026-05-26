(* The type of the abstract syntax tree (AST). *)
exception InvalidInputException of string

(* error types *)
exception TypeError of string
exception DeclareError of string
exception DivByZeroError

type op =
  | Add
  | Sub
  | Mult
  | Div
  | Pow
  | Greater
  | Less
  | GreaterEqual
  | LessEqual
  | Equal
  | NotEqual
  | Or
  | And
[@@deriving show { with_path = false }]

type var = string [@@deriving show { with_path = false }]

type exptype =
  | Int_Type
  | Bool_Type
  | Unknown_Type of int
[@@deriving show { with_path = false }]

type expr =
  | Int of int
  | Bool of bool
  | ID of var
  | Binop of op * expr * expr
  | Not of expr
  | Value
[@@deriving show { with_path = false }]

type stmt =
  | NoOp                                  (* For parser termination *)
  | Seq of stmt * stmt                    (* True sequencing instead of lists *)
  | Assign of string * exptype * expr
  | If of expr * stmt * stmt              
  | For of string * expr * expr * stmt    
  | While of expr * stmt                  (* Guard is an expr, body is a stmt *)
  | Print of expr                         (* Print the result of an expression *)
[@@deriving show { with_path = false }]

type value =
  | Int_Val of int
  | Bool_Val of bool
  | Unknown_Val

type environment = (string * value) list

let c = ref 0
let fresh () = let r = !c in c:= !c + 1; r
let reset () = c:= 0





