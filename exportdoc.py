#!/usr/bin/env python

# Copyright 2016 WebAssembly Community Group participants
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

import sys, re

def read_yy():
  with open('was_parser.yy', 'r') as f:
    read_data = f.read()
  grammar_content = re.compile(r"%%\n([\s\S]*)%%", re.M);
  m = grammar_content.search(read_data)
  remove_c_code = re.compile(r"\s+{\s[^}]*[^\n]*", re.M);
  no_code = re.sub(remove_c_code, "", m.group(1))
  return no_code

def read_l():
  with open('was_lexer.l', 'r') as f:
    read_data = f.read()
  remove_c_code = re.compile(r"%\{((?!%\})[\s\S])*%\}", re.M);
  remove_c_header = re.compile(r"/\*((?!\*/)[\s\S])*\*/\s*", re.M);
  no_code = re.sub(remove_c_code, "", re.sub(remove_c_header, "", read_data));
  remove_options = re.compile(r"^%\w[^\n]*\n", re.M);
  no_options = re.sub(remove_options, "", no_code);
  lexer_content = re.compile(r"\n*([\s\S]*)%%\n([\s\S]*)%%", re.M);
  m = lexer_content.search(no_options)
  sequences = m.group(1)
  tokens = m.group(2)
  simplify_tokens = re.compile(r"(\s+)\{.*?return\s+token::([^;]+);\s+\}", re.M)
  simplified_tokens = re.sub(simplify_tokens, r"\1\2", tokens)
  removed_trivial = re.sub(r"\n\x22([^\x22]+)\x22\s+\{.*?return\('\1'\)[^\n]+", "",simplified_tokens)
  removed_stats = re.sub(r"(\s+)\{\s+BEGIN\(([^\)]+)\);\s+\}", r"\1STATE:\2", removed_trivial)
  removed_code = re.sub(r"(\s+)\{[^\}]+\}[^\n]*", "", removed_stats);
  return sequences + removed_code

print "# Grammar Rules"
print
print read_yy()
print
print "# Scanner/Lexer"
print
print read_l()
print