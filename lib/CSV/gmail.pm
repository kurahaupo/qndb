#!/module/for/perl

use 5.010;

use strict;
use warnings;
use utf8;

=head 3

Exporting address book data from GMail provides a CSV in this format, encoded as UTF-16LE.
The range of numbered fields is extensible, so we cope with an arbitrary number of them.

Name,Given Name,Additional Name,Family Name,Yomi Name,Given Name Yomi,Additional Name Yomi,Family Name Yomi,Name Prefix,Name Suffix,Initials,Nickname,Short Name,Maiden Name,Birthday,Gender,Location,Billing Information,Directory Server,Mileage,Occupation,Hobby,Sensitivity,Priority,Subject,Notes,Group Membership,E-mail 1 - Type,E-mail 1 - Value,E-mail 2 - Type,E-mail 2 - Value,E-mail 3 - Type,E-mail 3 - Value,E-mail 4 - Type,E-mail 4 - Value,IM 1 - Type,IM 1 - Service,IM 1 - Value,Phone 1 - Type,Phone 1 - Value,Phone 2 - Type,Phone 2 - Value,Phone 3 - Type,Phone 3 - Value,Phone 4 - Type,Phone 4 - Value,Address 1 - Type,Address 1 - Formatted,Address 1 - Street,Address 1 - City,Address 1 - PO Box,Address 1 - Region,Address 1 - Postal Code,Address 1 - Country,Address 1 - Extended Address,Address 2 - Type,Address 2 - Formatted,Address 2 - Street,Address 2 - City,Address 2 - PO Box,Address 2 - Region,Address 2 - Postal Code,Address 2 - Country,Address 2 - Extended Address,Address 3 - Type,Address 3 - Formatted,Address 3 - Street,Address 3 - City,Address 3 - PO Box,Address 3 - Region,Address 3 - Postal Code,Address 3 - Country,Address 3 - Extended Address,Address 4 - Type,Address 4 - Formatted,Address 4 - Street,Address 4 - City,Address 4 - PO Box,Address 4 - Region,Address 4 - Postal Code,Address 4 - Country,Address 4 - Extended Address,Organization 1 - Type,Organization 1 - Name,Organization 1 - Yomi Name,Organization 1 - Title,Organization 1 - Department,Organization 1 - Symbol,Organization 1 - Location,Organization 1 - Job Description,Relation 1 - Type,Relation 1 - Value,Relation 2 - Type,Relation 2 - Value,Relation 3 - Type,Relation 3 - Value,Relation 4 - Type,Relation 4 - Value,Relation 5 - Type,Relation 5 - Value,Website 1 - Type,Website 1 - Value,Website 2 - Type,Website 2 - Value,Website 3 - Type,Website 3 - Value,Website 4 - Type,Website 4 - Value,Event 1 - Type,Event 1 - Value,Custom Field 1 - Type,Custom Field 1 - Value

 name given_name additional_name family_name yomi_name given_name_yomi
 additional_name_yomi family_name_yomi name_prefix name_suffix initials
 nickname short_name maiden_name birthday gender location billing_information
 directory_server mileage occupation hobby sensitivity priority subject notes
 group_membership
 e_mail_1_type e_mail_1_value
 e_mail_2_type e_mail_2_value
 e_mail_3_type e_mail_3_value
 e_mail_4_type e_mail_4_value
 im_1_type im_1_service im_1_value
 phone_1_type phone_1_value
 phone_2_type phone_2_value
 phone_3_type phone_3_value
 phone_4_type phone_4_value
 address_1_type address_1_formatted address_1_street address_1_city address_1_po_box address_1_region address_1_postal_code address_1_country address_1_extended_address
 address_2_type address_2_formatted address_2_street address_2_city address_2_po_box address_2_region address_2_postal_code address_2_country address_2_extended_address
 address_3_type address_3_formatted address_3_street address_3_city address_3_po_box address_3_region address_3_postal_code address_3_country address_3_extended_address
 address_4_type address_4_formatted address_4_street address_4_city address_4_po_box address_4_region address_4_postal_code address_4_country address_4_extended_address
 organization_1_type organization_1_name organization_1_yomi_name organization_1_title organization_1_department organization_1_symbol organization_1_location organization_1_job_description
 relation_1_type relation_1_value
 relation_2_type relation_2_value
 relation_3_type relation_3_value
 relation_4_type relation_4_value
 relation_5_type relation_5_value
 website_1_type website_1_value
 website_2_type website_2_value
 website_3_type website_3_value
 website_4_type website_4_value
 event_1_type event_1_value
 custom_field_1_type custom_field_1_value

=cut

package CSV::gmail;
use parent 'CSV::Common';

use Carp 'carp';

use list_functions 'flatten', 'uniq', 'first';
use phone_functions 'normalize_phone';
use verbose;
use quaker_info;

#
# Preference order for extracting fields; only use 'c/-' & 'parents' for
# function elements, not for display elements
#
# NB: 'c/-' presents as 'c_'
#     'G+' (GooglePlus) gets split into 'g'+(empty) and so presents as just 'g'
#
my @key_prefs = qw{ role personal g work home home1 home2 shared post listing other };

