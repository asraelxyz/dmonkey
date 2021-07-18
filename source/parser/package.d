module dmonkey.parser;

import dmonkey.ast;
import dmonkey.lexer;
import dmonkey.token;
import std.stdio;
import std.format: format;
import std.utf: toUTF32;
import std.conv: to;

enum Action {
	LOWEST,
	EQUALS,      // ==
	LESSGREATER, // > or <
	SUM,         // +
	PRODUCT,     // *
	PREFIX,      // -X or !X
	CALL,        // myFunction(X)
	INDEX        // array[index]
}


//auto prefixParseFn = Expression(void);
//nothrow {
alias PrefixParseFn = Expression delegate();
alias InfixParseFn  = Expression delegate(Expression);
//}

/*Action[TokenType] precedences = [
	TokenType.EQ:       Action.EQUALS,
];
*/

Action *precedences(TokenType tk_ty) {
	Action[TokenType] pre = [
		TokenType.EQ:       Action.EQUALS,
		TokenType.NOT_EQ:   Action.EQUALS,
		TokenType.LT:       Action.LESSGREATER,
		TokenType.GT:       Action.LESSGREATER,
		TokenType.PLUS:     Action.SUM,
		TokenType.MINUS:    Action.SUM,
		TokenType.SLASH:    Action.PRODUCT,
		TokenType.ASTERISK: Action.PRODUCT,
		TokenType.LPAREN:   Action.CALL,
		TokenType.LBRAKET:  Action.INDEX,
	];
	return tk_ty in pre;
}

class Parser {
private {
	Lexer *lex;  // antes l
	dstring[] xerrors;

	Token curToken;
	Token peekToken;

	PrefixParseFn[TokenType] prefixParseFns;
	InfixParseFn[TokenType] infixParseFns;
}

	this(Lexer* lex) {
		this.lex = lex;
		this.xerrors = [];
		// Read two tokens, so curToken and peekToken are both set
		this.nextToken();
		this.nextToken();

		this.registerPrefix(TokenType.IDENT, &this.parseIdentifier);
		this.registerPrefix(TokenType.INT, &this.parseIntegerLiteral);
		this.registerPrefix(TokenType.BANG, &this.parsePrefixExpression);
		this.registerPrefix(TokenType.MINUS, &this.parsePrefixExpression);
		this.registerPrefix(TokenType.TRUE, &this.parseBoolean);
		this.registerPrefix(TokenType.FALSE, &this.parseBoolean);
		this.registerPrefix(TokenType.LPAREN, &this.parseGroupedExpression);
		this.registerPrefix(TokenType.IF, &this.parseIfExpression);
		this.registerPrefix(TokenType.FUNCTION, &this.parseFunctionLiteral);
		this.registerPrefix(TokenType.STRING, &this.parseStringLiteral);
		this.registerPrefix(TokenType.LBRAKET, &this.parseArrayLiteral);
		this.registerPrefix(TokenType.LBRACE, &this.parseHashLiteral);


		this.registerInfix(TokenType.PLUS, &this.parseInfixExpression);
		this.registerInfix(TokenType.MINUS, &this.parseInfixExpression);
		this.registerInfix(TokenType.SLASH, &this.parseInfixExpression);
		this.registerInfix(TokenType.ASTERISK, &this.parseInfixExpression);
		this.registerInfix(TokenType.EQ, &this.parseInfixExpression);
		this.registerInfix(TokenType.NOT_EQ, &this.parseInfixExpression);
		this.registerInfix(TokenType.LT, &this.parseInfixExpression);
		this.registerInfix(TokenType.GT, &this.parseInfixExpression);
		this.registerInfix(TokenType.LPAREN, &this.parseCallExpression);
		this.registerInfix(TokenType.LBRAKET, &this.parseIndexExpression);
	}

	@property dstring[] errors() {
	    return this.xerrors;
	}

	Program parseProgram() {
		auto program = new Program();

		while (this.curToken.type != TokenType.EOF) {
			Statement stmt = this.parseStatement();
			if (stmt !is null) {
				program.statements ~= stmt;
			}
			this.nextToken();
		}

		return program;
	}

private:
	void nextToken() {
		this.curToken =  this.peekToken;
	    this.peekToken = this.lex.NextToken();
	}

	void registerPrefix(TokenType tkType, PrefixParseFn fn) {
		this.prefixParseFns[tkType] = fn;
	}

	Expression parseIdentifier() {
		return new Identifier(this.curToken, this.curToken.literal);
	}

	void registerInfix(TokenType tkType, InfixParseFn fn) {
		this.infixParseFns[tkType] = fn;
	}

