#!/module/for/perl
# vim: set et sw=4 sts=4 nowrap :

use strict;
use 5.010;
use warnings;
use utf8;

package M::PostageLabels;

use Data::Dumper;

use M::IO qw( _open_output _close_output );

################################################################################
#
# Generate postage labels as a printable PDF file
#     parameters: a list of tags; a description of the label layout
#
# Using "!post {tag}" as a category, select all the records from that category
# Gather all the records from all such categories
# Group them by families (spouse & children links)
# Make a label for each family:
# - Make a summary addressee line;
#   - for one person, use their full name
#   - for two people (any relationship), use "X Jones & Y Smith" or "X & Y
#     Smith" (child last, if applicable)
#   - for one adult and two or more children, use "X Jones & family"
#   - for two adults and one or more children, use "X & Y Smith & family" or "X
#     Jones & Y Smith & family"
# - Make an inclusions list from the union of all the categories that apply on
#   any of the family members
# - include the postal address; separately, the country & postcode
# Group the labels by tag-sets
# Generate PDF, generating control labels at the top of each page and before any
# change of tag-set
#

################################################################################

=head 3

Label records

The block of variable refences is a crude way of exporting the variables to the
module, rather than importing the variables from the module. Hopefully these will
be reduced or eliminated as code is tidied.

=cut

use verbose;

use math_constants 'PHI';   # used in several default calculations...
use list_functions qw( near min );

use PDF::scale_factors;

use M::Selection qw(
                     @inclusion_labels
                     @inclusion_tags
                     $postal_control_tag
                     @selection_tags
                     $skip_archived
                     $skip_deceased
                     $skip_meetings
                     $skip_newsletters_only
                     $skip_suppressed_email
                     $skip_suppressed_listing
                     $skip_suppressed_post
                     $skip_unsub
                     &sort_by_givenname
                     &sort_by_surname
                   );

########################################
# Label formatting options

our $do_labels = 0;

my $show_tiny_labels = 1;
my $use_cropbox = 0;
my $evenly_squash_to_fit = 0;

my $label_left_margin = 1*mm;
my $label_right_margin = 1*mm;
my $label_bottom_margin = 4*mm;
my $label_top_margin = 4*mm;

my $label_fontname = 'Helvetica';
my $label_fontsize = 12*pt;
my $label_postcode_fontsize = 14*pt;

my $label_banner_font = 'Helvetica';
my $label_banner_scale = PHI;
my $label_banner_colour = 'orange';

my $label_width;
my $label_height;
my $label_step_across;
my $label_step_down;
my $num_labels_across = 2;
my $num_labels_down = 4;
my $labels_ordered_in = 'columns';

use PDF::paginator qw(
                       $line_spacing
                       $page_bottom_margin
                       $page_height
                       $page_left_margin
                       $page_right_margin
                       $page_size
                       $page_top_margin
                       $page_width
                       $paper_sizes
                     );

use Label::common \($evenly_squash_to_fit, $label_banner_font,
                    $label_banner_colour, $label_banner_scale,
                    $label_bottom_margin, $label_fontname, $label_fontsize,
                    $label_height, $label_left_margin,
                    $label_postcode_fontsize, $label_right_margin,
                    $label_top_margin, $label_width, $line_spacing);
use Label::blank;
use Label::map_items \($label_bottom_margin, $label_fontname, $label_height,
                       $label_left_margin, $label_right_margin,
                       $label_top_margin, $label_width, $labels_ordered_in,
                       $line_spacing, $num_labels_across, $num_labels_down);
