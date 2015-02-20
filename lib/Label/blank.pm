#!/module/for/perl

use 5.010;
use strict;
use warnings;
use utf8;

package Label::blank;

use parent 'Label::common';

sub one { state $x = bless {}, shift }
sub new { die }
sub draw_label {}   # do nothing

1;
