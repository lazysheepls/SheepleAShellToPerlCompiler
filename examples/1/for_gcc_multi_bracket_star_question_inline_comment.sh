#!/bin/dash
for c_file in *[de]?[abcd]*.c       # comment
do      # comment
    echo gcc -c $c_file
done        # comment
