#!/bin/dash
for c_file in [abcd]*.c
do
    echo gcc -c $c_file
done
