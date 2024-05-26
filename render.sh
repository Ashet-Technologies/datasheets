#!/bin/sh

cd "$(dirname "$(realpath $0)")"

mkdir -p output temp

for path in $(find content -type f -name "*.md"); do 
  temp="output/${path#content/}"
  temp="${temp%.md}.pdf"
  mkdir -p "$(dirname "${temp}")"
  lua render.lua "${path}" "${temp}" "$@"
done
