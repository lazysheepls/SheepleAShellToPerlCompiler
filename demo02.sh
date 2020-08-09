#!/bin/dash
# demo02: find all demo files in the current folder

#Find file name
counter=0
for file_name in demo0*.sh
do
    echo "looking for $file_name"

    if [ -f $file_name ]
    then
        echo "$file_name exists"
    else
        # should never enter here
        echo "$file_name does not exists"
    fi

    counter=$((counter + 1))
done

echo "number of demo files is $counter"