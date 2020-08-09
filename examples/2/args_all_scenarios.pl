#!/usr/bin/perl -w

print "My first argument is $ARGV[0]\n";
print "My first argument is $ARGV[0] $ARGV[1] $ARGV[2] $ARGV[3]\n";
$b = $ARGV[1];

#arg in the comment (don't translate)
print "My first argument is $ARGV[0] $ARGV[1] $ARGV[2] $ARGV[3]\n"; # $1 $2 $3 $4
$a = $ARGV[4]; # $5
