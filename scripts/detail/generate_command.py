# Copyright (C) 2015 DataSift Ltd.
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

import difflib
import os
import sys

import detail.call

def run(generate_command, build_dir, build_temp_dir, reconfig, logging):
  if not os.path.exists(build_temp_dir):
    os.makedirs(build_temp_dir)
  saved_arguments_path = os.path.join(build_temp_dir, 'saved-arguments')
  cache_file = os.path.join(build_dir, 'CMakeCache.txt')

  generate_command_oneline = ' '.join(
      [ '"{}"'.format(x) for x in generate_command]
  )

  if reconfig or not os.path.exists(saved_arguments_path):
    detail.call.call(generate_command, logging, cache_file=cache_file)
    open(saved_arguments_path, 'w').write(generate_command_oneline)
    return

  # No need to generate project, just check that arguments not changed
  expected = open(saved_arguments_path, 'r').read()
  if expected != generate_command_oneline:
    sys.exit(
        "\n== WARNING ==\n"
        "\nLooks like cmake arguments changed."
        " You have two options to fix it:\n"
        "  * Remove build directory completely"
        " by adding '--clear' (works 100%)\n"
        "  * Run configure again by adding '--reconfigure'"
        " (you must understand how CMake cache variables works/updated)\n\n"
        "{}".format("\n".join(difflib.ndiff([expected], [generate_command_oneline])))
    )
