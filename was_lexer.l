%{
/* C++ string header, for string ops below */
#include <string>

/* Implementation of yyFlexScanner */ 
#include "was_scanner.hpp"
#undef  YY_DECL
#define YY_DECL int WAS::WAS_Scanner::yylex2(WAS::WAS_Parser::semantic_type * const lval, WAS::WAS_Parser::location_type *location)

/* typedef to make the returns for the tokens shorter */
typedef WAS::WAS_Parser::token token;

/* define to keep from re-typing the same code over and over */
#define STOKEN( x ) ( new std::string( x ) )

/* define yyterminate as this instead of NULL */
#define yyterminate() return( token::END )

/* msvc2010 requires that we exclude this header file. */
#define YY_NO_UNISTD_H

/* update location on matching */
#define YY_USER_ACTION loc->step(); loc->columns(yyleng);

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
ATOM            ({LETTER}|{DIGIT}|\$|_|\\{HEXDIGIT}{HEXDIGIT})*
IDENTIFIER      \${ATOM}

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
"call"                         { return token::CALL; }
"call_import"                  { return token::CALL_IMPORT; }
"call_indirect"                { return token::CALL_INDIRECT; }

"var"                          { return token::VAR; }

("i32"|"i64")":8s"             { return token::LOAD_S_8; }
("i32"|"i64")":8u"             { return token::LOAD_U_8; }

("i32"|"i64")":16s"            { return token::LOAD_S_16; }
("i32"|"i64")":16u"            { return token::LOAD_U_16; }

"i64:32s"                      { return token::LOAD_S_32; }
"i64:32u"                      { return token::LOAD_U_32; }

("i32"|"i64")":8"              { return token::STORE_8; }
("i32"|"i64")":16"             { return token::STORE_16; }
"i64:32"                       { return token::STORE_32; }

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

{IDENTIFIER}    { return token::IDENTIFIER; }
{INT}           { return token::INT; }
{FLOAT}         { return token::FLOAT; }
{TEXT}          { return token::TEXT; }

"/s"            { return token::DIVS; }
"/u"            { return token::DIVU; }
"%s"            { return token::REMS; }
"%u"            { return token::REMU; }
"<<"            { return token::SHL; } 
">>"            { return token::SHRU; } 
">>>"           { return token::SHRS; }

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
<COMMENT><<EOF>>      { printf("Unterminated comment\n"); return 0; }
"//".*                { }


[ \t]                 { loc->step(); }
(\n\r?)|[\r\f\v]      { loc->lines(); }
%%


