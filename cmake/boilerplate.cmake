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

### setup options
## Include guard
if(NOT BOILERPLATE_LOADED)
    set(BOILERPLATE_LOADED ON)

    option(FULL_WARNINGS "Enable full warnings" ON)
    option(ENABLE_SSE4   "Enable SSE 4"         ON)

    if("${CMAKE_SYSTEM}" MATCHES "Linux")
        set(LINUX ON)
    endif()

    if(FULL_WARNINGS)
        set(CMAKE_C_FLAGS   "${CMAKE_C_FLAGS} -Wall -Wextra")
        set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -Wall -Wextra")
    endif()

    if(NOT WIN32)
        set(CMAKE_C_FLAGS   "${CMAKE_C_FLAGS} -fno-strict-aliasing")
        set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -fno-strict-aliasing")
    endif()

    if(LINUX)
        set(PLATFORM_PREFIX             "linux")
        if(CMAKE_SIZEOF_VOID_P MATCHES "8" )
            set(CMAKE_EXECUTABLE_SUFFIX ".bin.x86_64")
            set(LIB_RPATH_DIR           "lib64")
            set_property(GLOBAL PROPERTY FIND_LIBRARY_USE_LIB64_PATHS ON)
        else()
            set(LINUX_X86 ON)
            set(CMAKE_EXECUTABLE_SUFFIX ".bin.x86")
            set(LIB_RPATH_DIR           "lib")
            set_property(GLOBAL PROPERTY FIND_LIBRARY_USE_LIB64_PATHS OFF)

            ### Ensure LargeFileSupport on 32bit linux
            set(CMAKE_C_FLAGS           "${CMAKE_C_FLAGS} -D_FILE_OFFSET_BITS=64")
            set(CMAKE_CXX_FLAGS         "${CMAKE_CXX_FLAGS} -D_FILE_OFFSET_BITS=64")
        endif()

        ### Enable SSE instructions
        set(CMAKE_C_FLAGS               "${CMAKE_C_FLAGS} -msse -msse2 -msse3")
        set(CMAKE_CXX_FLAGS             "${CMAKE_CXX_FLAGS} -msse -msse2 -msse3")

        ### Enable SSE4 instructions
        if(ENABLE_SSE4)
            set(CMAKE_C_FLAGS           "${CMAKE_C_FLAGS} -msse4")
            set(CMAKE_CXX_FLAGS         "${CMAKE_CXX_FLAGS} -msse4")
        endif()

        set_property(GLOBAL PROPERTY LIBRARY_RPATH_DIRECTORY ${LIB_RPATH_DIR})

        set(CMAKE_SKIP_BUILD_RPATH              TRUE)
        set(CMAKE_BUILD_WITH_INSTALL_RPATH      TRUE)
        set(CMAKE_INSTALL_RPATH                 "\$ORIGIN/${LIB_RPATH_DIR}")
        set(CMAKE_INSTALL_RPATH_USE_LINK_PATH   FALSE)
    else()
        MESSAGE(FATAL_ERROR "Unhandled Platform")
    endif()

    ### Export parent scope
    if(NOT CMAKE_CURRENT_SOURCE_DIR STREQUAL CMAKE_SOURCE_DIR)
        message(STATUS "Exporting variables to parent scope")

        set(LINUX                               ${LINUX} PARENT_SCOPE)
        set(LINUX_X86                           ${LINUX_X86} PARENT_SCOPE)
        set(PLATFORM_PREFIX                     ${PLATFORM_PREFIX} PARENT_SCOPE)

        set(CMAKE_INCLUDE_CURRENT_DIR           ${CMAKE_INCLUDE_CURRENT_DIR} PARENT_SCOPE)

        set(CMAKE_C_FLAGS                       ${CMAKE_C_FLAGS} PARENT_SCOPE)
        set(CMAKE_CXX_FLAGS                     ${CMAKE_CXX_FLAGS} PARENT_SCOPE)

        set(CMAKE_SKIP_BUILD_RPATH              ${CMAKE_SKIP_BUILD_RPATH} PARENT_SCOPE)
        set(CMAKE_BUILD_WITH_INSTALL_RPATH      ${CMAKE_BUILD_WITH_INSTALL_RPATH} PARENT_SCOPE)
        set(CMAKE_INSTALL_RPATH                 ${CMAKE_INSTALL_RPATH} PARENT_SCOPE)
        set(CMAKE_INSTALL_RPATH_USE_LINK_PATH   ${CMAKE_INSTALL_RPATH_USE_LINK_PATH} PARENT_SCOPE)
        set(CMAKE_EXECUTABLE_SUFFIX             ${CMAKE_EXECUTABLE_SUFFIX} PARENT_SCOPE)
    endif()

    enable_testing()

## include guard
endif()