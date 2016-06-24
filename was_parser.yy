/*
 * Copyright 2016 Mozilla Foundation
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

%skeleton "lalr1.cc"
%require  "3.0"
%debug 

%defines 
%define api.namespace {WAS}
%define parser_class_name {WAS_Parser}

%code requires{
   #include "ast.hpp"

   namespace WAS {
      class WAS_Driver;
      class WAS_Scanner;
   }
}

%parse-param { WAS_Scanner  &scanner  }
%parse-param { WAS_Driver  &driver  }

%code{
   /* include for all driver functions */
   #include "was_driver.hpp"

#undef yylex
#define yylex scanner.yylex2
#define YYDEBUG 1
}

%define api.value.type variant

%type <AST::NodePtr> group_expression call_expression load_expression assignment_expression
                     bitwise_and_expression bitwise_or_expression bitwise_xor_expression
                     block_expression if_expression br_expression operator_expression
                     equality_expression relational_expression prefix_operator_expression
                     binary_operator_expression select_operator_expression br_table_expression
                     shift_expression return_expression additive_expression block literal
                     expression align bookmarked_group_expression label
                     multiplicative_expression bookmarked_prefix_expression prefix_expression
                     function_declaration module_item module type_annotation
                     type_declaration segment memory_declaration table_declaration
                     import_declaration export_declaration
%type <AST::LiteralName> typed_binary_operator type typed_unary_operator
                         multiplicative_operator additive_operator shift_operator
                         relational_expression_operator equality_expression_operator
%type <AST::Nodes> optional_expression_list expression_list identifier_sequence
                   expression_sequence optional_local_declaration_statement_sequence
                   local_declaration_statement_sequence local_declaration_statement function_body
                   type_list optional_type_list identifier_list module_item_sequence segment_list
                   optional_segment_list memory_limits function_signature
%type <AST::LabeledNodes> optional_multi_block_content optional_expression_sequence_with_label
                          multi_block_content inner_block_content block_content
%type <AST::MemoryOperator> memory_operator
%type <AST::MemoryAddress> address
%type <AST::VarDefinitions> local_declaration optional_local_declaration_list local_declaration_list

%define parse.assert

%token               END    0     "end of file"

%token I32_LOAD_S_8
%token I32_LOAD_U_8
%token I64_LOAD_S_8
%token I64_LOAD_U_8
%token I32_LOAD_S_16
%token I32_LOAD_U_16
%token I64_LOAD_S_16
%token I64_LOAD_U_16
%token I64_LOAD_S_32
%token I64_LOAD_U_32

%token I32_STORE_8
%token I64_STORE_8
%token I32_STORE_16
%token I64_STORE_16
%token I64_STORE_32

%token ALIGN

%token SELECT
%token RETURN

%token <AST::NodePtr> IDENTIFIER
%token BOOKMARK
%token I32
%token I64
%token F32
%token F64
%token VAR
%token <AST::NodePtr> INT
%token <AST::NodePtr> FLOAT
%token <AST::NodePtr> TEXT
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
%token NOP
%token UNREACHABLE


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

// Notes:
//  Lists are separated by commas.
//  Sequences are separated by spaces.

%%

module
   : /* Empty */          { $$ = AST::NodeFactory::createListNode("module"); driver.result = $$; }
   | module_item_sequence { AST::ListNode* module = AST::NodeFactory::createListNode("module"); module->move($1); $$ = module; driver.result = module; }
   ;

module_item_sequence
   : module_item                      { AST::Nodes nodes; nodes.push_back($1); $$ = nodes; }
   | module_item_sequence module_item { $1.push_back($2); $$ = $1; }
   ;

module_item
   : function_declaration { $$ = $1; }
   | import_declaration   { $$ = $1; }
   | export_declaration   { $$ = $1; }
   | type_declaration     { $$ = $1; }
   | table_declaration    { $$ = $1; }
   | memory_declaration   { $$ = $1; }
   ;

