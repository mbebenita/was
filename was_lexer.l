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

%{
/* Implementation of yyFlexScanner */ 
#include "was_scanner.hpp"
#undef  YY_DECL
#define YY_DECL int WAS::WAS_Scanner::yylex2(WAS::WAS_Parser::semantic_type* const lval, WAS::WAS_Parser::location_type* location)

/* typedef to make the returns for the tokens shorter */
typedef WAS::WAS_Parser::token token;

/* define yyterminate as this instead of NULL */
#define yyterminate() return( token::END )

/* msvc2010 requires that we exclude this header file. */
#define YY_NO_UNISTD_H

/* update location on matching */
#define YY_USER_ACTION loc->step(); loc->columns(yyleng);

void WAS::WAS_Scanner::LexerError(const char* msg) {
   std::cerr << msg << " at " << *loc << std::endl;
   exit(2);
}

%}

%option debug
%option nodefault
%option yyclass="WAS::WAS_Scanner"
%option noyywrap
%option c++

%x COMMENT

INTSUFFIX       "i32"|"i64"|"u32"|"u64"
FLOATSUFFIX     "f32"|"f64"|"f"
BINDIGIT        [0-1]
OCTDIGIT        [0-7]
DIGIT           [0-9]
HEXDIGIT        [0-9a-fA-F]
LETTER          [a-zA-Z]
TICK            `
ESCAPE          [nt\\'"]
CHARACTER       [^"\\\x00-\x1f\x7f]|\\{ESCAPE}|\\{HEXDIGIT}{HEXDIGIT}
SIGN            [+-]
NUM             {DIGIT}+
BINNUM          "0b"{BINDIGIT}+
OCTNUM          "0o"{OCTDIGIT}+
HEXNUM          "0x"{HEXDIGIT}+
INT             {SIGN}?({NUM}|{BINNUM}|{OCTNUM}|{HEXNUM}){INTSUFFIX}?
FLOAT0          {SIGN}?{NUM}\.{DIGIT}*
FLOAT1          {SIGN}?{NUM}(\.{DIGIT}*)?[eE]{SIGN}?{NUM}
HEXFLOAT        {SIGN}?"0x"{HEXDIGIT}+\.?{HEXDIGIT}*p{SIGN}?{DIGIT}+
INFINITY        {SIGN}?"infinity"
NAN             {SIGN}?"nan"|{SIGN}?"nan:0x"{HEXDIGIT}+
FLOAT           ({FLOAT0}|{FLOAT1}|{HEXFLOAT}|{INFINITY}|{NAN}){FLOATSUFFIX}?
TEXT            \"{CHARACTER}*\"
ATOM            ({LETTER}|{DIGIT}|\$|_|\.|\\{HEXDIGIT}{HEXDIGIT})*
IDENTIFIER      \${ATOM}
BOOKMARK        \@{ATOM}

%%
%{          // Code executed at the beginning of yylex
            yylval = lval;
            loc = location;
%}

"function"                     { return token::FUNCTION; }
"import"                       { return token::IMPORT; }
"export"                       { return token::EXPORT; }
"table"                        { return token::TABLE; }
"memory"                       { return token::MEMORY; }
"segment"                      { return token::SEGMENT; }
"as"                           { return token::AS; }
"type"                         { return token::TYPE; }
"of"                           { return token::OF; }
"from"                         { return token::FROM; }
"typeof"                       { return token::TYPEOF; }

"br"                           { return token::BR; }
"br_if"                        { return token::BR_IF; }
"loop"                         { return token::LOOP; }
"br_table"                     { return token::BR_TABLE; }
"if"                           { return token::IF; }
"else"                         { return token::ELSE; }
"call_import"                  { return token::CALL_IMPORT; }
"call_indirect"                { return token::CALL_INDIRECT; }

"nop"                          { return token::NOP; }
"unreachable"                  { return token::UNREACHABLE; }

"var"                          { return token::VAR; }

"i32:8s"                       { return token::I32_LOAD_S_8; }
"i32:8u"                       { return token::I32_LOAD_U_8; }
"i64:8s"                       { return token::I64_LOAD_S_8; }
"i64:8u"                       { return token::I64_LOAD_U_8; }

"i32:16s"                      { return token::I32_LOAD_S_16; }
"i32:16u"                      { return token::I32_LOAD_U_16; }
"i64:16s"                      { return token::I64_LOAD_S_16; }
"i64:16u"                      { return token::I64_LOAD_U_16; }

"i64:32s"                      { return token::I64_LOAD_S_32; }
"i64:32u"                      { return token::I64_LOAD_U_32; }

"i32:8"                        { return token::I32_STORE_8; }
"i32:16"                       { return token::I32_STORE_16; }
"i64:8"                        { return token::I64_STORE_8; }
"i64:16"                       { return token::I64_STORE_16; }
"i64:32"                       { return token::I64_STORE_32; }

"align"                        { return token::ALIGN; }

"select"                       { return token::SELECT; }
"return"                       { return token::RETURN; }

"i32"                          { return token::I32; }
"i64"                          { return token::I64; }
"f32"                          { return token::F32; }
"f64"                          { return token::F64; }

"clz"                          { return token::CLZ; }
"ctz"                          { return token::CTZ; }
"eqz"                          { return token::EQZ; }
"popcnt"                       { return token::POPCNT; }
"abs"                          { return token::ABS; }
"neg"                          { return token::NEG; }
"copysign"                     { return token::COPYSIGN; }
"min"                          { return token::MIN; }
"max"                          { return token::MAX; }
"ceil"                         { return token::CEIL; }
"floor"                        { return token::FLOOR; }
"trunc"                        { return token::TRUNC; }
"nearest"                      { return token::NEAREST; }
"sqrt"                         { return token::SQRT; }
"extend_s/i32"                 { return token::EXTEND_S_I32; }
"extend_u/i32"                 { return token::EXTEND_U_I32; }
"wrap/i64"                     { return token::WRAP_I64; }
"trunc_s/f32"                  { return token::TRUNC_S_F32; }
"trunc_u/f32"                  { return token::TRUNC_U_F32; }
"trunc_s/f64"                  { return token::TRUNC_S_F64; }
"trunc_u/f64"                  { return token::TRUNC_U_F64; }
"reinterpret/f32"              { return token::REINTERPRET_F32; }
"reinterpret/f64"              { return token::REINTERPRET_F64; }
"convert_u/i32"                { return token::CONVERT_U_I32; }
"convert_s/i32"                { return token::CONVERT_S_I32; }
"convert_u/i64"                { return token::CONVERT_U_I64; }
"convert_s/i64"                { return token::CONVERT_S_I64; }
"promote/f32"                  { return token::PROMOTE_F32; }
"demote/f64"                   { return token::DEMOTE_F64; }
"reinterpret/i32"              { return token::REINTERPRET_I32; } 
"reinterpret/i64"              { return token::REINTERPRET_I64; }

{IDENTIFIER}    { yylval->build<AST::Node*>(AST::NodeFactory::createIdentifier(yytext)); return token::IDENTIFIER; }
{BOOKMARK}      { return token::BOOKMARK; }
{INT}           { yylval->build<AST::Node*>(AST::NodeFactory::createIntConstant(yytext)); return token::INT; }
{FLOAT}         { yylval->build<AST::Node*>(AST::NodeFactory::createFloatConstant(yytext)); return token::FLOAT; }
{TEXT}          { yylval->build<AST::Node*>(AST::NodeFactory::createText(yytext)); return token::TEXT; }

"/s"            { return token::DIVS; }
"/u"            { return token::DIVU; }
"%s"            { return token::REMS; }
"%u"            { return token::REMU; }
"<<"            { return token::SHL; } 
">>u"           { return token::SHRU; }
">>s"           { return token::SHRS; }

">="            { return token::LE; } 
"<="            { return token::GE; }
"=="            { return token::EQ; } 
"!="            { return token::NE; } 
"<s"            { return token::LTS; } 
"<u"            { return token::LTU; } 
">=s"           { return token::LES; } 
">=u"           { return token::LEU; } 
">s"            { return token::GTS; } 
">u"            { return token::GTU; }  
"<=s"           { return token::GES; } 
"<=u"           { return token::GEU; }  

"{"             { return('{'); }
"}"             { return('}'); }
"("             { return('('); }
")"             { return(')'); }
":"             { return(':'); }
","             { return(','); }
"="             { return('='); }
";"             { return(';'); }
"+"             { return('+'); }
"-"             { return('-'); }
"/"             { return('/'); }
"*"             { return('*'); }
"."             { return('.'); }
"&"             { return('&'); }
"|"             { return('|'); }
"^"             { return('^'); }
"["             { return('['); }
"]"             { return(']'); }
"!"             { return('!'); }
"~"             { return('~'); }
"?"             { return('?'); }

"<"             { return('<'); }
">"             { return('>'); }

"/*"                  { BEGIN(COMMENT); }
<COMMENT>"*/"         { BEGIN(INITIAL); }
<COMMENT>\n           { loc->lines(); }
<COMMENT>[^*\n]+|.    { }
<COMMENT><<EOF>>      { LexerError("Unterminated comment\n"); }
"//".*                { }


[ \t]                 { loc->step(); }
(\n\r?)|[\r\f\v]      { loc->lines(); }
%%


