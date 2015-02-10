#!/module/for/perl

########################################
# scale factors for sizes for PDF files

package PDF::scale_factors;
use constant pt => 1;
use constant px => 2/3;
use constant in => 72;
use constant mm => 72 / 25.4;

use export qw( - pt px in mm );

1;
