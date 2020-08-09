#!/bin/dash
# test01: for and while loop and string match

# while loop
while test Andrew = great
do
    echo correct
done

# for loop with []
for c_file in [abcd]*.c
do
    echo gcc -c $c_file
done

# for loop with  ? and *
for c_file in *[de]?[abcd]*.c       # comment
do      # comment
    echo gcc -c $c_file
done        # comment