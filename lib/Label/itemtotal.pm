#!/module/for/perl

use 5.010;
use strict;
use warnings;
use utf8;

package Label::itemtotal;
use parent 'Label::common';

use verbose;

sub new {
    warn sprintf "[%s] %s(%s)\n", __PACKAGE__, CORE::__SUB__, join ",", map { "'$_'" } @_ if $verbose > 2;
    my $class = shift;
    my ($inclusion_labels, $counts) = splice @_, 0, 2;
    bless {
        banner => "Totals",
        lines => [ map { sprintf "%3u× %s", $counts->[$_], $inclusion_labels->[$_] } grep { $counts->[$_] } 0..$#$inclusion_labels ],
        @_
    }, $class;
}

1;
