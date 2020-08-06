#!/usr/bin/perl -w
foreach $c_file (glob("*[de]?[abcd]*.c")) {
    print "gcc -c $c_file\n";
}
