// Written in the D programming language.

module dmonkey.repl;

import dmonkey.lexer;
import std.utf: toUTF32;
import dmonkey.ast: Program;
import dmonkey.parser: Parser;
import dmonkey.dmobject: MObject;
import dmonkey.evaluator: DMEval;
import std.stdio: stdin, stdout, writeln, File;
import dmonkey.dmobject.environment: Environment;
// -- -- -- --;

// Encuentra la diferencia* con el original.
const PROMPT = ">> ";
const MONKEY_FACE = `
            __,__
   .--.  .-'     '-.  .--.
  / .. \/  .-. .-.  \/ .. \
 | |  '|  /   Y   \  |'  | |
 | \   \  \ 0 | 0 /  /   / |
  \ '- ,\.-\"""""/-./, -' /
   ''-' /_   ^ ^   _\ '-''
       |  \._   _./  |
       \   \ '~' /   /
        '._ '-=-' _.'
           '-----'
`;

void start() {

  File sd = stdin();
  Environment env = new Environment();
  /* */
  while (true) {  
    stdout.write(PROMPT);
    stdout.flush();
    dstring data = sd.readln().toUTF32!();

    
    if (data == ".exit\n" || data == "") { // "" == Ctrl+D
      stdout.write('\n');
      break;
    }

    Lexer lex = new Lexer(data[0..$-1]); // skip the last char (\n)
    Parser parser = new Parser(&lex);
    Program program = parser.parseProgram();

    if (parser.errors.length != 0) {
      printParserErrors(stdout, parser.errors());
      continue;
    }

    // writeln(program.statements);
    MObject evaluated = DMEval(program, &env);
    if (evaluated !is null) stdout.write(evaluated.inspect(), "\n");
  }
  
}

void printParserErrors(File file, dstring[] errors) {
  file.write("parser errors:\n");
  file.flush();

  foreach (_, msg; errors) {
    file.write("  ", msg, "\n");
    file.flush();
  }
}