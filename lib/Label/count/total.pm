#!/module/for/perl

use 5.010;
use strict;
use warnings;
use utf8;

package Label::count::total;
use parent 'Label::common';
use verbose;

sub new {
    warn sprintf "%s(%s)\n", (caller(0))[3], join ",", map { "'$_'" } @_ if $verbose > 4 && $debug;
    my $class = shift;
    my ($banner, $inclusion_labels, $counts) = @_;
    bless {
        banner => $banner,
        lines => [ map { sprintf "%3u× %s", $counts->[$_], $inclusion_labels->[$_] } grep { $counts->[$_] } 0..$#$inclusion_labels ],
    }, $class;
}

1;
