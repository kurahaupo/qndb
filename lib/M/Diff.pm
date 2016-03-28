#!/module/for/perl
# vim: set et sw=4 sts=4 nowrap :

use strict;
use 5.010;
use warnings;
use utf8;

package M::Diff;

use POSIX 'strftime';

use verbose;
use list_functions qw( max min uniq );

use M::IO qw( open_file_for_reading _open_output _close_output );

use M::Selection qw(
                     $skip_archived
                     $skip_deceased
                     $skip_meetings
                     $skip_newsletters_only
                     $skip_suppressed_email
                     $skip_suppressed_listing
                     $skip_suppressed_post
                     $skip_unlisted
                     $skip_unsub
                     skip_restricted_record
                   );

use constant now => [ localtime $^T ];
use constant this_year => strftime "%Y", localtime $^T;
use constant this_date => strftime "%Y%m%d", localtime $^T;
use constant sixteen_years_ago => strftime "%Y%m%d", localtime $^T - 504921600;

########################################
# Dump & diff formatting options

my $show_adult_birthdays = 0;
my $show_contact_details = 1;
my $show_hyperlinks = 1;
my $show_last_update = 1;
my $show_relationships = 1;
my $show_send_by_email = 0;
my $show_send_by_post = 1;
my $show_status = 1;
my $show_uid;
my $show_yf_listing = 1;

my $diff_quietly = 0;

########################################
# Dump & diff formatting options

my $diff_by = 'uid';
my $skip_emailless = 0;

use run_options (
    'diff-by-any'                   => sub { $diff_by = '' },
    'diff-by-name'                  => sub { $diff_by = 'name' },
    'diff-by-uid'                   => sub { $diff_by = 'uid' },
    'diff-quietly'                  => \$diff_quietly,

    '!+include-all|skip-none'       => \$skip_emailless,
    '!+include-no-email!'           => \$skip_emailless,
    '+need-email!'                  => \$skip_emailless,
    '+skip-all|include-none'        => \$skip_emailless,

    '!hide-adult-birthdays!'        => \$show_adult_birthdays,
    'show-adult-birthdays!'         => \$show_adult_birthdays,

    '!hide-contact-details!'        => \$show_contact_details,
    'show-contact-details!'         => \$show_contact_details,

    '!hide-hyperlinks!'             => \$show_hyperlinks,
    'show-hyperlinks!'              => \$show_hyperlinks,

    '!hide-last-update!'            => \$show_last_update,
    'show-last-update!'             => \$show_last_update,

    '!hide-relationships!'          => \$show_relationships,
    'show-relationships!'           => \$show_relationships,

    '!+hide-send!'                  => \$show_send_by_email,
    '!+names-only!'                 => \$show_send_by_email,
    '!hide-send-by-email!'          => \$show_send_by_email,
    '+show-send!'                   => \$show_send_by_email,
    'show-send-by-email!'           => \$show_send_by_email,

    '!+hide-send!'                  => \$show_send_by_post,
    '!+names-only!'                 => \$show_send_by_post,
    '!hide-send-by-post!'           => \$show_send_by_post,
    '+show-send!'                   => \$show_send_by_post,
    'show-send-by-post!'            => \$show_send_by_post,

    '!+names-only!'                 => \$show_status,
    '!hide-status!'                 => \$show_status,
    'show-status!'                  => \$show_status,

    '!hide-uid!'                    => \$show_uid,
    'show-uid!'                     => \$show_uid,

    '!+names-only!'                 => \$show_yf_listing,
    '!hide-yf-listing!'             => \$show_yf_listing,
    'show-yf-listing!'              => \$show_yf_listing,

    '#help-diff'                    => <<EndOfHelp,
"diff" options:
    --names-only
    --names-only
    --diff-quietly
    --diff-by-any
    --diff-by-name
    --diff-by-uid
    (plus all "dump" options)

See:
    $0 --help-dump
    $0 --help-output
    $0 --help-generic
EndOfHelp

    '#help-dump'                    => <<EndOfHelp,
"dump" options:
    --[no-]names-only
    --[no-]{show|hide}-adult-birthdays
    --[no-]{show|hide}-hyperlinks
    --[no-]{show|hide}-relationships
    --[no-]{show|hide}-send-any
    --[no-]{show|hide}-send-by-email
    --[no-]{show|hide}-send-by-post
    --[no-]{show|hide}-uid
    --[no-]{show|hide}-status
    --[no-]{show|hide}-yf-listing
    (plus all "text-output" options)

See also:
    $0 --help-output
    $0 --help-generic
EndOfHelp

    '#help-birthday'                => <<EndOfHelp,
"birthday" options:
    --[no-]need-email / --[no-]include-no-email

See:
    $0 --help-generic
EndOfHelp

);

