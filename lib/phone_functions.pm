#!/module/for/perl

use 5.010;
use strict;
use warnings;
use utf8;

package phone_functions;

use verbose;

sub normalize_phone($) {
    my $oo = my $z = shift @_;
    for ($z) {      # fake local $_
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
    for ($z) {      # fake local $_

        # peel off country codes
        s/^\+1          # NANP
         |^\+2[07]      # Africa and... +239 (Saõ Tomé & Principe); +246(BIOT); +247 (Ascension Island); +261 (Madagascar)
         |^\+3[^578]    # Europe
         |^\+4[^2]      # Europe
         |^\+5[1-8]     # Americas except NANP
         |^\+6[0-6]     # Oceania & south-east Asia
         |^\+7          # Russian federation (СССР)
         |^\+8[1-46]    # central Asia
         |^\+9[0-58]    # west Asia
         |^\+\d\d\d     # all others are 3-digit
         /$& /x;

        # peel off area codes
        s/^\+1   \s \d\d\d      # NANP 3+3+4
         |^\+27  \s 1\d\d       # ZA landlines
         |^\+44  \s 1\d\d\d     # UK small towns
         |^\+44  \s 2\d         # UK large cities
         |^\+44  \s [389]\d\d   # UK most cities
         |^\+61  \s 1\d00       # AU 1300 & 1800 numbers
         |^\+61  \s [23478]     # AU landlines and mobile
         |^\+64  \s 2(?=499)    # Antartica (NZ)
         |^\+64  \s 2\d         # NZ mobile
         |^\+64  \s [58]0\d
         |^\+64  \s 83          # NZ telecom service numbers
         |^\+64  \s [34679]     # NZ landlines
         |^\+7   \s \d\d\d2?    # RU 7-xxx-xxx-xxxx large towns, 7-xxx2-xxx-xxx small towns
         |^\+86  \s (?: 10      # CN Beijing
                    | \d\d\d )  # CN elsewhere
         |^\+91  \s (?: 11|20|22|33|40|44|79|80
                      | [1-5]\d\d
                      | 612|621|641|657|712|721|724|751|761|821|831|836|870|891
                      | \d\d\d\d\d                           # IN mobile
                      )  # IN
         |^\+\d+ \s \d\d         # (rest of world; assume 2-digit area codes)
         /$& /x;

        # localize +64 for NZ
        s/^\+64\s*/0/;

        # use ';' before an extension (like Hayes dialler)
        s/;/ ext /;

        # a weird hack to accommodate the lack of a "label" for phone numbers
        # (nobody uses this any more)
        s/\^/ (fax)/;

        # try to put reasonable spacing in local phone number
        1 while
        s/\d{3}(?=\d{6})/$& /g;   # 9 or more digits will have 3 digits split off the front, repeatedly
        s/\d{4}(?=\d{4})/$& /g;   # 8 digits splits off 4
        s/\d{3}(?=\d{3})/$& /g;   # 6 or 7 digits split off 3

        # change spaces, tabs, etc to non-breaking spaces, to prevent word-wrapping
        s/\s+/\N{NBSP}/g;

        warn "LOCALIZED phone '$o' -> '$oo' -> '$_'\n" if ($o ne $_ || $oo ne $_) && $verbose > 3;
        return $_;
    }
}

use export qw( normalize_phone localize_phone );

1;
