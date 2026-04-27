#!/bin/sh

name=$"${1%.*}"
verilator --binary src/$1 -o $name -Mdir target 
echo ""
echo ""
echo ""
./target/$name
