module dmonkey.ast;

import dmonkey.token;
import std.array: join;
import std.stdio;

abstract class Node {
  dstring tokenLiteral();
  dstring string();
}

abstract class Statement: Node {
	void statementNode();
}

abstract class Expression: Node {
  void expressionNode();
}

class Program: Node {
	Statement[] statements;

  this() { }

	override dstring tokenLiteral() {
	  if (this.statements.length > 0 ) {
		  return this.statements[0].tokenLiteral();
	  }

	  return "";
  }

  override dstring string()  {
  	dstring xout;

  	foreach(_, s; this.statements) {
  	  xout ~= " "d ~ s.string();
  	}

  	return xout;
  }

}

class LetStatement: Statement {
	Token token; // the token.LET token
	Identifier name;
	Expression value;

  this(Token tk) {
    this.token = tk;
  }

	override void statementNode() {}

  override dstring tokenLiteral() {
  	return this.token.literal;
  }

  override dstring string() {
  	dstring xout;
  	xout ~= this.tokenLiteral() ~ " ";
  	xout ~= this.name.string();
  	xout ~= " = ";

  	if (this.value !is null) {
  	  xout ~= this.value.string();
  	}
  	xout ~= ";";

  	return xout;
  }
}

class Identifier: Expression {
	Token token; // the token.IDENT token
	dstring value;

  this(Token tk, dstring val) {
    this.token = tk;
    this.value = val;

  }

	override void expressionNode() {}
  override dstring tokenLiteral() {
  	return this.token.literal;
  }

  override dstring string() {
  	return this.value;
  }
}


class ReturnStatement: Statement {
	Token  token; // the `return` token
	Expression return_value;
  this(Token tk) {
    this.token = tk;
  }

	override void statementNode() {}
  override dstring tokenLiteral() {
  	return this.token.literal;
  }

  override dstring string() {
  	dstring xout;
  	xout ~= this.tokenLiteral() ~ " ";

  	if (this.return_value !is null) {
  	  xout ~= this.return_value.string();
  	}

  	xout ~= ";";
  	return xout;
  }
}

class ExpressionStatement: Statement {
	Token  token; // the first token of the expression
	Expression expression;

  this(Token tk) {
    this.token = tk;
  }

	override void statementNode() {}
  override dstring tokenLiteral() {
  	return this.token.literal;
  }

  override dstring string() {
  	if (this.expression !is null) {
  		return this.expression.string();
  	}

  	return "";
  }
}


class IntegerLiteral: Expression {
	Token token;
	long value;

  this(Token tk) {
    this.token = tk;
  }

	override void expressionNode() {}

  override dstring tokenLiteral() {
  	return this.token.literal;
  }

  override dstring string() {
  	return this.token.literal;
  }
}

class PrefixExpression: Expression {
	Token token; // The prefix token, e.g. !
	dstring operator;
	Expression right;

  this(Token tk, dstring op) {
    this.token = tk;
    this.operator = op;
  }

	override void expressionNode() {}
  override dstring tokenLiteral() {
  	return this.token.literal;
  }

  override dstring string() {
    dstring xout = "("d ~ this.operator;
    xout ~= this.right.string() ~ ")";
  	return xout;
  }
}

class InfixExpression: Expression {
	Token    token; // The operator tokne, e.g. +
	Expression left;
	dstring operator;
	Expression right;

  this(Token tk, Expression lt, dstring op) {
    this.token = tk;
    this.left = lt;
    this.operator = op;

  }
	override void expressionNode() {}
  override dstring tokenLiteral() {
  	return this.token.literal;
  }

  override dstring string() {
  	dstring xout = "(" ~ this.left.string();
  	xout ~= " " ~ this.operator ~ " ";
  	xout ~= this.right.string() ~ ")";

  	return xout;
  }
}


class Boolean: Expression {
	Token token;
	bool value;

  this(Token tk, bool val) {
    this.token = tk;
    this.value = val;
  }

	override void expressionNode() {}
  override dstring tokenLiteral() {
  	return this.token.literal;
  }
  override dstring string() {
  	return this.token.literal;
  }
}

