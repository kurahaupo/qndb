#!/module/for/perl

use 5.010;
use strict;
use warnings;
use utf8;

=head 3

A second ad-hoc file, basically taking a Word doc from Derek Carver, folding
up each entry onto a single line; tab-delimited

=cut

package PDF::adhoc2;
use parent 'CSV::Common';

use Carp 'croak';

use POSIX qw(strftime);
use Data::Dumper;

use constant this_year => strftime "%Y", localtime $^T;

use list_functions 'uniq';
use phone_functions 'normalize_phone';
use quaker_info;
use verbose;

sub new($\@\@) {
    my ($class, $headers, $ra) = @_;
    @$ra = grep { $_ } @$ra;
    @$ra or return ();

    state %headers;

    if ($ra->[0] =~ s/^%//) {
        $headers{lc $ra->[0]} = $ra->[1];
        warn "STATE ".::Dumper(\%headers) if $verbose > 4;
        return ();
    }

    my $yf = 'No';
    my $wg = $headers{wg} || croak "Data record before first '%wg' record\n".::Dumper(\%headers);
    if ( $wg eq 'YF' ) { undef $wg; $yf = 'Yes' }
    my %family = (
                __source_line => $. - 1,
                monthly_meeting_area => $wg,
                show_me_in_young_friends_listing => $yf,
            );
    my $seen_name;
    my %members;
    my $part = \%family;
    my @parents;
    my @children;

    my $xdebug = 0 && grep {/Armstrong/} @$ra;
    warn ::Dumper($ra) if $xdebug;

    for my $f (@$ra) {
        if ( $f =~ /^\-?$/ ) { next }  # ignore dash and empty

        warn "PARSE PART [$f]\n" if $xdebug;

        if ( $f =~ /^(\w+):$/ ) {
            # persistent tag, for all following
            my $k = lc $1;
            $part = $members{$k} ||= {};
            warn "PARSE persistent tag [$k] selected part:".::Dumper($part) if $xdebug;
            next;
        }

        my $tag;
        if ( $f =~ s/^(\w+):\s+// ) {
            # tag just this one item;
            # NB whitespace needed to distinguish from URI type
            $tag = lc $1;
            warn "PARSE emphemeral tag [$tag]\n" if $xdebug;
        }

        if ( (my $n = $f =~ s/[- ]//gr) =~ /^[0+]\d{7,}$/ ) {
            # it's (very probably) a phone number
            my $type = 'phone_number';
            $n = normalize_phone($n);
            if ($tag) {
                if ($tag eq 'fax') {
                    $type = 'fax_number';
                    $n .= '^';
                    undef $tag;
                }
                elsif ($tag eq 'mobile' || $tag eq 'mob' || $tag eq 'cell' || $tag eq 'txt' || $tag eq 'sms') {
                    $type = 'mobile_number';
                    undef $tag;
                }
                elsif ($tag eq 'freephone') {
                    #$type = 'freephone_number';
                    $type = 'phone_number';
                    undef $tag;
                }
            }
            if ($n =~ /^\+642|^\+614|^\+447/) {
                # mobile area code, so ignore tag
                $type = 'mobile_number';
            }
            $family{primary_phone} ||= $n;
            if ($tag) {
                push @{$members{$tag}{$type}}, $n;
            }
            else {
                push @{$part->{$type}}, $n;
            }
            warn "PARSE phone number [$n] type=$type\n" if $xdebug;
            next;
        }

        my $cp = $tag && ($members{$tag} || do { warn "Tag '$tag' in #$family{__source_line} doesn't refer to a person\n" if $verbose; (); }) || $part;

        if ( $f =~ /^\S+\@\S+$/ ) {
            push @{$cp->{listed_email}}, $f;
            warn "PARSE email [$f]\n" if $xdebug;
            next;
        }

        if ( $f =~ m{^(?:https?://|www\.)\w+(?:\.\w+)+(?:/\S*|$)|^skype:\S+$} ) {
            push @{$cp->{website_url}}, $f;
            warn "PARSE url [$f]\n" if $xdebug;
            next;
        }

        # inclusion of bracketed date is assumed to imply name and birthdate of child
        if ( (my $n = $f) =~ s{\s*\((xx|\d\d)/(xx|\d\d)/(\d\d\d\d|\d\d)\)\s*(.*)}{}x ) {
            my ($d,$m,$y,$q) = ($1,$2,$3,$4);
            warn "CHILD [$f] -> name=[$n] date=$1/$2/$3 extra=[$4]\n" if $xdebug;
            $y += int(this_year/100)*100 if $y < 100;
            $y -= 100 if $y > this_year;  # born in previous century
            my @np = split /\s*\+\s*/, $n, -1;
            @np = split /\s+/, $n if @np < 2;
            my $sn;
            $sn = pop @np if @np > 1;
            my $n0 = lc($np[0] || '');
            my %fm;
            push @children, \%fm;
            $members{$n0} and die sprintf( "Household [%s] already has child [%s]\n", $family{sn}, $n0 ) . ::Dumper($ra,$f,\@np,\@parents,\@children,\%members);
            $members{$n0} ||= \%fm;
            $fm{gn} = "@np";
            $fm{sn} = $sn if $sn;
            $fm{birthdate} = "$y-$m-$d";
            $fm{inactive} = 'No';
            my @q = grep { /\#/ } split /[, ]+/, $q;
            warn "Info about child: $f => n='$n', q='$q' => [@q]\n" if $xdebug;
            if (@q) {
                my %q = map { split /\#/,$_,2 } @q;
                $fm{uid} = $q{uid} if exists $q{uid};
            }
            warn "PARSE child [$f]\n".::Dumper(\%fm) if $xdebug;
            next;
        }

        if ( (my $k = $f) =~ s/\#(.*)$// ) {
            my $v = $1;
            $k =~ s/\W+/_/g;
            $k = lc $k;
            $cp->{$k} = $v;
            warn "PARSE key#value field key=$k value=[$v]\n" if $xdebug;
            next;
        }

        if ( !$seen_name++ ) {
            # First non-specific element is the person's or couple's name(s)
            $f =~ s/’/'/g;
            my @p = $f;
            if    ($p[0] =~ s/\s*\(\&\s*([^()]*)\)\s*$//) { push @p, $1 . ' (INACTIVE)' }
            elsif ($p[0] =~ s/\s*\&\s*(.*)//)             { push @p, $1                 }
            for my $i (0 .. $#p) {
                my $p = $p[$i];
                my $inactive = 'No';
                if ( $p =~ s/^\(([^()]+)\)/$1/ || $p =~ s/\s*\(INACTIVE\)$// ) {
                    $inactive = 'Yes'
                }
                my $member_of;
                if    ( $p =~ s#\s*\(\*\)$##            ) { $member_of = '* Overseas' }
                elsif ( $p =~ s#\s*\(($mm_keys_re)\)$## ) { $member_of = $mm_names{uc $1} }
                my $o = $p;
                my $name_prefix; if ( $p =~ s/ ^   (\([^()]*\)) \s* //x  ) { $name_prefix = $1 }
                my $name_suffix; if ( $p =~ s/ \s* (\([^()]*\))   $ //x  ) { $name_suffix = $1 }
                my $name_middle; if ( $p =~ s/ \s* (\([^()]*\)) \s* / /x ) { $name_middle = $1 }
                my @np = split /\s*\+\s*/, $p, -1;
                @np = split /\s+/, $p if @np < 2;
                my $sn;
                if (@np >= 2) {
                    if ($i == 0) {
                        $sn = shift @np;
                        if ($name_suffix && !$name_middle && $name_suffix !~ /^\(ex |^\(nee |^\(née /) {
                            $name_middle = $name_suffix;
                            $name_suffix = undef;
                        }
                    }
                    else {
                        $sn = pop @np;
                    }
                }
                $family{sn} ||= $sn;
                my $n0 = lc($np[0] || '');
                $n0 =~ s/[- ].*//;
                my %fm;
                push @parents, \%fm;
                $members{$n0} and warn sprintf "Household [%s] already has parent [%s]\n", $family{sn}, $n0;
                $members{$n0} ||= \%fm;
                $fm{gn} = "@np";
                $fm{name_prefix} = $name_prefix if $name_prefix;
                $fm{name_middle} = $name_middle if $name_middle;
                $fm{name_suffix} = $name_suffix if $name_suffix;
                $fm{sn} = $sn if $sn;
                $fm{formal_membership} = $member_of;
                $fm{inactive} = $inactive;
            }
            warn "PARSE name [$f]\n".::Dumper(\@parents) if $xdebug;
            next;
        }

        # Assume anything else is an address
        my $t = 'listed_address';
        if ($tag && ($tag eq 'post' || $tag eq 'postal')) {
            $t = 'postal_address'
        }
        elsif ($tag && $tag eq 'street') {
            $t = 'street_address'
        }
        !$family{$t} || @{$family{$t}} == 0 or warn sprintf "MULTIPLE ADDRESSES at [%s] in [%s]\n", $f, "@$ra";

        (my $a = $f) =~ s/\s*,\s*/\n/g;
        $a = $class->_canon_address($a);
        warn "PARSE address [$f] type=$t structure=".::Dumper($a) if $xdebug;
        push @{$family{$t}}, $a;
    }
    for my $m (@parents, @children) {
        bless $m, ref $class || $class;
        %$m = ( %family, %$m );
        my $sn = delete $m->{sn} || '';
        my $gn = delete $m->{gn} || '';
        my $name_prefix  = delete $m->{name_prefix} || '';
        my $name_middle  = delete $m->{name_middle} || '';
        my $name_suffix  = delete $m->{name_suffix} || '';
        my $clean_name  = join ' ', grep { $_ } $name_prefix, $gn, $name_middle, $sn, $name_suffix;
        my $sort_by_givenname = lc join ' ', grep { $_ } $gn, $sn;
        my $sort_by_surname   = lc join ' ', grep { $_ } $sn, $gn;
        my $n = new string_with_components:: $clean_name,
                                                            family_name       => $sn,
                                                            given_name        => $gn,
                                                            sort_by_surname   => $sort_by_surname,
                                                            sort_by_givenname => $sort_by_givenname;
        $m->{composite_name} = $n;
        $m->_make_name_sortable($n);
    }
    if (@parents == 2) {
        $parents[0]->{XREF_spouse} = $parents[1];
        $parents[1]->{XREF_spouse} = $parents[0];
    }
    for my $c (@children) {
        for my $p (@parents) {
            push @{$p->{ZREF_children}}, $c;
            push @{$c->{ZREF_parents}}, $p;
        }
    }
    print "parsed WordDoc line:\n", ::Dumper({ A_line => $., B_data => $ra, C_parents => \@parents, D_children => \@children, E_family => \%family, E_members => \%members }) if $verbose > 3;
    return @parents, @children;
}

use constant is_word_doc => 1;

sub birthdate { return shift->{birthdate} }

sub _phones($$) {
    my ($r, $k) = @_;
    my $p = $r->{$k} || return;
    return                             uniq @$p;
  # return map { ::localize_phone $_ } uniq @$p;
}

sub fax             { $_[1] = 'fax_number';    goto &_phones; }
sub phone_number    { $_[1] = 'phone_number';  goto &_phones; }
sub mobile_number   { $_[1] = 'mobile_number'; goto &_phones; }
sub show_me_in_young_friends_listing { return shift->{show_me_in_young_friends_listing} }
sub listed_address  { my $r = shift; return my ($a) = map { s/\nRD \d+\n/\n/r } map { $r->{$_} ? @{$r->{$_}} : () } qw{ street_address listed_address postal_address } }
sub postal_address  { my $r = shift; return my ($a) = map { $r->{$_} ? @{$r->{$_}} : () } qw{ postal_address listed_address street_address } }
sub all_addresses   { my $r = shift; return uniq      map { $r->{$_} ? @{$r->{$_}} : () } qw{ listed_address street_address postal_address } }
sub listed_email    { my $r = shift; return sort @{$r->{listed_email}} if $r->{listed_email} }
sub formal_membership { my $r = shift; return $r->{formal_membership} || (); }

sub uid {
    my $r = shift;
    $r->{'uid'} ||= 'GEN'.(0+$r).'-wdt';
}

sub uid_of_spouse            { my $r = shift; map { $_->uid } grep {$_} $r && $r->{XREF_spouse}   }
sub uids_of_parents          { my $r = shift; map { $_->uid }   flatten $r && $r->{ZREF_parents}  }
sub uid_of_children_under_16 { my $r = shift; map { $_->uid }   flatten $r && $r->{ZREF_children} }

sub receive_local_newsletter_by_post { () }
#sub nz_friends_by_email { 'No' }
sub nz_friends_by_post { 'No' }

1;
