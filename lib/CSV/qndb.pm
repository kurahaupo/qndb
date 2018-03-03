#!/module/for/perl

use 5.010;
use strict;
use warnings;

=head 3

The "download all data" link from quaker.org.nz delivers a spreadsheet
"all_members.csv" in this format...

Updated version from MyDropWizard:
uid,users_name,users_mail,family_name,first_name,uid_of_spouse,uid_of_children_under_16,monthly_meeting_area,formal_membership,property_name,address,suburb,town,postcode,country,po_box_number,rd_no,birthdate,inactive,phone_number,mobile_number,fax,website_url,receive_local_newsletter_by_post,nz_friends_by_post,nz_friends_by_email,show_me_in_young_friends_listing,changed

 uid users_name users_mail family_name first_name uid_of_spouse
 uid_of_children_under_16 monthly_meeting_area formal_membership property_name
 address suburb town postcode country po_box_number rd_no birthdate inactive
 phone_number mobile_number fax website_url receive_local_newsletter_by_post
 nz_friends_by_post nz_friends_by_email show_me_in_young_friends_listing
 changed

Last version from Catalyst:
uid,users_name,users_mail,family_name,first_name,uid_of_spouse,uid_of_children_under_16,monthly_meeting_area,formal_membership,property_name,address,suburb,town,postcode,country,po_box_number,rd_no,birthdate,inactive,phone_number,mobile_number,fax,website_url,receive_local_newsletter_by_post,nz_friends_by_post,nz_friends_by_email,show_me_in_young_friends_listing,last_updated

 uid users_name users_mail family_name first_name uid_of_spouse
 uid_of_children_under_16 monthly_meeting_area formal_membership property_name
 address suburb town postcode country po_box_number rd_no birthdate inactive
 phone_number mobile_number fax website_url receive_local_newsletter_by_post
 nz_friends_by_post nz_friends_by_email show_me_in_young_friends_listing
 last_updated

Original version circa 2014:
uid,users_name,users_mail,family_name,first_name,uid_of_spouse,uid_of_children_under_16,monthly_meeting_area,formal_membership,property_name,address,suburb,town,postcode,country,po_box_number,rd_no,birthdate,inactive,phone_number,mobile_number,fax,website_url,receive_local_newsletter_by_post,nz_friends_by_post,show_me_in_young_friends_listing

 uid users_name users_mail family_name first_name uid_of_spouse
 uid_of_children_under_16 monthly_meeting_area formal_membership property_name
 address suburb town postcode country po_box_number rd_no birthdate inactive
 phone_number mobile_number fax website_url receive_local_newsletter_by_post
 nz_friends_by_post show_me_in_young_friends_listing

=cut

package CSV::qndb;
use parent 'CSV::Common';

use POSIX 'strftime';

use verbose;
use phone_functions 'normalize_phone';

# This is a hack -- this lookup should be done as part of the database export
# process.
my %country_map = qw(
     13 Australia
     14 Austria
     32 Bulgaria
     38 Canada
     43 China
     70 France
    143 NZ
    154 PNG
    201 Tonga
    211 UK
    212 USA
);

sub _titlecase($$) { $_[1] }    # don't do TitleCase QNDB files any more; they should be uptodate

sub _hash_uid($) {
    my $z = shift;
    state $modulus = 0x7ffff;  # 2**19-1
    $z =~ /\D/ and $z = unpack( "%32L*", "$z\x00$z\x00\x00$z\x00\x00\x00" ) % $modulus;
    return $z;
}

