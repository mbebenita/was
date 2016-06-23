#include <cstdlib>
#include <iostream>
#include <fstream>
#include <string>
#include <vector>

#include "was_driver.hpp"
#include "ti.hpp"

int main(const int argc, const char **argv) {
  if (argc < 2)
    return EXIT_FAILURE;

  WAS::WAS_Driver driver;
  int debug_level = 0;
  int print = 0;
  int inferTypes = 0;
  std::string outputFilename;
  std::vector <std::string> sources;
  for (int i = 1; i < argc; i++) {
    if (std::string(argv[i]) == "--debug") {
      debug_level = 1;
    } else if (std::string(argv[i]) == "--print") {
      print = 1;
    } else if (std::string(argv[i]) == "--infer-types") {
      inferTypes = 1;
    } else if (std::string(argv[i]) == "--infer-types-td") {
      inferTypes = 2;
    } else if (std::string(argv[i]) == "--output") {
      outputFilename = argv[++i];
    } else {
      sources.push_back(std::string(argv[i]));
    }
  }

  std::ostream* output;
  if (outputFilename.empty())
    output = &std::cout;
  else
    output = new std::ofstream(outputFilename);

  for (std::string &source : sources) {
    driver.result = nullptr;
    driver.parse(source.c_str(), debug_level);

    AST::NodePtr ast = driver.result;
    if (inferTypes)
      TI::infer_types(ast, inferTypes == 2);
    if (print) {
      driver.result->print(*output);
      (*output) << std::endl;
    }
    delete ast;
  }

  if (!outputFilename.empty())
    delete output;

  return EXIT_SUCCESS;
}
