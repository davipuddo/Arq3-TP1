#!/bin/sh

file=$1
name=$"${1%.*}"

comp() {
    verilator --timing -Wno-UNOPTFLAT --binary src/$file -o $name -Mdir target $1
}

if [ $# == 1 ]; then
    comp
else [ $# == 2 ] && [ "$2" == "--dump" ]
    comp "--trace"
fi

printf "\n\n\n"

if [ -f ./target/$name ]; then
    ./target/$name
else
    echo "Error: No file named [$name] was found at target!"
    echo "Has the program compiled correctly?"
fi