sub fix_one($) {
    my $r = shift;
    $r->name or return 0;  # ignore records without names; also force components into {composite_name}
    $r->{$_} //= '' for qw{ property_name users_mail country mobile_number fax phone_number };
    $r->{$_} =~ s/^-$// for qw{ users_mail };
    $r->{$_} //= 'Maybe' for qw{ show_me_in_young_friends_listing receive_local_newsletter_by_post };
    $r->{users_mail} && $r->{users_mail} =~ /\@egressive\.com$|\@catalyst\.net\.nz$/ and return 0; # ignore Catalyst/Egressive staff accounts
    #print "Applying QNDB fixup to ", Dumper($r);

    state $split_fields = { map { ($_=>1) } qw{
            uid_of_children_under_16
            uids_of_parents
        }};
    state $patch_fields = {
            uid_of_children_under_16    => \&_hash_uid,
            uid_of_spouse               => \&_hash_uid,
            uids_of_parents             => \&_hash_uid,
            uid                         => \&_hash_uid,
            fax                         => \&normalize_phone,  # CSV::qndb
            mobile_number               => \&normalize_phone,  # CSV::qndb
            phone_number                => \&normalize_phone,  # CSV::qndb
        };
    FIELD: for my $f (keys %$r) {
        $split_fields->{$f} or next FIELD;
        my $v = $r->{$f};
        my @v = $split_fields->{$f} ? split /\s*,\s*/, $v : $v;
        $r->{"LIST_$f"} = \@v
    }
    PFIELD: for my $f ( keys %$patch_fields ) {
        exists $r->{$f} or next PFIELD;
        if ( $split_fields->{$f} ) {
            $_ = $patch_fields->{$f}->($_) for @{$r->{"LIST_$f"}};
        }
        else {
            $_ = $patch_fields->{$f}->($_) for $r->{$f};
        }
    }
    {
        my $property_name = $r->{property_name};
        my $care_of;
        my $po_box        = $r->{po_box_number};
        my $street        = $r->{address};
        my $qstreet = $street;
        my $streetnum = '';
        $streetnum = $1 if $qstreet =~ s/^(\S*\d\S*)\s+//;
        my $rd_no         = $r->{rd_no};
        my $suburb        = $r->{suburb};
        my $city          = $r->{town};
        my $postcode      = $r->{postcode};
        my $country       = $r->{country};

        if ($city =~ /\d{4,}$|\b\w\w?\d+[- ]\d+\w$/) {
            warn sprintf "Record for %s has city field '%s' which appears to hold a postcode '%s'\n", $r->name, $city, $&;
        }

        $_ and s/\s*,\s*/\n/g
            for $property_name, $street, $suburb, $city;
        $care_of = "c/- $1"
            if $property_name =~ s<^c/[-o]\s+(\S.*)\n?><>i;
        $_ = $r->_titlecase($_) for $suburb, $city;
        $country &&= $country_map{$country} || $r->_titlecase($country);
        $country = '' if $country eq 'NZ';
        $r->{country} = $country;
        $suburb ne $city or $suburb = undef if $suburb && $city;

        if ( $po_box ) {
            if ( $po_box =~ /^\d+$/ ) {
                $po_box = "PO Box $po_box";
                my $fulladdr = join "\n", grep {$_} $care_of, $property_name, $po_box, $suburb, $city;
                $fulladdr .= ' '.$postcode if $postcode;
                $fulladdr .= "\n".$country if $country;
                $fulladdr = $r->_canon_address($fulladdr);
                $r->{X_po_box_address} =
                    new string_with_components::
                        $fulladdr,
                        care_of         => $care_of,
                        property_name   => $property_name,
                        po_box          => $po_box,
                        city            => $suburb || $city,
                        postcode        => $postcode,
                        country         => $country;
            }
            else {
                ($po_box, my @lines) = split /\s*,\s*/, $po_box;
                my $xcountry = @lines > 1 && $lines[-1] !~ /\d$/ ? pop @lines : $country;
                my $xpostcode = @lines && $lines[-1] =~ s/\s+([- 0-9]{3,9}\d)$// ? $1 : $postcode;
                my $xcity = pop @lines || $suburb || $city;
                my $fulladdr = join "\n", grep {$_} $care_of, $property_name, $po_box, @lines, $xcity;
                $fulladdr .= ' '.$xpostcode if $xpostcode;
                $fulladdr .= "\n".$xcountry if $xcountry;
                $fulladdr = $r->_canon_address($fulladdr);
                $r->{X_po_box_address} =
                    new string_with_components::
                        $fulladdr,
                        care_of         => $care_of,
                        property_name   => $property_name,
                        po_box          => $po_box,
                        city            => $xcity,
                        postcode        => $xpostcode,
                        country         => $xcountry;
            }
        }
        if ( $rd_no ) {
            if ( $rd_no  =~ /^\d+$/ ) {
                $rd_no  = "RD $rd_no";
                my $fulladdr = join "\n", grep {$_} $care_of, $property_name, $street, $rd_no, $city;
                $fulladdr .= ' '.$postcode if $postcode;
                $fulladdr .= "\n".$country if $country;
                $fulladdr = $r->_canon_address($fulladdr);
                $r->{X_rd_address} =
                    new string_with_components::
                        $fulladdr,
                        care_of         => $care_of,
                        property_name   => $property_name,
                        streetnum       => $streetnum,
                        street          => $qstreet,
                        rd_no           => $rd_no,
                        city            => $suburb || $city,
                        postcode        => $postcode,
                        country         => $country;
            }
            else {
                ($rd_no, my @lines) = split /\s*,\s*/, $rd_no;
                my $xcountry = @lines > 1 && pop @lines || $country;
                my $xpostcode = @lines && $lines[-1] =~ s/\s+([- 0-9]{3,9}\d)$// ? $1 : $postcode;
                my $xcity = pop @lines || $suburb || $city;
                my $fulladdr = join "\n", grep {$_} $care_of, $property_name, $rd_no, @lines, $xcity;
                $fulladdr .= ' '.$xpostcode if $xpostcode;
                $fulladdr .= "\n".$xcountry if $xcountry;
                $fulladdr = $r->_canon_address($fulladdr);
                $r->{X_rd_address} =
                    new string_with_components::
                        $fulladdr,
                        care_of       => $care_of,
                        property_name => $property_name,
                        rd_no         => $rd_no,
                        city          => $xcity,
                        postcode      => $xpostcode,
                        country       => $xcountry;
            }
        }

        if ( $street || ! $po_box && ! $rd_no ) {
            if ($street =~ s/^\(([^()]*)\)$/$1/) {
                warn "Unwrapping bracketed street [$street]\n" if $verbose;
                if ($street =~ s/\s*\n\s*(.*)$//) {
                    $city = $1;
                    $postcode = $suburb = undef;
                    if ($city =~ s/\s+(\d\d\d\d)\s*$//) {
                        $postcode = $1;
                    }
                    if ($street =~ s/\s*\n\s*(.*)$//) {
                        $suburb = $1;
                    }
                }
                warn sprintf "Unwrapped bracketed street street=[%s], suburb=[%s], city=[%s], postcode=[%s]\n",
                        $street // '(none)',
                        $suburb // '(none)',
                        $city // '(none)',
                        $postcode // '(none)',
                    if $verbose;
            }
            my $fulladdr = join "\n", grep {$_} $care_of, $property_name, $street, $suburb, $city;
            if ($postcode) {
                if ($postcode =~ /^[A-Za-z]+\b/ || !$fulladdr) {
                    # XX or XXX is state or province; XX NNNNN is US
                    # state+postcode
                    $fulladdr .= "\n".$postcode;
                }
                else {
                    $fulladdr .= ' '.$postcode;
                }
            }
            $fulladdr .= "\n".$country if $country;
            $fulladdr = $r->_canon_address($fulladdr);
            $r->{X_home_address} =
                new string_with_components::
                    $fulladdr,
                    care_of       => $care_of,
                    property_name => $property_name,
                    streetnum     => $streetnum,
                    street        => $qstreet,
                    suburb        => $suburb,
                    city          => $city,
                    postcode      => $postcode,
                    country       => $country;
        };
    };
    1;
}

