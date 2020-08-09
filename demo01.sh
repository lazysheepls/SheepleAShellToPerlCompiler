#!/bin/dash
# demo01: print a sequence of odd integer numbers
start=$1
finish=$2

start_remainder=$((start % 2))
finish_remainder=$((finish % 2))

number=$start
if test $start_remainder -eq 0 -o $finish_remainder -eq 0
then
    echo "not a odd number"
    exit 1
fi 

while test $number -le $finish
do
    echo $number
    number=`expr $number + 2`  # increase by 2
done