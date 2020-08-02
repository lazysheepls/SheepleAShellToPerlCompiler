#!/usr/bin/perl

use warnings;
use strict;

# global regex
my $file_name_regex = qr/.sh$/;
my $empty_line_regex = qr/^\s*$/;
my $system_line_regex = qr/(?<spaces>\s*)(?<content>.*)/;
my $inline_comment_regex = qr/(?<content>.*)(?<comment>\s+#.*)$/;
my $fullline_comment_regex = qr/^(?<comment>\s*#.*)$/;

# subset 0 regex
my $echo_regex = qr/(?<spaces>\s*)echo\s*(?<content>.*)/;
my $assign_regex = qr/(?<spaces>\s*)(?<variable>\S+)=(?<value>\S+)/;

# subset 1 regex
my $cd_regex = qr/(?<spaces>\s*)cd\s*(?<content>.*)/;
my $for_regex = qr/(?<spaces>\s*)for\s+(?<iterator>\S+)\s+in\s+(?<content>.*)/;
my $do_regex = qr/(?<spaces>\s*)do(?!ne)/;
my $done_regex = qr/(?<spaces>\s*)done/;

# read shell file
my $file_name = $ARGV[0];
if ($file_name !~ $file_name_regex){
    exit;
}
my @lines = ();
open my $fh, "<", $file_name;
    @lines = <$fh>;
close $fh;

# process shell script
print "#!/usr/bin/perl -w\n";
process_lines(@lines);

# func: process each line in shell and translate to perl
sub process_lines{
    my (@lines) = @_;
    my $line = "";

    # remove the first line (#!/bin/dash)
    $line = shift @lines;

    for $line (@lines){
        # global
        if ($line =~ /$empty_line_regex/){
            print $line;
        }
        elsif ($line =~ /$fullline_comment_regex/){
            print $line;
        }
        # subset 0
        elsif ($line =~ /$echo_regex/){ #echo "hello world"
            process_echo($line);
        }
        elsif ($line =~ /$assign_regex/){ #a=hello
            process_assignment($line);
        }
        # subset 1
        elsif ($line =~ /$cd_regex/){ #cd /tmp
            process_cd($line);
        }
        elsif ($line =~ /$for_regex/){ #>for<...do...done
            process_for($line);
        }
        elsif ($line =~ /$do_regex/){ #for...>do<...done
            process_do($line);
        }
        elsif ($line =~ /$done_regex/){ #for...do...>done<
            process_done($line);
        }
        else{
            process_system_line($line);
        }
    }
}

# global
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

sub process_system_line{
    my ($line) = @_;
    my $spaces = "";
    my $content = "";
    my $comment = "";
    return undef unless ($line =~ /$system_line_regex/);
    
    $spaces = "$+{spaces}";
    $content = "$+{content}";

    # process in-line comment
    if ($line =~ /$inline_comment_regex/){
        my %match_result = ();
        %match_result = process_inline_comment($line);
        $content = $match_result{"content"};
        $comment = $match_result{"comment"};
    }

    print $spaces;
    print "system ";
    print "\"";
    print $content;
    print "\"";
    print ";";
    print "$comment";
    print "\n";
}

# subset 0
# func: handle echo the build-in program
# e.g: echo hello word #comment here
# format:($spaces)echo($content)($comment)
sub process_echo{
    my ($line) = @_;
    my $spaces = "";
    my $content = "";
    my $comment = "";
    return undef unless ($line =~ /$echo_regex/);
    
    $spaces = "$+{spaces}";
    $content = "$+{content}";

    # process in-line comment
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
    print "\n";
}

# func: handle variable assignment
# e.g a=Hello #comment here
# format:($spaces)($variable)=($value)($comment)
sub process_assignment{
    my ($line) = @_;
    my $spaces = "";
    my $variable = "";
    my $value = "";
    my $comment = "";
    return undef unless ($line =~ /$assign_regex/);
    
    $spaces = "$+{spaces}";
    $variable = "$+{variable}";
    $value = "$+{value}";

    # process in-line comment
    if ($line =~ /$inline_comment_regex/){
        my %match_result = ();
        %match_result = process_inline_comment($line);
        $comment = $match_result{"comment"};
    }
    print "$spaces";
    print "\$$variable";
    print " = ";
    print "\'";
    print "$value";
    print "\'";
    print ";";
    print "$comment";
    print "\n";
}

# subset 1
# func: handle cd the build-in program
# e.g: cd /tmp #comment here
# format:($spaces)cd($content) ($comment)
sub process_cd{
    my ($line) = @_;
    my $spaces = "";
    my $content = "";
    my $comment = "";
    return undef unless ($line =~ /$cd_regex/);
    
    $spaces = "$+{spaces}";
    $content = "$+{content}";

    # process in-line comment
    if ($content =~ /$inline_comment_regex/){
        my %match_result = ();
        %match_result = process_inline_comment($content);
        $content = $match_result{"content"};
        $comment = $match_result{"comment"};
    }

    print "$spaces";
    print "chdir \'";
    print "$content";
    print "\'";
    print ";";
    print "$comment";
    print "\n";
}

# func: handle the first line of the for statement
sub process_for{
    my ($line) = @_;
    my $spaces = "";
    my $iterator = "";
    my $content = "";
    my $comment = "";
    return undef unless ($line =~ /$for_regex/);

    $spaces = "$+{spaces}";
    $iterator = "$+{iterator}";
    $content = "$+{content}";

    # process in-line comment
    if ($content =~ /$inline_comment_regex/){
        my %match_result = ();
        %match_result = process_inline_comment($content);
        $content = $match_result{"content"};
        $comment = $match_result{"comment"};
    }

    print "$spaces";
    print "foreach ";
    print "\$$iterator ";

    # for content 1: split by space
    my @itertion_list = split /\s+/, $content;
    print "(";
    for (my $i=0; $i<=$#itertion_list; $i++){
        # if not a digit, need to rap item in single qoutation marks
        if ($itertion_list[$i] =~ /\D+/){
            print "\'";
        }
            
        print $itertion_list[$i];

        if ($itertion_list[$i] =~ /\D+/){
            print "\'";
        }
        # use comma as separator
        if ($i != $#itertion_list){
            print ", ";
        }         
    }
    print ") ";
}

# func: handle "do" key word in the for statement
sub process_do{
    my ($line) = @_;
    my $spaces = "";
    my $comment = "";
    return undef unless ($line =~ /$do_regex/);

    # process in-line comment
    if ($line =~ /$inline_comment_regex/){
        my %match_result = ();
        %match_result = process_inline_comment($line);
        $comment = $match_result{"comment"};
    }

    print "$spaces";
    print "{";
    print "$comment";
    print "\n";
}

# func: handle "done" key word in the for statement
sub process_done{
    my ($line) = @_;
    my $spaces = "";
    my $comment = "";
    return undef unless ($line =~ /$done_regex/);

    # process in-line comment
    if ($line =~ /$inline_comment_regex/){
        my %match_result = ();
        %match_result = process_inline_comment($line);
        $comment = $match_result{"comment"};
    }

    print "$spaces";
    print "}";
    print "$comment";
    print "\n";
}