#include <cstdlib>
#include <iostream>
#include <string>
#include <vector>

#include "was_driver.hpp"

int main(const int argc, const char **argv) {
  if (argc < 2)
    return EXIT_FAILURE;

  WAS::WAS_Driver driver;
  int debug_level = 0;
  int trace_level = 0;
  std::vector <std::string> sources;
  for (int i = 1; i < argc; i++) {
    if (std::string(argv[i]) == "--debug") {
      debug_level = 1;
    } else if (std::string(argv[i]) == "--trace") {
      trace_level = 1;
    } else {
      sources.push_back(std::string(argv[i]));
    }
  }

  for (std::string &source : sources) {
    driver.parse(source.c_str(), debug_level, trace_level);
  }

  return EXIT_SUCCESS;
}
