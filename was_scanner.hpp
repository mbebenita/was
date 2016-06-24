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

#ifndef __WAS_SCANNER_HPP__
#define __WAS_SCANNER_HPP__

#ifndef yyFlexLexerOnce
#include <FlexLexer.h>
#endif

#include "was_parser.tab.hh"
#include "location.hh"

namespace WAS {

class WAS_Scanner : public yyFlexLexer {
public:
   WAS_Scanner(std::istream *in)
    : yyFlexLexer(in),
      yylval(nullptr)
   {
     loc = new WAS::WAS_Parser::location_type();
   };
   
   // YY_DECL defined in WAS_lexer.l
   // Method body created by flex in WAS_lexer.yy.cc
   virtual int yylex2(WAS::WAS_Parser::semantic_type* const lval,
                      WAS::WAS_Parser::location_type* location);

   virtual void LexerError(const char* msg);

private:
   WAS::WAS_Parser::semantic_type *yylval;
   WAS::WAS_Parser::location_type *loc;
};

} /* end namespace WAS */

#endif /* __WAS_SCANNER_HPP__ */
