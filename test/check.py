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

import os, shutil, sys, subprocess, difflib, json, time, urllib2

def check(was):
  FAIL = '\033[91m'
  PASS = '\033[92m'
  WARN = '\033[93m'
  ENDC = '\033[0m'

  print 'Checking', was.ljust(32),
  todo_count = open(was, 'r').read().count("TODO");
  trace_file = os.path.basename(was) + '.trace';
  args = [os.path.join('..', 'was'), was]
  trace_file_exists = os.path.exists(trace_file)
  if trace_file_exists:
    args.append("--print")
    todo_count += open(trace_file, 'r').read().count("TODO");
  proc = subprocess.Popen(args, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
  out, err = proc.communicate()
  passed = (proc.returncode == 0) == was.endswith('pass')
  sys.stdout.write('PARSE')
  if passed and trace_file_exists:
    sys.stdout.write(' + TRACE')
    args = [os.path.join('..', 'was'), trace_file, '--print']
    proc = subprocess.Popen(args, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    trace, err = proc.communicate()
    if out != trace:
      passed = False
  if passed:
    sys.stdout.write(' ' + PASS + 'OK' + ENDC)
  else:
    sys.stdout.write(' ' + FAIL + 'FAIL' + ENDC)
  if todo_count:
    sys.stdout.write(", " + WARN + "TODOs " + str(todo_count) + ENDC)
  print
  return passed

def check_parse():
  print '\n[ checking parsing ... ]\n'
  some_failed = False
  for was in sorted(os.listdir('.')):
    if not was.endswith('pass') and not was.endswith('fail'): continue
    if not check(was):
      some_failed = True
  assert not some_failed

check_parse()