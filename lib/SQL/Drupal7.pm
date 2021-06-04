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

use Carp 'confess';
use POSIX 'strftime', 'floor';

use list_functions qw( flatten uniq randomly_choose flip_coin );
use quaker_info qw( @mm_order @wg_order %wg_map );

sub uid { $_[0]->{uid}; }

sub hide_listing() {
    return ! $_[0]->{visible};
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
                       || join( ' ', grep { $_ } $pn || $gn, $sn )
                       || '';
        my $sort_by_givenname = lc join ' ', grep { $_ } $gn, $sn;
        my $sort_by_surname   = lc join ' ', grep { $_ } $sn, $gn;
        my $n = new string_with_components:: $clean_name,
                                                family_name       => $sn,
                                                given_name        => $gn,
                                                pref_name         => $pn,
                                                sort_by_surname   => $sort_by_surname,
                                                sort_by_givenname => $sort_by_givenname;
        $n;
    }
}

sub listed_email {
    my $r = shift;
    return $r->{visible_emails} // ();
}

    my %phone_slot_map = (
        M => 'personal_phone',
        H => 'household_phone',
    );
    sub _mash_phones($) {
        my $r = shift;
        my $pp = delete $r->{__phones} or return;
        for my $p (@$pp) {
            my $slot = $phone_slot_map{ $p->{phone_slot} } || 'other_phone';
            my @numbers = split /\s*[;:|]\s*/, $p->{phone};
            push @{$r->{$slot}}, @numbers if @numbers;
        }
    }

sub listed_phone {
    my $r = shift;
    _mash_phones $r;
    return flatten $r->{personal_phone}, $r->{household_phone}, $r->{other_phone};
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

    sub _mash_addresses($) {
        my $r = shift;
        my $pp = delete $r->{__addresses} or return;
        for my $p (@$pp) {
            my $slot = $p->{address_slot};
            $r->{addresses}[$slot] = {
                label           => $p->{address_label},
                address         => $p->{address},
                show_in_book    => $p->{address_show_in_book},
                use_as_postal   => $p->{address_use_as_postal},
            };
        }
    }

    sub _mash_addresses2($) {
        my $r = shift;
        my $pp = delete $r->{__addresses2} or return;
        for my $p (@$pp) {
            my $slot = $p->{address_slot};
            $r->{addresses2}[$slot] = {
                label           => $p->{address_label},
                address         => $p->{address},
                show_in_book    => $p->{address_show_in_book},
                use_as_postal   => $p->{address_use_as_postal},
            };
        }
    }

sub listed_address {
    my $r = shift;
    _mash_addresses $r;
    return
    map {
        my $A = $_->{address};
        $A =~ s/[\r\n]+/\n/g;
        $A =~ s/\n*(?:New Zealand)$//;
        if (! $::hide_address_labels) {
            my $L = $_->{address_label};
            $A = "$L: $A" if $L;
        }
        $A
    } grep {
        $_ && $_->{show_in_book} && $_->{address}
    } flatten $r->{addresses};
}

sub postal_address {
    my $r = shift;
    _mash_addresses $r;
    return
    map {
        my $A = $_->{address};
        $A =~ s/[\r\n]+/\n/g;
        $A =~ s/\n*(?:New Zealand)$//;
        if (! $::hide_address_labels) {
            my $L = $_->{address_label};
            $A = "$L: $A" if $L;
        }
        $A
    } grep {
        $_ && $_->{use_as_postal} && $_->{address}
    } flatten $r->{addresses};
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

    BEGIN {
           +8 % +3 == +2 && -17 % -8 == -1
        && -8 % +3 == +1 && -17 % +8 == +7
        && +8 % -3 == -1 && +17 % -8 == -7
        && -8 % -3 == -2 && +17 % +8 == +1
            or die "This version of Perl has a broken implementation of modulus";
    }
    $t -= $t % 86400;   # ≈24h  NOTE: modulus must be positive

    $t = strftime '%Y-%m-%d', gmtime $t;
    return $t;
}

sub fix_one {
    my ($r) = @_;

    $r->{monthly_meeting_area} = do { delete $r->{mmm_xmtag} } // '';
    $r->{formal_membership} = do { my $mmm = delete $r->{__mm_member}; $mmm ? join "\n", map { $_->{mmm_xmtag} } @$mmm : undef; } // '';
    $r->{inactive} = 0; # TODO
    $r->{show_me_in_young_friends_listing} = 'TODO';

    $r->{fax} = ''; # defunct
  # $r->{listed_address} = $r->listed_address;
  # $r->{postal_address} = $r->postal_address;
    $r->{receive_local_newsletter_by_post} = 'TODO';
    $r->{nz_friends_by_post} = 'TODO';
    $r->{receive_local_newsletter_by_email} = 'TODO';
    $r->{nz_friends_by_email} = 'TODO';
    $r->{last_updated} = 'TODO';

    CSV::Common::make_name_sortable($r);    # copied from CSV::Common::fix_one
    return $r;
}

sub want_shown_in_book {
    return 1;   # TODO
}

sub is_human($) {
    my $r = shift;
    return 1;   # TODO
}

sub is_meeting($) {
    my $r = shift;
    return 0;   # Never
}

sub is_role($) {
    my $r = shift;
    return 0;   # Never
}

sub is_admin($) {
    my $r = shift;
    return 0;   # Never
}

sub is_role_or_admin($) {
    my $r = shift;
    return is_role($r) || is_admin($r);
}

sub is_adult($) {
    my $r = shift;
    return $r->{__is_adult} //= flip_coin 0.75;     # TODO
}

sub is_child($) {
    my $r = shift;
    return not $r->{__is_adult} //= flip_coin 0.75; # TODO
}

sub is_member($) {
    my $r = shift;
    return $r->{__is_member} //= $r->is_adult && flip_coin 0.625;   # TODO
}

sub is_attender($) {
    my $r = shift;
    return $r->{__is_attender} //= ! $r->is_member && $r->is_adult && flip_coin 0.875;    # TODO
}

sub is_inactive($) {
    my $r = shift;
    return $r->{__is_inactive} //= ! $r->is_member && ! $r->is_attender;   # TODO
}

sub is_child_or_inactive($) {
    my $r = shift;
    return is_child($r) || is_inactive($r);
}

sub is_member_or_attender($) {
    my $r = shift;
    return is_member($r) || is_attender($r);
}

sub is_maci($) {
    my $r = shift;
    return is_member_or_attender($r) || is_child_or_inactive($r);
}

sub want_wg_listings($) {
    my $r = shift;
    #state $wgx = [ grep { !/^NO/ } @wg_order ];
    #return @{ $r->{__wg_listings} ||= [ randomly_choose flip_coin 0.125 ? 2 : 1, @$wgx ] }; # TODO
    return @{ $r->{__wg_listings} ||= do {
        my $w = delete $r->{__wgroup} || [];
        my @w = @$w;
        @w = grep { $_ } map { $_->{wgroup_name} } @w;
        @w or @w = 'NONE';
        @w = map { $wg_map{$_} || $_ } @w;
        \@w
    } }; # TODO
}

sub want_mm_listings($) {
    my $r = shift;
    my @wg = want_wg_listings $r;
    s/\S.*// for @wg;
    return uniq @wg;
}

sub postal_inclusions($@) {
    my $r = shift;
    my @inclusion_tags = @_;
    return randomly_choose 2, @_;   # TODO
}

sub needs_overseas_postage($) {
    my $r = shift;
    return flip_coin 0.0625;        # TODO
}

}

