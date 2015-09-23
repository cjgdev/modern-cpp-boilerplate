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
import platform

class Toolchain:
  def __init__(
      self,
      name,
      generator,
      arch='',
  ):
    self.name = name
    self.generator = generator
    self.arch = arch
    self.is_make = self.generator.endswith('Makefiles')
    self.verify()

  def verify(self):
    if self.arch:
      assert(self.arch == 'amd64' or self.arch == 'x86')

toolchain_table = []

if platform.system() == 'Linux':
  toolchain_table += [
      Toolchain('sanitize-leak', 'Unix Makefiles'),
      Toolchain('sanitize-memory', 'Unix Makefiles'),
      Toolchain('sanitize-thread', 'Unix Makefiles'),
      Toolchain('sanitize-undefined', 'Unix Makefiles'),
  ]

if os.name == 'posix':
  toolchain_table += [
      Toolchain('analyze', 'Unix Makefiles'),
      Toolchain('clang', 'Unix Makefiles'),
      Toolchain('clang-lto', 'Unix Makefiles'),
      Toolchain('gcc', 'Unix Makefiles'),
      Toolchain('gcc-lto', 'Unix Makefiles'),
      Toolchain('sanitize-address', 'Unix Makefiles'),
  ]

def get_by_name(name):
  for x in toolchain_table:
    if name == x.name:
      return x
  sys.exit('Internal error: toolchain not found in toolchain table')
