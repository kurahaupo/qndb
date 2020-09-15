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
package SQL::Drupal7::users;
use parent 'SQL::Drupal7';

use Carp 'cluck', 'confess';
use POSIX 'strftime', 'floor';

sub uid { $_[0]->{uid}; }

sub hide_listing() {
    return undef;   # don't hide. TODO: look for privacy flag
}

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

sub listed_email {
    my $r = shift;
    return $r->{visible_email};
}

    my %phone_slot_map = (
        M => 'personal_phone',
        H => 'household_phone',
    );
    sub _mash_phones {
        my $r = shift;
        my $pp = delete $r->{__phones} or return;
        for my $p (@$pp) {
            my $slot = $phone_slot_map{ $p->{phone_slot} } || 'other_phone';
            my @numbers = split /\s*[;:|]\s*/, $p->{phone};
            push @{$r->{$slot}}, @numbers if @numbers;
        }
    }

    sub flatten {
        my $s = shift;
        ref $s or return $s;
        join "\n", @$s;
    }

sub mobile_number {
    my $r = shift;
    _mash_phones $r;
    return flatten $r->{personal_phone};
}

sub phone_number {
    my $r = shift;
    _mash_phones $r;
    return flatten $r->{household_phone};
}

sub _mod($$) {
    use integer;
    my ($x, $y) = @_;
    $x %= $y;
    if ( $x && sign($x) != sign($y) ) { $x += $y }
    return $x;
}

sub birthdate {
    my $r = shift;
    # Assume that dates are recorded as midnight at the start of the date,
    # where the timezone TZ satisfies [[ UTC-11 < TZ ≤ UTC+13 ]].
    #
    # TODO: fix handling of "calendar" dates and "wallclock time".
    #
    # Ob Grumble: why don't databases have a separate timestamp type, that
    # shows the same regardless of the timezone of the viewer or editor. Then
    # calendar dates such as birthdays could be recorded using that, without
    # being broken by timezones.

    my $t = $r->{birthdate};
    return $t if !$t || $t =~ /\D/;

    $t += 46800;        # ≈13h

    BEGIN { -5 % 3 == 1 or die "This version of Perl has a broken implementation of modulus"; }
    $t -= $t % 86400;   # ≈24h  NOTE: modulus must be positive

    $t = strftime '%Y-%m-%d', gmtime $t;
    return $t;
}

sub parent_fix_one  {
    my ($r) = @_;
    cluck 'Creating parent_fix_one\n';
    my $f = UNIVERSAL::can($r, 'SUPER::fix_one') // do {
        our @ISA;
        warn "UNIVERSAL::can(".__PACKAGE__.", 'SUPER::fix_one') couldn't find fix_one";
        for ( SQL::Drupal7::users::,
              SQL::Drupal7::,
              SQL::Common::,
              CSV::Common:: ) {
            my $pkg = $_.'::';
            no strict 'refs';
            $pkg = \%$pkg || die;
            if ( my $fix = $pkg->{fix_one} ) {
                warn '&'.$_.'::fix_one='.\&$fix."\n";
            } else {
                warn '&'.$_.'::fix_one=(undef)'."\n";
            }
            if ( my $isa = $pkg->{ISA} ) {
                warn '@'.$_.'::ISA=( '.join('; ',@{ $pkg->{ISA} })." )\n\n";
            } else {
                warn '@'.$_."::ISA=(empty)\n\n";
            }
        }
        confess;
    };
    *parent_fix_one = $f;
    goto &$f;
}

sub fix_one {
    my ($r) = @_;
    cluck "Running ".__PACKAGE__."::fix_one\n";

    $r->{monthly_meeting_area} = do { delete $r->{mmm_xmtag} } // '';
    $r->{formal_membership} = do { my $mmm = delete $r->{__mm_member}; $mmm ? join "\n", map { $_->{mmm_xmtag} } @$mmm : undef; } // '';
    $r->{inactive} = 0; # TODO
    $r->{show_me_in_young_friends_listing} = 'TODO';

    $r->{fax} = ''; # defunct
    $r->{listed_address} = 'TODO';
    $r->{postal_address} = 'TODO';
    $r->{receive_local_newsletter_by_post} = 'TODO';
    $r->{nz_friends_by_post} = 'TODO';
    $r->{receive_local_newsletter_by_email} = 'TODO';
    $r->{nz_friends_by_email} = 'TODO';
    $r->{last_updated} = 'TODO';

    goto &parent_fix_one;

#   $r->make_name_sortable;
#   $r;
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