import_declaration
   : IMPORT TEXT AS IDENTIFIER FROM TEXT TYPEOF IDENTIFIER ';'
    { AST::ListNodePtr import = AST::NodeFactory::createListNode("import", $4, $2, $6); import->append($8); $$ = import; }
   | IMPORT TEXT AS IDENTIFIER FROM TEXT TYPEOF function_signature ';'
    { AST::ListNodePtr import = AST::NodeFactory::createListNode("import", $4, $2, $6); import->move($8); $$ = import; }
   ;

export_declaration
   : EXPORT MEMORY AS TEXT ';'
     { $$ = AST::NodeFactory::createListNode("export", $4, AST::NodeFactory::createListNode("memory")); }
   | EXPORT IDENTIFIER AS TEXT ';'
     { $$ = AST::NodeFactory::createListNode("export", $4, $2); }
   ;

type_declaration
   : TYPE IDENTIFIER OF function_signature ';'
     { AST::ListNodePtr fn = AST::NodeFactory::createListNode("func"); fn->move($4); $$ = AST::NodeFactory::createListNode("type", $2, fn); }
   ;

table_declaration
   : TABLE '[' identifier_list ']' ';'
     { AST::ListNodePtr table = AST::NodeFactory::createListNode("table"); table->move($3); $$ = table; }
   ;

memory_declaration
   : MEMORY memory_limits '{' optional_segment_list '}'
     { AST::ListNodePtr memory = AST::NodeFactory::createListNode("memory"); memory->move($2); memory->move($4); $$ = memory; }
   ;

memory_limits
   :             { $$ = AST::Nodes(); }
   | INT         { AST::Nodes nodes; nodes.push_back($1); $$ = nodes; }
   | INT ',' INT { AST::Nodes nodes; nodes.push_back($1); nodes.push_back($3); $$ = nodes; }
   ;

optional_segment_list
   : /* Empty */  { $$ = AST::Nodes(); }
   | segment_list { $$ = $1; }
   ;

segment_list
   : segment              { AST::Nodes nodes; nodes.push_back($1); $$ = nodes; }
   | segment_list segment { $1.push_back($2); $$ = $1; }
   ;

segment
   : SEGMENT INT ',' TEXT ';' { $$ = AST::NodeFactory::createListNode("segment", $2, $4); }
   ;

function_signature
   : FUNCTION '(' optional_type_list ')'
     { AST::Nodes nodes; nodes.push_back(AST::NodeFactory::createListNode("param", $3)); $$ = nodes; }
   | FUNCTION '(' optional_type_list ')' ':' '(' optional_type_list ')' 
     { AST::Nodes nodes; nodes.push_back(AST::NodeFactory::createListNode("param", $3));
       if ($7.size() > 0) nodes.push_back(AST::NodeFactory::createListNode("result", $7));
       $$ = nodes; }
   ;

function_declaration
   : FUNCTION IDENTIFIER '(' optional_local_declaration_list ')' function_body
     { AST::ListNodePtr node = AST::NodeFactory::createListNode("func", $2);
       AST::Nodes params; $4.toASTNodes("param", params); node->move(params);
       node->move($6); $$ = node; }
   | FUNCTION IDENTIFIER '(' optional_local_declaration_list ')' ':' '(' optional_type_list ')' function_body
     { AST::ListNodePtr node = AST::NodeFactory::createListNode("func", $2);
       AST::Nodes params; $4.toASTNodes("param", params); node->move(params);
       if ($8.size() > 0) node->append(AST::NodeFactory::createListNode("result", $8));
       node->move($10); $$ = node; }
   ;

local_declaration_statement
   : VAR local_declaration_list ';'
     { AST::Nodes nodes; $2.toASTNodes("local", nodes); $$ = nodes; }
   ;

local_declaration_statement_sequence
   : local_declaration_statement                                      { $$ = $1; }
   | local_declaration_statement_sequence local_declaration_statement { $$ = AST::append_to($1, $2); }
   ;