	void noPrefixParseFnError(TokenType t) {
		string msg = "no prefix parse function for %s found".format(t);
		this.xerrors ~= msg.toUTF32!();
	}

	Statement parseStatement() {
		switch (this.curToken.type) {
			case TokenType.LET:
				return this.parseLetStatement();
			case TokenType.RETURN:
				return this.parseReturnStatement();
			default:
				return this.parseExpressionStatement();
		}
	}

	LetStatement parseLetStatement() {
		LetStatement stmt = new LetStatement(this.curToken);

		if (!this.expectPeek(TokenType.IDENT)) {
			return null;
		}

		stmt.name = new Identifier(this.curToken, this.curToken.literal);

		if (!this.expectPeek(TokenType.ASSIGN)) {
			return null;
		}

		this.nextToken();

		stmt.value = this.parseExpression(Action.LOWEST);

		if (this.peekTokenIs(TokenType.SEMICOLON)) {
			this.nextToken();
		}

		return stmt;
	}

	ReturnStatement parseReturnStatement() {
		ReturnStatement stmt = new ReturnStatement(this.curToken);

		this.nextToken();

		stmt.return_value =  this.parseExpression(Action.LOWEST);

		if (this.peekTokenIs(TokenType.SEMICOLON)) {
			this.nextToken();
		}

		return stmt;
	}

	ExpressionStatement parseExpressionStatement() {
		ExpressionStatement stmt = new ExpressionStatement(this.curToken);
		stmt.expression = this.parseExpression(Action.LOWEST);

		if (this.peekTokenIs(TokenType.SEMICOLON)) {
			this.nextToken();
		}

		return stmt;
	}

	Expression parseExpression(int precedence){
		PrefixParseFn* prefix = this.curToken.type in this.prefixParseFns;
		if (prefix is null) {
			this.noPrefixParseFnError(this.curToken.type);
			return null;
		}

		Expression left_exp = (*prefix)(); // Call to function*

		while (!this.peekTokenIs(TokenType.SEMICOLON) && precedence < this.peekPrecedence()) {
			InfixParseFn* infix = this.peekToken.type in this.infixParseFns;
			if (infix is null) {
				return left_exp;
			}

			this.nextToken();
			left_exp = (*infix)(left_exp); // Call to function*
		}

		return left_exp;
	}

	Expression parseIntegerLiteral() {
		IntegerLiteral lit = new IntegerLiteral(this.curToken);

		long value = to!long(this.curToken.literal);
		// WARNING: Rapair in the future!
		auto err = false;
		//if (err) {
		if (err) {
			auto msg = format("could not parse %s as integer", this.curToken.literal);
			this.xerrors ~= msg.toUTF32!();
			return null;
		}

		lit.value = value;
		return lit;
	}

	Expression parsePrefixExpression() {
		PrefixExpression expression = new PrefixExpression(this.curToken, this.curToken.literal);

		this.nextToken();

		expression.right = this.parseExpression(Action.PREFIX);

		return expression;
	}

	Expression parseInfixExpression(Expression left) {
		auto expression = new InfixExpression(this.curToken, left, this.curToken.literal);

		int precedence = this.curPrecedence();
		this.nextToken();
		expression.right = this.parseExpression(precedence);

		return expression;
	}

	Expression parseBoolean() {
		return new Boolean(this.curToken, this.curTokenIs(TokenType.TRUE));
	}

	Expression parseGroupedExpression() {
		this.nextToken();

		Expression exp = this.parseExpression(Action.LOWEST);

		if (!this.expectPeek(TokenType.RPAREN)) {
			return null;
		}

		return exp;
	}

	Expression parseIfExpression() {
		IfExpression expression = new IfExpression(this.curToken);

		if (!this.expectPeek(TokenType.LPAREN)) {
			return null;
		}

		this.nextToken();
		expression.condition = this.parseExpression(Action.LOWEST);

		if (!this.expectPeek(TokenType.RPAREN)) {
			return null;
		}

		if (!this.expectPeek(TokenType.LBRACE)) {
			return null;
		}

		expression.consequence = this.parseBlockStatement();

		if (this.peekTokenIs(TokenType.ELSE)){
			this.nextToken();

			if (!this.expectPeek(TokenType.LBRACE)) {
				return null;
			}

			expression.alternative = this.parseBlockStatement();
		}

		return expression;
	}

	BlockStatement parseBlockStatement() {
		BlockStatement block = new BlockStatement(this.curToken);

		this.nextToken();

		while (!this.curTokenIs(TokenType.RBRACE)) {
			auto stmt = this.parseStatement();
			if (stmt !is null) {
				block.statements ~= stmt;
			}
			this.nextToken();
		}

		return block;
	}

