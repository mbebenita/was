%skeleton "lalr1.cc"
%require  "3.0"
%debug 

%defines 
%define api.namespace {WAS}
%define parser_class_name {WAS_Parser}

%code requires{
   namespace WAS {
      class WAS_Driver;
      class WAS_Scanner;
   }

// The following definitions is missing when %locations isn't used
# ifndef YY_NULLPTR
#  if defined __cplusplus && 201103L <= __cplusplus
#   define YY_NULLPTR nullptr
#  else
#   define YY_NULLPTR 0
#  endif
# endif

}

%parse-param { WAS_Scanner  &scanner  }
%parse-param { WAS_Driver  &driver  }

%code{
   #include <iostream>
   #include <cstdlib>
   #include <fstream>
   
   /* include for all driver functions */
   #include "was_driver.hpp"

   using namespace std;

   extern int trace_level;

   void trace(const char *message) {
      if (trace_level) {
         cout << message << endl;
      }
   }

#undef yylex
#define yylex scanner.yylex2
#define YYDEBUG 1
}

%define api.value.type variant
%define parse.assert

%token               END    0     "end of file"
%token               UPPER
%token               LOWER
%token <std::string> WORD
%token               NEWLINE
%token               CHAR

%token LOAD

%token LOAD_S_8
%token LOAD_U_8

%token LOAD_S_16
%token LOAD_U_16

%token LOAD_S_32
%token LOAD_U_32

%token STORE
%token STORE_8
%token STORE_16
%token STORE_32

%token SELECT
%token RETURN

%token IDENTIFIER
%token I32
%token I64
%token F32
%token F64
%token VAR
%token INT
%token FLOAT
%token TEXT
%token REINTERPRET
%token BR
%token BR_IF
%token BR_TABLE
%token LOOP
%token IF
%token ELSE
%token CALL
%token CALL_IMPORT
%token CALL_INDIRECT

%token FUNCTION
%token IMPORT
%token EXPORT
%token TABLE
%token MEMORY
%token SEGMENT
%token AS
%token TYPE
%token OF
%token FROM
%token TYPEOF


// Binary Operators

%token DIVS
%token DIVU
%token REMS
%token REMU

%token SHL
%token SHRU
%token SHRS

%token EQ
%token NE
%token LTS
%token LTU
%token LES
%token LEU
%token GTS
%token GTU
%token GES
%token GEU

%token LE
%token GE

// Unary Operators

%token CLZ
%token CTZ
%token EQZ
%token POPCNT
%token ABS
%token MIN
%token MAX
%token NEG
%token COPYSIGN
%token CEIL
%token FLOOR
%token TRUNC
%token NEAREST
%token SQRT
%token EXTEND_S_I32
%token EXTEND_U_I32
%token WRAP_I64
%token TRUNC_S_F32
%token TRUNC_U_F32
%token TRUNC_S_F64
%token TRUNC_U_F64
%token REINTERPRET_F32
%token REINTERPRET_F64
%token CONVERT_U_I32
%token CONVERT_S_I32
%token CONVERT_U_I64
%token CONVERT_S_I64
%token PROMOTE_F32
%token DEMOTE_F64
%token REINTERPRET_I32
%token REINTERPRET_I64

%locations

%%

// Notes:
//  Lists are separated by commas.
//  Sequences are separated by spaces.

module
   : /* Empty */
   | module_item_sequence
   ;

module_item_sequence
   : module_item
   | module_item_sequence module_item
   ;

module_item
   : function_declaration
   | import_declaration
   | export_declaration
   | type_declaration
   | table_declaration
   | memory_declaration
   ;

import_declaration
   : IMPORT TEXT AS IDENTIFIER FROM TEXT TYPEOF IDENTIFIER { trace("import_declaration"); }
   | IMPORT TEXT AS IDENTIFIER FROM TEXT TYPEOF function_signature { trace("import_declaration"); }
   ;

export_declaration
   : EXPORT MEMORY AS TEXT { trace("export_memory_declaration"); }
   | EXPORT IDENTIFIER AS TEXT { trace("export_declaration"); }
   ;

type_declaration
   : TYPE IDENTIFIER OF function_signature { trace("type_declaration"); }
   ;

