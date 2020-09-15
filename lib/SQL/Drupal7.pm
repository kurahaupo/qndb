#!/module/for/perl

use 5.018;
use strict;
use warnings;
use utf8;

package SQL::Drupal7;

#BEGIN { my $p = __PACKAGE__; $p =~ s@::@/@; $p .= '.pm'; warn sprintf "INC{%s} = %s\n", $p, $INC{$p}; $INC{'SQL/Drupal7.pm'} ||= __FILE__; }
#use export; # also patches up %INC so that use « parent 'SQL::Drupal7' » works

#use SQL::Common;

use parent 'SQL::Common';
use parent 'CSV::Common';

{
package SQL::Drupal7::users;              use parent 'SQL::Drupal7';

sub uid { $_[0]->{uid}; }

sub name($) {
    my $r = shift;
    return $r->{composite_name} ||= do {
        my $sn = delete $r->{surname} || '';
        my $pn = delete $r->{pref_name} || '';
        my $gn = delete $r->{given_name} || '';
        #$pn ||= $gn;
        #$gn ||= $pn;
        my $clean_name  = delete $r->{full_name}
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
        $r->{composite_name} = $n;
        $n;
    }
}

}

{ package SQL::Drupal7::user_addresses;     use parent 'SQL::Drupal7'; use export; }
{ package SQL::Drupal7::user_email_subs;    use parent 'SQL::Drupal7'; use export; }
{ package SQL::Drupal7::user_kin;           use parent 'SQL::Drupal7'; use export; }
{ package SQL::Drupal7::user_mm_member;     use parent 'SQL::Drupal7'; use export; }
{ package SQL::Drupal7::user_notes;         use parent 'SQL::Drupal7'; use export; }
{ package SQL::Drupal7::user_phones;        use parent 'SQL::Drupal7'; use export; }
{ package SQL::Drupal7::user_print_subs;    use parent 'SQL::Drupal7'; use export; }
{ package SQL::Drupal7::user_wgroup;        use parent 'SQL::Drupal7'; use export; }

1;
