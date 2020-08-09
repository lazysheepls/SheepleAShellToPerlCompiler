#!/usr/bin/perl

use warnings;
use strict;

# global regex
my $file_name_regex = qr/.sh$/;
my $empty_line_regex = qr/^\s*$/;
my $system_line_regex = qr/(?<spaces>\s*)(?<content>.*)/;
my $inline_comment_regex = qr/(?<content>.*\S+)(?<comment>\s+#.*)$/;
my $fullline_comment_regex = qr/^(?<comment>\s*#.*)$/;

# subset 0 regex
my $echo_regex = qr/(?<spaces>\s*)echo\s+(?<content>.*)/;
my $echo_option_n_regex = qr/(?<spaces>\s*)echo\s+-n\s+(?<content>.*)/;
my $assign_regex = qr/(?<spaces>\s*)(?<variable>[^=]+)=(?<value>.+)/;
# subset 1 regex
my $cd_regex = qr/(?<spaces>\s*)cd\s+(?<content>.*)/;
my $exit_regex = qr/(?<spaces>\s*)exit\s+(?<exit_number>\d+)?/;
my $read_regex = qr/(?<spaces>\s*)read\s+(?<content>.*)/;
my $for_regex = qr/(?<spaces>\s*)for\s+(?<iterator>\S+)\s+in\s+(?<content>.*)/;
my $do_regex = qr/(?<spaces>\s*)do(?!ne)(?!\S+)/;
my $done_regex = qr/(?<spaces>\s*)done(?!\S+)/;

# subset 2 regex
my $arg_regex = qr/\$(?<arg_index>\d)/;
my $if_regex = qr/(?<spaces>\s*)(?<!el)if\s+(?<content>.*)/;
my $elif_regex = qr/(?<spaces>\s*)elif\s+(?<content>.*)/;
my $then_regex = qr/(?<spaces>\s*)then(?!\S+)/;
my $else_regex = qr/(?<spaces>\s*)else(?!\S+)/;
my $fi_regex = qr/(?<spaces>\s*)fi(?!\S+)/;
my $while_regex = qr/(?<spaces>\s*)while\s+(?<content>.*)/;
my $compare_regex = qr/(?<left>\S+)\s+(?<middle>\S+)\s+(?<right>\S+)/;
my $file_arguement_regex = qr/(?<file_argument>-\S)\s+(?<file_name>\S+)/;
my $expr_regex_back_qoute = qr/\`\s*expr\s+(?<content>.*)\`/;
my $expr_regex_bracket = qr/\$\(+(?<content>[^\)]*)\)+/;

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
        elsif ($line =~ /$echo_regex/){ # echo "hello world"
            process_echo($line);
        }
        # subset 1
        elsif ($line =~ /$cd_regex/){ # cd /tmp
            process_cd($line);
        }
        elsif ($line =~ /$exit_regex/){ # exit 0
            process_exit($line);
        }
        elsif ($line =~ /$read_regex/){ # read line
            process_read($line);
        }
        elsif ($line =~ /$for_regex/){ # >for<...do...done
            process_for($line);
        }
        elsif ($line =~ /$do_regex/){ # for...>do<...done; while...>do<...done
            process_do($line);
        }
        elsif ($line =~ /$done_regex/){ # for...do...>done<; while...do...>done<
            process_done($line);
        }
        # subset 2
        elsif ($line =~ /$if_regex/){ # >if<...then...elif...then...else...fi
            process_if($line);
        }
        elsif ($line =~ /$then_regex/){ # if...>then<...elif...>then<...else...fi
            process_then($line);
        }
        elsif ($line =~ /$elif_regex/){ # if...then...>elif<...then...else...fi
            process_elif($line);
        }
        elsif ($line =~ /$else_regex/){ # if...then...elif...then...>else<...fi
            process_else($line);
        }
        elsif ($line =~ /$fi_regex/){ # if...then...elif...then...else...>fi<
            process_fi($line);
        }
        elsif ($line =~ /$while_regex/){ # >while<...do...done
            process_while($line);
        }
        elsif ($line =~ /$assign_regex/){ # a=hello (NOTE: order matters, assign pattern need to fall behind if, elif, while and for)
            process_assignment($line);
        }
        else{
            process_system($line);
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

sub process_system{
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

    # process each item in system command
    my @items = (); #TODO:
    my @processed_items = ();
    @items = split /\s+/, $content;
    @items = grep /\S/, @items; # remove empty strings;
    
    while(@items){
        my $item = shift @items;
        if ($item =~ /$arg_regex/ || $item =~ /\$\#/ || $item =~ /\$\@/ || $item =~ /\$\*/){
            $item = process_item($item);
        }
        push @processed_items, $item;
    }

    print $spaces;
    print "system ";
    print "\"";
    print join(" ",@processed_items);
    # print $content;
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
    my $is_trailing_edge_newline_needed = 1;
    return undef unless ($line =~ /$echo_regex/ || $line =~ /$echo_option_n_regex/);

    if ($line =~ /$echo_option_n_regex/){
        $is_trailing_edge_newline_needed = 0;
        $spaces = "$+{spaces}";
        $content = "$+{content}";
    }
    elsif ($line =~ /$echo_regex/){
        $spaces = "$+{spaces}";
        $content = "$+{content}";
    }

    # process in-line comment
    if ($content =~ /$inline_comment_regex/){
        my %match_result = ();
        %match_result = process_inline_comment($content);
        $content = $match_result{"content"};
        $comment = $match_result{"comment"};
    }

    # process arguments
    $content = process_arg_in_echo($content);

    # Remove single / double qoute at beginning or end
    $content =~ s/^\s*[\'\"]//g;
    $content =~ s/[\'\"]\s*$//g;

    # Translate double qoute
    $content =~ s/\"/\\\"/g;

    print "$spaces";
    print "print \"";
    print "$content";
    if ($is_trailing_edge_newline_needed){
        print "\\n";
    }
    print "\"";
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
    if ($value =~ /$inline_comment_regex/){
        my %match_result = ();
        %match_result = process_inline_comment($value);
        $value = $match_result{"content"};
        $comment = $match_result{"comment"};
    }

    # process arguments
    $value = process_item($value);
    
    print "$spaces";
    print "\$$variable";
    print " = ";
    print "$value";
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

# func: handle exit build-in program
sub process_exit{
    my ($line) = @_;
    my $spaces = "";
    my $exit_number = "";
    my $comment = "";
    return undef unless ($line =~ /$exit_regex/);

    $spaces = "$+{spaces}";
    $exit_number = "$+{exit_number}" if defined($+{exit_number});

    # process in-line comment
    if ($line =~ /$inline_comment_regex/){
        my %match_result = ();
        %match_result = process_inline_comment($line);
        $comment = $match_result{"comment"};
    }

    print "$spaces";
    print "exit";
    print " " if $exit_number ne "";
    print "$exit_number";
    print ";";
    print "$comment";
    print "\n";
}

# func: handle read build-in program
sub process_read{
    my ($line) = @_;
    my $spaces = "";
    my $content = "";
    my $comment = "";
    return undef unless ($line =~ /$read_regex/);

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
    print "\$$content";
    print " = <STDIN>;\n";
    print "$spaces";
    print "chomp \$$content";
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

    # process for iteration list
    if ($content =~ /[\*\[\]\?]+/){
        process_for_iteration_list_matching($content);
    } else {
        process_for_iteration_list_full_expansion($content);
    }
    
    # print comment if there is any
    if($comment ne ""){
        print $comment,"\n";
    }
}

# func: handle for loop iteration list with content fully expanded
# e.g for Huston 1202 alarm
sub process_for_iteration_list_full_expansion{
    my ($content) = @_;
    my @itertion_list = split /\s+/, $content;

    print "(";
    for (my $i=0; $i<=$#itertion_list; $i++){
        # if not a digit, need to rap item in single qoutation marks
        if ($itertion_list[$i] !~ /[+-]*\d+/){
            print "\'";
        }
            
        print $itertion_list[$i];

        if ($itertion_list[$i] !~ /[+-]*\d+/){
            print "\'";
        }
        # use comma as separator
        if ($i != $#itertion_list){
            print ", ";
        }         
    }
    print ") ";
}

# func: handle for loop iteration list with string matching
# e.g for file in *.c
# e.g for file in [ab].c
sub process_for_iteration_list_matching{
    my ($content) = @_;

    print "(";
    print "glob(";
    print "\"";
    print "$content";
    print "\"";
    print ")";
    print ") ";
}

# func: handle "do" key word in the for statement
sub process_do{
    my ($line) = @_;
    my $spaces = "";
    my $comment = "";
    return undef unless ($line =~ /$do_regex/);

    $spaces = "$+{spaces}";

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

    $spaces = "$+{spaces}";

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

# subset 2
# func: process arg in echo command
sub process_arg_in_echo{
    my ($content) = @_;
    $content = arg_to_ARGV($content);
    return $content;
}

# func: find arg ($1,$2...) and replace with $ARGV[1], $ARGB[2]..
sub arg_to_ARGV{
    my ($content) = @_;
    while ($content =~ /$arg_regex/g){
        my $arg_index = "$+{arg_index}";
        my $ARGV_index = int($arg_index) - 1;
        $content =~ s/\$$arg_index/\$ARGV\[$ARGV_index\]/g;
    }
    return $content;
}

# func: process if statement
# e.g if test andrew = great
#     if [ -d /dev/null ]
sub process_if{
    my ($line) = @_;
    my $spaces = "";
    my $content = "";
    my $comment = "";
    return undef unless ($line =~ /$if_regex/);

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
    print "if (";

    # process test or [...]
    if ($content =~ /\[.*\]/ || $content =~ /test/){
        process_test($content);
    } else {
        process_system($content);
    }
    
    print ") ";

    # print comment if there is any
    if($comment ne ""){
        print $comment,"\n";
    }
}

# func: process test in if/elif/while
sub process_test{
    my ($line) = @_;
    my $content = "";
    my $test_pattern_1 = qr/test\s+(?<content>.*)/;
    my $test_pattern_2 = qr/\[\s+(?<content>.*)\s+\]/;
    return undef unless ($line =~ /$test_pattern_1/ || $line =~ /$test_pattern_2/);
    
    if ($line =~ /$test_pattern_1/){
        $content = "$+{content}";
    }
    elsif ($line =~ /$test_pattern_2/){
        $content = "$+{content}";
    }

    # 3 type of content
    # type 1 compare (string or numeric): str1 = str2, int1 eq int2, ...
    # type 2 file arguments: -d, -r, ...
    # type 3 logic operations: -a(and), -o(or) -> split content into multiple groups
    #                          !(not) -> could be infornt of each group of compare or file arguments

    # split content into groups by logic operations (-a, -o)
    my @groups = ();
    @groups = split /-a|-o/, $content;
    
    # find logic operators
    my @logic_operators = ();
    while($content =~ /(-a|-o)/g){
        push @logic_operators, $1;
    }
    
    while (@groups){
        my $group = shift @groups;
        
        # find negation in front (! translate as not)
        if ($group =~ /^\s*!/){
            print "not ";
            $group =~ s/^\s*!//;
        }
        
        # check compare type (compare or file arguement)
        if ($group =~ /$compare_regex/){
            process_compare($group);
        }
        elsif ($group =~ /$file_arguement_regex/){
            process_file_argument($group);
        }

        # print logic operator
        if (@logic_operators){
            my $logic_operator = shift @logic_operators;
            if ($logic_operator =~ /-a/){
                print " && ";
            }
            elsif ($logic_operator =~ /-o/){
                print " || ";
            }
        }
    }
}

# func: process compare within a test statement (numeric or string)
# e.g. Andrew = Mark
#      $1 -gt 5
sub process_compare{
    my ($line) = @_;
    my $left = "";
    my $right = "";
    my $middle = "";
    return undef unless ($line =~ /$compare_regex/);

    $left = "$+{left}";
    $right = "$+{right}";
    $middle = "$+{middle}";

    print process_item($left);
    print " ";
    process_middle_comparator($middle);
    print process_item($right);
}

# func: process the compare item on either the left or right of the comparator
# use cases: right side of assignment, if test ..., elsif test ..., while ..., for ... #TODO:
sub process_item{
    my ($value) = @_;
    # `expr <content>` -> <content>
    if ($value =~ /$expr_regex_back_qoute/ || $value =~ /$expr_regex_bracket/){
        $value = process_expr($value);
    }
    # $1(arguement) -> $ARGV[0]
    elsif ($value =~ /$arg_regex/g){
        $value = arg_to_ARGV($value);
    } 
    # $#(number of arguments) -> @ARGV
    # $@(array form of all arguements) -> @ARGV
    elsif ($value =~ /\$\#/ || $value =~ /\$\@/){
        $value = "\@ARGV";
    }
    # $*(string expansion of all arguements) -> 'arg1 arg2 arg3'
    elsif ($value =~ /\$\*/){
        $value = join(" ",@ARGV);
        $value = join("","\'",$value,"\'");
    }
    # $k(variable) -> $k
    elsif ($value =~ /(\$\w+)/){
        $value = $1;
    }
    # number -> number
    elsif ($value =~ /([+-]*\d+)/){
        $value = $1;
    }
    # string
    elsif($value =~ /\s*(.*)/){
        $value = $1;
        # TODO:
        # # single qoute -> double qoute
        # if ($value =~ /\'/){
        #     $value =~ s/\'/\"/g;
        # }
        # # double qoute -> \double qoute
        # elsif ($value =~ /\"/){
        #     # if double qoute is at front and end, keep it
        #     $value =~ s/^\s*\"//g;
        #     $value =~ s/\"\s*$//g;
        #     # translate double qoute in middele
        #     $value =~ s/\"/\\\"/g;
        #     $value = join("","\"",$value,"\"");
        # }
        # # no qoute -> single qoute
        # else {
            $value = join("","\'",$value,"\'");
        # }
    }
    return $value;
}

# func: process the comparator (numeric or string)
sub process_middle_comparator{
    my ($comparator) = @_;
    # numeric comparator
    if ($comparator =~ /-eq/){
        print "== ";
    }
    elsif ($comparator =~ /-ne/){
        print "!= ";
    }
    elsif ($comparator =~ /-gt/){
        print "> ";
    }
    elsif ($comparator =~ /-ge/){
        print ">= ";
    }
    elsif ($comparator =~ /-lt/){
        print "< ";
    }
    elsif ($comparator =~ /-le/){
        print "<= ";
    }
    # string comparator
    elsif ($comparator =~ /(?<!!)=/){
        print "eq ";
    }
    elsif ($comparator =~ /!=/){
        print "ne ";
    }
    elsif ($comparator =~ />(?!=)/){
        print "gt ";
    }
    elsif ($comparator =~ />=/){
        print "ge ";
    }
    elsif ($comparator =~ /<(?!=)/){
        print "lt ";
    }
    elsif ($comparator =~ /<=/){
        print "le ";
    }
}

# func: process file argument within a test statement
# e.g. -d file_name
#      -r file_directory
sub process_file_argument{
    # my $file_arguement_regex = qr/(?<file_argument>-\S)\s+(?<file_name>\S+)/;
    my ($line) = @_;
    my $file_argument = "";
    my $file_name = "";
    return undef unless ($line =~ /$file_arguement_regex/);

    $file_argument = "$+{file_argument}";
    $file_name = "$+{file_name}";
    $file_name = process_item($file_name);

    print $file_argument;
    print " ";
    print $file_name;
}

sub process_then{
    my ($line) = @_;
    my $spaces = "";
    my $comment = "";
    return undef unless ($line =~ /$then_regex/);

    $spaces = "$+{spaces}";

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

sub process_expr{
    my ($line) = @_;
    my $content = "";
    my @results = ();
    return undef unless ($line =~ /$expr_regex_back_qoute/ || $line =~ /$expr_regex_bracket/);

    if ($line =~ /$expr_regex_back_qoute/){
        $content = "$+{content}";
    }
    elsif ($line =~ /$expr_regex_bracket/){
        $content = "$+{content}";
    }
    
    # 3 types of expr
    # logical operators (|,&)
    # argument  comparison (<.<=,>,>=,!=,=)
    # arithmetic sign (+.-.*,/,%)

    # split content into groups by logic operations (|, &)
    # possible variations \|, '|', \&, '&'
	my @groups = ();
	@groups = split(/\S*\|\S*|\S*\&\S*/, $content);

    # find logic operators
	my @logic_operators = ();
	while($content =~ /\S*(\||\&)\S*/g){
        push @logic_operators, $1;
	}

    while(@groups){
        my $group = shift @groups;
        push @results, process_expr_item($group);

        # print logic operators
        if (@logic_operators){
            my $logic_operator = shift @logic_operators;
            if ($logic_operator =~ /\|/){
                push @results, " && ";
	            # print " && ";
	        }
	        elsif ($logic_operator =~ /\&/){
                push @results, " || ";
	            # print " || ";
	        }
        }
    }
    
    return join("",@results);
}

# func: process expr format that is a x b
# e.g   ARG1 < ARG2
#       ARG1 >= ARG2
#       ARG1 + ARG2
#       7 '*' $number + 3
sub process_expr_item{
    my ($content) = @_;
    my @items = ();
    my @results = ();
    @items = split /\s+/, $content; # split equation into items 
    @items = grep /\S/, @items; # remove empty strings;

    # check if it is string or numeric comparison
    my $is_numeric = 0; #TODO: string compare or numeric compare (< or lt)

    while(@items){
        my $item = shift @items;
        if ($item =~ /<(?<!=)/){ # <
            push @results, "<";
        } 
        elsif ($item =~ /<=/){ # <=
            push @results, "<=";
        }
        elsif ($item =~ />(?<!=)/){ # >
            push @results, ">";
        }
        elsif ($item =~ />=/){ # >=
            push @results, ">=";
        }
        elsif ($item =~ /\!=/){ # !=
            push @results, "!=";
        }
        elsif ($item =~ /\=/){ # =
            push @results, "==";
        }
        elsif ($item =~ /\+/){ # arithmetic +
            push @results, "+";
        }
        elsif ($item =~ /\-/){ # arithmetic -
            push @results, "-";
        }
        elsif ($item =~ /\*/ && $item !~ /\$\*/){ # arithmetic *
            push @results, "*";
        }
        elsif ($item =~ /\//){ # arithmetic /
            push @results, "%";
        }
        elsif ($item =~ /\%/){ # arithmetic %
            push @results, "%";
        }
        elsif ($item =~ /length/){
            push @results, "length";
        }
        else{
            push @results, process_item($item);
        }
    }

    my $result_str = join(" ", @results);    
    return $result_str;
}

# func: process elif (...)
sub process_elif{
    my ($line) = @_;
    my $spaces = "";
    my $content = "";
    my $comment = "";
    return undef unless ($line =~ /$elif_regex/);

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
    print "} elsif (";

    # process test or [...]
    if ($content =~ /\[.*\]/ || $content =~ /test/){
        process_test($content);
    } else {
        process_system($content);
    }
    
    print ") ";

    # print comment if there is any
    if($comment ne ""){
        print $comment,"\n";
    }
}

# func: process else 
sub process_else{
    my ($line) = @_;
    my $spaces = "";
    my $comment = "";
    return undef unless ($line =~ /$else_regex/);

    $spaces = "$+{spaces}";

    # process in-line comment
    if ($line =~ /$inline_comment_regex/){
        my %match_result = ();
        %match_result = process_inline_comment($line);
        $comment = $match_result{"comment"};
    }

    print "$spaces";
    print "} else {";
    print "$comment";
    print "\n";
}

# func: process fi
sub process_fi{
    my ($line) = @_;
    my $spaces = "";
    my $comment = "";
    return undef unless ($line =~ /$fi_regex/);

    $spaces = "$+{spaces}";

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

# func: process while statement
# e.g while test andrew = great
#     while [ -d /dev/null ]
sub process_while{
    my ($line) = @_;
    my $spaces = "";
    my $content = "";
    my $comment = "";
    return undef unless ($line =~ /$while_regex/);

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
    print "while (";

    # process test or [...]
    if ($content =~ /\[.*\]/ || $content =~ /test/){
        process_test($content);
    } else {
        process_system($content);
    }
    
    print ") ";

    # print comment if there is any
    if($comment ne ""){
        print $comment,"\n";
    }
}