optional_local_declaration_statement_sequence
   : /* Empty */                          { $$ = AST::Nodes(); }
   | local_declaration_statement_sequence { $$ = $1; }
   ;

function_body
   : '{' optional_local_declaration_statement_sequence optional_multi_block_content '}'
     { $$ = AST::append_to($2, $3.nodes); }
   ;

block
   :                 '{' optional_multi_block_content '}'
     { AST::ListNodePtr block = $2.toBlockNode("block"); $$ = block; }
   |           LOOP  '{' optional_multi_block_content '}'
     { AST::ListNodePtr loop = $3.toBlockNode("loop"); $$ = loop; }
   | LOOP IDENTIFIER '{' optional_multi_block_content '}'
     { AST::ListNodePtr loop = $4.toBlockNode("loop"); loop->insertAt($2, 1); $$ = loop; }
   ;

label
   : IDENTIFIER ':' { $$ = $1; }
   ;

optional_multi_block_content
   : /* Empty */          { $$ = AST::LabeledNodes(); }
   | multi_block_content  { $$ = $1; }
   ;

multi_block_content
   : block_content                     { $$ = $1; }
   | inner_block_content block_content { $2.prependInnerBlock($1); $$ = $2; }
   ;

inner_block_content
   : optional_expression_sequence_with_label                     { $$ = $1; }
   | inner_block_content optional_expression_sequence_with_label { $2.prependInnerBlock($1); $$ = $2; }
   ;
   
block_content
   : optional_expression_sequence_with_label { $$ = $1; }
   | expression_sequence                     { AST::LabeledNodes nodes; nodes.fromNodes($1); $$ = nodes; }
   | expression_sequence ';'                 { AST::LabeledNodes nodes; nodes.fromNodes($1); $$ = nodes; }
   ;

optional_expression_sequence_with_label
   : label                           { AST::LabeledNodes nodes; nodes.label = $1; $$ = nodes; }
   | expression_sequence label       { AST::LabeledNodes nodes; nodes.fromNodes($1); nodes.label = $2; $$ = nodes; }
   | expression_sequence ';' label   { AST::LabeledNodes nodes; nodes.fromNodes($1); nodes.label = $3; $$ = nodes; }
   ;

expression_sequence
   : expression                         { AST::Nodes nodes; $$ = AST::append_item_to(nodes, $1); }
   | expression_sequence ';' expression { $$ = AST::append_item_to($1, $3); }
   ;

literal
   : INT   { $$ = AST::NodeFactory::createListNode("const", $1->inferredType, $1); }
   | FLOAT { $$ = AST::NodeFactory::createListNode("const", $1->inferredType, $1); }
   ;

bookmarks
   : BOOKMARK
   | bookmarks BOOKMARK
   ;

group_expression
   : '(' assignment_expression ')' { $$ = $2; }
   | literal                       { $$ = $1; }
   | IDENTIFIER                    { AST::ListNodePtr node = AST::NodeFactory::createListNode("get_local"); node->append($1); $$ = node; }
   | call_expression               { $$ = $1; }
   | load_expression               { $$ = $1; }
   | operator_expression           { $$ = $1; }
   | block_expression              { $$ = $1; }
   ;

bookmarked_group_expression
   : group_expression           { $$ = $1; }
   | bookmarks group_expression { $$ = $2; }
   ;

align
   : ALIGN '=' INT { $$ = $3; }
   ;

address
   : '[' expression ']'                   { $$ = AST::MemoryAddress($2, nullptr, nullptr); }
   | '[' expression ',' align ']'         { $$ = AST::MemoryAddress($2, nullptr, static_cast<AST::LiteralNodePtr>($4)); }
   | '[' expression ',' INT ']'           { $$ = AST::MemoryAddress($2, static_cast<AST::LiteralNodePtr>($4), nullptr); }
   | '[' expression ',' INT ',' align ']' { $$ = AST::MemoryAddress($2, static_cast<AST::LiteralNodePtr>($4), static_cast<AST::LiteralNodePtr>($6)); }
   ;

