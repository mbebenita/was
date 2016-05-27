#ifndef __WASSCANNER_HPP__
#define __WASSCANNER_HPP__ 1

#if ! defined(yyFlexLexerOnce)
#include <FlexLexer.h>
#endif

#include "was_parser.tab.hh"
#include "location.hh"

namespace WAS{

class WAS_Scanner : public yyFlexLexer{
public:
   
   WAS_Scanner(std::istream *in) : yyFlexLexer(in),
                                  yylval( nullptr )
   {
     loc = new WAS::WAS_Parser::location_type();
   };
   
   virtual int yylex2(WAS::WAS_Parser::semantic_type * const lval, WAS::WAS_Parser::location_type *location);
   // YY_DECL defined in WAS_lexer.l
   // Method body created by flex in WAS_lexer.yy.cc

   virtual void LexerError(const char* msg);

private:
   /* yyval ptr */
   WAS::WAS_Parser::semantic_type *yylval;
   /* location ptr */
   WAS::WAS_Parser::location_type *loc;
};

} /* end namespace WAS */

#endif /* END __WASSCANNER_HPP__ */
