#!/bin/bash

ASPELL_DIR="$PWD/.aspell"

spellcheck() {
	local file="$1"
	aspell check --mode=markdown --lang=en --home-dir="$ASPELL_DIR" -- "$file"
}

mkdir -p -- "$ASPELL_DIR"

if [[ "$1" != "" ]]
then
	spellcheck "$1"
	exit
fi

for file in $(find docs -name "*.md" -type f)
do
	spellcheck "$file"
done