memory_operator
   : I32       { $$ = AST::MemoryOperator(nullptr, AST::InferredType::I32); }
   | I64       { $$ = AST::MemoryOperator(nullptr, AST::InferredType::I64); }
   | F32       { $$ = AST::MemoryOperator(nullptr, AST::InferredType::F32); }
   | F64       { $$ = AST::MemoryOperator(nullptr, AST::InferredType::F64); }
   | I32_LOAD_S_8  { $$ = AST::MemoryOperator("load/8s", AST::InferredType::I32); }
   | I64_LOAD_S_8  { $$ = AST::MemoryOperator("load/8s", AST::InferredType::I64); }
   | I32_LOAD_U_8  { $$ = AST::MemoryOperator("load/8u", AST::InferredType::I32); }
   | I64_LOAD_U_8  { $$ = AST::MemoryOperator("load/8u", AST::InferredType::I64); }
   | I32_LOAD_S_16 { $$ = AST::MemoryOperator("load/16s", AST::InferredType::I32); }
   | I64_LOAD_S_16 { $$ = AST::MemoryOperator("load/16s", AST::InferredType::I64); }
   | I32_LOAD_U_16 { $$ = AST::MemoryOperator("load/16u", AST::InferredType::I32); }
   | I64_LOAD_U_16 { $$ = AST::MemoryOperator("load/16u", AST::InferredType::I64); }
   | I64_LOAD_S_32 { $$ = AST::MemoryOperator("load/32s", AST::InferredType::I64); }
   | I64_LOAD_U_32 { $$ = AST::MemoryOperator("load/32u", AST::InferredType::I64); }
   | I32_STORE_8  { $$ = AST::MemoryOperator("store/8", AST::InferredType::I32); }
   | I64_STORE_8  { $$ = AST::MemoryOperator("store/8", AST::InferredType::I64); }
   | I32_STORE_16 { $$ = AST::MemoryOperator("store/16", AST::InferredType::I32); }
   | I64_STORE_16 { $$ = AST::MemoryOperator("store/16", AST::InferredType::I64); }
   | I64_STORE_32 { $$ = AST::MemoryOperator("store/32", AST::InferredType::I64); }
   ;

load_expression
   : memory_operator address
     { AST::ListNode* node = AST::NodeFactory::createListNode($1.name ? $1.name : "load", $1.type);
       if ($2.offset) node->append(AST::NodeFactory::createFlag("offset=", $2.offset));
       if ($2.flags) node->append(AST::NodeFactory::createFlag("align=", $2.flags));
       if ($2.base) node->append($2.base);
       $$ = node; }
   ;

typed_unary_operator
   : CLZ             { $$ = "clz"; }
   | CTZ             { $$ = "ctz"; }
   | EQZ             { $$ = "eqz"; }
   | POPCNT          { $$ = "popcnt"; }
   | ABS             { $$ = "abs"; }
   | NEG             { $$ = "neg"; }
   | CEIL            { $$ = "ceil"; }
   | FLOOR           { $$ = "floor"; }
   | TRUNC           { $$ = "trunc"; }
   | NEAREST         { $$ = "nearest"; }
   | SQRT            { $$ = "sqrt"; }
   | EXTEND_S_I32    { $$ = "extend_s/i32"; }
   | EXTEND_U_I32    { $$ = "extend_u/i32"; }
   | WRAP_I64        { $$ = "wrap/i64"; }
   | TRUNC_S_F32     { $$ = "trunc_s/f32"; }
   | TRUNC_U_F32     { $$ = "trunc_u/f32"; }
   | TRUNC_S_F64     { $$ = "trunc_s/f64"; }
   | TRUNC_U_F64     { $$ = "trunc_u/f64"; }
   | REINTERPRET_F32 { $$ = "reinterpret/f32"; }
   | REINTERPRET_F64 { $$ = "reinterpret/f64"; }
   | REINTERPRET_I32 { $$ = "reinterpret/i32"; }
   | REINTERPRET_I64 { $$ = "reinterpret/i64"; }
   | CONVERT_U_I32   { $$ = "convert_u/i32"; }
   | CONVERT_S_I32   { $$ = "convert_s/i32"; }
   | CONVERT_U_I64   { $$ = "convert_u/i64"; }
   | CONVERT_S_I64   { $$ = "convert_s/i64"; }
   | PROMOTE_F32     { $$ = "promote/f32"; }
   | DEMOTE_F64      { $$ = "demote/f64"; }
   ;