use Label::count::total;
use Label::recipient;

    sub suppress_unwanted_records($) {
        my $rr = shift;
        if ( @$rr && $rr->[0]->can('gtags') ) {
            my @rr = @$rr;
            my @skips;
            push @skips, 'archive - deceased'     if $skip_deceased;
            push @skips, 'archive - unsubscribed' if $skip_unsub;
            push @skips, 'meetings'               if $skip_meetings;
            push @skips, 'suppress listing'       if $skip_suppressed_listing;
            push @skips, 'newsletters-only'       if $skip_newsletters_only;
            push @skips, 'suppress email'         if $skip_suppressed_email;
            push @skips, 'suppress post'          if $skip_suppressed_post;
            push @skips, 'explanatory texts';
            @rr = grep { ! $_->gtags(@skips) } @rr if @skips;
            @rr = grep { ! $_->gtags(qr/^archive - /) } @rr if $skip_archived;
            $rr = \@rr;
        }
        return $rr;
    }

    sub group_people_into_households($) {
        my $rr = shift;
        $rr = suppress_unwanted_records $rr;
        @$rr or return [];
        if ( $rr->[0]->can('gtags') ) {
            my %households;
            my $z = 0;
            for my $r (@$rr) {
                my $a = $r->postal_address or next;
                $a .= '__SPLIT_POST__'.++$z if $r->gtags('split post');
                push @{$households{$a}}, $r;
            }
            return [ values %households ]
        }
        elsif ( $rr->[0]->can('uid') ) {
            my @households;
            my $unique_id = 0;
            my %s;
            for my $r (@$rr) {
                $s{$r->uid} and next;
                $r->{XREF_parents} and next;
                my @h = $r;
                push @h, $r->{"XREF_spouse"} if $r->{"XREF_spouse"};
                push @h, @{ $r->{"XREF_children"} } if $r->{"XREF_children"};
                $s{$_->uid}++ for @h;
                push @households, \@h;
            }
            return \@households;
        }
        else {
            die "Can't group households of $rr->[0]";
        }
    }

