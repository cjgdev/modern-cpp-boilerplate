cmake_minimum_required(VERSION 2.8.11)

### build up utility functions
include(CheckCCompilerFlag)
include(CheckCXXCompilerFlag)

function(GitVersion _var)
    if(NOT GIT_FOUND)
        find_package(Git QUIET)
    endif()
    if(NOT GIT_FOUND)
        set(${_var} "GIT-NOTFOUND" PARENT_SCOPE)
        return()
    endif()
    set(format_params "'date : %ci, hash : %H'")
    execute_process(
        COMMAND
            "${GIT_EXECUTABLE}" show -s --format=${format_params} HEAD
        WORKING_DIRECTORY
            "${CMAKE_CURRENT_SOURCE_DIR}"
        RESULT_VARIABLE
            res
        OUTPUT_VARIABLE
            out
        ERROR_QUIET
        OUTPUT_STRIP_TRAILING_WHITESPACE
    )
    if(NOT res EQUAL 0)
        set(out "${out}-${res}-NOTFOUND")
    endif()
    set(${_var} "${out}" PARENT_SCOPE)
endfunction()

function(GenerateVersionInfo outvar)
    GitVersion(GIT_VERSION)
    configure_file(${CMAKE_CURRENT_SOURCE_DIR}/cmake/.version.h.in ${CMAKE_CURRENT_BINARY_DIR}/.version.h)
    configure_file(${CMAKE_CURRENT_SOURCE_DIR}/cmake/.version.cpp.in ${CMAKE_CURRENT_BINARY_DIR}/.version.cpp)
    set(${outvar} ${CMAKE_CURRENT_BINARY_DIR}/.version.cpp PARENT_SCOPE)
endfunction()

function(CheckCFlags outvar)
    foreach(flag ${ARGN})
        string(REGEX REPLACE "[^a-zA-Z0-9_]+" "_" cleanflag ${flag})
        check_cxx_compiler_flag(${flag} CHECK_C_FLAG_${cleanflag})
        if(CHECK_C_FLAG_${cleanflag})
            list(APPEND valid ${flag})
        endif()
    endforeach()
    set(${outvar} ${valid} PARENT_SCOPE)
endfunction()

function(CheckCXXFlags outvar)
    foreach(flag ${ARGN})
        string(REGEX REPLACE "[^a-zA-Z0-9_]+" "_" cleanflag ${flag})
        check_cxx_compiler_flag(${flag} CHECK_CXX_FLAG_${cleanflag})
        if(CHECK_CXX_FLAG_${cleanflag})
            list(APPEND valid ${flag})
        endif()
    endforeach()
    set(${outvar} ${valid} PARENT_SCOPE)
endfunction()

# Helper to ensures a scope has been set for certain target properties
macro(_SetDefaultScope var_name default_scope)
    list(GET ${var_name} 0 __setdefaultscope_temp)
    if(__setdefaultscope_temp STREQUAL "PRIVATE" OR __setdefaultscope_temp STREQUAL "PUBLIC" OR __setdefaultscope_temp STREQUAL "INTERFACE")
    else()
        list(INSERT ${var_name} 0 ${default_scope})
    endif()
    unset(__setdefaultscope_temp)
endmacro()

function(MakeCopyFileDepenency outvar file)
    if(IS_ABSOLUTE ${file})
        set(_input ${file})
    else()
        set(_input ${CMAKE_CURRENT_SOURCE_DIR}/${file})
    endif()
    if(ARGC GREATER "2")
        if(IS_ABSOLUTE ${ARGV2})
            set(_output ${ARGV2})
        else()
            set(_output ${CMAKE_CURRENT_BINARY_DIR}/${ARGV2})
        endif()
    else()
        get_filename_component(_outfile ${file} NAME)
        set(_output ${CMAKE_CURRENT_BINARY_DIR}/${_outfile})
    endif()

    add_custom_command(
        OUTPUT ${_output}
        COMMAND ${CMAKE_COMMAND} -E copy ${_input} ${_output}
        DEPENDS ${_input}
        COMMENT "Copying ${file}"
    )
    set(${outvar} ${_output} PARENT_SCOPE)
endfunction()