table_declaration
   : TABLE '[' identifier_list ']' { trace("table_declaration"); }
   ;

memory_declaration
   : MEMORY memory_limits '{' optional_segment_list '}' { trace("memory_declaration"); }
   ;

memory_limits
   :
   | INT
   | INT ',' INT
   ;

optional_segment_list
   : /* Empty */
   | segment_list
   ;

segment_list
   : segment
   | segment_list segment
   ;

segment
   : SEGMENT INT ',' TEXT { trace("segment"); }
   ;

function_signature
   : FUNCTION '(' optional_type_list ')' 
   | FUNCTION '(' optional_type_list ')' ':' '(' optional_type_list ')' 
   ;

function_declaration
   : FUNCTION IDENTIFIER '(' optional_local_declaration_list ')' function_body { trace("function_declaration"); }
   | FUNCTION IDENTIFIER '(' optional_local_declaration_list ')' ':' '(' optional_type_list ')' function_body { trace("function_declaration"); }
   ;

local_declaration_statement
   : VAR local_declaration_list
   ;

local_declaration_statement_sequence
   : local_declaration_statement
   | local_declaration_statement_sequence local_declaration_statement
   ;

optional_local_declaration_statement_sequence
   :
   | local_declaration_statement_sequence
   ;

function_body
   : '{' optional_local_declaration_statement_sequence optional_multi_block_content '}'
   ;

block
   :                 '{' optional_multi_block_content '}'
   |           LOOP  '{' optional_multi_block_content '}'
   | LOOP IDENTIFIER '{' optional_multi_block_content '}'
   ;

label
   : IDENTIFIER ':'
   ;

optional_multi_block_content
   :
   | multi_block_content
   ;

multi_block_content
   : block_content
   | inner_block_content block_content
   ;

inner_block_content
   : label
   | inner_block_content label
   | expression_sequence_with_tail_label
   | inner_block_content expression_sequence_with_tail_label
   ;
   
block_content
   : label
   | expression_sequence
   | expression_sequence_with_tail_label
   ;

expression_sequence_with_tail_label
   : expression_sequence label
   
expression_sequence
   : expression
   | expression_sequence expression { trace("expression_sequence"); }
   ;

literal
   : INT
   | FLOAT
   ;

group_expression
   : literal
   | IDENTIFIER
   | '(' assignment_expression ')'
   | call_expression
   | load_expression
   | block_expression
   ;

address
   : '[' expression ',' INT ']'
   ;

load_operator
   : LOAD
   | LOAD_S_8
   | LOAD_U_8
   | LOAD_S_16
   | LOAD_U_16
   | LOAD_S_32
   | LOAD_U_32
   ;

store_operator
   : STORE
   | STORE_8
   | STORE_16
   | STORE_32
   ;

load_expression
   : type '.' load_operator address
   ;

typed_unary_operator
   : CLZ
   | CTZ
   | EQZ
   | POPCNT
   | ABS
   | NEG
   | CEIL
   | FLOOR
   | TRUNC
   | NEAREST
   | SQRT
   | EXTEND_S_I32
   | EXTEND_U_I32
   | WRAP_I64
   | TRUNC_S_F32
   | TRUNC_U_F32
   | TRUNC_S_F64
   | TRUNC_U_F64
   | REINTERPRET_F32
   | REINTERPRET_F64
   | CONVERT_U_I32
   | CONVERT_S_I32
   | CONVERT_U_I64
   | CONVERT_S_I64
   | PROMOTE_F32
   | DEMOTE_F64
   | REINTERPRET_I32
   | REINTERPRET_I64
   ;
   
prefix_expression
   : group_expression
   | '-' prefix_expression
   | '+' prefix_expression
   | '!' prefix_expression
   | type '.' typed_unary_operator prefix_expression
   ;

copysign_expression
   : prefix_expression
   | type '.' COPYSIGN prefix_expression ',' copysign_expression { trace("copysign_expression"); }
   ;

minmax_expression
   : copysign_expression
   | type '.' MIN copysign_expression ',' minmax_expression { trace("minmax_expression"); }
   | type '.' MAX copysign_expression ',' minmax_expression { trace("minmax_expression"); }
   ;

multiplicative_operator
   : '*' 
   | '/' 
   | DIVS
   | DIVU
   | REMS
   | REMU
   ;

