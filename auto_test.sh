#!/bin/sh
folder="examples"
sub_folder=$1

dir="$folder/$sub_folder/"
for file in "$dir"*.sh
do
    file_name=`echo "$file" | sed "s/$folder\/$sub_folder\///g;s/\..*$//g"`
    shell_file="$file_name"".sh"
    perl_file="$file_name"".pl"
    echo "Checking $file_name ..."
    `2041 ./sheeple.pl "$folder/$sub_folder/$shell_file" > tmp.pl`
    if ! diff tmp.pl $folder/$sub_folder/$perl_file >/dev/null
    then
        echo "!!different!!"
    fi
done