function(SetupCoverage target type)
    if (COVERAGE)
        if (NOT LCOV_PATH)
            find_program(LCOV_PATH lcov)
        endif()
        if (NOT LCOV_PATH)
            message(FATAL_ERROR "unable to find lcov!")
            return()
        endif()
        if (NOT GENHTML_PATH)
            find_program(GENHTML_PATH genhtml)
        endif()
        if (NOT GENHTML_PATH)
            message(FATAL_ERROR "unable to find genhtml!")
            return()
        endif()
        set_target_properties(${target}
            PROPERTIES
                COMPILE_FLAGS
                    "${CMAKE_CXX_FLAGS} -g -O0 -fprofile-arcs -ftest-coverage"
                LINK_FLAGS
                    "-fprofile-arcs"
        )
        if(type STREQUAL "test")
            add_custom_target(${target}_coverage
                # cleanup lcov
                ${LCOV_PATH} --directory . --zerocounters
                # run tests
                COMMAND $<TARGET_FILE:${name}>
                # capture lcov counters and generate report
                COMMAND ${LCOV_PATH} --directory . --capture --output-file ${target}_coverage.info
                COMMAND ${LCOV_PATH} --remove ${target}_coverage.info ${target}_coverage.info.cleaned
                COMMAND ${GENHTML_PATH} -o ${target}_coverage ${target}_coverage.info.cleaned
                COMMAND ${CMAKE_COMMAND} -E remove ${target}_coverage.info ${target}_coverage.info.cleaned
                WORKING_DIRECTORY
                    ${CMAKE_BINARY_DIR}
                COMMENT
                    "Processing code coverage counters and generating report"
            )
        endif()
    endif()
endfunction()

