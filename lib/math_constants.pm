#!/module/for/perl

use 5.018;
use strict;
use warnings;
use utf8;

package math_constants;

use constant PHI => (sqrt(5)+1)/2;
use constant φ => PHI;
use constant PI => atan2(0,-1);
use constant π => PI;
use constant degrees_to_radians => π/180;
use export qw( - PI π degrees_to_radians PHI φ );

1;
