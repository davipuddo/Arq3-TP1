#!/bin/sh

file=$1
name=$"${1%.*}"

comp_verb() {
    verilator --timing -Wno-UNOPTFLAT --binary src/$file -o $name -Mdir target $1
}

comp_silent() {
    verilator --timing -Wno-UNOPTFLAT --binary src/$file -o $name -Mdir target $1 > /dev/null
}

if [ $# == 0 ]; then
    file="testbench.sv"
    name="testbench"
    comp_silent
fi

if [ $# -lt 2 ]; then

    if [ "$1" == "--verbose" ]; then
        file="testbench.sv"
        name="testbench"
        comp_verb
    else
        comp_silent 
    fi

elif [ $# == 2 ] && [ "$2" == "--dump" ]; then
    comp_verb "--trace"
elif [ $# == 2 ] && [ "$2" == "--verbose" ]; then
    comp_verb
fi

printf "\n\n\n"

if [ -f ./target/$name ]; then
    ./target/$name
else
    echo "Error: No file named [$name] was found at target!"
    echo "Has the program compiled correctly?"
fi
