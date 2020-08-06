#!/usr/bin/perl -w

# in-line

foreach $c_file (glob("[abcd]*.c")) {
    # in-line
    print "gcc -c $c_file\n";

    # in-line
}
