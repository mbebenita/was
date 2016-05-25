#include <cassert>
#include <cctype>
#include <fstream>

#include "was_driver.hpp"

WAS::WAS_Driver::~WAS_Driver() {
  delete (scanner);
  scanner = nullptr;
  delete (parser);
  parser = nullptr;
}

int trace_level;

void WAS::WAS_Driver::parse(const char *const filename, int debug_level, int trace_level_) {
  assert(filename != nullptr);
  std::ifstream in_file(filename);
  if (!in_file.good())
    exit(EXIT_FAILURE);
  delete (scanner);
  try {
    scanner = new WAS::WAS_Scanner(&in_file);
  } catch (std::bad_alloc &ba) {
    std::cerr << "Failed to allocate scanner: (" << ba.what()
              << "), exiting!!\n";
    exit(EXIT_FAILURE);
  }
  delete parser;
  try {
    parser = new WAS::WAS_Parser(*scanner, *this);
    parser->set_debug_level(debug_level);
    trace_level = trace_level_;
  } catch (std::bad_alloc &ba) {
    std::cerr << "Failed to allocate parser: (" << ba.what()
              << "), exiting!!\n";
    exit(EXIT_FAILURE);
  }
  const int accept(0);
  if (parser->parse() != accept) {
    std::cerr << "Parse failed!!\n";
    exit(EXIT_FAILURE);
  }
}