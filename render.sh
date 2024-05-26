#!/bin/sh

set -eu

cd "$(dirname "$(realpath $0)")"

mkdir -p output temp

for path in $(find content -type f -name "*.md"); do 
  echo "Process ${path#content/}"
  output="$(lua render.lua "${path}" "$@")"
  if [ ! -z "${output}" ]; then
    folder="output/$(echo "${output}" | cut -d : -f 1)"
    srcfile="$(echo "${output}" | cut -d : -f 2)"
    mkdir -p "${folder}"
    mv "${srcfile}" "${folder}"
  fi
done
