#!/module/for/perl
# vim: set et sw=4 sts=4 nowrap :

use strict;
use 5.010;
use warnings;
use utf8;

package M::Selection;

use Carp 'croak';

use verbose;
use quaker_info qw( $mm_keys_re
                    %mm_names );

########################################
# How are records selected (these affect various modes in DWIM ways...)

our $skip_archived = 1;
our $skip_deceased = 1;
our $skip_meetings = 1;
our $skip_newsletters_only = undef;     # default to "yes" for do_book
our $skip_suppressed_email = 0;
our $skip_suppressed_listing = undef;   # default to "yes" for do_book
our $skip_suppressed_post = undef;      # default to "yes" for do_labels
our $skip_unlisted = 1;
our $skip_unsub = 1;

our @inclusion_labels;
our @inclusion_tags;
our $postal_control_tag = 'overseas';
our @selection_tags;

my @restrict_regions;
my $skip_regionless = 0;
my @restrict_classes;
my $diff_ignore_file;

########################################

sub sort_by_surname(@) {
    if ( my @x = grep { ! defined $_->{composite_name} } @_ ) { croak "Records don't have names:\n" . Dumper(\@x) }
    if ( my @x = grep { ! defined $_->{composite_name}->{sort_by_surname} } @_ ) { die "Records have names without sort-by-surname:\n" . Dumper(\@x) }
    return sort { $a->{composite_name}->{sort_by_surname}   cmp $b->{composite_name}->{sort_by_surname}
               || $a->{composite_name}->{sort_by_givenname} cmp $b->{composite_name}->{sort_by_givenname} } @_;
}

sub sort_by_givenname(@) {
    if ( my @x = grep { ! defined $_->{composite_name} } @_ ) { croak "Records don't have names:\n" . Dumper(\@x) }
    if ( my @x = grep { ! defined $_->{composite_name}->{sort_by_givenname} } @_ ) { die "Records have names without sort-by-givenname:\n" . Dumper(\@x) }
    return sort { $a->{composite_name}->{sort_by_givenname} cmp $b->{composite_name}->{sort_by_givenname}
               || $a->{composite_name}->{sort_by_surname}   cmp $b->{composite_name}->{sort_by_surname} } @_;
}

