#!/module/for/perl

use 5.010;
use strict;
use warnings;
use utf8;

package Label::recipient;
use parent 'Label::common';
use verbose;

sub new {
    warn sprintf "%s(%s)\n", (caller(0))[3], join ",", map { "'$_'" } @_ if $verbose > 4 && $debug;
    my $class = shift;
    my ($inclusions, $postcode, @lines) = @_;
    bless {
            inclusions => $inclusions,
            lines    => \@lines,
            postcode => $postcode,
        }, $class;
}

use constant colour => 'black';

1;