prefix_expression
   : '-' bookmarked_prefix_expression { $$ = AST::NodeFactory::createListNode("neg", AST::InferredType::Unknown, $2); }
   | '!' bookmarked_prefix_expression { $$ = AST::NodeFactory::createListNode("eqz", AST::InferredType::Unknown, $2); }
   ;

bookmarked_prefix_expression
   : bookmarked_group_expression { $$ = $1; }
   | prefix_expression           { $$ = $1; }
   | bookmarks prefix_expression { $$ = $2; }
   ;

prefix_operator_expression
   : type '.' typed_unary_operator '(' expression ')'
     { $$ = AST::NodeFactory::createListNode($3, AST::parse_inferred_type($1), $5); }
   ;

typed_binary_operator
   : COPYSIGN { $$ = "copysign"; }
   | MIN      { $$ = "min"; }
   | MAX      { $$ = "max"; }
   ;

binary_operator_expression
   : type '.' typed_binary_operator '(' expression ',' expression ')'
    { $$ = AST::NodeFactory::createListNode($3, AST::parse_inferred_type($1), $5, $7); }
   ;

multiplicative_operator
   : '*'  { $$ = "mul"; }
   | '/'  { $$ = "div"; }
   | DIVS { $$ = "div_s"; }
   | DIVU { $$ = "div_u"; }
   | REMS { $$ = "rem_s"; }
   | REMU { $$ = "rem_u"; }
   ;

multiplicative_expression
   : bookmarked_prefix_expression                                                   { $$ = $1; }
   | multiplicative_expression multiplicative_operator bookmarked_prefix_expression { $$ = AST::NodeFactory::createListNode($2, AST::InferredType::Unknown, $1, $3); }
   ;

additive_operator
   : '+' { $$ = "add"; }
   | '-' { $$ = "sub"; }
   ;

additive_expression
   : multiplicative_expression                                       { $$ = $1; }
   | additive_expression additive_operator multiplicative_expression { $$ = AST::NodeFactory::createListNode($2, AST::InferredType::Unknown, $1, $3); }
   ;

shift_operator
   : SHL  { $$ = "shl"; }
   | SHRU { $$ = "shr_u"; }
   | SHRS { $$ = "shr_s"; }
   ;

shift_expression
   : additive_expression                                 { $$ = $1; }
   | shift_expression shift_operator additive_expression { $$ = AST::NodeFactory::createListNode($2, AST::InferredType::Unknown, $1, $3); }
   ;

relational_expression_operator
   : LTS { $$ = "lt_s"; }
   | LTU { $$ = "lt_u"; }
   | LES { $$ = "le_s"; }
   | LEU { $$ = "le_u"; }
   | GTS { $$ = "gt_s"; }
   | GTU { $$ = "gt_u"; }
   | GES { $$ = "ge_s"; }
   | GEU { $$ = "ge_u"; }
   | GE  { $$ = "ge"; }
   | LE  { $$ = "le"; }
   | '<' { $$ = "gt"; }
   | '>' { $$ = "lt"; }
   ;

