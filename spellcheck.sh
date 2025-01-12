#!/bin/bash

ASPELL_DIR="$PWD/.aspell"
mkdir -p -- "$ASPELL_DIR"

for file in $(find docs -name "*.md" -type f)
do
    aspell check --mode=markdown --lang=en --home-dir="$ASPELL_DIR" -- "$file"
done
