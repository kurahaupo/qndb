#!/module/for/perl

use 5.010;
use strict;
use warnings;
use utf8;

package Label::recipient;
use parent 'Label::common';

sub new {
    my $class = shift;
    my ($inclusions, $postcode, $lines) = splice @_, 0, 3;
    bless {
            inclusions => $inclusions,
            lines    => [@$lines],
            postcode => $postcode,
            @_
        }, $class;
}

use constant colour => 'black';

1;
