module dmonkey.evaluator.builtins;

import dmonkey.evaluator: newError;
import dmonkey.dmobject: Builtin, MObject, ObjectType, Array, String, Integer, Null;
import std.stdio: write;

void load_builtins(ref Builtin[dstring] builtins) {
    builtins["len"] = new Builtin(function MObject(MObject[] args...) {
        if (args.length != 1) {
            return newError("wrong number of arguments. got=%d, want=1", args.length);
        }

        switch (args[0].type()) {
        case ObjectType.Array:
            Array* arr = cast(Array*)&args[0];
            return new Integer(arr.elements.length);
        case ObjectType.String:
            String* str = cast(String*)&args[0];
            return new Integer(str.value.length);
        default:
            return newError("argument to `len` not supported, got %s", args[0].type());
        }
    });

    builtins["first"] = new Builtin(function MObject(MObject[] args...) {
        if (args.length != 1) {
            return newError("wrong number of arguments. got=%d, want=1", args.length);
        }

        if (args[0].type() != ObjectType.Array) {
            return newError("argument to `first` must be Array, got %s", args[0].type());
        }

        Array* arr = cast(Array*)&args[0];
        if (arr.elements.length > 0) {
            return arr.elements[0];
        }

        return new Null();
    });

    builtins["last"] = new Builtin(function MObject(MObject[] args...) {
        if (args.length != 1) {
            return newError("wrong number of arguments. got=%d, want=1", args.length);
        }

        if (args[0].type() != ObjectType.Array) {
            return newError("argument to `last` must be Array, got %s", args[0].type());
        }

        Array* arr = cast(Array*)&args[0];
            if (arr.elements.length > 0) {
                return arr.elements[$-1];
        }

        return new Null();
    });

    builtins["rest"] = new Builtin(function MObject(MObject[] args...) {
        if (args.length != 1) {
            return newError("wrong number of arguments. got=%d, want=1", args.length);
        }

        if (args[0].type() != ObjectType.Array) {
            return newError("argument to `rest` must be Array, got %s", args[0].type());
        }

        Array* arr = cast(Array*)&args[0];
        if (arr.elements.length > 0) {
            // TODO: Debo terminar de verificar que no se lleva a cabo una
            // referencia a datos (copia débil) como en la mayoría de
            // lenguajes.
            return new Array(arr.elements[1..$]);
        }

        return new Null();
    });

    builtins["push"] = new Builtin(function MObject(MObject[] args...) {
        if (args.length != 2) {
            return newError("wrong number of arguments. got=%d, want=1", args.length);
        }

        if (args[0].type() != ObjectType.Array) {
            return newError("argument to `rest` must be Array, got %s", args[0].type());
        }

        Array* arr = cast(Array*)&args[0];

        return new Array(arr.elements ~ args[1]);
    });

    builtins["writeln"] = new Builtin(function MObject(MObject[] args...) {
        foreach (_, val; args) {
            write(val.inspect());
        }

        write('\n');
        return new Null();
    });
}