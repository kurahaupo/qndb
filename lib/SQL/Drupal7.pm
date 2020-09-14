#!/module/for/perl

use 5.018;
use strict;
use warnings;
use utf8;

package SQL::Drupal7;

sub foldrows {
    my ($mm) = @_;
    warn sprintf "SQL foldrows; start with %u rows, keeping all\n", scalar @$mm;
    for my $m (@$mm) {
        my $sn = delete $m->{surname} || '';
        my $pn = delete $m->{pref_name} || '';
        my $gn = delete $m->{given_name} || '';
        #$pn ||= $gn;
        #$gn ||= $pn;
        my $clean_name  = delete $m->{full_name}
                       || join( ' ', grep { $_ } $gn || $pn, $sn )
                       || '';
        my $sort_by_givenname = lc join ' ', grep { $_ } $gn, $sn;
        my $sort_by_surname   = lc join ' ', grep { $_ } $sn, $gn;
        my $n = new string_with_components:: $clean_name,
                                                family_name       => $sn,
                                                given_name        => $gn,
                                                pref_name         => $pn,
                                                sort_by_surname   => $sort_by_surname,
                                                sort_by_givenname => $sort_by_givenname;
        $m->{composite_name} = $n;
        $m->_make_name_sortable($n);
    }
}

1;