########################################

sub show_date($) {
    for ( my $z = shift ) {
    s/T\d\d.*//;
    if (my @ymd = m/^(19\d\d|20[01]\d)\W*([012]\d)\W*(\d\d)$/) {
        warn "Date '$_' with year, ymd=[@ymd]" if $verbose > 3;
        if ($ymd[0] >= 1900 && $ymd[0] <= this_year && $ymd[1] <= 12 && $ymd[2] <= 31) {
            $_ = (strftime "%d %b %Y", 0,0,0,$ymd[2],$ymd[1]-1,$ymd[0]-1900,0,0)." ($_) (ymd)";
        }
    }
    elsif (my @dmy = m/^(\d\d)([012]\d)(19\d\d|20[01]\d)$/) {
        warn "Date '$_' with year, dmy=[@dmy]" if $verbose > 3;
        if ($dmy[2] >= 1900 && $dmy[2] <= this_year && $dmy[1] <= 12 && $dmy[0] <= 31) {
            $_ = (strftime "%d %b %Y", 0,0,0,$dmy[0],$dmy[1]-1,$dmy[2]-1900,0,0)." ($_) (dmy)";
        }
    }
    elsif (my @md = m/^\s*\-\-([012]\d)\-(\d\d)$/) {
        warn "Date '$_' without year, md=[@md]" if $verbose > 3;
        # day & month without year (GMail-style)
        if ($md[0] <= 12 && $md[1] <= 31) {
            $_ = (strftime "%d %b", 0,0,0,$md[1],$md[0]-1,-120,0,0)." ($_) (xmd)";
        }
    }
    warn "FIXED date $_" if $verbose > 3;
    return $_;
    }
}

sub show_qonu($) { $_[0] =~ /^GEN/ and return ''; return sprintf "http://quaker.org.nz/user/%s/edit/profile", shift }

my %show_fields = (
    birthdate                       => \&show_date,   # CSV::qndb
  # uid                             => \&show_qonu,   # CSV::qndb
  # uid_of_children_under_16        => \&show_qonu,   # CSV::qndb
  # uid_of_spouse                   => \&show_qonu,   # CSV::qndb
  # uids_of_parents                 => \&show_qonu,   # CSV::qndb
);

########################################

sub preferred_sort(@) {
    goto &M::Selection::sort_by_givenname;
}

