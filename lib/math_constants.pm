#!/module/for/perl

package math_constants;
use constant PHI => (sqrt(5)+1)/2;
use constant PI => atan2(0,-1);
use constant degrees_to_radians => PI/180;
use export qw( - PI degrees_to_radians PHI );

1;
