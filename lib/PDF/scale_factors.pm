#!/module/for/perl

use 5.010;
use strict;
use warnings;
use utf8;
no integer; # everything here is floating point

########################################
# scale factors for sizes for PDF files

package PDF::scale_factors;
use constant pt => 1;
use constant px => 2/3;
use constant in => 72;
use constant ft => in * 12;
use constant yd => ft * 2;

use constant mm => in / 25.4;
use constant cm => mm * 10;
use constant 'µm' => mm / 1000;     # micro symbol, deprecated by Unicode v6 in favour of
use constant 'μm' => mm / 1000;     # lower-case Greek letter mu

use export qw( - pt px in ft yd cm mm µm μm );

1;
