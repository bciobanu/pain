#/usr/bin/env bash
shopt -s extglob
./node_modules/.bin/prettier *.@(html|json|js) **/*.@(ts|tsx) "$@"
