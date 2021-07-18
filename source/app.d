import std.stdio: writefln;
import std.process: environment;
import dmonkey.repl: start;

void main(string[] args) {
    string username = environment.get("USER");
    username = username.length > 0 ? username : "Unknown";
    writefln("Hello %s! This is the Monkey programming language!\n" ~
             "Feel free to type in commands", username);

    start();
}