	Expression parseFunctionLiteral() {
		FunctionLiteral lit = new FunctionLiteral(this.curToken);

		if (!this.expectPeek(TokenType.LPAREN)) {
			return null;
		}

		lit.parameters = this.parseFunctionParameters();

		if (!this.expectPeek(TokenType.LBRACE)) {
			return null;
		}

		lit.body = this.parseBlockStatement();

		return lit;
	}

	Identifier[] parseFunctionParameters() {
		Identifier[] identifiers;

		if (this.peekTokenIs(TokenType.RPAREN)) {
			this.nextToken();
			return identifiers;
		}

		this.nextToken();

		Identifier ident = new Identifier(this.curToken, this.curToken.literal);

		identifiers ~= ident;

		while (this.peekTokenIs(TokenType.COMMA)) {
			this.nextToken();
			this.nextToken();
			ident = new Identifier(this.curToken, this.curToken.literal);
			identifiers ~= ident; 
		}

		if (!this.expectPeek(TokenType.RPAREN)) {
			return null;
		}

		return identifiers;
	}

	Expression parseCallExpression(Expression xfun) {
		CallExpression exp = new CallExpression(this.curToken, xfun);
		exp.arguments = this.parseExpressionList(TokenType.RPAREN);
		return exp;
	}

	Expression[] parseCallArguments() {
		Expression[] args;

		if (this.peekTokenIs(TokenType.RPAREN)) {
			this.nextToken();
			return args;
		}

		this.nextToken();
		args ~= this.parseExpression(Action.LOWEST);

		while (this.peekTokenIs(TokenType.COMMA)) {
			this.nextToken();
			this.nextToken();
			args ~= this.parseExpression(Action.LOWEST);
		}

		if (!this.expectPeek(TokenType.RPAREN)) {
			return null;
		}

		return args;
	}

	Expression parseStringLiteral() {
		return new StringLiteral(this.curToken, this.curToken.literal);
	}

	Expression parseArrayLiteral() {
		ArrayLiteral array = new ArrayLiteral(this.curToken);

		array.elements = this.parseExpressionList(TokenType.RBRAKET);

		return array;
	}

	Expression[] parseExpressionList(TokenType end) {
		Expression[] list;

		if (this.peekTokenIs(end)) {
			this.nextToken();
			return list;
		}

		this.nextToken();
		list ~= this.parseExpression(Action.LOWEST);

		while (this.peekTokenIs(TokenType.COMMA)) {
			this.nextToken();
			this.nextToken();
			list ~= this.parseExpression(Action.LOWEST);
		}

		if (!this.expectPeek(end)) {
			return null;
		}
		
		return list;
	}

	Expression parseIndexExpression(Expression left) {
		IndexExpression exp = new IndexExpression(this.curToken, left);

		this.nextToken();
		exp.index = this.parseExpression(Action.LOWEST);

		if (!this.expectPeek(TokenType.RBRAKET)) {
			return null;
		}

		return exp;
	}

	Expression parseHashLiteral() {
		HashLiteral hash = new HashLiteral(this.curToken);
		// hash.pairs = make(map[ast.Expression]ast.Expression)

		while (!this.peekTokenIs(TokenType.RBRACE)) {
			this.nextToken();
			auto key = this.parseExpression(Action.LOWEST);

			if (!this.expectPeek(TokenType.COLON)) {
				return null;
			}

			this.nextToken();
			auto value = this.parseExpression(Action.LOWEST);

			hash.pairs[key] = value;

			if (!this.peekTokenIs(TokenType.RBRACE) && !this.expectPeek(TokenType.COMMA)) {
				return null;
			}
		}

		if (!this.expectPeek(TokenType.RBRACE)) {
			return null;
		}

		return hash;
	}

	bool curTokenIs(TokenType t) {
		return this.curToken.type == t;
	}

	bool peekTokenIs(TokenType t) {
		return this.peekToken.type == t;
	}

	int peekPrecedence() {
		Action *p = precedences(this.peekToken.type);
		if (p !is null) {
			return *p;
		}

		return Action.LOWEST;
	}

	int curPrecedence() {
		Action *p = precedences(this.peekToken.type);
		if (p !is null) {
			return *p;
		}

		return Action.LOWEST;
	}

	bool expectPeek(TokenType t) {
		if (this.peekTokenIs(t)) {
			this.nextToken();
			return true;
		}

		this.peekError(t);
		return false;
	}

	void peekError(TokenType t) {
		string msg = format("expected next token to be %s, got %s instead", cast(string)t, this.peekToken.type);
		this.xerrors ~= msg.toUTF32!(); 
	}
}
