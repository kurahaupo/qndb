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
use quaker_info '%mm_names';

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
                   );

use constant now => [ localtime $^T ];
use constant this_year => strftime "%Y", localtime $^T;
use constant this_date => strftime "%Y%m%d", localtime $^T;
use constant sixteen_years_ago => strftime "%Y%m%d", localtime $^T - 504921600;

########################################
# Dump formatting options

my $names_only = 0;
my $show_relationships = 1;
my $show_uid;
my $suppress_last_update = 0;
my $suppress_adult_birthdays = 1;
my $suppress_send_by_post = 0;
my $suppress_send_by_email = 1;
my $suppress_status = 0;
my $suppress_yf_listing = 0;
my $show_hyperlinks = 1;
my $diff_by = 'uid';
my $diff_ignore_file;
my $diff_quietly = 0;
my @restrict_regions;
my $need_region = 1;
my @restrict_classes;

use run_options (
    'class|only-class=s'            => sub { push @restrict_classes, split /[, ]+/, pop },
    'names-only!'                   => \$names_only,
    'all-regions|any-region'        => sub { @restrict_regions = () },
    'region|only-region=s'          => sub { push @restrict_regions, split /[, ]+/, pop },
    '#check'                        => sub {
                                        $_ = uc $_ for @restrict_regions;
                                        @restrict_regions = grep { $_ ne 'NONE' or $need_region = 0; } @restrict_regions;
                                        $mm_names{$_} or die "Invalid region '$_'\n" for @restrict_regions;
                                        warn "RESTRICTION: limit to regions: @restrict_regions\n" if $verbose > 2;
                                        1;
                                    },

    'diff-by-any'                   => sub { $diff_by = '' },
    'diff-by-name'                  => sub { $diff_by = 'name' },
    'diff-by-uid'                   => sub { $diff_by = 'uid' },
    'diff-ignore-file=s'            => \$diff_ignore_file,
    'diff-quietly'                  => \$diff_quietly,
    'need-region!'                  => \$need_region,
    'hide-no-region!'               => \$need_region,
   '!include-no-region!'            => \$need_region,

   '!hide-hyperlinks!'              => \$show_hyperlinks,
    'show-hyperlinks!'              => \$show_hyperlinks,

   '!hide-relationships!'           => \$show_relationships,
    'show-relationships!'           => \$show_relationships,

   '!hide-uid!'                     => \$show_uid,
    'show-uid!'                     => \$show_uid,

   '!show-adult-birthdays!'         => \$suppress_adult_birthdays,
    'hide-adult-birthdays!'         => \$suppress_adult_birthdays,

    'hide-send-by-email!'           => \$suppress_send_by_email,
   '!show-send-by-email!'           => \$suppress_send_by_email,
    'hide-send-by-post!'            => \$suppress_send_by_post,
   '!show-send-by-post!'            => \$suppress_send_by_post,
    'show-send!'                    => sub { $suppress_send_by_email = $suppress_send_by_post = ! $_[-1] },
    'hide-send!'                    => sub { $suppress_send_by_email = $suppress_send_by_post = $_[-1] },

   '!show-status!'                  => \$suppress_status,
    'hide-status!'                  => \$suppress_status,

    'hide-yf-listing!'              => \$suppress_yf_listing,
   '!show-yf-listing!'              => \$suppress_yf_listing,

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
    --[no-]{show|hide}-send
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
    push @ofields, qw( monthly_meeting_area formal_membership inactive ) unless $names_only || $suppress_status;
    push @ofields, qw( show_me_in_young_friends_listing ) unless $names_only || $suppress_yf_listing;
    push @ofields, qw( listed_email phone_number mobile_number fax listed_address postal_address ) unless $names_only;
    push @ofields, qw( receive_local_newsletter_by_post nz_friends_by_post) unless $names_only || $suppress_send_by_post;
    push @ofields, qw( receive_local_newsletter_by_email nz_friends_by_email ) unless $names_only || $suppress_send_by_email;
                   # Possible additional fields:
                   #   synthesized website_url rd_no po_box_number country postcode
                   #   town suburb address property_name users_name
                   #   uid_of_children_under_16 uid_of_spouse uid first_name
                   #   family_name
    push @ofields, qw( uid uid_of_spouse uid_of_children_under_16 uids_of_parents ) if $show_uid;
    push @ofields, qw( birthdate ) unless $suppress_adult_birthdays;
    push @ofields, qw( last_updated ) if ! $suppress_last_update;
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
            if ( ! $suppress_adult_birthdays || $ymd gt sixteen_years_ago ) {
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

    sub _skip_restricted_record($) {
        my $r = shift;

        if (@restrict_regions) {
            my $skip = 0;
            my $where;
            my @mt;
            if ( $r->can('gtags') ) {
                $where = 'gmail';
                $r->isa(CSV::qndb::) and die "gtags shouldn't work on QNDB record; method=".$r->can('gtags');
                if ( @mt = $r->gtags( qr/^(?:member|listing|send|post)[- ]+($mm_keys_re|YF)\b/ ) ) {
                    grep { my $reg = $_; grep { $_ eq $reg } @mt } @restrict_regions
                    or $skip = 1;
                }
                elsif ($need_region) {
                    $skip = 2;
                }
            }
            else {
                $where = 'profile';
                if ( @mt = map {
                                    my $a = $r->{$_} || '';
                                    $a =~ m{^($mm_keys_re|YF)\b} ? $1 : ()
                                } qw{   formal_membership
                                        monthly_meeting_area
                                        receive_local_newsletter_by_post
                                        receive_local_newsletter_by_email
                                       } ) {
                                    # Also, maybe:
                                    # - receive_local_newsletter_by_post
                                    # - receive_local_newsletter_by_email
                    grep {
                            my $reg = $_;
                            grep { $_ eq $reg } @mt;
                        } @restrict_regions
                    or $skip = 3;
                }
                elsif ($need_region) {
                    $skip = 4;
                }
            }
            if ($skip) {
                warn sprintf "Skipping REGION %s doesn't have %s%s\n",
                            $r->debuginfo,
                            @mt ? 'any of the wanted regions ('.join(', ', @mt).')' : 'any regions',
                            $where,
                    if $why_not;
                return 1;
            }
        }
        if ( $r->can('gtags') ) {
            if ($need_region) {
                if ( ! $r->gtags( qr/^(?:member|listing)[- ]+($mm_keys_re|YF)\b/ ) ) {
                    warn sprintf "Skipping NOREGION %s\n", $r->debuginfo if $why_not;
                    return 1;
                }
            }
            if ($skip_archived) {
                if ( my @s = $r->gtags( qr/^archive - (.*)/ ) ) {
                    warn sprintf "Skipping ARCHIVED %s [%s]\n", $r->debuginfo, "@s" if $why_not;
                    return 1;
                }
            }
            state $skips = do {
                my @skips;
                push @skips, 'archive - deceased'     if $skip_deceased && !$skip_archived;
                push @skips, 'archive - unsubscribed' if $skip_unsub    && !$skip_archived;
                push @skips, 'meetings'               if $skip_meetings;
                push @skips, 'suppress listing'       if $skip_suppressed_listing;
                push @skips, 'newsletters-only'       if $skip_newsletters_only;
                push @skips, 'suppress email'         if $skip_suppressed_email;
                push @skips, 'suppress post'          if $skip_suppressed_post;
                \@skips;
            };
            if ( @$skips && $r->gtags(@$skips) ) {
                warn sprintf "Skipping TAGGED %s tagged with [%s]\n", $r->debuginfo, join "; ", @$skips if $why_not;
                return 1;
            }
            if ( @restrict_classes ) {
                if (! $r->gtags( @restrict_classes )) {
                    warn sprintf "Skipping EXCLASS %s not in [%s]\n", $r->debuginfo, join "; ", @restrict_classes;
                    return 1;
                }
            }
            if ($skip_unlisted) {
                if (! $r->gtags( 'meeting', 'role', 'admin', 'members', 'attenders', 'enquirer', 'child', 'inactive' )) {
                    if ( $why_not ) {
                        if ($r->gtags( 'newsletter-only' )) {
                            warn sprintf "Skipping NEWS-ONLY %s\n", $r->debuginfo;
                        } else {
                            warn sprintf "Skipping NON-PERSON %s\n", $r->debuginfo;
                        }
                    }
                    return 1;
                }
            }
        }
        else {
            if ($skip_meetings && (! $r->{monthly_meeting_area} &&
            ! $r->{formal_membership} &&
            ! ( $r->{show_me_in_young_friends_listing}
             && $r->{show_me_in_young_friends_listing} eq 'Yes' ))) {
                warn sprintf "Skipping UNLISTED %s [no MM membership, WG listing, or YF listing]\n", $r->debuginfo if $why_not;
                return 1;
            }
        }
        if ( $diff_ignore_file ) {
            state $things_to_ignore = do {
                my %ignore_uid;
                my %ignore_name;

                my ( $in, $in_name ) = open_file_for_reading $diff_ignore_file;

                my @f = <$in>;
                close $in or die "Couldn't read '$in_name'; $!\n";
                for my $f (@f) {
                    chomp $f;
                    $f =~ s/\#.*//;
                    $f =~ s/\s+$//;
                    next if !$f;
                    if ($f =~ /^\d/) {
                        $ignore_uid{$f} = 1;
                    } else {
                        $ignore_name{lc $f} = 1;
                    }
                }
                warn "Loading ignorance table, ".(0+%ignore_uid)." uids and ".(0+%ignore_name)." names\n" if $verbose;
                warn Dumper( \%ignore_uid, \%ignore_name ) if $verbose > 2;
                [ \%ignore_uid, \%ignore_name ]
            };
            if ($things_to_ignore->[0]{$r->uid}) {
                warn sprintf "Skipping IGNORED %s [ignoring uid]\n", $r->debuginfo if $why_not;
                return 1;
            }
            if ($things_to_ignore->[1]{lc $r->name}) {
                warn sprintf "Skipping IGNORED %s [ignoring name]\n", $r->debuginfo if $why_not;
                return 1;
            }
        }
        return 0;
    }

    my $C_plain = "\e[49m";
    my $C_black = "\e[30m";
    my $C_red   = "\e[31m";
    my $C_green = "\e[32m";
    my $C_yellow= "\e[33m";
    my $C_blue  = "\e[34m";
    my $C_purple= "\e[35m";
    my $C_cyan  = "\e[34m";
    my $C_white = "\e[37m";

    my $B_plain = "\e[49m";
    my $B_black = "\e[40m";
    my $B_red   = "\e[41m";
    my $B_green = "\e[42m";
    my $B_yellow= "\e[43m";
    my $B_blue  = "\e[44m";
    my $B_purple= "\e[45m";
    my $B_cyan  = "\e[44m";
    my $B_white = "\e[47m";

    sub show_one_diff($$$$) {
        my ($out, $r1, $r2, $ofields) = @_;
        state $fmt = "%-18.18s %-32s %-3.3s %s";
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
                        printf $out "$fmt  (%s === %s)\n", 'RENUMBER', $uid1, '===', $uid2, $suid1, $suid2;
                    }
                    else {
                    }
                }
                elsif ( $suid1 && $suid2 && $uid1 ne $uid2 ) {
                    printf $out "\nMODIFY #%-8s %s %s\n", $uid2, $name2, $suid2;
                    $said_title++;
                    printf $out "$fmt  (%s === %s)\n", 'RENUMBER', $uid1, '===', $uid2, $suid1, $suid2;
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
                                    printf "$C_green$fmt$C_plain\n",  $f, $vl1, '', '';
                                } elsif ( $v1[0] lt $v2[0] ) {
                                    # left older than right
                                    printf "$C_green$fmt$C_plain\n",  $f, $vl1, "▷", $vl2;
                                } else {
                                    # left newer than right
                                    printf "$C_yellow$fmt$C_plain\n", $f, $vl1, "◁", $vl2;
                                }
                            } else {
                                    printf "$C_yellow$fmt$C_plain\n", $f, $vl1, '',  $vl2;
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
                                    next if $diff_quietly;
                                    printf "$fmt\n", $f, '', 'x', '';
                                } else {
                                    printf "$C_green$fmt$C_plain\n", $f, "(add)", "→", $vl2;
                                }
                            } elsif ( $vl2 eq '' ) {
                                    printf "$C_red$fmt$C_plain\n", $f, $vl1, "←", "(del)";
                            } elsif ( $vl1 eq $vl2 ) {
                                next if $diff_quietly;
                                printf "$fmt\n", $f, $vl1, "=", $vl2;
                            } else {
                                printf "$C_yellow$fmt$C_plain\n", $f, $vl1, "≠", $vl2;
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

sub generate_diff($$$$$) {
    my ($out, $rr1, $in1, $rr2, $in2 ) = @_;
    $in1 ||= '(stdin)';
    $in2 ||= '(stdin)';

    warn sprintf "DIFF: comparing %u record from %s with %u records from %s\n", scalar @$rr1, $in1, scalar @$rr2, $in2 if $verbose;
    my @ofields = _choose_ofields;

    my @rr1 = preferred_sort grep { !_skip_restricted_record $_ } @$rr1;
    my @n1 = map { $_->name . '' } @rr1; my %kn1; @kn1{@n1} = 0 .. $#n1;
    my @u1 = map { $_->uid } @rr1;       my %ku1; @ku1{@u1} = 0 .. $#u1;

    my @rr2 = preferred_sort grep { !_skip_restricted_record $_ } @$rr2;
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
        _skip_restricted_record $r and do {
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
        if ($r->can('gtags') && $r->gtags('suppress birthday') || _skip_restricted_record $r ) {
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
        if ( $suppress_adult_birthdays && $ymd le sixteen_years_ago ) {
            warn sprintf "BIRTHDAY: not-child %s\n", $r->debuginfo if $verbose > 2;
            next RECORD
        }
        my $emails = join ",", uniq $r->listed_email;
        if (!$emails) {
            warn sprintf "BIRTHDAY: email not recorded %s\n", $r->debuginfo if $verbose > 2;
            next RECORD;
        }

        my @meetings = $r->can('gtags') ? $r->gtags( qr/^(?:listing|member)[- ]+($mm_keys_re)/ ) : ();
        @meetings = uniq @meetings if @meetings > 1;
        my $xdate = join ".", $y ? 'xdate='.$y : 'zdate=0000', $m, $d;
        my $dpat = strftime "%d-%b", 0,0,0,$d,$m-1,$y?$y-1900:2000;
        my @areas = map { "area=" . uc $_ } sort @meetings;

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
