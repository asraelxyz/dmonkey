// DMonkey Object

module dmonkey.dmobject;
import dmonkey.ast;
import std.conv: to;
import std.array: join;
import std.format: format;
import std.utf: toUTF32;
import dmonkey.dmobject.environment: Environment;

enum ObjectType {
    Integer  = "Integer",
    Boolean  = "Boolean",
    Null     = "Null",
    Return   = "Return",
    Error    = "Error",
    Function = "Function",
    String   = "String",
    Builtin  = "Builtin",
    Array    = "Array",
    Hash     = "Hash",
}

// Object is a reserved name in D-lang.
abstract class MObject {
    ObjectType type();
    dstring inspect();

    Hashable intoHashable() {
        return null;
    }
}


interface Hashable {
    HashKey hashKey();
}

class Integer: MObject, Hashable {
    long value;

    this(long val=0) {
        this.value = val;
    }

    override ObjectType type()  { return ObjectType.Integer; }
    override dstring inspect()  { return to!dstring(this.value); }

    HashKey hashKey()  {
        return new HashKey(this.type(), ulong(this.value));
    }

    override Hashable intoHashable() {
        return this;
    }
}

class Boolean: MObject, Hashable {
    bool value;

    this(bool val=false) {
        this.value = val;
    }

    override ObjectType type()  { return ObjectType.Boolean; }
    override dstring inspect()  { return to!dstring(this.value); }

    HashKey hashKey() {
        long value;

        if (this.value) {
            value = 1;
        } else {
            value = 0;
        }

        return new HashKey(this.type(), value);
    }

    override Hashable intoHashable() {
        return this;
    }
}

class Null: MObject {
    this() { }

    override ObjectType type()  { return ObjectType.Null; }
    override dstring inspect()  { return "null"; }
}


class ReturnValue: MObject {
    // private
    private MObject val;

    this(MObject val = new Null()) {
        this.val = val;
    }

    @property MObject value() {
        return this.val;
    }

    override ObjectType type()  { return ObjectType.Return; }
    override dstring inspect()  { return this.val.inspect(); }
}



// Error is a reserved name in D-lang.
// class Error only object.d can define this reserved class name
class MError: MObject {
    private dstring message;

    this(dstring val) {
        this.message = val;
    }

    this(string val) {
        this.message = val.toUTF32();
    }
    
    override ObjectType type()  { return ObjectType.Error; }
    override dstring inspect()  { return "ERROR: " ~ this.message; }
}


class Function: MObject {
    Identifier[] parameters;
    BlockStatement body;
    Environment* env;
    

    this(Identifier[] params, BlockStatement bd, Environment* env) {
        this.parameters = params;
        this.body = bd;
        this.env = env;
    }

    override ObjectType type()  { return ObjectType.Function; }override 

    dstring inspect() {
        dstring xout;

        dstring[] params;
        foreach(_, p; this.parameters) {
            params ~= p.string();
        }

        xout ~= "fn(";
        xout ~= params.join(", ");
        xout ~= ") {\n";
        xout ~= this.body.string();
        xout ~= "\n}";

        return xout;
    }
}


// Hashable
class String: MObject {
    dstring value;

    this(dstring val="") {
        this.value = val;
    }
    
    override ObjectType type()  { return ObjectType.String; }
    override dstring inspect()  { return this.value; }
    /*
    HashKey hashKey() {
        // Convierte a bytes
        h := fnv.New64a()
        h.Write([]byte(s.Value))
        // Codifica en sum64
        return HashKey{Type: s.Type(), Value: h.Sum64()}
    }
    */
}

// MObject
alias BuiltinFunction = MObject function(MObject[] m...);

class Builtin: MObject {
    BuiltinFunction fn;

    this(BuiltinFunction xfn) {
        this.fn = xfn;
    }

    override ObjectType type()  { return ObjectType.Builtin; }
    override dstring inspect()  { return "builtin function"; }

}


class Array: MObject {
    MObject[] elements;

    this(MObject[] eles=[]) {
        this.elements = eles;
    }

    override ObjectType type()  { return ObjectType.Array; }
    override dstring inspect() {
        dstring xout;

        dstring[] elements;
        foreach(_, e; this.elements) {
            elements ~= e.inspect();
        }
        xout ~= "[";
        xout ~= elements.join(", ");
        xout ~= "]";

        return xout;
    }
}


class HashKey {
    private {
        ObjectType type;
        ulong value;
    }

    this(ObjectType ty, ulong val) {
        this.type =  ty;
        this.value = val;
    }
}

struct HashPair {
    MObject key;   
    MObject value; 
}

class Hash: MObject {
    HashPair[HashKey] pairs;

    this() {}

    this(HashPair[HashKey] p) {
        this.pairs = p;
    }

    override ObjectType type() { return ObjectType.Hash; }
    override dstring inspect() {
        dstring xout;

        dstring[] pairs;
        foreach(_, pair; this.pairs) {
            // pairs = append(pairs, fmt.Sprintf("%s: %s", pair.Key.Inspect(), pair.Value.Inspect()))
            pairs ~= format("%s: %s", pair.key.inspect(), pair.value.inspect()).toUTF32();
        }

        xout ~= "{";
        xout ~= pairs.join(", ");
        xout ~= "}";

        return xout;
    }
}