sub generate_labels($$;$) {
    my $out = shift;
    my $rr = shift;
    my $in_name = shift || '(stdin)';

    # Make family groups or households
    my $households = group_people_into_households $rr;

    warn sprintf "grouped-households: %u\n", 0+@$households if $verbose;

    # Select households which have any member wanting any of the offered
    # inclusions

    @$households = grep { grep { $_->gtags(@selection_tags) } @$_; } @$households if @selection_tags;

    # Group households by which inclusions they want, and remove members of
    # households who want nothing

    my %inclusion_label; @inclusion_label{@inclusion_tags} = @inclusion_labels;

    warn sprintf "selected-households: %u\nselection-tags: [%s]\ninclusion-tags: [%s]\ninclusion-labels: [%s]\n",
            0+@$households,
            join('; ', @selection_tags),
            join('; ', @inclusion_tags),
            join('; ', @inclusion_labels)
        if $verbose;

    my $next_inclusion_group = 'E0';
    my %inclusion_groups;
    my %group_counts;
    my %inclusion_counts;
    my %households_by_inclusions;
    HOUSEHOLD: for my $hh (@$households) {
        # Which members of household are requesting at least one item?
        my @hh = @$hh;
        @hh = grep { $_->gtags(@selection_tags) } @hh if @selection_tags;
        @hh or next HOUSEHOLD;
        # Which inclusions for this household?
        my @inclusions = map { $inclusion_label{$_} }
                            grep { my $t = $_; grep { $_->gtags($t) } @hh; }
                                @inclusion_tags
            or next HOUSEHOLD;
        $hh[0]->{inclusions} = \@inclusions;
        my $postal_address = $hh[0]->postal_address;
        # What sort-order within the tag group?
        my @sort_by = qw( country postcode city suburb street streetnum );
        $hh[0]->{sort_by} = join "\t", map { $postal_address->{$_} || '' } @sort_by;
        # and done
        $hh[0]->{inclusion_group} =
        my $igroup = $inclusion_groups{join ',', @inclusions} ||= ++$next_inclusion_group;
        ++$group_counts{$igroup};
        if ( $postal_control_tag && grep { $_->gtags($postal_control_tag) } @hh ) {
            # are they overseas?
            push @inclusions, "\x{fe01}(Special Postage)";
        }
        my $group_by = join ', ', @inclusions;
        push @{$households_by_inclusions{$group_by}}, \@hh;
        ++$inclusion_counts{$_} for @inclusions;
    }

    keys %households_by_inclusions > 0 or warn "No households selected; remember to use the GMail dump rather than the Profile dump\n";

    if ($verbose > 2) {
        for my $hh (values %households_by_inclusions) {
            for my $h (@$hh) {
                warn sprintf "NAME: %s SORT: %s INCLUDE: %s\n", $h->[0]->name, $h->[0]->{sort_by}, $h->[0]->{inclusions};
            }
        }
    }

    my $use_item_count_labels = keys %households_by_inclusions > 1;

    my @summary_labels = ( Label::count::total::->new( "Make copies",     \@inclusion_labels,            [@inclusion_counts{@inclusion_labels}]       ),
                           Label::count::total::->new( "Stuff envelopes", ['E1'..$next_inclusion_group], [@group_counts{'E1'..$next_inclusion_group}] ) );

    # Sort within each inclusion group
    @$_ = sort { $a->[0]{sort_by}  cmp $b->[0]{sort_by} } @$_ for values %households_by_inclusions;

    my $labels_per_page = $num_labels_across * $num_labels_down;

    # generate the lines to be put on each household's label, and
    # create inclusion labels
    my @labels;
    for my $group_by ( sort { @{$households_by_inclusions{$b}} <=> @{$households_by_inclusions{$a}} } keys %households_by_inclusions ) {
        my @households = @{$households_by_inclusions{$group_by}};
        my $inclusions = $households[0][0]{inclusions};
        for my $hi ( 0..$#households ) {
            my $hh = $households[$hi];
            if ($use_item_count_labels and $hi == 0 || @labels % $labels_per_page == 0) {
                my $first_label_on_page = (@labels+1) % $labels_per_page;
                if ( $first_label_on_page == 0 ) {
                    # No point putting a count-label in last position on page,
                    # where its count would be zero, so put the summary totals
                    # label here, or otherwise just leave it blank.
                    if (@summary_labels) {
                        push @labels, pop @summary_labels;
                    }
                    else {
                        push @labels, one Label::blank::;
                    }
                }
                my $last_label_on_page = min( @households-$hi+$first_label_on_page, $labels_per_page ) - 1;
                push @labels, new Label::map_items::
                                    $inclusions,
                                    $group_counts{$hh->[0]{inclusion_group}}, #scalar(@households),
                                    $hh->[0]{inclusion_group},
                                    $first_label_on_page,
                                    $last_label_on_page;
            }
            my @hh = @$hh;
            if (@hh > 2) {
                # Rearrange the list to put the parent(s) first & second; leave the
                # second slot blank if there is only one parent.
                # (a) look for uid_of_children_under_16
                my @parents = grep { $_->uid_of_children_under_16 } @hh;
                my @children = grep { !$_->uid_of_children_under_16 } @hh;
                $#parents == 0 ||
                $#parents == 1 || warn sprintf "WARNING: group for %s has %u parents and %u children", $hh[0]->name, scalar @parents, scalar @children;
                if (@parents) {
                    $#parents = 1;
                    for (@children) {
                        # Omit surnames on children
                        my $sn = $_->{family_name};
                        $_->{formatted} =~ s/\s*$sn$//,
                        $_->{family_name} = ' '
                    }
                    @hh = ( @parents, @children );
                }
                # If more than one child, just use "and family"
                if (@hh > 3) {
                    package AndFamily;
                    # This sub has static scope, which is intentional
                    sub name {
                        my $r = shift;
                        $r->{composite_name} ||= state $f =
                            new string_with_components::
                                "family",
                                family_name => '',
                                given_name => '',
                                sort_by_surname => 'zz',
                                sort_by_givenname => 'zz';
                    }
                    state $and_family = bless {};
                    @hh = (@hh[0,1], $and_family);
                }
            }
            my @names = map { $_ && $_->name } @hh;
            for (1..$#names) {
                if ( $names[$_-1]->{family_name} eq $names[$_]->{family_name} ) {
                    $names[$_-1] = $names[$_-1]->{given_name};
                }
            }
            s/\s*\([^()]*\)\s*/ /g,
            s/ (?:ex|née*) .*// for @names;
            my $names = join ' & ', @names;
            @hh && $hh[0] or die "Empty household #$hi\n".Dumper(\@hh, \@households);
            my $postal_address = $hh[0]->postal_address;
            my $postcode = $postal_address->{postcode} || (UNIVERSAL::can($hh[0],'postcode') && $hh[0]->postcode || $hh[0]->{postcode})
                or warn sprintf "WARNING: missing postcode on %s at %s\n", $names[0], $postal_address;
            $postal_address =~ s/(.*\S)\s*\b$postcode\b/$1/ if $postcode;
            my @lines = grep {$_}
                            $names,
                            split /\s*\n/, $postal_address;
            push @labels, new Label::recipient:: ($inclusions, $postcode, @lines);
        }
    }
    if (@summary_labels) {
        push @labels, @summary_labels;
        @summary_labels = ();
    }

    my $pq = new PDF::paginator:: ( page_size => [$page_size || ($page_width, $page_height)] );
    my $display_page_width = $pq->{page_width};
    my $display_page_height = $pq->{page_height};
    my ($display_page_size) = (
        $page_size || (),
        (                grep { my $ps = $paper_sizes->{$_}; near $display_page_width, $ps->[1], 200 and near $display_page_height, $ps->[0], 200 } keys %$paper_sizes ),
        ( map { $_.'R' } grep { my $ps = $paper_sizes->{$_}; near $display_page_width, $ps->[0], 200 and near $display_page_height, $ps->[1], 200 } keys %$paper_sizes ),
        ( sprintf "custom[%.2f × %.2f mm]", $display_page_height/mm, $display_page_width/mm ),
    );

    my $x_start = $label_left_margin + $page_left_margin;
    my $y_start = $label_top_margin  + $page_top_margin ;

    {
    my $printable_page_height = $display_page_height - $page_top_margin - $page_bottom_margin;
    my $printable_page_width  = $display_page_width  - $page_left_margin - $page_right_margin;

    $num_labels_across ||= $printable_page_width  / ($label_step_across || $label_width);
    $num_labels_down   ||= $printable_page_height / ($label_step_down   || $label_height);

    $label_step_across ||= $printable_page_width  / $num_labels_across || $label_height + $label_top_margin + $label_bottom_margin;
    $label_step_down   ||= $printable_page_height / $num_labels_down   || $label_width  + $label_left_margin + $label_right_margin;

    $label_height ||= $label_step_down   -  $label_top_margin - $label_bottom_margin;
    $label_width  ||= $label_step_across -  $label_left_margin - $label_right_margin;

    warn sprintf "First Page\n"
               . " page size: %.2fmm × %.2fmm (w×h) (%s)\n"
               . " printable: %.2fmm × %.2fmm (w×h)\n"
               . " labels/page: %d × %d (a×d)\n"
               . " label size: %.2fmm × %.2fmm (w×h)\n"
               . " label step: %.2fmm × %.2fmm (a×d)\n"
               . " offset: %.2fmm × %.2fmm (a×d)\n"
               ,
                $display_page_width/mm, $display_page_height/mm, $display_page_size,
                $printable_page_width/mm, $printable_page_height/mm,
                $num_labels_across, $num_labels_down,
                $label_width/mm, $label_height/mm,
                $label_step_across/mm, $label_step_down/mm,
                $x_start/mm, $y_start/mm,
        if $verbose;
    }

    my $printable_label_width  = $label_width  - $label_left_margin - $label_right_margin;
    my $printable_label_height = $label_height - $label_top_margin  - $label_bottom_margin;

    for my $r ( @labels ) {
        my $text = $pq->text;

        my $label_on_page = $pq->{page_item_num}++;

        my $col;
        my $row;
        if ($labels_ordered_in eq 'columns') {
            $row  = $label_on_page        % $num_labels_down;
            $col  = ($label_on_page-$row) / $num_labels_down;
        }
        else {
            $col  = $label_on_page        % $num_labels_across;
            $row  = ($label_on_page-$col) / $num_labels_across;
        }
        my $top  = $display_page_height - $y_start - $label_step_down   * $row;
        my $left =                $x_start + $label_step_across * $col;
        if ($use_cropbox) {
            my $right = $left + $printable_label_width;
            my $bottom = $top - $printable_label_height;
            $pq->pdf->cropbox($left, $bottom, $right, $top);
        }

        warn sprintf "Page %u label %u -> row %u/%u column %u/%u\n",
                    $pq->pages,
                    $label_on_page,
                    $row, $num_labels_across, $col, $num_labels_down if $verbose > 1;

        $r->draw_label($pq, $top, $left, $label_on_page);

        if ($label_on_page+1 >= $num_labels_across * $num_labels_down) {
            warn "Throwpage\n" if $verbose > 1;
            $pq->closepage;
        }
    }

    ( $out, my $out_name, my $close_when_done ) = _open_output $out, 1;
    warn "Writing PDF to $out_name ($out)\n";
    print {$out} $pq->stringify;
    _close_output $out, $out_name, $close_when_done;
}

