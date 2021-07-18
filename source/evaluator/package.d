// Written in the D programming language.
module dmonkey.evaluator;

import dmonkey.ast;
import dmonkey.dmobject;
import std.format: format;
import std.stdio: writeln;
import std.traits: isSomeString;
import dmonkey.dmobject.environment: Environment;

alias ObjType = dmobject.ObjectType;
alias dmobject = dmonkey.dmobject;
alias ast = dmonkey.ast;

// let a = {"a":1}; let a = [1,2,3]; a[i]

/* Errores:
1) No realiza llamadas a función
2) No aplica las operaciones matemáticas del modo correcto 
*/

// cast(ast.IntegerLiteral)node is null <- Llama a padre!

// import std.traits: StringTypeOf stringof fqn;
// StringTypeOf stringof fqn std.traits
MObject DMEval(ast.Node node, Environment* env) {
    //writeln("Loop: ", node.string());
    if (cast(ast.Program)node !is null) {
        ast.Program* p = (cast(ast.Program*)&node);
        return evalProgram(p, env);
    }

    if (cast(ast.ExpressionStatement)node !is null)
        return DMEval((cast(ast.ExpressionStatement)node).expression, env);

    if (cast(ast.IntegerLiteral)node !is null) {
        return new dmobject.Integer((cast(ast.IntegerLiteral)node).value);
    }

    if (cast(ast.Boolean)node !is null)
        return nativeBoolToBooleanObject((cast(ast.Boolean)node).value);
    
    if (cast(ast.PrefixExpression)node !is null) {
        ast.PrefixExpression* prefix_expr = cast(ast.PrefixExpression*)&node;
        MObject right = DMEval(prefix_expr.right, env);
        if (isError(right)) {
            return right;
        }
        return evalPrefixExpression(prefix_expr.operator, right);
    }

    if (cast(ast.InfixExpression)node !is null) {
        ast.InfixExpression* infix_expr = cast(ast.InfixExpression*)&node;
        MObject left = DMEval(infix_expr.left, env);
        if (isError(left)) {
            return left;
        }

        MObject right = DMEval(infix_expr.right, env);
        if (isError(right)) {
            return right;
        }

        return evalInfixExpression(infix_expr.operator, left, right);
    }

    if (cast(ast.BlockStatement)node !is null)
        return evalBlockStatement(cast(ast.BlockStatement*)&node, env);

    if (cast(ast.IfExpression)node !is null)
        return evalIfExpression(cast(ast.IfExpression*)&node, env);

    if (cast(ast.ReturnStatement)node !is null) {
        MObject val = DMEval((cast(dmobject.ReturnStatement)node).return_value, env);
        if (isError(val)) {
            return val;
        }
        return new dmobject.ReturnValue(val);
    }

    if (cast(ast.LetStatement)node !is null) {
        ast.LetStatement* nd = (cast(ast.LetStatement*)&node);
        MObject val = DMEval(nd.value, env);
        if (isError(val)) {
            return val;
        }

        env.set(nd.name.value, val);
    }

    if (cast(ast.Identifier)node !is null)
        return evalIdentifier(cast(ast.Identifier*)&node, env);
    
    if (cast(ast.FunctionLiteral)node !is null) {
        ast.FunctionLiteral* nd = cast(ast.FunctionLiteral*)&node;
        return new dmobject.Function(nd.parameters, nd.body, env);
    }
    
    if (cast(ast.CallExpression)node !is null) {
        ast.CallExpression* nd = cast(ast.CallExpression*)&node;
        MObject fn = DMEval(nd.xfunc, env);
        if (isError(fn)) {
            return fn;
        }

        MObject[] args = evalExpressions(nd.arguments, env);
        if (args.length == 1 && isError(args[0])) {
            return args[0];
        }

        return applyFunction(fn, args);
    }

    if (cast(ast.StringLiteral)node !is null)
        return new dmobject.String((cast(ast.Identifier*)&node).value);

    
    if (cast(ast.ArrayLiteral)node !is null) {
        ast.ArrayLiteral* nd = cast(ast.ArrayLiteral*)&node;
        MObject[] elements = evalExpressions(nd.elements, env);
        if (elements.length == 1 && isError(elements[0])) {
            return elements[0];
        }

        return new dmobject.Array(elements);
    }
    
    if (cast(ast.IndexExpression)node !is null) {
        ast.IndexExpression* nd = cast(ast.IndexExpression*)&node;
        MObject left = DMEval(nd.left, env);
        if (isError(left)) {
            return left;
        }
        
        MObject index = DMEval(nd.index, env);
        if (isError(index)) {
            return index;
        }

        return evalIndexExpression(left, index);
    }
    /*
    if (cast(ast.HashLiteral)node !is null){
        return evalHashLiteral(cast(ast.HashLiteral*)&node, env)
    }
    */

    return null;
}

