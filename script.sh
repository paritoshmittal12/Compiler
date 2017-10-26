#!/bin/bash

echo "Compiling our files"
yacc -d c_yacc.y
lex -ll c_lex.l
g++ -std=c++1y y.tab.c lex.yy.c
echo "Files Compiled Successfully. Running the compiler on test file"
./a.out < "test.c" > "output.txt"
echo "Please Check the output file for compile status ^_^ "