class IfExpression: Expression {
	Token       token; // The 'if' token
	Expression condition;
	BlockStatement consequence;
	BlockStatement alternative;

  this(Token tk) {
    this.token = tk;
  }

	override void expressionNode() {}
  override dstring tokenLiteral() {
  	return this.token.literal;
  }

  override dstring string() {
  	dstring xout = "if";
  	xout ~= this.condition.string() ~ " ";
  	xout ~= this.consequence.string();

  	if (this.alternative !is null) {
  	  xout ~= "else ";
  	  xout ~= this.alternative.string();
  	}

  	return xout;
  }
}

class BlockStatement: Expression {
	Token token; // the { token
	Statement[] statements;

  this(Token tk) {
    this.token = tk;
    this.statements = [];
  }

	override void expressionNode() {}
  override dstring tokenLiteral() {
  	return this.token.literal;
  }

  override dstring string() {
    dstring xout;

  	foreach (_, s; this.statements) {
  	  xout ~= s.string();
  	}

  	return xout;
  }
}

class FunctionLiteral: Expression {
	Token      token; // The 'fn' token
	Identifier[] parameters;
	BlockStatement body;

  this(Token tk) {
    this.token = tk;
  }

	override void expressionNode() {}
  override dstring tokenLiteral() {
  	return this.token.literal;
  }

  override dstring string() {
  	dstring xout;
  	dstring[] params;

  	foreach(_, p; this.parameters) {
  		params ~= p.string();
  	}
  	xout ~= this.tokenLiteral();
  	xout ~= "(";
  	xout ~= params.join(", ");
  	xout ~= ") ";
  	xout ~= this.body.string();

  	return xout;
  }
}

class CallExpression: Expression {
	Token     token; // the '(' token
	Expression xfunc;  // Identifier or FunctionLiteral
	Expression[] arguments;

  this(Token tk,  Expression xfun) {
    this.token = tk;
    this.xfunc = xfunc;
  }

	override void expressionNode() {}
  override dstring tokenLiteral() {
  	return this.token.literal;
  }

  override dstring string() {
  	dstring xout;
  	dstring[] args;

  	foreach(_, a; this.arguments) {
  		args ~= a.string();
  	}
  	xout ~= this.xfunc.string();
  	xout ~= "(";
  	xout ~= args.join(", ");
  	xout ~= ")";
  	return xout;
  }
}

// -------- ---------- ----------
class StringLiteral: Expression {
	Token token;
	dstring value;

  this(Token tk,  dstring val) {
    this.token = tk;
    this.value = val;
  }

	override void expressionNode()      {}
  override dstring tokenLiteral() { return this.token.literal; }
  override dstring string()  { return this.token.literal; }
}

class ArrayLiteral: Expression {
	Token    token; // the `[` token
	Expression[] elements;

  this(Token tk) {
    this.token = tk;
  }

	override void expressionNode()      {}
  override dstring tokenLiteral() { return this.token.literal; }
  override dstring string() {
  	dstring xout;

  	dstring[] elements;
  	foreach(_, el; this.elements) {
  		elements ~= el.string();
  	}
  	xout ~= "[" ~ elements.join(", ") ~ "]";
  	return xout;
  }
}

class IndexExpression: Expression {
	Token token; // The [ token
	Expression left;
	Expression index;

  this(Token tk,  Expression le) {
    this.token = tk;
    this.left = le;
  }

	override void expressionNode()      {}
  override dstring tokenLiteral() { return this.token.literal; }
  override dstring string() {
  	dstring xout = "(";
  	xout ~= this.left.string() ~ "[";
  	xout ~= this.index.string() ~ "])";
  	return xout;
  }
}

class HashLiteral: Expression{
	Token token; // the `{` token
	Expression[Expression] pairs;

  this(Token tk) {
    this.token = tk;
  }

  override void expressionNode()      {}
  override dstring tokenLiteral() { return this.token.literal; }
  override dstring string() {
  	dstring xout;
  	dstring[] pairs;
  	foreach(k, v; this.pairs) {
  	  pairs ~= k.string() ~ ": " ~ v.string();
  	}
  	xout ~= "{" ~ pairs.join(", ") ~ "}";

  	return xout;
  }
}
