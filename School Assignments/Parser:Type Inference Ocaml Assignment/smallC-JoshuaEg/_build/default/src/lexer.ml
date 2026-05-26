open TokenTypes

let re_bool = Re.Str.regexp "true\\b\\|false\\b"
let re_int = Re.Str.regexp "-?[0-9]+"
let re_str = Re.Str.regexp "[a-zA-Z][a-zA-Z0-9]*"

let leftP = Re.Str.regexp "("
let rightP = Re.Str.regexp ")"
let leftB = Re.Str.regexp "{"
let rightB = Re.Str.regexp "}"

let assign = Re.Str.regexp "="

let equal = Re.Str.regexp "=="
let notequal = Re.Str.regexp "!="

let less = Re.Str.regexp "<"
let great = Re.Str.regexp ">"
let eqless = Re.Str.regexp "<="
let eqgreat = Re.Str.regexp ">="

let c_or = Re.Str.regexp "||"
let c_and = Re.Str.regexp "&&"
let c_not = Re.Str.regexp "!"
let semi = Re.Str.regexp ";"

let int_type = Re.Str.regexp "int\\b"
let bool_type = Re.Str.regexp "bool\\b"

let c_if = Re.Str.regexp "if\\b"
let c_else = Re.Str.regexp "else\\b"
let c_for = Re.Str.regexp "for\\b"
let c_while = Re.Str.regexp "while\\b"
let from = Re.Str.regexp "from\\b"
let c_to = Re.Str.regexp "to\\b"

let main = Re.Str.regexp "main\\b"
let prints = Re.Str.regexp "printf\\b"

let add = Re.Str.regexp "\\+"
let sub = Re.Str.regexp "-"
let div = Re.Str.regexp "/"
let mul = Re.Str.regexp "\\*"
let pow = Re.Str.regexp "\\^"

let white_space = Re.Str.regexp "[\n\r\t \b]"




let tokenize input =

  let rec tok pos s = 
    if pos >= String.length s then [EOF]
    else
    if (Re.Str.string_match re_bool s pos) then
      let token = Re.Str.matched_string s in 
      let tembool = ((String.length token) = 4) in
      (Tok_Bool tembool) :: (tok (pos + (String.length token)) s)
    else if (Re.Str.string_match re_int s pos) then
      let token = Re.Str.matched_string s in (Tok_Int (int_of_string token)) :: (tok (pos + (String.length token)) s)


    else if (Re.Str.string_match leftP s pos) then (Tok_LParen) :: (tok (pos + 1) s)
    else if (Re.Str.string_match rightP s pos) then (Tok_RParen) :: (tok (pos + 1) s)
    else if (Re.Str.string_match leftB s pos) then (Tok_LBrace) :: (tok (pos + 1) s)
    else if (Re.Str.string_match rightB s pos) then (Tok_RBrace) :: (tok (pos + 1) s)
    else if (Re.Str.string_match equal s pos) then (Tok_Equal) :: (tok (pos + 2) s)
    else if (Re.Str.string_match notequal s pos) then (Tok_NotEqual) :: (tok (pos + 2) s)

    else if (Re.Str.string_match assign s pos) then (Tok_Assign) :: (tok (pos + 1) s)

    
    else if (Re.Str.string_match eqless s pos) then (Tok_LessEqual) :: (tok (pos + 2) s)
    else if (Re.Str.string_match eqgreat s pos) then (Tok_GreaterEqual) :: (tok (pos + 2) s)
    else if (Re.Str.string_match less s pos) then (Tok_Less) :: (tok (pos + 1) s)
    else if (Re.Str.string_match great s pos) then (Tok_Greater) :: (tok (pos + 1) s)

    else if (Re.Str.string_match c_or s pos) then (Tok_Or) :: (tok (pos + 2) s)
    else if (Re.Str.string_match c_and s pos) then (Tok_And) :: (tok (pos + 2) s)
    else if (Re.Str.string_match c_not s pos) then (Tok_Not) :: (tok (pos + 1) s)
    else if (Re.Str.string_match semi s pos) then (Tok_Semi) :: (tok (pos + 1) s)

    else if (Re.Str.string_match int_type s pos) then (Tok_Int_Type) :: (tok (pos + 3) s)
    else if (Re.Str.string_match bool_type s pos) then (Tok_Bool_Type) :: (tok (pos + 4) s)
    else if (Re.Str.string_match main s pos) then (Tok_Main) :: (tok (pos + 4) s)

    else if (Re.Str.string_match c_if s pos) then (Tok_If) :: (tok (pos + 2) s)
    else if (Re.Str.string_match c_while s pos) then (Tok_While) :: (tok (pos + 5) s)
    else if (Re.Str.string_match c_else s pos) then (Tok_Else) :: (tok (pos + 4) s)
    else if (Re.Str.string_match c_for s pos) then (Tok_For) :: (tok (pos + 3) s)
    else if (Re.Str.string_match from s pos) then (Tok_From) :: (tok (pos + 4) s)
    else if (Re.Str.string_match c_to s pos) then (Tok_To) :: (tok (pos + 2) s)

    else if (Re.Str.string_match prints s pos) then (Tok_Print) :: (tok (pos + 6) s)

    else if (Re.Str.string_match add s pos) then (Tok_Add) :: (tok (pos + 1) s)
    else if (Re.Str.string_match sub s pos) then (Tok_Sub) :: (tok (pos + 1) s)
    else if (Re.Str.string_match mul s pos) then (Tok_Mult) :: (tok (pos + 1) s)
    else if (Re.Str.string_match div s pos) then (Tok_Div) :: (tok (pos + 1) s)
    else if (Re.Str.string_match pow s pos) then (Tok_Pow) :: (tok (pos + 1) s)
    
    else if (Re.Str.string_match re_str s pos) then
      let token = Re.Str.matched_string s in (Tok_ID token) :: (tok (pos + (String.length token)) s)
    else if (Re.Str.string_match white_space s pos) then (tok (pos + 1) s) 
    else raise (InvalidInputException("lexer skill issue")) in

    tok 0 input
  