my %patch_types = (
    phone => \&normalize_phone,
);

# GMail list
sub _list($$) {
    my ($r, $k) = @_;
    my $l = $r->{"LIST_$k"} ||= do {
            my @q = split ' ::: ', $r->{$k} || '';
            s# :(:::+) # $1 # for @q;
            \@q
        };
    return @$l if wantarray;
    return $l;
}

sub fix_one($) {
    my $r = shift;
    $r->name;  # force components into {composite_name}
    state $care_of = {  c_      => 3,
                        shared  => 1,
                        parents => 2, };
    state $min_care_of = 2;
    state $address_parts = [qw{ formatted street city po_box region postal_code country extended_address }];

    ADDRESS: for (my $n = 1; exists $r->{"address_${n}_type"}; ++$n) {
        my $types = $r->{"address_${n}_type"} || 'UNSPEC';
        $types =~ s#^\*\s*##;
        $types = lc $types;
        my @types = split /\s*\+\s*(?=[^+ ])/, $types;
        s#\W+#_#g for @types;
        my @a;
        PART: for my $part (@$address_parts) {
            my $p = delete $r->{"address_${n}_${part}"} || next PART;
            my @p = split / ::: /, $p;
            s# :(:::+) # $1 # for @p;
            for my $pi (0..$#p) {
                $a[$pi]{$part} = $p[$pi];
            }
        }
        @a && $a[0]{formatted} or next ADDRESS;
        for my $a (@a) {
            $a->{country} && $a->{country} eq 'NZ' and $a->{country} = '';
            $a->{formatted} =~ s#\s*\n*NZ$##o;
            $a = new string_with_components::
                    $r->_canon_address($a->{formatted}, scalar grep { $care_of->{$_} && $care_of->{$_} >= $min_care_of } @types ),
                    types       => \@types,
                    streetnum   => $a->{streetnum},
                    street      => $a->{street},
                    po_box      => $a->{po_box},
                    suburb      => $a->{extended_address},
                    city        => $a->{city},
                    region      => $a->{region},
                    postcode    => $a->{postal_code},
                    country     => $a->{country},
                    ;
            $a->{streetnum} = $a->{street} && $a->{street} =~ s#^(\S*\d\S*)\s+## && $1 || '';
            push @{$r->{"LIST_address"}}, $a;
            for my $type (@types) {
                push @{$r->{"LIST_${type}_address"}}, $a;
                push @{$r->{"MAP_address"}->{$type}}, $a;
                $r->{"${type}_address"} ||= $a;
            }
        }
    }
    KIND: for my $kind (qw(phone e_mail im relation website custom_field)) {
        my $patch = $patch_types{$kind};
        ATTEMPT: for (my $n = 1, my $m = 4 ;; ++$n) {
            my $types = delete $r->{"${kind}_${n}_type"} // do { --$m or last; next ATTEMPT; };
            $m = 4;
            $types =~ s#^\*\s*##;
            $types = lc $types;
            my @types = split /\s*\+\s*/, $types;
            s#\W+#_#g for @types;

            my $value = delete $r->{"${kind}_${n}_value"} || next ATTEMPT;
            for my $type (@types) {
                $r->{"${type}_${kind}"} = $value;
            }
            for my $v2 (split ' ::: ', $value) {
                $v2 =~ s# :(:::+) # $1 #;
                $v2 = $patch->($v2) if $patch;
                $v2 =~ s#\.$##;
                $v2 =~ s#^#c/- # if $CSV::Common::use_care_of && $kind eq 'e_mail' && grep { $care_of->{$_} && $care_of->{$_} >= $min_care_of } @types;
                push @{$r->{"LIST_${kind}"}}, $v2;
                for my $type (@types) {
                    push @{$r->{"LIST_${type}_${kind}"}}, $v2;
                    push @{$r->{"MAP_${kind}"}->{$type}}, $v2;
                }
            }
        }
    }

    $r->{home_phone} ||= '';
    $r->{mobile_phone} ||= '';

    $r->name or do { warn "Ignoring line#$r->{__source_line} ".($r->uid || '(unnumbered)')." nameless record" if $why_not; return 0 };  # ignore records without names
    $r->gtags('explanatory texts') and do { warn "Ignoring line#$r->{__source_line} explanatory text ".($r->name) if $why_not; return 0 };
    1;
}

