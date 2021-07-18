module dmonkey.dmobject.environment;

import dmonkey.dmobject: Builtin, MObject;
import dmonkey.evaluator.builtins: load_builtins;

class Environment {
    MObject[dstring] store;
    Environment* outer;
    Builtin[dstring] builtins;

    // Necesarry
    this() {
        load_builtins(builtins);
    }

    this(Environment* outer) {
        assert(outer !is null, "The argument outer never by null");
        this.outer = outer;
    }

    // WARNING: Esto puede retornar un puntero nulo 
    MObject* get(dstring name) {
        auto obj = name in this.store;
        if (obj is null && this.outer !is null) {
            obj = this.outer.get(name);
        }

        return obj;
    }

    MObject set(dstring name, MObject val) {
        this.store[name] = val;
        return val;
    }
}


