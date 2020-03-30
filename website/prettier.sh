#/usr/bin/env sh
shopt -s extglob
./node_modules/.bin/prettier *.@(html|json|js) **/*.ts **/*.tsx "$@"