# QNDB list
sub _list($$) {
    my ($r, $k) = @_;
    my $l = $r->{"LIST_$k"} ||= [ split /\s*,\s*/, $r->{$k} || '' ];
    return @$l if wantarray;
    return $l;
}

sub uid {
    my $r = shift;
    return $r->{'uid'} ||= "GEN".(0+$r).'-qdb';
}

sub uid_of_spouse {
    my $r = shift;
    $r->_list('uid_of_spouse');
}

sub uid_of_children_under_16($) {
    my $r = shift;
    $r->_list('uid_of_children_under_16');
}

sub name($) {
    my $r = shift;
    return $r->{composite_name} ||= do {
        my $given_name = delete $r->{first_name};
        my $family_name = $r->_titlecase(delete $r->{family_name});
        my @p = grep {$_} $given_name, $family_name;
        my $clean_name = join " ", @p;
        my $sort_by_surname = lc join " ", reverse @p;
        my $sort_by_givenname = lc join " ", @p;
        my $n = new string_with_components::
            $clean_name,
            family_name       => $family_name,
            given_name        => $given_name,
            sort_by_surname   => $sort_by_surname,
            sort_by_givenname => $sort_by_givenname;
        $r->_make_name_sortable($n);
        $n;
    };
}

sub birthdate($) {
    my $r = shift;
    my $d = $r->{birthdate};
    $d =~ s/T00:00:00// if $d;
    return $d;
}

sub _spouse_and_parents {
    my $r = shift;
    return $r->{XREF_spouse} || (), $r->{XREF_parents} ? @{$r->{XREF_parents}} : ();
}

use list_functions 'uniq';
use quaker_info;

sub formal_membership {
    my $r = shift;
    my $m = $r->{formal_membership} || return ();
    return $m;
}

