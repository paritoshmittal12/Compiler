%{
#include "y.tab.h"
#include <stdio.h>
#include <stdlib.h>
int line_number=1;
int query_number=1;
#define KEYS(val,val1){ return val1; /* keywords are inserted here */}
#define LIT(val,val1){char a[100]; int len = strlen(val); strncpy(a,(val + 1), len-2);a[len -2] = '\0'; return val1; /* keywords are inserted here */}
#define ID(val){ strcpy(yylval.str, yytext); return STRING; /* Identifiers are inserted here */}
#define NUM(val){ yylval.num = atoi(yytext); return INTVAL; /* number are inserted here */}
#define FLT(val){ yylval.flt = atoi(yytext); return FLTVAL; /* number are inserted here */}
#define OP(val){ return val; }
#define OPE(val,val1){ return val1; /* comparators are inserted here */}
#define SC(val){ query_number++;return val;}

#define errorFunc(val){printf(" => %s pops an Error in %d \n",val,line_number);}


%}
%option yylineno
digit [0-9]
number 	[0-9]+
letter [a-zA-Z_]
lett_num [a-zA-Z0-9_]
id 		{letter}{lett_num}*
floatx 	{number}+[.]{number}*

%option noyywrap
%%

exit  					{printf("GoodBye :) \n");exit (EXIT_SUCCESS); /* exit command */}
("#include")	        KEYS(yytext,INCLUDE)
("#define")             KEYS(yytext,DEFINE)
("float")               KEYS(yytext,FLOAT)
("char")                KEYS(yytext,CHAR)
("int")                 KEYS(yytext,INT)
("struct") 				KEYS(yytext,STRUCT)
("typedef")				KEYS(yytext,TYPEDEF)
("const")				KEYS(yytext,CONST)
("if")					KEYS(yytext,IF)
("else")				KEYS(yytext,ELSE)
("while")				KEYS(yytext,WHILE)
("for")					KEYS(yytext,FOR)
("break")				KEYS(yytext,BREAK)
("default")				KEYS(yytext,DEFAULT)
("continue")			KEYS(yytext,CONTINUE)
("extern")				KEYS(yytext,EXTERN)
("return")				KEYS(yytext,RETURN)
("void")				KEYS(yytext,VOID)
("NULL")				KEYS(yytext,NULLX)
("static")				KEYS(yytext,STATIC)
("enum")				KEYS(yytext,ENUM)

">="						OPE(">=", GTE_OPE)
"<="						OPE("<=", LTE_OPE)
"=="						OPE("==", EQL_OPE)
"!="						OPE("!=", NTE_OPE)
"+="						OPE("+=", ADD_OPE)
"-="						OPE("-=", SUB_OPE)
"*="						OPE("*=", MUL_OPE)
"/="						OPE("/=", DIV_OPE)
"++"						OPE("++", INC_OPE)
"--"						OPE("--", DEC_OPE)
"<<"						OPE("<<", LEF_OPE)
">>"						OPE(">>", RGT_OPE)
"&&"						OPE("&&", AND_OPE)
"||"						OPE("||", OR_OPE)
"?:"						OPE("?:", TER_OPE)
"->"						OPE("->", PTR_OPE)
"["							OP(yytext[0])
"]"							OP(yytext[0])
"*"									OP(yytext[0])
"+"									OP(yytext[0])
"-"									OP(yytext[0])
"/"									OP(yytext[0])
"<"									OP(yytext[0])
">"									OP(yytext[0])
"("									OP(yytext[0])
")"									OP(yytext[0])
"{"									OP(yytext[0])
"}"									OP(yytext[0])
","									OP(yytext[0])
"="									OP(yytext[0])
"."									OP(yytext[0])
"&"									OP(yytext[0])
"|"									OP(yytext[0])
"%"									OP(yytext[0])
{id}								ID(yytext)
{number}							NUM(yytext)
{floatx}							FLT(yytext)
{number}{lett_num}+					{errorFunc(yytext); /* error function */}

[;] 								SC(yytext[0])
[ \t\r]		         				;
[\n]								{line_number++;yylineno++;};
. 									{ errorFunc(yytext);}
%% 