relational_expression
   : shift_expression                                                      { $$ = $1; }
   | relational_expression relational_expression_operator shift_expression { $$ = AST::NodeFactory::createListNode($2, AST::InferredType::Unknown, $1, $3); }
   ;

equality_expression_operator
   : EQ { $$ = "eq"; }
   | NE { $$ = "ne"; }
   ;

equality_expression
   : relational_expression                                                  { $$ = $1; }
   | equality_expression equality_expression_operator relational_expression { $$ = AST::NodeFactory::createListNode($2, AST::InferredType::Unknown, $1, $3); }
   ; 

bitwise_and_expression
   : equality_expression                            { $$ = $1; }
   | bitwise_and_expression '&' equality_expression { $$ = AST::NodeFactory::createListNode("and", AST::InferredType::Unknown, $1, $3); }
   ;

bitwise_xor_expression
   : bitwise_and_expression                            { $$ = $1; }
   | bitwise_xor_expression '^' bitwise_and_expression { $$ = AST::NodeFactory::createListNode("xor", AST::InferredType::Unknown, $1, $3); }
   ;

bitwise_or_expression
   : bitwise_xor_expression                           { $$ = $1; }
   | bitwise_or_expression '|' bitwise_xor_expression { $$ = AST::NodeFactory::createListNode("or", AST::InferredType::Unknown, $1, $3); }
   ;

select_operator_expression
   : SELECT '(' expression ',' expression ',' expression ')' { $$ = AST::NodeFactory::createListNode("select", $3, $5, $7); }
   ;
   
   
assignment_expression
   : bitwise_or_expression { $$ = $1; }
   | IDENTIFIER '=' assignment_expression
     { AST::ListNode* node = AST::NodeFactory::createListNode("set_local");
       node->append($1);
       node->append($3);
       $$ = node; }
   | memory_operator address '=' assignment_expression
     { AST::ListNode* node = AST::NodeFactory::createListNode($1.name ? $1.name : "store", $1.type);
       if ($2.offset) node->append(AST::NodeFactory::createFlag("offset=", $2.offset));
       if ($2.flags) node->append(AST::NodeFactory::createFlag("align=", $2.flags));
       if ($2.base) node->append($2.base);
       node->append($4);
       $$ = node; }
   ;

operator_expression
   : prefix_operator_expression { $$ = $1; }
   | binary_operator_expression { $$ = $1; }
   | select_operator_expression { $$ = $1; }
   ;

block_expression
   : if_expression       { $$ = $1; }
   | br_expression       { $$ = $1; }
   | br_table_expression { $$ = $1; }
   | return_expression   { $$ = $1; }
   | block               { $$ = $1; }
   | NOP                 { $$ = AST::NodeFactory::createListNode("nop"); }
   | UNREACHABLE         { $$ = AST::NodeFactory::createListNode("unreachable"); }
   ;

expression   
   : assignment_expression { $$ = $1; }
   ;

call_expression
   : CALL IDENTIFIER '(' optional_expression_list ')'
     { AST::ListNodePtr call = AST::NodeFactory::createListNode("call", $2); call->move($4); $$ = call; }
   | CALL_IMPORT IDENTIFIER '(' optional_expression_list ')'
     { AST::ListNodePtr call = AST::NodeFactory::createListNode("call_import", $2); call->move($4); $$ = call; }
   | CALL_INDIRECT IDENTIFIER '[' expression ']' '(' optional_expression_list ')'
     { AST::ListNodePtr call = AST::NodeFactory::createListNode("call_indirect", $2, $4); call->move($7); $$ = call; }
   ;

return_expression
   : RETURN            { $$ = AST::NodeFactory::createListNode("return"); }
   | RETURN expression { $$ = AST::NodeFactory::createListNode("return", $2); }
   ;

if_expression
   : IF '(' expression ')' '{' optional_multi_block_content '}'
     { $$ = AST::NodeFactory::createListNode("if", $3, $6.toBlockNode("then")); }
   | IF '(' expression ')' '{' optional_multi_block_content '}' ELSE '{' optional_multi_block_content '}'
     { $$ = AST::NodeFactory::createListNode("if", $3, $6.toBlockNode("then"), $10.toBlockNode("else")); }
   ;

