#!/module/for/perl
# vim: set et sw=4 sts=4 nowrap :

use strict;
use 5.010;
use warnings;
use utf8;

package M::Selection;

use Carp 'croak';

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

use export qw(
    $skip_archived
    $skip_deceased
);

########################################
# actual parsing of command-line

sub II(&) {
    my $f = pop;
    sub {
        for my $i ( split m{\s*,\s*}, $_[1] ) {
            my @k = split m{[=/]}, $i;
            $k[1] ||= '!post '.$k[0];
            $f->(@k);
        }
    }
}

use run_options (
   '!include-archived!'           => \$skip_archived,
    'skip-archived!'              => \$skip_archived,
   '!include-deceased!'           => \$skip_deceased,
    'skip-deceased!'              => \$skip_deceased,
   '!include-meetings!'           => \$skip_meetings,
    'skip-meetings!'              => \$skip_meetings,
   '!include-newsletters-only!'   => \$skip_newsletters_only,
    'skip-newsletters-only!'      => \$skip_newsletters_only,
   '!include-suppressed-email!'   => \$skip_suppressed_email,
    'skip-suppressed-email!'      => \$skip_suppressed_email,
   '!include-suppressed-listing!' => \$skip_suppressed_listing,
    'skip-suppressed-listing!'    => \$skip_suppressed_listing,
   '!include-suppressed-post!'    => \$skip_suppressed_post,
    'skip-suppressed-post!'       => \$skip_suppressed_post,
   '!include-unlisted!'           => \$skip_unlisted,
    'skip-unlisted!'              => \$skip_unlisted,
   '!include-unsubscribed!'       => \$skip_unsub,
    'skip-unsubscribed!'          => \$skip_unsub,

    'select-and-include=s'        => II { push @selection_tags, $_[1]; push @inclusion_labels, $_[0]; push @inclusion_tags, $_[1]; },
    'optional-include=s'          => II {                              push @inclusion_labels, $_[0]; push @inclusion_tags, $_[1]; },
    'select=s'                    => II { push @selection_tags, $_[1]; },
    '=' => sub {
                    # punctuation in tags is ignored by gtags()
                    s/^\W*// for @selection_tags,
                                 @inclusion_tags;
                    1;
                },

    'help-selection'              => <<EndOfHelp,
"record-selection" options:
    --[only-]region=REGION[,REGION...]          exclude records not in any of the REGIONs
    --all-regions           --any-region        include records with any region
    --no-need-region --no-hide-no-region     --include-no-region include records without a region
       --need-region    --hide-no-region  --no-include-no-region exclude records without a region
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