multiplicative_expression
   : minmax_expression
   | multiplicative_expression multiplicative_operator minmax_expression { trace("multiplicative_expression"); }
   ;

additive_operator
   : '+'
   | '-'
   ;

additive_expression
   : multiplicative_expression
   | additive_expression additive_operator multiplicative_expression { trace("additive_expression"); }
   ;

shift_expression
   : additive_expression
   | shift_expression SHL additive_expression { trace("shift_expression"); }
   | shift_expression SHRU additive_expression { trace("shift_expression"); }
   | shift_expression SHRS additive_expression { trace("shift_expression"); }
   ;

relational_expression_operator
   : LTS
   | LTU
   | LES
   | LEU
   | GTS
   | GTU
   | GES
   | GEU
   | GE
   | LE
   | '<'
   | '>'
   ;

relational_expression
   : shift_expression
   | relational_expression relational_expression_operator shift_expression { trace("relational_expression"); }
   ;

equality_expression_operator
   : EQ
   | NE
   ;

equality_expression
   : relational_expression
   | equality_expression equality_expression_operator relational_expression { trace("equality_expression"); }
   ; 

bitwise_and_expression
   : equality_expression
   | bitwise_and_expression '&' equality_expression { trace("bitwise_and_expression"); }
   ;

bitwise_xor_expression
   : bitwise_and_expression
   | bitwise_xor_expression '^' bitwise_and_expression { trace("bitwise_xor_expression"); }
   ;

bitwise_or_expression
   : bitwise_xor_expression
   | bitwise_or_expression '|' bitwise_xor_expression { trace("bitwise_or_expression"); }
   ;

select_expression
   : SELECT expression ',' expression '?' expression { trace("select_expression"); }
   ;

store_expression
   : bitwise_or_expression
   | type '.' store_operator address ',' store_expression
   ;
   
assignment_expression
   : store_expression
   | IDENTIFIER '=' assignment_expression { trace("assignment_expression"); }
   ;

block_expression
   : if_expression
   | br_expression
   | br_table_expression
   | return_expression
   | block
   | select_expression
   ;

expression   
   : assignment_expression
   | block_expression
   ;
   
call_expression
   : CALL IDENTIFIER '(' optional_expression_list ')' { trace("call_expression"); }
   | CALL_IMPORT IDENTIFIER '(' optional_expression_list ')' { trace("call_expression"); }
   | CALL_INDIRECT IDENTIFIER '[' expression ']' '(' optional_expression_list ')' { trace("call_expression"); }
   ;

return_expression
   : RETURN
   | RETURN expression
   ;

if_expression
   : IF '(' expression ')' '{' optional_multi_block_content '}'
   | IF '(' expression ')' '{' optional_multi_block_content '}' ELSE '{' optional_multi_block_content '}'
   ;

br_expression
   : BR IDENTIFIER
   | BR expression ',' IDENTIFIER
   | BR_IF expression ',' IDENTIFIER
   | BR_IF expression ',' expression ',' IDENTIFIER
   ; 

br_table_expression
   : BR_TABLE expression ',' '[' identifier_list ']' ',' IDENTIFIER
   | BR_TABLE expression ',' expression ',' '[' identifier_list ']' ',' IDENTIFIER
   ;

type
   : I32
   | F32
   | I64
   | F64
   ;

type_annotation
   : ':' type
   ;

optional_expression_list
   : /* Empty */
   | expression_list
   ; 

expression_list
   : expression
   | expression_list ',' expression
   ;

local_declaration
   : identifier_sequence type_annotation
   ;

optional_local_declaration_list
   :
   | local_declaration_list
   ; 

local_declaration_list
   : local_declaration
   | local_declaration_list ',' local_declaration
   ;

optional_type_list
   :
   | type_list
   ;

type_list
   : type
   | type_list ',' type
   ;

identifier_list
   : IDENTIFIER
   | identifier_list ',' IDENTIFIER
   ;

identifier_sequence
   : IDENTIFIER
   | identifier_sequence IDENTIFIER
   ;

%%


void 
WAS::WAS_Parser::error( const location_type &l, const std::string &err_message )
{
   std::cerr << "Error: " << err_message << " at " << l << "\n";
}