br_expression
   : BR IDENTIFIER
     { AST::ListNodePtr node = AST::NodeFactory::createListNode("br"); node->append($2); $$ = node; }
   | BR '(' expression ')' IDENTIFIER
     { AST::ListNodePtr node = AST::NodeFactory::createListNode("br"); node->append($5); node->append($3); $$ = node; }
   | BR_IF '(' expression ')' IDENTIFIER
     { AST::ListNodePtr node = AST::NodeFactory::createListNode("br_if"); node->append($5); node->append($3); $$ = node; }
   | BR_IF '(' expression ',' expression ')' IDENTIFIER
     { AST::ListNodePtr node = AST::NodeFactory::createListNode("br_if"); node->append($7); node->append($3); node->append($5); $$ = node; }
   ; 

br_table_expression
   : BR_TABLE '(' expression ')' '[' identifier_list ']' IDENTIFIER
     { AST::ListNodePtr node = AST::NodeFactory::createListNode("br_table"); node->move($6); node->append($8); node->append($3); $$ = node; }
   | BR_TABLE '(' expression ',' expression ')' '[' identifier_list ']' IDENTIFIER
     { AST::ListNodePtr node = AST::NodeFactory::createListNode("br_table"); node->move($8); node->append($10); node->append($3); node->append($5); $$ = node; }
   ;

type
   : I32 { $$ = "i32"; }
   | F32 { $$ = "f32"; }
   | I64 { $$ = "i64"; }
   | F64 { $$ = "f64"; }
   ;

type_annotation
   : ':' type { $$ = AST::NodeFactory::createLiteralNode($2); }
   ;

optional_expression_list
   : /* Empty */     { $$ = AST::Nodes(); }
   | expression_list { $$ = $1; }
   ; 

expression_list
   : expression                     { AST::Nodes nodes; $$ = AST::append_item_to(nodes, $1); }
   | expression_list ',' expression { $1.push_back($3); $$ = $1; }
   ;

local_declaration
   : identifier_sequence type_annotation { AST::VarDefinitions defs; defs.fromNames($1, static_cast<AST::LiteralNodePtr>($2)); $$ = defs; }
   ;

optional_local_declaration_list
   : /* Empty */             { $$ = AST::VarDefinitions(); }
   | local_declaration_list  { $$ = $1; }
   ; 

local_declaration_list
   : local_declaration                            { $$ = $1; }
   | local_declaration_list ',' local_declaration { $$ = AST::append_to($1, $3); }
   ;

optional_type_list
   : /* Empty */ { $$ = AST::Nodes(); }
   | type_list   { $$ = $1; }
   ;

type_list
   : type               { AST::Nodes nodes; AST::append_item_to(nodes, static_cast<AST::NodePtr>(AST::NodeFactory::createLiteralNode($1))); $$ = nodes; }
   | type_list ',' type { AST::append_item_to($1, static_cast<AST::NodePtr>(AST::NodeFactory::createLiteralNode($3))); $$ = $1; }
   ;

identifier_list
   : IDENTIFIER                     { AST::Nodes nodes; $$ = AST::append_item_to<AST::NodePtr>(nodes, $1); }
   | identifier_list ',' IDENTIFIER { $$ = AST::append_item_to<AST::NodePtr>($1, $3); }
   ;

identifier_sequence
   : IDENTIFIER                     { AST::Nodes nodes; $$ = AST::append_item_to(nodes, $1); }
   | identifier_sequence IDENTIFIER { $$ = AST::append_item_to($1, $2); }
   ;

%%


void 
WAS::WAS_Parser::error( const location_type &l, const std::string &err_message )
{
   std::cerr << "Error: " << err_message << " at " << l << "\n";
}
