#!/module/for/perl

package list_functions;
sub min(@) { my $r = shift; $r < $_ or $r = $_ for @_; $r }
sub max(@) { my $r = shift; $r > $_ or $r = $_ for @_; $r }
sub sum(@) { my $r = shift; $r += $_ for @_; $r }
sub uniq(@) { my %seen; grep { ! $seen{$_}++ } @_ }
sub first(@) { @_ ? shift : () }
sub near($$;$) { my ($a,$b) = @_; my $s = max(abs($a),abs($b)); abs($a-$b) < $s / ($_[2]||1000) }
sub flatten(@) { map { ref $_ ? @$_ : $_ || () } @_ }

use export qw( - min max sum uniq first near flatten );

1;