// Private functions from here

MObject evalProgram(ast.Program* program, Environment* env) {
    MObject result;

    foreach (n, stmt; program.statements) {
        result = DMEval(stmt, env);
    
        if (cast(dmobject.ReturnValue)result !is null)
            return (cast(dmobject.ReturnValue)result).value;

        if (cast(dmobject.MError)result !is null)
            return (cast(dmobject.MError)result);
    }

    return result;
}

MObject evalBlockStatement(ast.BlockStatement* block, Environment* env) {
    MObject result;

    foreach (_, statement;  block.statements) {
        result = DMEval(statement, env);

        if (result.type != ObjType.Null) {
            ObjType rt = result.type;
            if (rt == ObjType.Return || rt == ObjType.Error) {
                return result;
            }
        }
    }

    return result;
}
/*
MObject evalBlockStatement(ast.BlockStatement* block, Environment* env) {
    MObject result;

    foreach (_, statement; block.statements) {
        result = DMEval(statement, env);

        if (result !is null) {
            ObjType rt = result.type();
            if (rt == ObjType.Return || rt == ObjType.Error) {
                return result;
            }
        }
    }

    return result;
}*/


MObject nativeBoolToBooleanObject(bool input) { // or Boolean?
    return new dmobject.Boolean(input);
}


MObject evalPrefixExpression(dstring operator, MObject right) {
    switch (operator) {
    case "!":
        return evalBangOperatorExpression(right);
    case "-":
        return evalMinusPrefixOperatorExpression(right);
    default:
        return newError!()("unknown operator: %s%s", operator, cast(string)right.type);
    }
}

MObject evalBangOperatorExpression(MObject right) {
    return (cast(dmobject.Boolean)right !is null) ?
                  new dmobject.Boolean(!(cast(dmobject.Boolean)right).value) :
           (cast(dmobject.Null)right !is null)  ? new dmobject.Boolean(true) :
                                                  new dmobject.Boolean(false);
}

MObject evalMinusPrefixOperatorExpression(MObject right) {
    if (right.type != ObjType.Integer) {
        return newError!()("unknown operator: -%s", cast(string)right.type);
    }

    long value = (cast(dmobject.Integer*)&right).value;
    return new dmobject.Integer(-value);
}

MObject evalInfixExpression(dstring operator, MObject left, MObject right) {
    
    if (left.type == ObjType.Integer && right.type == ObjType.Integer)
        return evalIntegerInfixExpression(operator, left, right);
    if (operator == "==")
        return nativeBoolToBooleanObject(left == right);
    if (operator == "!=")
        return nativeBoolToBooleanObject(left != right);
    if (left.type == ObjType.String && right.type == ObjType.String)
        return evalStringInfixExpression(operator, left, right);
    if (left.type != right.type)
        return newError!()("type mismatch: %s %s %s", left.type, operator, right.type);
    
    return newError!()("unknown operator: %s %s %s", left.type, operator, right.type);
    
}

MObject evalIntegerInfixExpression(dstring operator, MObject left, MObject right) {
    long leftVal = (cast(dmobject.Integer*)&left).value;
    long rightVal = (cast(dmobject.Integer*)&right).value;

    switch (operator) {
    case "+":
        return new dmobject.Integer(leftVal + rightVal);
    case "-":
        return new dmobject.Integer(leftVal - rightVal);
    case "*":
        return new dmobject.Integer(leftVal * rightVal);
    case "/":
        return new dmobject.Integer(leftVal / rightVal);
    case "<":
        return nativeBoolToBooleanObject(leftVal < rightVal);
    case ">":
        return nativeBoolToBooleanObject(leftVal > rightVal);
    case "==":
        return nativeBoolToBooleanObject(leftVal == rightVal);
    case "!=":
        return nativeBoolToBooleanObject(leftVal != rightVal);
    default:
        return newError("unknown operator: %s %s %s", left.type, operator, right.type);
    }
}

