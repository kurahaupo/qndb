#!/module/for/perl

use 5.010;

use strict;
use warnings;
use utf8;

package phone_functions;

use verbose;

sub normalize_phone($) {
    my $oo = my $z = shift @_;
    for ($z) {
        s/fa?x?(?!\w)(.*)/$1^/i;
       #s/(?:cell|mob)\D*(.*)/$1^/i;
        s/x/;/g;
        s/[^+0-9;^]//g;
        s/^00/+/ or
        s/^0/+64/;
        warn "NORMALIZED phone '$oo' -> '$_'\n" if $oo ne $_ && $verbose > 3;
        return $_;
    }
}

sub localize_phone($) {
    my $o = shift @_;
    my $oo = my $z = normalize_phone $o;
    for ($z) {
        s/^\+1      # NANP
         |^\+27     # ZA
         |^\+4\d    # GB+EU
         |^\+6[145] # Oceania
         |^\+7      # СССР
         |^\+86     # CH
         |^\+91     # IN
         |^\+\d\d\d
         /$& /x;
        s/^\+1\s\d\d\d
         |^\+27\s1\d\d
         |^\+44\s1\d\d\d
         |^\+44\s[2389]\d\d
         |^\+61\s1\d00
         |^\+61\s[23478]
         |^\+64\s2\d
         |^\+64\s508
         |^\+64\s800
         |^\+64\s83
         |^\+64\s[34679]
         |^\+7\s\d\d\d2*
         |^\+\d\+\s\d\d
         /$& /x;
        s/^\+64\s*/0/;
        s/\s/\N{NBSP}/g;
        s/;/ ext /;
        s/\^/ (fax)/;
        1 while
        s/(?<=\d{3})(?=\d{6})/\N{NBSP}/g;
        s/(?<=\d{-3,4})(?=\d{3,4})/\N{NBSP}/g;
        warn "LOCALIZED phone '$o' -> '$oo' -> '$_'\n" if ($o ne $_ || $oo ne $_) && $verbose > 3;
        return $_;
    }
}

use export qw( normalize_phone localize_phone );

1;
