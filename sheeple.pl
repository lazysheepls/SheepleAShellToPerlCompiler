#!/usr/bin/perl

use warnings;
use strict;
my $empty_line_regex = qr/^\s*$/;
my $inline_comment_regex = qr/(?<content>.*)(?<comment>\s+#.*)$/;
my $fullline_comment_regex = qr/^(?<comment>\s*#.*)$/;
my $echo_regex = qr/(?<spaces>\s*)echo\s*(?<content>.*)/;

# read shell file
my $file_name = $ARGV[0];
my @lines = ();
open my $fh, "<", $file_name;
    @lines = <$fh>;
close $fh;

# process shell script
print "#!/usr/bin/perl -w\n";
process_lines(@lines);
print "\n";

# func: process each line in shell and translate to perl
sub process_lines{
    my (@lines) = @_;
    my $line = "";

    # remove the first line (#!/bin/dash)
    $line = shift @lines;

    for $line (@lines){
        if ($line =~ /$empty_line_regex/){
            print $line;
        }
        elsif ($line =~ /$fullline_comment_regex/){
            print $line;
        }
        elsif ($line =~ /$echo_regex/){
            process_echo($line);
        }
    }
}

# func: process echo build-in program
# e.g: echo hello word #comment here
#      echo ($content) ($comment)
sub process_echo{
    my ($line) = @_;
    my $spaces = "";
    my $content = "";
    my $comment = "";
    return undef unless ($line =~ /$echo_regex/);
    
    # get content after echo (echo >"hello world"<)
    $spaces = "$+{spaces}";
    $content = "$+{content}";

    # process in-line comment if any
    if ($content =~ /$inline_comment_regex/){
        my %match_result = ();
        %match_result = process_inline_comment($content);
        $content = $match_result{"content"};
        $comment = $match_result{"comment"};
    }

    print "$spaces";
    print "print \"";
    print "$content";
    print "\\n\"";
    print ";";
    print "$comment";
}

# func: split line into content and comment
# return: return content without comment and comment individually
sub process_inline_comment{
    my ($line) = @_;
    my %result = ();
    return undef unless ($line =~ /$inline_comment_regex/);

    $result{"content"} = "$+{content}";
    $result{"comment"} = "$+{comment}";
    return %result;
}