#!/bin/bash

set -x

for x in "$@"; do
  if [ "${x}" == "-c" ]; then
    TEMP_OUT="`mktemp /tmp/clang-analyze.out.XXXXX`"
    TEMP_BIN="`mktemp /tmp/clang-analyze.bin.XXXXX`"

    # analyze
    clang++ --analyze "$@" -o "${TEMP_BIN}" 2> "${TEMP_OUT}"

    RESULT=0
    [ "$?" == 0 ] || RESULT=1
    [ -s "${TEMP_OUT}" ] && RESULT=1

    cat "${TEMP_OUT}";
    rm -f "${TEMP_OUT}"
    rm -f "${TEMP_BIN}"

    if [ "${RESULT}" == "1" ]; then
      exit 1;
    fi
  fi
done

# compile real code
clang++ "$@"