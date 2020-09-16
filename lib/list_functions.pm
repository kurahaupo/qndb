#!/module/for/perl

use 5.018;
use strict;
use warnings;
use utf8;

package list_functions;

sub min(@) { my $r = shift; $r < $_ or $r = $_ for @_; $r }
sub max(@) { my $r = shift; $r > $_ or $r = $_ for @_; $r }
sub sum(@) { my $r = shift; $r += $_ for @_; $r }
sub uniq(@) { my %seen; grep { ! $seen{$_}++ } @_ }
sub first(@) { @_ ? shift : () }
sub near($$;$) { my ($a,$b) = @_; my $s = max(abs($a),abs($b)); abs($a-$b) < $s / ($_[2]||1000) }
sub flatten(@) { map { ref $_ ? @$_ : $_ || () } @_ }

# Randomly choose N items from a list, while
# keeping the results in the original order.
sub randomly_choose($@) {
    my $n = shift // 1;
    $n <= @_ or $n = @_;
    if ($n == 1 || !wantarray) {
        return $_[ int rand scalar @_ ];
    }
    return @_[ grep { rand(@_-$_) < $n and $n-- } 0 .. $#_ ];
}

# TODO: this is only to substitute random values until the real values can be computed
#
sub flip_coin(;$) {
    return rand(1) < pop || 0.5;
}

use export qw( - min max sum uniq first near flatten randomly_choose flip_coin );

1;
