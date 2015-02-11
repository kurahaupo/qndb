#!/usr/bin/perl

use 5.010;
use strict;
use warnings;
use utf8;

=head 3

An ad-hoc file received from previous Distrodude, with an "inserts" field
added. (Not sure where it came from, or who specified the field-list.)

inserts,country,postcode,name,care-of,address1,address2,address3,address4,address5

 inserts country postcode name care-of address1 address2 address3 address4
 address5

=cut

package CSV::adhoc1;
use parent 'CSV::Common';

sub fix_one {
    my $r = shift;
    1;
}

1;
