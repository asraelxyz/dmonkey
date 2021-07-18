// Written in the D programming language.

module dmonkey.token;

enum TokenType {
  ILLEGAL = "ILLEGAL",
	EOF     = "EOF",

	// Identifiers + literals
	IDENT  = "IDENT", // add, foobar, x, y, ...
	INT    = "INT",   // 1343456
	STRING = "STRING",

	// Operators
	ASSIGN   = "=",
	PLUS     = "+",
	MINUS    = "-",
	BANG     = "!",
	ASTERISK = "*",
	SLASH    = "/",

	LT = "<",
	GT = ">",

	EQ     = "==",
	NOT_EQ = "!=",

	// Delimiters
	COMMA     = ",",
	SEMICOLON = ";",
	LPAREN    = "(",
	RPAREN    = ")",
	LBRACE    = "{",
	RBRACE    = "}",
	LBRAKET   = "[",
	RBRAKET   = "]",
	COLON     = ":",

	// Keywords
	FUNCTION = "FUNCTION",
	LET      = "LET",
	TRUE     = "TRUE",
	FALSE    = "FALSE",
	IF       = "IF",
	ELSE     = "ELSE",
	RETURN   = "RETURN",
}

struct Token {
	TokenType type;
	dstring literal;
}

TokenType LookupIdent(dstring ident) {
  switch (ident) {
    case "fn":
      return TokenType.FUNCTION;
    case "let":
      return TokenType.LET;
  	case "true":
  	  return TokenType.TRUE;
  	case "false":
  	  return TokenType.FALSE;
  	case "if":
  	  return TokenType.IF;
  	case "else":
  	   return TokenType.ELSE;
  	case "return":
  	   return TokenType.RETURN;
    default:
      return TokenType.IDENT;
  }
}