MObject evalIfExpression(ast.IfExpression* ie, Environment* env) {
    MObject condition = DMEval(ie.condition, env);

    if (isError(condition)) {
        return condition;
    }

    if (isTruthy(condition)) {
        return DMEval(ie.consequence, env);
    } else if (ie.alternative !is null) {
        return DMEval(ie.alternative, env);
    } else {
        return new dmobject.Null();
    }
}

MObject evalIdentifier(ast.Identifier* node, Environment* env) {
    MObject* val;
    if ((val = env.get(node.value)) !is null) {
        return *val;
    }

    auto b = node.value in env.builtins;
    if (b !is null)  {
        return *b;
    }

    return newError("identifier not found: " ~ node.value);
}

MObject[] evalExpressions(ast.Expression[] exps, Environment* env) {
    MObject[] result = [];

    foreach (_, e; exps) {
        MObject evaluated = DMEval(e, env);
        if (isError(evaluated)) {
            return [evaluated];
        }
        result ~= evaluated;
    }

    return result;
}

MObject evalStringInfixExpression(dstring operator, MObject left, MObject right)  {
    if (operator != "+") {
        return newError!()("unknown operator: %s %s %s", left.type, operator, right.type);
    }

    dstring lv = (cast(dmobject.String*)&left).value;
    dstring rv = (cast(dmobject.String*)&right).value;
    return new dmobject.String(lv ~ rv);
}

MObject evalIndexExpression(MObject left, MObject index) {
    
    if (left.type() == ObjType.Array && index.type() == ObjType.Integer)
        return evalArrayIndexExpression(left, index);
  
    //  case left.Type() == object.HASH_OBJ:
    //     return evalHashIndexExpression(left, index)
    
    return newError("index operator not supported: %s", left.type());
   
}

MObject evalArrayIndexExpression(MObject arr, MObject index) {
    dmobject.Array* array = cast(dmobject.Array*)&arr;
    long idx = (cast(dmobject.Integer*)&index).value;
    long max = array.elements.length -1;

    if (idx < 0 || idx > max) {
        return new dmobject.Null();
    }

    return array.elements[idx];
}
/*
func evalHashIndexExpression(hash, index object.Object) object.Object {
    hashObj := hash.(*object.Hash)
    k, ok := index.(object.Hashable)
    if !ok {
        return newError("unusable as hash key: %s", index.Type())
    }

    pair, ok := hashObj.Pairs[k.HashKey()]
    if !ok {
        return NULL
    }

    return pair.Value
}

func evalHashLiteral(
    node *ast.HashLiteral,
    env *object.Environment,
) object.Object {
    pairs := make(map[object.HashKey]object.HashPair)

    for k, v := range node.Pairs {
        key := Eval(k, env)
        if isError(key) {
            return key
        }

        hashKey, ok := key.(object.Hashable)
        if !ok {
            return newError("unusable as hash key: %s", key.Type())
        }

        value := Eval(v, env)
        if isError(value) {
            return value
        }

        hashed := hashKey.HashKey()
        pairs[hashed] = object.HashPair{Key: key, Value: value}
    }

    return &object.Hash{Pairs: pairs}
}*/

bool isTruthy(MObject obj) {
    if (obj.type() == ObjType.Null) return false;
    if (obj.type() == ObjType.Boolean) return (cast(dmobject.Boolean*)&obj).value;
    return true;
}

MError newError(Str, Args...)(Str fmt,  Args args) 
if (isSomeString!Str) {
    return new MError(format(fmt, args));
}

bool isError(MObject obj) {
    if (obj !is null) {
        return obj.type == ObjType.Error;
    }

    return false;
}

MObject applyFunction(MObject fn, MObject[] args) {
    // switch fn := fn.(type) {
 
    if (cast(dmobject.Function)fn !is null) {
        dmobject.Function* n_fn = cast(dmobject.Function*)&fn;

        Environment extendedEnv = extendFunctionEnv(n_fn, args);
        MObject evaluated = DMEval(n_fn.body, &extendedEnv);
        return unwrapReturnValue(evaluated);
    }

    if (cast(dmobject.Builtin)fn !is null) return (cast(dmobject.Builtin*)&fn).fn(args);

    return newError("not a function: %s", fn.type());
}

Environment extendFunctionEnv(dmobject.Function* fn,  MObject[] args) {
    auto env = new Environment(fn.env);

    foreach (i, param; fn.parameters) {
        env.set(param.value, args[i]);
    }

    return env;
}

MObject unwrapReturnValue(MObject obj) {
    ReturnValue ret = cast(dmobject.ReturnValue)obj;
    if (ret !is null) {
        return ret.value;
    }

    return obj;
}
