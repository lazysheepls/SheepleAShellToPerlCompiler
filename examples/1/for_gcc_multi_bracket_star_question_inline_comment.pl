#!/usr/bin/perl -w
foreach $c_file (glob("*[de]?[abcd]*.c"))        # comment
{      # comment
    print "gcc -c $c_file\n";
}        # comment
