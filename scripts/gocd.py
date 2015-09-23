#!/usr/bin/env python3

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
import sys

def run():
  toolchain = os.getenv('TOOLCHAIN')
  if not toolchain:
    sys.exit('Environment variable TOOLCHAIN is empty')

  config = os.getenv('CONFIG')
  if not config:
    sys.exit('Environment variable CONFIG is empty')

  build = os.path.join(os.path.dirname(os.path.realpath(__file__)), 'build.py')

  print('Run script: {}'.format(build))
  print('Toolchain: {}'.format(toolchain))
  print('Config: {}'.format(config))

  args = [
      sys.executable,
      build,
      '--toolchain',
      toolchain,
      '--config',
      config,
      '--verbose',
      '--clear',
      '--test'
  ]

  try:
    subprocess.check_call(args)
  except subprocess.CalledProcessError as error:
    print(error)
    print(error.output)
    sys.exit(1)

if __name__ == '__main__':
  run()