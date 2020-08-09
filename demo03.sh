#!/bin/dash
# demo03: get user input and determine size
size=$1

if [ $size -lt 10 ]
then
    echo "$size is small"
elif [ "$size" -lt 100 ]
then
    echo "$size is medium"
else
    echo "$size is large"
fi