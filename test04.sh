#!/bin/dash
# test04: exprsions 

number=`expr $number + 1`

i=`expr $i + 1`

k=`expr $number % 2`

number=`expr 7 '*' $number + 3`

number=`expr 12 \* 2`

number=`expr length $x`

i=$((i + 1))

i=$((i - 1))

i=$((i / 1))

i=$((i % 1))

number=$($i "<" 5 "|" 19  -  6 ">" 10)

