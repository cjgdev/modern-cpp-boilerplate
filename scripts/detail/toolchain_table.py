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
      Toolchain('sanitize-thread', 'Unix Makefiles'),
      Toolchain('sanitize-undefined', 'Unix Makefiles'),
  ]

if os.name == 'posix':
  toolchain_table += [
      Toolchain('analyze', 'Unix Makefiles'),
      Toolchain('coverage', 'Unix Makefiles'),
      Toolchain('gcc', 'Unix Makefiles'),
      Toolchain('sanitize-address', 'Unix Makefiles'),
  ]

def get_by_name(name):
  for x in toolchain_table:
    if name == x.name:
      return x
  sys.exit('Internal error: toolchain not found in toolchain table')
