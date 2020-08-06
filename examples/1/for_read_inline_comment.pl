#!/usr/bin/perl -w

foreach $n ('one', 'two', 'three') {
    $line = <STDIN>;
    chomp $line;           # coke is not pepsi
    print "Line $n $line\n";              # coke is not sprint
}
