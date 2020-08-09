#!/bin/dash
# test03: if statements

if test Andrew = great
then
    echo tested
elif test Andrew = $1
then
    echo tested
elif [ -d /dev/null ]
then
    echo tested
elif [ -d $1 ]
then
    echo tested
elif test -r /dev/null
then
    echo -n tested
elif test $k -eq 1
then
    echo -n tested
elif test $number -gt 100000000 -o  $number -lt -100000000
then
    echo -n tested
else
    echo -n tested
fi

