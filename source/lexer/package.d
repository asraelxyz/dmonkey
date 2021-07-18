// Written in the D programming language.

module dmonkey.lexer;
import dmonkey.token;
import std.uni: isAlpha;

bool isDigit(dchar c) {
  return c >= '0' && '9' >= c;
}

class Lexer {
	dstring input;
	// current position in input (points to current char)
	int position;
	// current reading position in input (after current char)
	int read_position;
	// current char under examination
	dchar chr;

	this(dstring input) {
	  this.input = input;
	  this.readChar();
	}

	void readChar() {
  	if (this.read_position >= this.input.length) {
  		this.chr = '\0';
  	} else {
  		this.chr = this.input[this.read_position];
  	}

  	this.position = this.read_position;
  	this.read_position += 1;
  }

  Token NextToken() {
	 Token tok;

	this.skipWhitespace();

	switch (this.chr) {
	case '=':
		if (this.peekChar() == '=') {
			dchar ch = this.chr;
			this.readChar();
			tok = Token(TokenType.EQ, cast(dstring)[ch, this.chr]);
		} else {
			tok = newToken(TokenType.ASSIGN, this.chr);
		}
		break;
	case '+':
		tok = newToken(TokenType.PLUS, this.chr);
		break;
	case '-':
		tok = newToken(TokenType.MINUS, this.chr);
		break;
	case '!':
		if (this.peekChar() == '=') {
			dchar ch = this.chr;
			this.readChar();
			tok = Token(TokenType.NOT_EQ, cast(dstring)[ch, this.chr]);
		} else {
			tok = newToken(TokenType.BANG, this.chr);
		}
		break;
	case '/':
		tok = newToken(TokenType.SLASH, this.chr);
		break;
	case '*':
		tok = newToken(TokenType.ASTERISK, this.chr);
		break;
	case '<':
		tok = newToken(TokenType.LT, this.chr);
		break;
	case '>':
		tok = newToken(TokenType.GT, this.chr);
		break;
	case ';':
		tok = newToken(TokenType.SEMICOLON, this.chr);
		break;
	case '(':
		tok = newToken(TokenType.LPAREN, this.chr);
		break;
	case ')':
		tok = newToken(TokenType.RPAREN, this.chr);
		break;
	case ',':
		tok = newToken(TokenType.COMMA, this.chr);
		break;
	case '{':
		tok = newToken(TokenType.LBRACE, this.chr);
		break;
	case '}':
		tok = newToken(TokenType.RBRACE, this.chr);
		break;
	case '[':
		tok = newToken(TokenType.LBRAKET, this.chr);
		break;
	case ']':
		tok = newToken(TokenType.RBRAKET, this.chr);
		break;
	case ':':
		tok = newToken(TokenType.COLON, this.chr);
		break;
	case '"':
	  tok = Token(TokenType.STRING, this.readString());
	  break;
	case '\0':
		tok.literal = "";
		tok.type = TokenType.EOF;
		break;
	default:
		if (isAlpha(this.chr)) {
			tok.literal = this.readIdentifier();
			tok.type = LookupIdent(tok.literal);
			return tok;
		} else if (isDigit(this.chr)) {
			tok.type = TokenType.INT;
			tok.literal = this.readNumber();
			return tok;
		} else {
			tok = newToken(TokenType.ILLEGAL, this.chr);
		}
		break;
	}

	this.readChar();
	return tok;
}

  dchar peekChar() {
  	if (this.read_position >= this.input.length) {
  		return '\0';
  	}

	  return this.input[this.read_position];
  }

  // import std.ascii : isAlphaNum;
  // import std.ascii : isDigit, isAlpha, isPrintable;
  // assert(!"ab1".endsWith!(a => a.isAlpha));


  dstring readIdentifier() {
  	int pos = this.position;
  	while (isAlpha(this.chr) || isDigit(this.chr) || this.chr == '_') {
  		this.readChar();
  	}

  	  return this.input[pos..this.position];
  }

  dstring readNumber() {
  	int pos = this.position;
  	while (isDigit(this.chr)) {
      this.readChar();
  	}
  	return this.input[pos..this.position];
  }

   void skipWhitespace() {
    while (this.chr == ' ' || this.chr == '\t' || this.chr == '\n' || this.chr == '\r') {
      this.readChar();
  }
  }

  dstring readString() {
	int pos = this.position + 1;
	while (true) {
		this.readChar();
		if (this.chr == '"') { break; }
	}
	  return this.input[pos..this.position];
  }

}

Token newToken(TokenType type, dchar c) {
  Token tk = {type, cast(dstring)[c]};
  return tk;
}

