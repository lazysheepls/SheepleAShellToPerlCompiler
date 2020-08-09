#!/bin/dash
# https://www.geeksforgeeks.org/expr-command-in-linux-with-examples/

# 3 types
# logical operators (|,&)
# argument  comparison (<.<=,>,>=,!=,=)
# arithmetic sign (+.-.*,/,%)

# expr
number=`expr $number + 1`  # increment number

i=`expr $i + 1`

k=`expr $number % 2`

number=`expr 7 '*' $number + 3`

number=`expr 12 \* 2`

number=`expr $number / 2`

number=`expr $x \< $y`

number=`expr $x \> $y`

number=`expr $x \>= $y`

number=`expr $x \<= $y`

number=`expr $x \!= $y`

number=`expr $x \< $1`

number=`expr $1 \< $y`

number=`expr $x \> $@`

number=`expr $x \>= $*`

number=`expr $x \<= $#`

number=`expr $@ \!= $y`

number=`expr $* \!= $y`

number=`expr $# \>= $y`

number=`expr length $x`

number=`expr length  "geekss"  "<"  5  "|"  19  -  6  ">"  10`

number=`expr length  "geekss"  "<"  5  "&"  19  -  6  ">"  10`

number=`expr length  "geekss"  "<"  5  "&"  19  -  6  ">"  10 "&"  $1  \*  $x  "<="  10`

#$()

number=$($number + 1)  # increment number

i=$($i + 1)

i=$($# + 1)

k=$($number % 2)

number=$(7 '*' $number + 3)

number=$(12 \* 2)

number=$($number / 2)

number=$($x \< $y)

number=$(length $x)

number=$(length  "geekss"  "<"  5  "|"  19  -  6  ">"  10)

number=$(length  "geekss"  "<"  5  "&"  19  -  6  ">"  10)

#$(())

number=$(($number + 1))  # increment number

i=$(($i + 1))

i=$(($i - 1))

i=$(($i / 1))

i=$(($i \/ 1))

i=$(($i '/' 1))

i=$(($i % 1))

i=$(($i \% 1))

i=$(($i '%' 1))

k=$(($number % 2))

number=$((7 '*' $number + 3))

number=$((7 '*' $number + 3 \% $number))

number=$((12 \* 2))

number=$(($number / 2))