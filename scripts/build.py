#!/usr/bin/env python3

# Copyright (C) 2015 Christopher Gilbert
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

import argparse
import os
import platform
import shutil
import sys

import detail.call
import detail.cpack_generator
import detail.generate_command
import detail.logging
import detail.pack_command
import detail.test_command
import detail.timer
import detail.toolchain_name
import detail.toolchain_table

toolchain_table = detail.toolchain_table.toolchain_table

assert(sys.version_info.major == 3)
assert(sys.version_info.minor >= 2)

print(
    'Python version: {}.{}'.format(
        sys.version_info.major, sys.version_info.minor
     )
)

description="""
Script for building. Available toolchains:\n
"""

for x in toolchain_table:
  description += '  ' + x.name + '\n'

parser = argparse.ArgumentParser(
    formatter_class=argparse.RawDescriptionHelpFormatter,
    description=description
)

parser.add_argument(
    '--toolchain',
    choices=[x.name for x in toolchain_table],
    help="CMake generator/toolchain",
)

parser.add_argument(
    '--config',
    help="CMake build type (Release, Debug, ...)",
)

parser.add_argument(
    '--home',
    help="Project home directory (directory with CMakeLists.txt)"
)

parser.add_argument('--test', action='store_true', help="Run ctest after build")
parser.add_argument('--test-xml', help="Save ctest output to xml")

parser.add_argument(
    '--pack',
    choices=detail.cpack_generator.available_generators,
    nargs='?',
    const=detail.cpack_generator.default(),
    help="Run cpack after build"
)
parser.add_argument(
    '--nobuild', action='store_true', help="Do not build (only generate)"
)
parser.add_argument('--verbose', action='store_true', help="Verbose output")
parser.add_argument(
    '--install', action='store_true', help="Run install (local directory)"
)
parser.add_argument(
    '--strip', action='store_true', help="Run strip/install cmake targets"
)
parser.add_argument(
    '--clear',
    action='store_true',
    help="Remove build and install dirs before build"
)
parser.add_argument(
    '--reconfig',
    action='store_true',
    help="Run configure even if CMakeCache.txt exists. Used to add new args."
)
parser.add_argument(
    '--fwd',
    nargs='*',
    help="Arguments to cmake without '-D', like:\nBOOST_ROOT=/some/path"
)
parser.add_argument(
    '--jobs',
    type=int,
    help="Number of concurrent build operations"
)

args = parser.parse_args()

build_toolchain = detail.toolchain_name.get(args.toolchain)
toolchain_entry = detail.toolchain_table.get_by_name(build_toolchain)
cpack_generator = args.pack

build_root = os.path.join(os.path.dirname(os.path.realpath(__file__)), '..')
build_root = os.path.realpath(build_root)

"""Build directory tag"""
if args.config:
  build_tag = "{}-{}".format(build_toolchain, args.config)
else:
  build_tag = build_toolchain

"""Tune environment"""
cdir = os.getcwd()

toolchain_path = os.path.join(build_root, "{}.cmake".format(build_toolchain))
if not os.path.exists(toolchain_path):
  sys.exit("Toolchain file not found: {}".format(toolchain_path))
toolchain_option = "-DCMAKE_TOOLCHAIN_FILE={}".format(toolchain_path)

build_dir = os.path.join(cdir, 'build', build_tag)
print("Build dir: {}".format(build_dir))
build_dir_option = "-B{}".format(build_dir)

install_dir = os.path.join(cdir, '_install', build_toolchain)
local_install = args.install

if args.strip:
  if not toolchain_entry.is_make:
    sys.exit('CMake install/strip targets are only supported for the Unix Makefile generator')
  if not args.install: # strip will always imply --install 
    local_install = True 

strip_install = args.strip

if local_install:
  install_dir_option = "-DCMAKE_INSTALL_PREFIX={}".format(install_dir)

if args.clear:
  if os.path.exists(build_dir):
    print("Remove build directory: {}".format(build_dir))
    shutil.rmtree(build_dir)
  if os.path.exists(install_dir):
    print("Remove install directory: {}".format(install_dir))
    shutil.rmtree(install_dir)
  if os.path.exists(build_dir):
    sys.exit("Directory removing failed ({})".format(build_dir))
  if os.path.exists(install_dir):
    sys.exit("Directory removing failed ({})".format(install_dir))

build_temp_dir = os.path.join(build_dir, 'logs')
if not os.path.exists(build_temp_dir):
  os.makedirs(build_temp_dir)
logging = detail.logging.Logging(build_temp_dir, args.verbose)

if os.name != 'nt':
  detail.call.call(['which', 'cmake'], logging)
detail.call.call(['cmake', '--version'], logging)

home = '.'
if args.home:
  home = args.home

generate_command = [
    'cmake',
    '-H{}'.format(home),
    build_dir_option
]

if args.config:
  generate_command.append("-DCMAKE_BUILD_TYPE={}".format(args.config))

if toolchain_entry.generator:
  generate_command.append('-G{}'.format(toolchain_entry.generator))

if toolchain_option:
  generate_command.append(toolchain_option)

generate_command.append('-DCMAKE_VERBOSE_MAKEFILE=ON')

if local_install:
  generate_command.append(install_dir_option)

if cpack_generator:
  generate_command.append('-DCPACK_GENERATOR={}'.format(cpack_generator))

if args.fwd != None:
  for x in args.fwd:
    generate_command.append("-D{}".format(x))

timer = detail.timer.Timer()

timer.start('Generate')
detail.generate_command.run(
    generate_command, build_dir, build_temp_dir, args.reconfig, logging
)
timer.stop()

build_command = [
    'cmake',
    '--build',
    build_dir
]

if args.config:
  build_command.append('--config')
  build_command.append(args.config)

if local_install:
  build_command.append('--target')
  if strip_install:
    build_command.append('install/strip')
  else:
    build_command.append('install')

# NOTE: This must be the last `build_command` modification!
build_command.append('--')

if args.jobs:
  if toolchain_entry.is_make:
    build_command.append('-j')
    build_command.append('{}'.format(args.jobs))

if not args.nobuild:
  timer.start('Build')
  detail.call.call(build_command, logging)
  timer.stop()

if not args.nobuild:
  os.chdir(build_dir)
  if args.test or args.test_xml:
    timer.start('Test')
    detail.test_command.run(build_dir, args.config, logging, args.test_xml)
    timer.stop()
  if args.pack:
    timer.start('Pack')
    detail.pack_command.run(args.config, logging, cpack_generator)
    timer.stop()

print('-')
print('Log saved: {}'.format(logging.log_path))
print('-')
timer.result()
print('-')
print('SUCCESS')