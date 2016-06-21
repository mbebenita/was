#ifndef __WASDRIVER_HPP__
#define __WASDRIVER_HPP__ 1

#include "was_parser.tab.hh"
#include "was_scanner.hpp"
#include <cstdint>
#include <string>
#include <iostream>

namespace WAS {

class WAS_Driver {
public:
  WAS_Driver() = default;

  virtual ~WAS_Driver();

  void parse(const char *filename, int debug_level);

  AST::NodePtr result;

private:
  WAS::WAS_Parser *parser = nullptr;
  WAS::WAS_Scanner *scanner = nullptr;
};

} /* end namespace WAS */
#endif /* END __WASDRIVER_HPP__ */