sub use_preset {
    my $pt = pop;

    state $x = warn Dumper($paper_sizes) if $verbose > 4 && $debug;

    state $page_product = {
      # ( map { ( $_     => { num_labels_across => 2, num_labels_down => 3, } ) } keys %$paper_sizes ),
      # ( map { ( $_.'R' => { num_labels_across => 3, num_labels_down => 2, } ) } keys %$paper_sizes ),

        'avery-l7160' => {
                num_across           => 3,
                num_down             => 7,
                ordered_in           => 'columns',
            },

        };

    state $y = warn Dumper($page_product) if $verbose > 4 && $debug;

    my $p = $page_product->{$pt} || return; #die "Unknown label or paper product '$pt'\nAvailable presets are @{[sort keys %$page_product]}\n";
    (
        $num_labels_across, $num_labels_down, $labels_ordered_in,
        $label_top_margin, $label_bottom_margin, $label_left_margin, $label_right_margin,
    ) = @$p{qw{
        num_across num_down ordered_in
        label_top_margin label_bottom_margin label_left_margin label_right_margin
    }};
}

use run_options (

    'labels'                        => \$do_labels,

    'instruction-color|instruction-colour=s' => \$label_banner_colour,
   '%label-height|lh=s'             => \$label_height,
   '%label-step-across|lxw=s'       => \$label_step_across,
   '%label-step-down|lxh=s'         => \$label_step_down,
   '%label-width|lw=s'              => \$label_width,
    'labels-ordered-in-columns'     => sub { $labels_ordered_in = 'columns' },
    'labels-ordered-in-rows'        => sub { $labels_ordered_in = 'rows' },
    'labels-ordered-in=s'           => \$labels_ordered_in,
    'num-labels-across|nla=i'       => \$num_labels_across,
    'num-labels-down|nld=i'         => \$num_labels_down,

   '+preset=s'                      => \&use_preset,

    '#check'                        => sub {
                                        # extra sanity-check
                                        $labels_ordered_in eq 'columns' ||
                                          $labels_ordered_in eq 'rows' ||
                                            die "Label ordering must be 'rows' or 'columns'\n";
                                        $skip_suppressed_post    //= $do_labels;
                                        1;
                                    },

    '#help-labels'                  => <<EndOfHelp,
label-options (with --labels):
    --preset={avery-l7160|...}
    --instruction-colour=COLOUR     colour of metadata labels
    --label-height=LENGTH       --lh=LENGTH
    --label-step-across=LENGTH  --lxw=LENGTH
    --label-step-down=LENGTH    --lxh=LENGTH
    --label-width=LENGTH        --lw=LENGTH
    --labels-ordered-in={columns|rows}
    --labels-ordered-in-{columns|rows}
    --num-labels-across=NUM     --nla=NUM
    --num-labels-down=NUM       --nld=NUM
    (plus all "pdf-output" options)

See:
    $0 --help-pdf
    $0 --help-generic
EndOfHelp
);

use export qw( generate_labels $do_labels );

1;