sub skip_restricted_record($) {
    my $r = shift;

    if (@restrict_regions) {
        my $skip = 0;
        my $where;
        my @mt;
        if ( $r->can('gtags') ) {
            $where = 'gmail';
            if ( @mt = $r->gtags( qr/^(?:member|listing|send|post)[- ]+($mm_keys_re|YF)\b/ ) ) {
                grep { my $reg = $_; grep { $_ eq $reg } @mt } @restrict_regions
                or $skip = 1;
            }
            elsif ($skip_regionless) {
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
            elsif ($skip_regionless) {
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
        if ($skip_regionless) {
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

use export qw(
    $skip_archived
    $skip_deceased
    skip_restricted_record
);

########################################
# actual parsing of command-line

sub II(&) {
    my $f = pop;
    sub {
        my @k = split m{[=/]}, $_[1], 2;
        $k[1] ||= '!post '.$k[0];
        $f->(@k);
    }
}

use run_options (
    '!+include-all|skip-none'       => \$skip_regionless,
    '!include-regionless!'          => \$skip_regionless,
    'need-region!'                  => \$skip_regionless,
    'skip-regionless!'              => \$skip_regionless,
    'all-regions|any-region'        => sub { @restrict_regions = () },
    ',only-region=s'                => \@restrict_regions,
    ',region=s'                     => \@restrict_regions,
    '#check'                        => sub {
                                        if (@restrict_regions) {
                                            $_ = uc $_ for @restrict_regions;
                                            @restrict_regions = grep { $_ ne 'NONE' or $skip_regionless = 0; } @restrict_regions;
                                            $mm_names{$_} or die "Invalid region '$_'\n" for @restrict_regions;
                                            warn "RESTRICTION: limit to regions: @restrict_regions\n" if $verbose > 2;
                                        } else {
                                            $skip_regionless = 0;
                                        }
                                        1;
                                    },

    ',class=s'                      => \@restrict_classes,
    ',only-class=s'                 => \@restrict_classes,

    '!+include-all|skip-none'       => \$skip_archived,
    '!include-archived!'            => \$skip_archived,
    '+skip-all|include-none'        => \$skip_archived,
    'skip-archived!'                => \$skip_archived,

    '!+include-all|skip-none'       => \$skip_deceased,
    '!include-deceased!'            => \$skip_deceased,
    '+skip-all|include-none'        => \$skip_deceased,
    'skip-deceased!'                => \$skip_deceased,

    '!+include-all|skip-none'       => \$skip_meetings,
    '!include-meetings!'            => \$skip_meetings,
    '+skip-all|include-none'        => \$skip_meetings,
    'skip-meetings!'                => \$skip_meetings,

    '!+include-all|skip-none'       => \$skip_newsletters_only,
    '!include-newsletters-only!'    => \$skip_newsletters_only,
    '+skip-all|include-none'        => \$skip_newsletters_only,
    'skip-newsletters-only!'        => \$skip_newsletters_only,

    '!+include-all|skip-none'       => \$skip_suppressed_email,
    '!include-suppressed-email!'    => \$skip_suppressed_email,
    '+skip-all|include-none'        => \$skip_suppressed_email,
    'skip-suppressed-email!'        => \$skip_suppressed_email,

    '!+include-all|skip-none'       => \$skip_suppressed_listing,
    '!include-suppressed-listing!'  => \$skip_suppressed_listing,
    '+skip-all|include-none'        => \$skip_suppressed_listing,
    'skip-suppressed-listing!'      => \$skip_suppressed_listing,

    '!+include-all|skip-none'       => \$skip_suppressed_post,
    '!include-suppressed-post!'     => \$skip_suppressed_post,
    '+skip-all|include-none'        => \$skip_suppressed_post,
    'skip-suppressed-post!'         => \$skip_suppressed_post,

    '!+include-all|skip-none'       => \$skip_unlisted,
    '!include-unlisted!'            => \$skip_unlisted,
    '+skip-all|include-none'        => \$skip_unlisted,
    'skip-unlisted!'                => \$skip_unlisted,

    '!+include-all|skip-none'       => \$skip_unsub,
    '!include-unsubscribed!'        => \$skip_unsub,
    '+skip-all|include-none'        => \$skip_unsub,
    'skip-unsubscribed!'            => \$skip_unsub,

    'diff-ignore-file=s'            => \$diff_ignore_file,

    ',select-and-include=s'         => II { push @selection_tags, $_[1]; push @inclusion_labels, $_[0]; push @inclusion_tags, $_[1]; },
    ',optional-include=s'           => II {                              push @inclusion_labels, $_[0]; push @inclusion_tags, $_[1]; },
    ',select=s'                     => II { push @selection_tags, $_[1]; },
    '#check'                        => sub {
                                        # leading punctuation in tags is ignored by gtags()
                                        s/^\W*// for @selection_tags,
                                                     @inclusion_tags;
                                        1;
                                    },

    '#help-selection'               => <<EndOfHelp,
"record-selection" options:
    --[only-]region=REGION[,REGION...]          exclude records not in any of the REGIONs
    --all-regions           --any-region        include records with any region
    --no-need-region --no-hide-regionless     --include-regionless include records without a region
       --need-region    --hide-regionless  --no-include-regionless exclude records without a region
    --[no-]include-archived --[no-]skip-archived
    --include-deceased      --skip-deceased
    --include-meetings      --skip-meetings
    --include-unlisted      --skip-unlisted
    --include-unsubscribed  --skip-unsubscribed
    --only-region=REGION
    --select-and-include=TAG[,TAG...]
    --select=TAG[,TAG...]
    --optional-include=TAG[,TAG...]
    --why-not  --why-skipped        [explain exclusion of each record]
EndOfHelp
);

1;
