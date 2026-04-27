#!/bin/sh

name=$"${1%.*}"
verilator --binary src/$1 -o $name -Mdir target 
echo ""
echo ""
echo ""
if [ -f ./target/$name ]; then
    ./target/$name
else
    echo "Error: No file named [$name] was found at target!"
    echo "Has the program compiled correctly?"
fi
