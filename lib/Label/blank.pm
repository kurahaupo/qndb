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
    warn sprintf "[%s] %s(%s)\n", __PACKAGE__, CORE::__SUB__, join ",", map { "'$_'" } @_ if $verbose > 2;
}   # do nothing

1;
