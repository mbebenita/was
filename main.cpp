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

#include <cstdlib>
#include <iostream>
#include <fstream>
#include <string>
#include <vector>

#include "was_scanner.hpp"
#include "ti.hpp"

AST::NodePtr parse(const char *const filename, int debug_level) {
  std::ifstream in_file(filename);
  if (!in_file.good())
    exit(EXIT_FAILURE);
  WAS::WAS_Scanner scanner(&in_file);
  AST::NodePtr result;
  WAS::WAS_Parser parser(scanner, &result);
  parser.set_debug_level(debug_level);
  const int success(0);
  if (parser.parse() != success)
      return nullptr;
  return result;
}

int main(const int argc, const char **argv) {
  if (argc < 2)
    return EXIT_FAILURE;

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
    AST::NodePtr ast = parse(source.c_str(), debug_level);
    if (!ast) {
      std::cerr << "Parse failed!!\n";
      return EXIT_FAILURE;
    }

    if (inferTypes)
      TI::infer_types(ast, inferTypes == 2);
    if (print) {
      ast->print(*output);
      (*output) << std::endl;
    }
    delete ast;
  }

  if (!outputFilename.empty())
    delete output;

  return EXIT_SUCCESS;
}