sub name($) {
    my $r = shift;
    return $r->{composite_name} ||= do {
        my $sort_by_surname   = lc join " ", map { $r->{$_} || () } qw{family_name given_name additional_name full_name};
        my $sort_by_givenname = lc join " ", map { $r->{$_} || () } qw{given_name additional_name family_name full_name};
        my $clean_name = $r->{name};
        my $n = new string_with_components::
            $clean_name,
            full_name       => $r->{name},
            additional_name => $r->{additional_name},
            family_name     => $r->{family_name},
            given_name      => $r->{given_name},
            initials        => $r->{initials},
            maiden_name     => $r->{maiden_name},
            name_prefix     => $r->{name_prefix},
            name_suffix     => $r->{name_suffix},
            nickname        => $r->{nickname},
            short_name      => $r->{short_name},
            yomi_name       => $r->{yomi_name},
            given_name_yomi => $r->{given_name_yomi},
            family_name_yomi => $r->{family_name_yomi},
            additional_name_yomi => $r->{additional_name_yomi},
            sort_by_surname => $sort_by_surname,
            sort_by_givenname => $sort_by_givenname;
        $r->_make_name_sortable($n);
        $n
    };
}

sub uid($) {
    my $r = shift;
    $r->{qdb_custom_field} ||= do {
        my ($x) = $r->_list('qdb_custom_field');
        $x || "GEN".(0+$r).'-gmail';
    };
}

sub uid_of_spouse($) {
    my $r = shift;
    $r->_list('qdb_spouse_custom_field');
}

sub uid_of_children_under_16($) {
    my $r = shift;
    my $k = $r->_map('custom_field')->{qdb_child};
    $k ? @$k : ()
}

sub listed_email($) {
    my $r = shift;
    my $e = $r->_map('e_mail');
    return sort uniq
            flatten
             map { $e->{$_} }
              'listing', @key_prefs; #, keys %$e
}

sub listed_phone($) {
    my $r = shift;
    my $e = $r->_map('phone');
    return uniq
            flatten
             map { $e->{$_} }
              'listing', 'mobile', @key_prefs; #, keys %$e
}

sub all_addresses($) {
    my $r = shift;
    my $e = $r->_map('address');
    return uniq
            flatten
             map { $e->{$_} }
              grep { ! /^old$|unlisted/ }
               @key_prefs, keys %$e
}

sub listed_address($) {
    my $r = shift;
    my $e = $r->_map('address');
    return first
            flatten
              first
                map { $e->{$_} || () }
                  'listing', @key_prefs;
}

sub postal_address($) {
    my $r = shift;
    my $e = $r->_map('address');
    return first
            flatten
              map { $e->{$_} }
                'post', @key_prefs, 'c_', 'parents'; #, keys %$e;
}

sub birthdate($) {
    my $r = shift;
    $r->{birthday};
}

sub _gtags_list {
    my $r = shift;
    return map { s/^\W*//r } $r->_list('group_membership');
}

sub _gtags_set {
    my $r = shift;
    return $r->{"SET_group_membership"} ||= +{ map { ( $_ => 1 ) } _gtags_list($r) };
}

sub gtags {
    my $r = shift;
    if (@_ && ref $_[0] eq 'Regexp') {
        my $re = shift @_;
        @_ and carp "gtags called with spurious args after RegEx";
        return map { /$re/ ? $+ // $& : () } _gtags_list($r);
    }
    else {
        return _gtags_list($r) if ! @_ && wantarray;
        carp "gtags called in scalar context with no args\n" if ! @_;
        my $m = _gtags_set($r);
        # run grep in scalar/list context from caller
        return grep { $m->{$_} } @_;
    }
}

sub monthly_meeting_area($) {
    my $r = shift;
    sort
        map { s/ - overseas/ - Members overseas/;
              s/ - elsewhere/ - Members in other areas/;
              $_; }
            grep { !/YF/ }
                $r->gtags( qr/^listing[- ]*(.*)/ );
}

sub formal_membership($) {
    my $r = shift;
    return                           $r->gtags('members of overseas meetings') ? '* Overseas'  : (),
            map { $mm_names{uc $_} } $r->gtags( qr/^member - ($mm_keys_re)/ );
}

sub inactive($) {
    my $r = shift;
    $r->gtags('inactive') ? "Yes" : "No";
}

sub phone_number($) {
    my $r = shift;
    uniq map { $r->_list($_.'_phone') } 'listing', @key_prefs;
}

sub mobile_number($) {
    my $r = shift;
    map { $r->_list($_.'_phone') } qw{ mobile shared_mobile };
}

sub fax($) {
    my $r = shift;
    $r->{home_fax_phone} || $r->{fax_phone} || $r->{work_fax_phone};
}

sub show_me_in_young_friends_listing($) {
    my $r = shift;
    $r->gtags(qr/^listing - YF/) ? 'Yes' : 'No';
}

sub website_url($) {
    my $r = shift;
    flatten values %{$r->{'MAP_website'}};
}

sub nz_friends_by_post($) {
    my $r = shift;
    $r->gtags('post NZ Friends') ? 'Yes' : 'No';
}

sub receive_local_newsletter_by_post($) {
    my $r = shift;
    return uniq map { $mm_names{uc $_} } $r->gtags( qr/^post ($mm_keys_re)\s+[Nn]ews/ );
}

sub receive_local_newsletter_by_email($) {
    my $r = shift;
    return uniq map { $mm_names{uc $_} } $r->gtags( qr/^send ($mm_keys_re)\s+[Nn]ews/ );
}

1;