sub _choose_ofields() {
    my @ofields;
    # 'name' is not required; as it's always printed, separately from the list of fields
    push @ofields, qw( monthly_meeting_area formal_membership inactive ) if $show_status;
    push @ofields, qw( show_me_in_young_friends_listing ) if $show_yf_listing;
    push @ofields, qw( listed_email phone_number mobile_number fax listed_address postal_address ) if $show_contact_details;
    push @ofields, qw( receive_local_newsletter_by_post nz_friends_by_post) if $show_send_by_post;
    push @ofields, qw( receive_local_newsletter_by_email nz_friends_by_email ) if $show_send_by_email;
                   # Possible additional fields:
                   #   synthesized website_url rd_no po_box_number country postcode
                   #   town suburb address property_name users_name
                   #   uid_of_children_under_16 uid_of_spouse uid first_name
                   #   family_name
    push @ofields, qw( uid uid_of_spouse uid_of_children_under_16 uids_of_parents ) if $show_uid;
    push @ofields, qw( birthdate ) if $show_adult_birthdays;
    push @ofields, qw( last_updated ) if $show_last_update;
    return grep { ! /^#/ } @ofields;
}

sub _dump_one($$$) {
    my ($out, $r, $ofields) = @_;
    my $ov = $verbose;
    {
        # Fixed fields: name, sort-keys, birthday
        my $v = $r->name || do { warn "UNNAMED RECORD\n" . Dumper($r); '(unknown)' };
        if ($show_hyperlinks and my $ru = $r->uid) {
            if ($ru !~ /^GEN/) {
                my $rl = show_qonu($ru);
                $v .= "  $rl";
            }
        }
        if ($r->can("gtags") && $r->gtags("suppress listing")) {
            $v .= "  [SUPPRESSED LISTING]";
        }
        printf $out "%s: %s\n", "name", $v;
        printf $out "%s: %s\n", "sort-by-surname", $r->{composite_name}->{sort_by_surname};
        printf $out "%s: %s\n", "sort-by-givenname", $r->{composite_name}->{sort_by_givenname};
        if ( my $bd = $r->birthdate ) {
            my ($y,$m,$d,$ymd) = ($1,$2,$3,"$1$2$3") if $bd =~ m#^(\d{4})\W*(\d{2})\W*(\d{2})(?:T[:0-9]{8}|\W*)$#;
            if ( $show_adult_birthdays || $ymd gt sixteen_years_ago ) {
                $bd = show_date($bd);
                printf $out "%s: %s\n", 'Birthday', $bd;
            }
        }
    }
    FIELD: for my $f (@$ofields) {
        my @v;
        if (my $ff = $r->can($f)) {
            @v = $ff->($r);
        }
        elsif (exists $r->{"LIST_$f"}) {
            @v = @{ $r->{"LIST_$f"} };
        }
        elsif (exists $r->{$f}) {
            @v = $r->{$f} // ();
        }
        elsif ( $f ne 'last_updated' ) {
            if ($verbose > 1) {
                warn "Missing field '$f' in $r\n".Dumper($r);
            }
            elsif ($verbose) {
                warn "Missing field '$f' in $r\n";
            }
        }
        @v = grep { defined $_ && "$_" ne '' } @v;
        defined $v[0] or next FIELD;
        if (my $fn = $show_fields{$f}) {
            $_ = $fn->($_) for @v
        }
        for my $v (@v) {
            if ($v =~ /\n/) {
                printf $out "%s:\n%s\n", $f, $v;
            }
            else {
                printf $out "%s: %s\n", $f, $v;
            }
        }
    }
    if ($show_relationships) {
        if ( my $s = $r->{XREF_spouse} ) {
            my $v = $s->name || '(unknown)';
            if ($show_hyperlinks and my $su = $s->uid) {
                my $sl = show_qonu($su);
                $v .= "  $sl";
            }
            printf $out "%s: %s\n", "spouse", $v;
        }
        if (my $pp = $r->{XREF_parents}) {
            for my $p ( preferred_sort @$pp ) {
                my $v = $p->name || '(unknown)';
                if ($show_hyperlinks and my $pu = $p->uid) {
                    my $pl = show_qonu($pu);
                    $v .= "  $pl";
                }
                printf $out "%s: %s\n", "parent", $v;
            }
        }
        if (my $cc = $r->{XREF_children}) {
            for my $c ( preferred_sort @$cc ) {
                my $v = $c->name || '(unknown)';
                if ($show_hyperlinks and my $cu = $c->uid) {
                    my $cl = show_qonu($cu);
                    $v .= "  $cl";
                }
                printf $out "%s: %s\n", "child", $v;
            }
        }
    }
    print $out Dumper($r) if $verbose > 4 && $debug;
    $verbose = $ov;
}

################################################################################
#
# Generate a report of differences between two files
#

    # Take two lists, and expand them with undefs so that equal elements line up.
    # Work by picking the longest common subsequence, then recursively operating
    # on the parts either side of that.
    # If there are no equal elements, just pad the two lists to the same length.
    sub _diff_align(&\@\@) {
        my ($cmp, $l1, $l2) = @_;
        my @stack = [ 0, $#$l1, 0, $#$l2 ];
        while (my $q = pop @stack) {
            my ( $s1, $e1, $s2, $e2) = @$q;
            my $d = ($e1-$s1) - ($e2-$s2);
            if ($s1 > $e1) {
                splice @$l1, $e1+1, 0, (undef) x -$d;
                next;
            }
            if ($s2 > $e2) {
                splice @$l2, $e2+1, 0, (undef) x $d;
                next;
            }
            # find maximal common stretch, with minimal offset from the centres
            my $ml = int( (($e1-$s1) + ($e2-$s2)) / 2 );
            my $mo = int( (($e1-$s1) - ($e2-$s2)) / 2 );
            my $pos;
            my $off;
            my $len = 0;
            for my $o ( $mo, map { $mo+$_, $mo-$_ } 1 .. $ml+1 ) {
                my $i = max $s1, $s2-$o;
                my $e = min $e1, $e2-$o;
                for (; $i <= $e ;++$i) {
                    if ( $cmp->($l1->[$i], $l2->[$i+$o]) ) {
                        my ($z) = grep { !$cmp->($l1->[$_], $l2->[$_+$o]) } $i .. $e;  # index of next non-matching element
                        $z //= $e+1;            # if all the rest match, then there is no "next non-matching element"
                        if ($len < $z-$i) {
                            # found a new longest subset
                            $len = $z-$i;
                            $pos = $i;
                            $off = $o;
                        }
                        $i = $z;
                    }
                }
            }
            if (defined $pos) {
                # found a common subset; perform alignment on the parts either side
                push @stack, [ $s1,       $pos-1, $s2,            $pos+$off-1 ],
                             [ $pos+$len, $e1,    $pos+$off+$len, $e2         ];
            }
            else {
                if ($d<0) {
                    splice @$l1, $e1+1, 0, (undef) x -$d;
                }
                else {
                    splice @$l2, $e2+1, 0, (undef) x $d;
                }
            }
        }
    }

use quaker_info '$mm_keys_re';

{
    my $C_plain = "\e[49m";
    my $C_black = "\e[30m";
    my $C_red = "\e[31m";
    my $C_green = "\e[32m";
    my $C_yellow = "\e[33m";
    my $C_blue = "\e[34m";
    my $C_purple = "\e[35m";
    my $C_cyan = "\e[34m";
    my $C_white = "\e[37m";

    my $B_plain = "\e[49m";
    my $B_black = "\e[40m";
    my $B_red = "\e[41m";
    my $B_green = "\e[42m";
    my $B_yellow = "\e[43m";
    my $B_blue = "\e[44m";
    my $B_purple = "\e[45m";
    my $B_cyan = "\e[44m";
    my $B_white = "\e[47m";
    my $fmt_label = "%-18.18s ";
    my $fmt = "%-32s %-3.3s %s";

    sub show_one_diff($$$$) {
        my ($out, $r1, $r2, $ofields) = @_;
        my $said_title;
        if ($r1) {
            my $name1 = $r1->name;
            my $uid1  = $r1->uid;
            my $suid1 = show_qonu($uid1);
            if ($r2) {
                my $name2 = $r2->name;
                my $uid2  = $r2->uid;
                my $suid2 = show_qonu($uid2);
                if ( $name1 ne $name2) {
                    printf $out "\nRENAME #%-8s %s === %s  %s\n", $uid2 || $uid1, $name1, $name2, $suid1 || $suid2;
                    $said_title++;
                    if ( $suid1 && $suid2 && $uid1 ne $uid2 ) {
                        printf $out "$fmt_label$fmt  (%s === %s)\n", 'RENUMBER', $uid1, '===', $uid2, $suid1, $suid2;
                    }
                    else {
                    }
                }
                elsif ( $suid1 && $suid2 && $uid1 ne $uid2 ) {
                    printf $out "\nMODIFY #%-8s %s %s\n", $uid2, $name2, $suid2;
                    $said_title++;
                    printf $out "$fmt_label$fmt  (%s === %s)\n", 'RENUMBER', $uid1, '===', $uid2, $suid1, $suid2;
                }
                FIELD: for my $f ( my @zof = @$ofields ) {
                    my (@v1, @v2);
                    for my $z ( [$r1, \@v1], [$r2, \@v2] ) {
                        my $r = $z->[0];
                        my @v;
                        if (my $ff = $r->can($f)) {
                            @v = $ff->($r);
                        }
                        elsif (exists $r->{"LIST_$f"}) {
                            @v = @{ $r->{"LIST_$f"} };
                        }
                        elsif (exists $r->{$f}) {
                            @v = $r->{$f} // ();
                        }
                        elsif ( $f ne 'last_updated' ) {
                            warn "Missing field '$f' in $r\n" if $verbose;
                            warn Dumper($r) if $verbose > 2;
                            @v = "Missing field '$f'";
                        }
                        @{ $z->[1] } = map { split /\n|(?<=\bc\/-)\s+/, $_ } grep { defined $_ && "$_" ne '' } @v;
                    }
                    if ( $f eq 'last_updated' ) {
                        if ($said_title) {
                            my $vl1 = $v1[0] // '';
                            my $vl2 = $v2[0] // '';
                            if (@v1 && @v2) {
                                # show time-order
                                if ( $v1[0] eq $v2[0] ) {
                                    printf "$fmt_label$C_green$fmt$C_plain\n",  $f, $vl1, '', '';
                                } elsif ( $v1[0] lt $v2[0] ) {
                                    # left older than right
                                    printf "$fmt_label$C_green$fmt$C_plain\n",  $f, $vl1, "▷", $vl2;
                                } else {
                                    # left newer than right
                                    printf "$fmt_label$C_yellow$fmt$C_plain\n", $f, $vl1, "◁", $vl2;
                                }
                            } else {
                                    printf "$fmt_label$C_yellow$fmt$C_plain\n", $f, $vl1, '',  $vl2;
                            }
                        }
                    }
                    elsif ( $#v1 != $#v2 || grep { $v1[$_] ne $v2[$_] } 0..$#v1 ) {
                        if (!$said_title++) {
                            printf $out "\nMODIFY #%-8s %s  %s\n", $uid2, $name2, $suid2;
                        }
                        my $said_label;
                        _diff_align { $_[0] ne '' && $_[0] eq $_[1] } @v1, @v2;
                        for my $i ( 0 .. max $#v1, $#v2 ) {
                            my $vl1 = $v1[$i] || '';
                            my $vl2 = $v2[$i] || '';
                            $f = '' if $said_label++;
                            if ( $vl1 eq '' ) {
                                if ( $vl2 eq '' ) {
                                    printf "$fmt_label$fmt\n", $f, '', 'x', '' if ! $diff_quietly;
                                } else {
                                    printf "$fmt_label$C_green$fmt$C_plain\n", $f, "(add)", "→", $vl2;
                                }
                            } elsif ( $vl2 eq '' ) {
                                    printf "$fmt_label$C_red$fmt$C_plain\n", $f, $vl1, "←", "(del)";
                            } elsif ( $vl1 eq $vl2 ) {
                                printf "$fmt_label$fmt\n", $f, $vl1, "=", $vl2 if ! $diff_quietly;
                            } else {
                                printf "$fmt_label$C_yellow$fmt$C_plain\n", $f, $vl1, "≠", $vl2;
                            }
                        }
                    }
                }
            }
            else {
                # deletion
                printf $out "\nDELETE #%-8s %s  %s\n", $uid1, $name1, $suid1;
            }
        }
        else {
            if ($r2) {
                my $name2 = $r2->name;
                my $uid2  = $r2->uid;
                my $suid2 = show_qonu($uid2);
                printf $out "\nINSERT #%-8s %s  %s\n", $uid2, $name2, $suid2;
                _dump_one $out, $r2, $ofields;
            }
            else {
                printf $out "\nBROKEN: double null records\n";
                die "NOTREACHED";
            }
        }
    }
}

sub generate_diff($$$$$) {
    my ($out, $rr1, $in1, $rr2, $in2 ) = @_;
    $in1 ||= '(stdin)';
    $in2 ||= '(stdin)';

    warn sprintf "DIFF: comparing %u record from %s with %u records from %s\n", scalar @$rr1, $in1, scalar @$rr2, $in2 if $verbose;
    my @ofields = _choose_ofields;

    my @rr1 = preferred_sort grep { ! skip_restricted_record $_ } @$rr1;
    my @n1 = map { $_->name . '' } @rr1; my %kn1; @kn1{@n1} = 0 .. $#n1;
    my @u1 = map { $_->uid } @rr1;       my %ku1; @ku1{@u1} = 0 .. $#u1;

    my @rr2 = preferred_sort grep { ! skip_restricted_record $_ } @$rr2;
    my @n2 = map { $_->name . '' } @rr2; my %kn2; @kn2{@n2} = 0 .. $#n2;
    my @u2 = map { $_->uid } @rr2;       my %ku2; @ku2{@u2} = 0 .. $#u2;

    my $can_map_uid  = $diff_by ne 'name' && ! grep { ! $_ } @n1, @n2;
    my $can_map_name = $diff_by ne 'uid'  && ! grep { ! $_ } @u1, @u2;

    $can_map_uid or $can_map_name or die "Can map by neither UID nor Name, due to missing values of both\n";

    ( $out, my $out_name, my $close_when_done ) = _open_output $out;

    if ($can_map_uid) {
        for my $uid ( uniq @u2, @u1 ) {
            my $suid = show_qonu($uid);
            my $i1 = $ku1{$uid};
            my $r1 = defined $i1 && $rr1[$i1];
            my $i2 = $ku2{$uid};
            my $r2 = defined $i2 && $rr2[$i2];
            if ($r1) {
                $r1->uid eq $uid or die "A Missed UID #$uid in ".Dumper($r1)."\n".Dumper([\%ku1, \%kn1, \@rr1, \%ku2, \%kn2, \@rr2,]);
            }
            if ($r2) {
                $r2->uid eq $uid or die "B Missed UID #$uid in ".Dumper($r2)."\n".Dumper([\%ku1, \%kn1, \@rr1, \%ku2, \%kn2, \@rr2,]);
            }
            show_one_diff $out, $r1, $r2, \@ofields;
        }
    }
    elsif ($can_map_name) {
        for my $name ( uniq @n2, @n1 ) {
            my $i1 = $kn1{$name};
            my $r1 = defined $i1 && $rr1[$i1];
            my $i2 = $kn2{$name};
            my $r2 = defined $i2 && $rr2[$i2];

            if ($r1) {
                $r1->name eq $name or die "A Missed name '$name' in ".Dumper($r1)."\n".Dumper([\%ku1, \%kn1, \@rr1, \%ku2, \%kn2, \@rr2,]);
            }
            if ($r2) {
                $r2->name eq $name or die "A Missed name '$name' in ".Dumper($r2)."\n".Dumper([\%ku1, \%kn1, \@rr1, \%ku2, \%kn2, \@rr2,]);
            }
            show_one_diff $out, $r1, $r2, \@ofields;
        }
    }
    _close_output $out, $out_name, $close_when_done;
}

################################################################################
#
# Dump records in a textual form that allows easy inspection and comparison;
# - record as blank-line separated paragraph
# - multivalue fields split into separate (identically named) fields
# - fields on separate lines
# - postal & street addresses in multiline format
#

sub diffably_dump_records($$;$) {
    my $out = shift;
    my $rr = shift;
    my $in_name = shift || '(stdin)';

    warn sprintf "DUMP: dumping %u records from %s\n", scalar @$rr, $in_name if $verbose;

    ( $out, my $out_name, my $close_when_done ) = _open_output $out;
    my @ofields = _choose_ofields;
    my @records = @$rr;
    @records = preferred_sort @records;
    RECORD: for my $r (@records) {
        skip_restricted_record $r and do {
            warn sprintf "DUMP: skipping #%s (%s)\n", $r->{__source_line}, $r->{name} // '' if $verbose > 2;
            next RECORD;
        };
        print $out "\n";
        _dump_one $out, $r, \@ofields;
    }
    _close_output $out, $out_name, $close_when_done;
}

################################################################################
#
# Dump records in a textual form that can be read by automail to send birthday
# greetings.
#

sub birthday_dump_records($$;$) {
    my $out = shift;
    my $rr = shift;
    my $in_name = shift || '(stdin)';

    warn sprintf "DUMP: dumping %u records from %s\n", scalar @$rr, $in_name if $verbose;

    ( $out, my $out_name, my $close_when_done ) = _open_output $out;
    my @ofields = _choose_ofields;
    my @records = @$rr;
    @records = preferred_sort @records;
    RECORD: for my $r (@records) {
        if ($r->can('gtags') && $r->gtags('suppress birthday') || skip_restricted_record $r ) {
            warn sprintf "BIRTHDAY: skipping %s\n", $r->debuginfo if $verbose > 2;
            next RECORD;
        }

        my $name = $r->name;
        if (!$name ) {
            warn "UNNAMED RECORD\n" . Dumper($r);
            next RECORD
        }
        my $bd = $r->birthdate;
        if (!$bd) {
            warn sprintf "BIRTHDAY: date not recorded %s\n", $r->debuginfo if $verbose > 2;
            next RECORD;
        }
        my ( $y, $m, $d, $ymd ) = ( $1, $2, $3, "$1$2$3" )
            if $bd =~ m#^(\d{4})\W*(\d{2})\W*(\d{2})(?:T[:0-9]{8}|\W*)$#
            || $bd =~ m#^()\W*(\d{2})\W*(\d{2})(?:T[:0-9]{8}|\W*)$#;
        if ( ! $ymd ) {
            warn sprintf "BIRTHDAY: not valid date %s\n", $r->debuginfo if $verbose > 2;
            next RECORD;
        }
        if ($r->can('gtags') && $r->gtags("suppress birthday")) {
            warn sprintf "BIRTHDAY: suppressing %s\n", $r->debuginfo if $verbose > 2;
            next RECORD;
        }
        if ( ! $show_adult_birthdays && $ymd le sixteen_years_ago ) {
            warn sprintf "BIRTHDAY: not-child %s\n", $r->debuginfo if $verbose > 2;
            next RECORD
        }
        my $emails = join ",", uniq $r->listed_email;
        if (!$emails && $skip_emailless) {
            warn sprintf "BIRTHDAY: email not recorded %s\n", $r->debuginfo if $verbose > 2;
            next RECORD;
        }

        my @meetings = $r->can('gtags') ? $r->gtags( qr/^(?:listing|member)[- ]+($mm_keys_re)/ ) : ();
        @meetings = uniq @meetings if @meetings > 1;
        my $xdate = join ".", $y ? 'xdate='.$y : 'zdate=0000', $m, $d;
        my $dpat = strftime "%d-%b", 0,0,0,$d,$m-1,$y?$y-1900:2000;
        my @areas = map { "area=" . uc $_ } sort @meetings;

        if ( !$emails ) {
            printf $out "#NoEmail#";
            $emails = '-'
        }

        printf $out "%s\n", join("\t", join(",", 'rcpt', $dpat, $xdate, @areas), $emails, $name);
    }
    _close_output $out, $out_name, $close_when_done;
}

################################################################################
#
# Generate a Google import csv that includes the various qdb* fields, so these
# imported records can be merged with the existing ones to incorporate those
# new fields.
#

    sub notno($) {
        (my $z) = @_;
        return defined $z && $z =~ /^[Yy1]$|^yes$/i;
    }

sub generate_qndb_map($$;$) {
    my $out = shift;
    my $rr = shift;
    my $in_name = shift || '(stdin)';
    ( $out, my $out_name, my $close_when_done ) = _open_output $out;
    my %rr = map { ( $_->uid => $_ ) } @$rr;
    print $out "Name,Group Membership,Custom Field 1 - Type,Custom Field 1 - Value,Custom Field 2 - Type,Custom Field 2 - Value,Custom Field 3 - Type,Custom Field 3 - Value\n";
    my @records = preferred_sort @$rr;
    RECORD: for my $r (@records) {
        my $fullname = $r->name || next RECORD; #die "Missing name\n".Dumper($r);
        my $qdb = $r->uid || die "missing uid\n".Dumper($r);
        my $spouse = $r->{uid_of_spouse} // die "mssing spouse-uid\n".Dumper($r); #$r->uid_of_spouse;
        my @uids_of_kids = $r->uid_of_children_under_16; #// die "missing children-uid\n".Dumper($r); #$r->uid_of_children_under_16;
        my @uids_of_parents = $r->_list('uids_of_parents');
        my @groups = '* My Contacts';
        my $l = $r->{monthly_meeting_area};
        push @groups, '@listing - '.$l if $l;
        if (my $m = $r->{formal_membership}) {
            if ( $l && substr($m,0,3) eq substr($l,0,3) && $l !~ /overseas|elsewhere/i ) {
                $m = $l;
            }
            push @groups, '@member - '.$m, '#member';
        }
        elsif ( ! notno $r->{inactive} ) {
            push @groups, '#attender';
        }
        else {
            push @groups, '#inactive';
        }
        push @groups, '!post NZ Friends' if notno $r->{nz_friends_by_post};
        push @groups, '!send NZ Friends' if notno $r->{nz_friends_by_email};
        push @groups, '@listing - YF'    if notno $r->{show_me_in_young_friends_listing};
        if (my $n = $r->{receive_local_newsletter_by_post}) {
            push @groups, '!post '.$n;
        }
        printf $out "%s,%s,qdb,%s,qdb-spouse,%s,qdb-parent,%s,qdb-child,%s\n", $fullname, join(' ::: ', @groups), $qdb, $spouse, join(' ::: ', @uids_of_parents), join(' ::: ', @uids_of_kids);
    }
    _close_output $out, $out_name, $close_when_done;
}

1;

use export qw( diffably_dump_records generate_diff generate_qndb_map birthday_dump_records );

1;
