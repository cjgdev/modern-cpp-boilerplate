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

cmake_minimum_required(VERSION 2.8.12)
project(mybinary)

### pull in boilerplate cmake
set(CMAKE_MODULE_PATH "${CMAKE_CURRENT_SOURCE_DIR}/cmake")
include(boilerplate)

# this sets the paths that cmake will use to locate libs (via the FindXXX.cmake or XXConfig.cmake scripts)
LIST(APPEND CMAKE_MODULE_PATH ${CMAKE_CURRENT_SOURCE_DIR}/vendor)

include(utility_functions)

### Find Libraries
find_package(Boost 1.59.0 COMPONENTS regex system filesystem REQUIRED)
find_package(Catch)
find_package(Threads)

## Setup libs
CreateLibrary(mylibrary
    DIRS
        src/mylibrary/**
    INCLUDES
        PUBLIC
            src/mylibrary
        PRIVATE
            ${Boost_INCLUDE_DIRS}
            ${CATCH_INCLUDE_DIRS}
    DEFINES
        PUBLIC
            $<$<BOOL:${LINUX}>:PLATFORM_LINUX>
            $<$<CONFIG:Debug>:BUILD_DEBUG>
            $<$<NOT:$<CONFIG:Debug>>:BUILD_PRODUCTION>
    LINK
        ${Boost_LIBRARIES}
        ${CMAKE_THREAD_LIBS_INIT}
    PROPERTIES
        FOLDER Libraries
)

## Setup binaries
CreateProgram(mybinary
    DIRS
        src/mybinary/**
    INCLUDES
        PUBLIC
            src/mybinary
    LINK
        mylibrary
        ${Boost_LIBRARIES}
        ${CMAKE_THREAD_LIBS_INIT}
    PROPERTIES
        FOLDER Executables
)

## this auto copies the needed libraries over
CopyDependentLibs(${PROJECT_NAME})
