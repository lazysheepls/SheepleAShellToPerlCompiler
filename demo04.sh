#!/bin/dash

input=$1
for n in one two three
do
    read line           # read line
    echo Line $n $line              # echo line
    input=$((input + 5))
    input=`expr $input + 1`
done

echo new input is $input