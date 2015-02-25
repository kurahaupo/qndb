#!/module/for/perl

use 5.010;
use strict;
use warnings;
use utf8;

package Label::blank;
use parent 'Label::common';
use verbose;

sub one { state $x = bless {}, shift }
sub new { die }
sub draw_label {
    warn sprintf "%s(%s)\n", (caller(0))[3], join ",", map { "'$_'" } @_ if $verbose > 4 && $debug;
}   # do nothing

1;
