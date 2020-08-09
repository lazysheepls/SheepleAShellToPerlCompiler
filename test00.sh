#!/bin/dash
# test00: test full line and inline comment

# full line comment

for word in Houston 1202 alarm # some random comment here
do
    echo $word      # this is an echo cmd
    # more useless comment here
    exit			    # this is an exit cmd
done