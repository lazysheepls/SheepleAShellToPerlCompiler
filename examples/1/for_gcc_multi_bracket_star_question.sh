#!/bin/dash
for c_file in *[de]?[abcd]*.c
do
    echo gcc -c $c_file
done