sub monthly_meeting_area {
    my $r = shift;
    my @x = $r->{monthly_meeting_area} || ();
    s/Thames and Coromandel/Thames \& Coromandel/ for @x;
    s/\bWG - Taranaki\b/TN - Taranaki/ for $m;
    (my $xmma = $x[0] || '') =~ s/\s.*//;
    for my $rr ( $r, $r->_spouse_and_parents ) {
        my $m = $rr->{formal_membership} or next;
        $m =~ m{^($mm_keys_re) }o or next;
        if ( $1 ne $xmma || !@x ) {
            push @x, "$1 - Members in other areas";
        }
    }
    return uniq sort @x;
}

sub nz_friends_by_post {
    my $r = shift;
    my @x = $r->{nz_friends_by_post} || ();
    (my $xmma = $x[0] || '') =~ s/\s.*//;
    for my $rr ( $r, $r->_spouse_and_parents ) {
        my $m = $rr->{nz_friends_by_post} or next;
        $m =~ m{^($mm_keys_re) }o or next;
        if ( $1 ne $xmma || !@x ) {
            push @x, "$1 - Members in other areas";
        }
      # if ( $m =~ /overseas/ ) {
      #     ;
      # }
    }
    return uniq sort @x;
}

sub nz_friends_by_email {
    my $r = shift;
    my @x = $r->{nz_friends_by_email} || ();
    (my $xmma = $x[0] || '') =~ s/\s.*//;
    for my $rr ( $r, $r->_spouse_and_parents ) {
        my $m = $rr->{nz_friends_by_email} or next;
        $m =~ m{^($mm_keys_re) }o or next;
        if ( $1 ne $xmma || !@x ) {
            push @x, "$1 - Members in other areas";
        }
      # if ( $m =~ /overseas/ ) {
      #     ;
      # }
    }
    return uniq sort @x;
}

sub last_updated {
    my $r = shift;
    my $c = $r->{last_updated} || $r->{changed};
    if ($c && $c =~ /^\d+$/ && $c >= 1000000000) {
        local $ENV{TZ} = 'NZ';
        $c = strftime "%Y-%m-%d %T", localtime $c;
    }
    return $c // ();
}

sub listed_email($) {
    my $r = shift;
    my @a = $r->{users_mail};
    @a = map { lc $_ } @a;
    @a = grep { $_ } @a;
    @a = grep {
                # skip any email addresses that forward to list managers, and
                # any that are tagged with suppression keywords
                !  m{ ^$
                 | ^ \w+\.list \+ \S+          \@ quaker(?:\.org|)\.nz $
                 |             \+ \S*hidden\S* \@
                 |             \+ \S*spouse\S* \@
                 |             \+ \S*parent\S* \@
                 |             \+ \S*child\S*  \@
                 |             \+ \S*unlist\S* \@
                 }iox;
            } @a;
    @a = grep {
                ! m{ \+\S*\@ }iox || m{ \+ \S*shared\S* \@ }iox;
            } @a
        if $CSV::Common::only_explicitly_shared_email;
    if ( $CSV::Common::use_care_of ) {
        # Any addresses marked "shared" are NOT care-of,
        # but any other marked addresses ARE care-of
        s#^([^@]*\+[^@]*)\+(\@.*)$#$1$2# or
        s#^([^@]*)\+[^@+]*shared[^@+]*(\@.*)$#$1$2# or
        s#^([^@]*)\+(\@.*)$#$1$2# or
        s#^([^@]*)\+\S*(\@.*)$#c/- $1$2# for @a;
    }
    else {
        s#^([^@]*)\+\S*(\@.*)$#$1$2# for @a;
    }
    return uniq sort @a;
}

sub all_addresses($) {
    my $r = shift;
    return uniq grep {$_}
        $r->{X_home_address},
        $r->{X_po_box_address},
        $r->{X_rd_address},
        ;
}

sub listed_address($) {
    my $r = shift;
    return  $r->{X_home_address} ||
            $r->{X_po_box_address} ||
            $r->{X_rd_address};
}

sub postal_address($) {
    my $r = shift;
    return  $r->{X_po_box_address} ||
            $r->{X_rd_address} ||
            $r->{X_home_address};
}

   sub _notno($) {
       return defined $_ && /^[Yy1]$|^yes$/i for @_;
   }

sub receive_local_newsletter_by_post($) {
    my $r = shift;
    _notno $r->{receive_local_newsletter_by_post};
}

sub receive_local_newsletter_by_email($) {
    my $r = shift;
    _notno $r->{receive_local_newsletter_by_email};
}

sub phone_number { $_[0]->{phone_number} }
sub mobile_number { $_[0]->{mobile_number} }

1;
