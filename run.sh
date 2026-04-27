#!/bin/sh

name=$"${1%.*}"
verilator --binary $1 -o $name -Mdir $name
echo ""
echo ""
echo ""
./$name/$name