# magic function to handle the power functions below
function(_BuildDynamicTarget name type)
    GenerateVersionInfo(_version_file)
    set(_mode "files")
    foreach(dir ${ARGN})
        if(dir STREQUAL "EXCLUDE")
            set(_mode "excl")
        elseif(dir STREQUAL "DIRS")
            set(_mode "dirs")
        elseif(dir STREQUAL "FILES")
            set(_mode "files")
        elseif(dir STREQUAL "REFERENCE")
            set(_mode "reference")
        elseif(dir STREQUAL "INCLUDES")
            set(_mode "incl")
        elseif(dir STREQUAL "DEFINES")
            set(_mode "define")
        elseif(dir STREQUAL "PREFIX")
            set(_mode "prefix")
        elseif(dir STREQUAL "FLAGS")
            set(_mode "flags")
        elseif(dir STREQUAL "FEATURES")
            if(NOT COMMAND "target_compile_features")
                message(FATAL_ERROR "CMake 3.1+ is required to use this feature")
            endif()
            set(_mode ${dir})
        elseif(dir STREQUAL "LINK")
            set(_mode "link")
        elseif(dir STREQUAL "PROPERTIES")
            set(_mode "properties")
        elseif(dir STREQUAL "SHARED")
            set(type "shared")
        # Simple Copying files to build dir
        elseif(dir STREQUAL "COPY_FILES")
            set(_mode "copyfiles")
        # The real work
        else()
            if(_mode STREQUAL "excl")
                if (dir MATCHES "\\/\\*\\*$")
                    string(LENGTH ${dir} dir_LENGTH)
                    math(EXPR dir_LENGTH "${dir_LENGTH} - 3")
                    string(SUBSTRING ${dir} 0 ${dir_LENGTH} dir)

                    file(GLOB_RECURSE _files RELATIVE ${CMAKE_CURRENT_SOURCE_DIR}
                        ${dir}/*.*
                    )
                else()
                    file(GLOB _files RELATIVE ${CMAKE_CURRENT_SOURCE_DIR}
                        ${dir}
                    )
                endif()
                if(_files)
                    list(REMOVE_ITEM _source_files
                        ${_files}
                    )
                endif()
                set(_files)
            elseif(_mode STREQUAL "files")
                if (dir MATCHES "\\*")
                    file(GLOB _files RELATIVE ${CMAKE_CURRENT_SOURCE_DIR}
                        ${dir}
                    )
                else()
                    set(_files ${dir})
                endif()
                if(_files)
                    list(APPEND _source_files
                        ${_files}
                    )
                endif()
                set(_files)
            elseif(_mode STREQUAL "incl")
                list(APPEND _include_dirs
                    ${dir}
                )
            elseif(_mode STREQUAL "define")
                list(APPEND _definitions
                    ${dir}
                )
            elseif(_mode STREQUAL "flags")
                list(APPEND _flags
                    ${dir}
                )
            elseif(_mode STREQUAL "FEATURES")
                list(APPEND _features
                    ${dir}
                )
            elseif(_mode STREQUAL "link")
                list(APPEND _link_libs
                    ${dir}
                )
            elseif(_mode STREQUAL "properties")
                list(APPEND _properties
                    ${dir}
                )
            elseif(_mode STREQUAL "reference")
                if (dir MATCHES "\\*")
                    file(GLOB _files RELATIVE ${CMAKE_CURRENT_SOURCE_DIR}
                        ${dir}
                    )
                else()
                    set(_files ${dir})
                endif()
                if(_files)
                    list(APPEND _reference
                        ${_files}
                    )
                endif()
                set(_files)
            elseif(_mode STREQUAL "prefix")
                if(IS_ABSOLUTE ${dir})
                    list(APPEND _flags
                        PRIVATE "-include ${dir}"
                    )
                elseif(EXISTS ${CMAKE_CURRENT_SOURCE_DIR}/${dir})
                    list(APPEND _flags
                        PRIVATE -include ${CMAKE_CURRENT_SOURCE_DIR}/${dir}
                    )
                else()
                    message(FATAL_ERROR "could not find prefix header")
                endif()
            elseif(_mode STREQUAL "dirs")
                if (dir STREQUAL ".")
                    set(dir ${CMAKE_CURRENT_SOURCE_DIR})
                endif()
                if (dir MATCHES "\\/\\*\\*$")
                    string(LENGTH ${dir} dir_LENGTH)
                    math(EXPR dir_LENGTH "${dir_LENGTH} - 3")
                    string(SUBSTRING ${dir} 0 ${dir_LENGTH} dir)

                    file(GLOB_RECURSE _files RELATIVE ${CMAKE_CURRENT_SOURCE_DIR}
                        ${dir}/*.c
                        ${dir}/*.cpp
                        ${dir}/*.cxx
                        ${dir}/*.cc
                        ${dir}/*.h
                        ${dir}/*.hpp
                        ${dir}/*.inl
                        ${dir}/*.m
                        ${dir}/*.mm
                        ${dir}/*.proto
                    )
                else()
                    file(GLOB _files RELATIVE ${CMAKE_CURRENT_SOURCE_DIR}
                        ${dir}/*.c
                        ${dir}/*.cpp
                        ${dir}/*.cxx
                        ${dir}/*.cc
                        ${dir}/*.h
                        ${dir}/*.hpp
                        ${dir}/*.inl
                        ${dir}/*.m
                        ${dir}/*.mm
                        ${dir}/*.proto
                    )
                endif()
                if(_files)
                    list(APPEND _source_files
                        ${_files}
                    )
                endif()
            # simple copy files
            elseif(_mode STREQUAL "copyfiles")
                file(GLOB_RECURSE _files RELATIVE ${CMAKE_CURRENT_SOURCE_DIR} ${dir})
                foreach(_file ${_files})
                    set(_output ${CMAKE_CURRENT_BINARY_DIR}/${_file})
                    MakeCopyFileDepenency(_copyfile
                        ${_file}
                        ${_output}
                    )
                    list(APPEND _source_files
                        ${_copyfile}
                    )
                    unset(_copyfile)
                endforeach()
            else()
                message(FATAL_ERROR "Unknown Mode ${_mode}")
            endif()
        endif()
    endforeach()
    if (NOT _source_files)
        message(FATAL_ERROR "Could not find any sources for ${name}")
    endif()
    foreach(_file ${_source_files})
        get_filename_component(_file_ext ${_file} EXT)
        string(TOLOWER ${_file_ext} _file_ext)
        if(${_file_ext} MATCHES ".proto")
            list(REMOVE_ITEM _source_files
                ${_file}
            )
            PROTOBUF_GENERATE_CPP(_proto_src _proto_hdr ${_file})
            list(APPEND _source_files
                ${_proto_src} ${_proto_hdr}
            )
        endif()
    endforeach()
    list(APPEND _source_files ${_version_file})
    if(_reference)
        list(APPEND _source_files ${_reference})
        set_source_files_properties(${_reference}
            PROPERTIES
                HEADER_FILE_ONLY TRUE
        )
    endif()
    if(type STREQUAL "lib")
        add_library(${name} STATIC EXCLUDE_FROM_ALL
            ${_source_files}
        )
    elseif(type STREQUAL "shared")
        add_library(${name} SHARED
            ${_source_files}
        )
    elseif(type STREQUAL "object")
        add_library(${name} OBJECT
            ${_source_files}
        )
    elseif(type STREQUAL "module")
        add_library(${name} MODULE
            ${_source_files}
        )
    elseif(type STREQUAL "tool")
        add_executable(${name}
            ${_source_files}
        )
    elseif(type STREQUAL "test")
        add_executable(${name}
            ${_source_files}
        )
        add_test(NAME ${name} COMMAND $<TARGET_FILE:${name}>)
    else()
        add_executable(${name} MACOSX_BUNDLE WIN32
            ${_source_files}
        )
    endif()
    if(_include_dirs)
        _SetDefaultScope(_include_dirs PRIVATE)
        target_include_directories(${name} ${_include_dirs})
    endif()
    if(_definitions)
        _SetDefaultScope(_definitions PRIVATE)
        target_compile_definitions(${name} ${_definitions})
    endif()
    if(_features)
        _SetDefaultScope(_features PRIVATE)
        target_compile_features(${name} ${_features})
    endif()
    if(_link_libs)
        target_link_libraries(${name} ${_link_libs})
    endif()
    if(_flags)
        _SetDefaultScope(_flags PRIVATE)
        target_compile_options(${name} ${_flags})
    endif()
    if(_properties)
        set_target_properties(${name} PROPERTIES
            ${_properties}
        )
    endif()
    SetupCoverage(${name} ${type})
endfunction()

## These two power functions build up library and program targets
## 
## the parameters are simply the target name followed by a list of directories or other parameters
## parameters that can be specified
## FILES      followed by a list of explicit files/globs to add (or generated files).
## DIRS       followed by a list of directories ..  will glob in *.c, *.cpp, *.h, *.hpp, *.inl, *.m, *.mm
##                      If you end the string with ** it will pull in recursively.
## REFERENCE  followed by a list of explicit files/globs to add.
##                      These files will be available in the IDE, but will NOT be compiled. (ini files, txt files)
## EXCLUDE    followed by a list of files/globs to exclude
## INCLUDES   followed by a list of include directories.
##                      These use Generator expressions (see CMAKE documentation) default is PRIVATE scoped
## DEFINES    followed by a list of compiler defines.
##                      These use Generator expressions (see CMAKE documentation) default is PRIVATE scoped
## FLAGS      followed by a list of compiler flags.
##                      These use Generator expressions (see CMAKE documentation) default is PRIVATE scoped
## FEATURES   followed by a list of compiler features (cmake 3.1+).
##                      These use Generator expressions (see CMAKE documentation) default is PRIVATE scoped
## PREFIX     followed by a header. Basic prefix header support..  currently only GCC/Clang is supported.
## LINK       followed by a list of link targets.  Can use Generator expressions (see CMAKE documentation)
## PROPERTIES followed by a list of target properties.
## COPY_FILES followed by a list of files to copy to the build directory.
##                      If relative, assumes relative to source dir
function(CreateSharedLibrary name)
    _BuildDynamicTarget(${name} shared ${ARGN})
endfunction()

function(CreateObjectLibrary name)
    _BuildDynamicTarget(${name} object ${ARGN})
endfunction()

function(CreateModule name)
    _BuildDynamicTarget(${name} module ${ARGN})
endfunction()

function(CreateLibrary name)
    _BuildDynamicTarget(${name} lib ${ARGN})
endfunction()

function(CreateProgram name)
    _BuildDynamicTarget(${name} exe ${ARGN})
endfunction()

function(CreateTool name)
    _BuildDynamicTarget(${name} tool ${ARGN})
endfunction()

function(CreateTest name)
    _BuildDynamicTarget(${name} test ${ARGN})
endfunction()