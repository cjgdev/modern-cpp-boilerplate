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
import threading

def tee(infile, *files):
  """Print `infile` to `files` in a separate thread."""
  def fanout(infile, *files):
    for line in iter(infile.readline, b''):
      for f in files:
        s = line.decode('utf-8')
        s = s.replace('\r', '')
        s = s.replace('\t', '  ')
        s = s.rstrip() # strip spaces and EOL
        s += '\n' # append stripped EOL back
        f.write(s)
    infile.close()
  t = threading.Thread(target=fanout, args=(infile,)+files)
  t.daemon = True
  t.start()
  return t

def teed_call(cmd_args, logging):
  p = subprocess.Popen(
      cmd_args,
      stdout=subprocess.PIPE,
      stderr=subprocess.PIPE,
      env=os.environ,
      bufsize=0
  )
  threads = []

  if logging.verbose:
    threads.append(tee(p.stdout, logging.log_file, sys.stdout))
    threads.append(tee(p.stderr, logging.log_file, sys.stderr))
  else:
    threads.append(tee(p.stdout, logging.log_file))
    threads.append(tee(p.stderr, logging.log_file))

  for t in threads:
    t.join() # wait for IO completion

  return p.wait()

def call(call_args, logging, cache_file='', ignore=False):
  pretty = 'Execute command: [\n'
  for i in call_args:
    pretty += '  `{}`\n'.format(i)
  pretty += ']\n'
  print(pretty)
  logging.log_file.write(pretty)

  # print one line version
  oneline = ''
  for i in call_args:
    oneline += ' "{}"'.format(i)
  oneline = "[{}]>{}\n".format(os.getcwd(), oneline)
  if logging.verbose:
    print(oneline)
  logging.log_file.write(oneline)

  x = teed_call(call_args, logging)
  if x == 0 or ignore:
    return
  if os.path.exists(cache_file):
    os.unlink(cache_file)
  print('Command exit with status "{}": {}'.format(x, oneline))
  print('Log: {}'.format(logging.log_path))
  print('*** FAILED ***')
  sys.exit(1)
