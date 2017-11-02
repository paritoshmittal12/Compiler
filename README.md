# Compiler for a Sub C Language

The program perfroms the Lexical, Syntax and Semantic analysis of the given Code.

The program has three major parts:

* **Lexical Analysis**: The lex file parses the string and identifies keywords, variables etc. It passes this information for further processing. Any lexical error is detected at this stage.
* **Syntax Analysis**: Every language has its grammar and any sentence will be processed only if it follows the rules of grammar. The grammar is written in Yacc file. 
* **Semantic Analysis**: All important functions necessary for semantic analysis is present in function.cpp file. It maintains global function table and variable table to keep track of declarations, definitions and usage while compiling. Any compile time error like *variable usa without declaring* is identified here.

After all this is done, the intermediate code generation takes place. This means that a compiler independent three address code is generated at the end of execution.


#### **Software Requirements**

```
1. install Lex.
2. install Yacc or bison.
```

#### **Execute the code**

Create a test.c file. Write your code in this file and then run:

```
./script.sh
```

An output.txt file will contain the output, can be errors or intermediate three address code.