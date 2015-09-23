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

import os
import subprocess

import detail.call

def run(config, logging, cpack_generator):
  pack_command = ['cpack']
  if os.name == 'nt':
    # use full path to cpack since Chocolatey pack command has the same name
    cmake_list = subprocess.check_output(
        ['where', 'cmake'], universal_newlines=True
    )
    cmake_path = cmake_list.split('\n')[0]
    cpack_path = os.path.join(os.path.dirname(cmake_path), 'cpack')
    pack_command = [cpack_path]
  if config:
    pack_command.append('-C')
    pack_command.append(config)
  pack_command.append('--verbose')
  if cpack_generator:
    pack_command.append('-G{}'.format(cpack_generator))
  detail.call.call(pack_command, logging)