{ package SQL::Drupal7::user_access_needs;      use parent 'SQL::Drupal7'; use export; }        # access_needs_uid
#{ package SQL::Drupal7::user_addresses2;        use parent 'SQL::Drupal7'; use export; }        # key=address_uid
{ package SQL::Drupal7::user_addresses;         use parent 'SQL::Drupal7'; use export; }        # key=address_uid
{ package SQL::Drupal7::user_all_subs;          use parent 'SQL::Drupal7'; use export; }        # key=subs_uid
{ package SQL::Drupal7::user_kin;               use parent 'SQL::Drupal7'; use export; }        # key=kin_uid
{ package SQL::Drupal7::user_med_needs;         use parent 'SQL::Drupal7'; use export; }        # key=med_needs_uid
{ package SQL::Drupal7::user_mm_member;         use parent 'SQL::Drupal7'; use export; }        # key=mmm_uid
{ package SQL::Drupal7::user_notes;             use parent 'SQL::Drupal7'; use export; }        # key=notes_uid
{ package SQL::Drupal7::user_phones;            use parent 'SQL::Drupal7'; use export; }        # key=phones_uid
{ package SQL::Drupal7::user_phones;            use parent 'SQL::Drupal7'; use export; }        # key=phone_uid
{ package SQL::Drupal7::user_visible_emails;    use parent 'SQL::Drupal7'; use export; }        # key=visible_email_uid
{ package SQL::Drupal7::user_websites;          use parent 'SQL::Drupal7'; use export; }        # key=website_uid
{ package SQL::Drupal7::user_wgroup;            use parent 'SQL::Drupal7'; use export; }        # key=wgroup_uid

{ package SQL::Drupal7::user_email_subs;        use parent 'SQL::Drupal7::user_all_subs'; }     # TODO: not used yet
{ package SQL::Drupal7::user_print_subs;        use parent 'SQL::Drupal7::user_all_subs'; }     # TODO: not used yet

1;
