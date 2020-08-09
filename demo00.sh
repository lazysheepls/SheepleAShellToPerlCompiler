#!/bin/dash
# demo 00

for file in *.sh
do
    # Get email address
    echo -n "Address to e-mail this shell file to? "
    read email

    # Get message
    echo "enter message down below"
    read message

    # Send email
    echo "here is a short summary"
    echo $file sent to $email    
    echo "$message"
done