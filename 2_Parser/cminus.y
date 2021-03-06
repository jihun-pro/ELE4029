%{

#define YYPARSER /* distinguishes Yacc output from other code files */

#include "globals.h"
#include "util.h"
#include "scan.h"
#include "parse.h"

#define YYSTYPE TreeNode *
static char * savedName; /* for use in assignments */
static int savedLineNo;  /* ditto */
static TreeNode * savedTree; /* stores syntax tree for later return */
int yyerror(char * message);
static int yylex(void);

%}

%token IF ELSE INT RETURN VOID WHILE
%token PLUS MINUS TIMES OVER LT LE GT GE EQ NE ASSIGN SEMI COMMA
%token LPAREN RPAREN LCURLY RCURLY LBRACE RBRACE
%token ID NUM LETTER DIGIT
%token ERROR

%%

program                 : declaration_list { savedTree = $1; }
                        ;
declaration_list        : declaration declaration_list {
                                  YYSTYPE t = $1;
                                  if (t != NULL) {
                                    while (t->sibling != NULL)
                                      t = t->sibling;
                                    t->sibling = $2;
                                    $$ = $1;
                                  } else $$ = $2;
                                }
                        | declaration { $$ = $1; }
                        ;
declaration             : var_declaration { $$ = $1; }
                        | fun_declaration { $$ = $1; }
			;
identifier              : ID { savedName = copyString(tokenString); savedLineNo = lineno; }
                        ;
var_declaration		: type_specifier identifier SEMI
			| type_specifier identifier LBRACE NUM RBRACE SEMI
			;
type_specifier		: INT
			| VOID
			;
fun_declaration         : type_specifier identifier {
                                  $$ = newDeclNode(FunK);
                                  $$->lineno = lineno;
                                  $$->attr.name = savedName;
                                }
                        LPAREN params RPAREN compound_stmt {
                                  $$ = $3;
                                  $$->child[0] = $1;
                                  $$->child[1] = $5;
                                  $$->child[2] = $7;
                                }
                        ;
params			: param_list
			| VOID
			;
param_list		: param_list COMMA param
			| param
			;
param			: type_specifier identifier
			| type_specifier identifier LBRACE RBRACE
			;
compound_stmt		: LCURLY local_declarations statement_list RCURLY
			;
local_declarations	: local_declarations var_declaration
			|
			;
statement_list		: statement_list statement
			|
			;
statement		: expression_stmt
			| compound_stmt
			| selection_stmt
			| iteration_stmt
			| return_stmt
			;
expression_stmt		: expression SEMI
			| SEMI
			;
selection_stmt		: IF LPAREN expression RPAREN statement
			| IF LPAREN expression RPAREN statement ELSE statement
			;
iteration_stmt		: WHILE LPAREN expression RPAREN statement
			;
return_stmt		: RETURN SEMI
			| RETURN expression SEMI
			;
expression		: var ASSIGN expression
			| simple_expression
			;
var			: identifier
			| identifier LBRACE expression RBRACE
			;
simple_expression	: additive_expression relop additive_expression
			| additive_expression
			;
relop			: LT
			| LE
			| GT
			| GE
			| EQ
			| NE
			;
additive_expression	: additive_expression addop term
			| term
			;
addop			: PLUS
			| MINUS
			;
term			: term mulop factor
			| factor
			;
mulop			: TIMES
			| OVER
			;
factor			: LPAREN expression RPAREN
			| var
			| call
			| NUM
			;
call			: identifier LPAREN args RPAREN
			;
args			: arg_list
			|
			;
arg_list		: arg_list COMMA expression
			| expression
			;

%%

int yyerror(char * message)
{ fprintf(listing,"Syntax error at line %d: %s\n",lineno,message);
  fprintf(listing,"Current token: ");
  printToken(yychar,tokenString);
  Error = TRUE;
  return 0;
}

/* yylex calls getToken to make Yacc/Bison output
 * compatible with ealier versions of the C-minus scanner
 */
static int yylex(void)
{ return getToken(); }

TreeNode * parse(void)
{ yyparse();
  return savedTree;
}

