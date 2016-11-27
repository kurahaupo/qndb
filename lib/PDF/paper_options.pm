#!/module/for/perl
# vim: set nowrap :

use 5.010;
use strict;
use warnings;
use utf8;

package PDF::paper_options;

use Carp qw( croak carp );

use verbose;
use PDF::scale_factors;

########################################
#
# Generic "PDF output" command-line options
# (shared between labels and book generation)
#

my $page_size;                  # = 'a4';
my $page_height;                # = 297.3mm;
my $page_width;                 # = 210.2mm;

my $top_inset;                  # = 0 or 14mm;
my $vertical_gap;               # = 0
my $bottom_inset;               # = 0 or 14mm;
my $left_inset;                 # = 0 or 18mm;
my $horizontal_gap;             # = 0
my $right_inset;                # = 0 or 18mm;

my $top_margin;                 # = 4mm or 1.5mm
my $bottom_margin;              # = 4mm or 1.5mm
my $left_margin;                # = 1mm or 5.7mm
my $right_margin;               # = 1mm or 7.7mm

my $count_across;               # = 3
my $count_down;                 # = 7
my $step_across;                # 
my $step_down;                  # 

my $printable_width;            # ==
my $printable_height;           # == computed from values above

our %paper_sizes = (
        # A-series paper sizes, portrait
        (map {
            (my $x = $_) =~ s/^a//i;
            my $h = 2**(0.25-$x/2);
            my $w = $h / sqrt(2);
            ( ( $_ < 0 ? (2**-$_).'a0' : "a$_") => [ $h*1000*mm, $w*1000*mm ] );
        } -2 .. 10),
        # B-series paper sizes, portrait
        (map {
            (my $x = $_) =~ s/^b//i;
            my $h = 2**(0.5-$x/2);
            my $w = $h / sqrt(2);
            ( ( $_ < 0 ? (2**-$_).'b0' : "b$_") => [ $h*1000*mm, $w*1000*mm ] );
        } 0 .. 10),
        # C-series envelope sizes, landscape
        (map {
            (my $x = $_) =~ s/^c//i;
            my $w = 2**(0.375-$x/2);
            my $h = $w / sqrt(2);
            ( ( $_ < 0 ? (2**-$_).'c0' : "c$_") => [ $h*1000*mm, $w*1000*mm ] );
        } 0 .. 10),
        # DL envelope size, landscape
        dl => [ 110*mm, 220*mm ],
    );

our %r_paper_sizes = ( %paper_sizes,
                       map { ( $_.'R' => [ reverse @{$paper_sizes{$_}} ] ) }
                        keys %paper_sizes );

#   sub dimensions_from_papersize($) {
#       return @{$r_paper_sizes{$_[0]} || []}
#   }

#   sub papersize_from_dimensions($$) {
#       my ($w, $h) = @_;
#       for my $k ( keys %r_paper_sizes ) {
#           my ($wk, $hk) = @{$r_paper_sizes{$k}};
#           if ( abs($h-$hk) < 0.6*cm && abs($w-$wk) < 0.6*cm ) {
#               return $k
#           }
#       }
#       return sprintf 'custom[%.2f×%.2fmm]', $w / mm, $h / mm;
#   }

########################################

my %page_product = (

    'book' => {
            page_size           => 'a5',
          # page_width          => $r_paper_sizes{a5}[1],
          # page_height         => $r_paper_sizes{a5}[0],

            left_inset          => 0,
            right_inset         => 0,
            top_inset           => 0,
            bottom_inset        => 0,
            vertical_gap        => 0,
            horizontal_gap      => 0,

            count_across        => 1,
            count_down          => 1,

            left_margin         => 12.5*mm,  # == ~page_height/12
            right_margin        => 12.5*mm,  # ==
            bottom_margin       => 10.0*mm,  # == ~page_width/21
            top_margin          => 10.0*mm,  # ==
        },

    'avery-l7160' => {
            # baseline paper size
            page_size           => 'a4',
          # page_width          => $r_paper_sizes{a4}[1],
          # page_height         => $r_paper_sizes{a4}[0],

            # insets and gaps are between printable areas
            # (allow ±1mm for physical feed "slop")
            left_inset          =>  6.0*mm,
            right_inset         =>  7.0*mm,
            top_inset           => 18.0*mm,
            bottom_inset        => 14.0*mm,
            vertical_gap        =>  1.0*mm,
            horizontal_gap      =>  1.0*mm,
        },
    );

sub get_page_configuration() {

    if ($page_height && $page_width) {
    }
    elsif ($page_size) {
        my $p = $r_paper_sizes{$page_size} || croak "Invalid page size '$page_size'\n";
        ($page_height, $page_width) = @$p;
    }
    else {
        croak "Missing both paper size and paper dimensions";
    }

    my $start_x;
    my $end_x;
    my $step_x;
    my $count_x;

    my $start_y;
    my $end_y;
    my $step_y;
    my $count_y;

    for my $d ( {
                  o  => \$start_x,      # left side of first column, after allowing for margins
                  e  => \$end_x,        # right side of first column, after allowing for margins
                  s  => \$step_x,       # step from column to column
                  n  => \$count_x,      # number of columns

                  sz => $page_width,
                  st => $step_across,
                  nu => $count_across,
                  si => $left_inset,
                  ii => $horizontal_gap,
                  ei => $right_inset,
                  sm => $left_margin,
                  em => $right_margin,
                },
                {
                  o  => \$start_y,
                  e  => \$end_y,
                  s  => \$step_y,
                  n  => \$count_y,

                  sz => $page_height,
                  st => $step_down,
                  nu => $count_down,
                  si => $top_inset,
                  ii => $vertical_gap,
                  ei => $bottom_inset,
                  sm => $top_margin,
                  em => $bottom_margin,
                } ) {
        $d->{sz} or next;
        if (!$d->{nu}) {
            $d->{nu} = croak '';
        }
        #$d->{sz} - $d->{si} - $d->{ei} + $d->{ii} == $d->{st} * $d->{nu};
    }

#   my $page_printable_width  = $display_page_width  - $page_left_margin - $page_right_margin;
#   my $page_printable_height = $display_page_height - $page_top_margin - $page_bottom_margin;

#   $count_across ||= int( $page_printable_width  / ($label_step_across || $label_width  || 1E9) + 0.0001 );
#   $count_down   ||= int( $page_printable_height / ($label_step_down   || $label_height || 1E9) + 0.0001 );

#   $label_step_across ||= ( $page_printable_width  + $label_horizontal_intersticial ) / ($count_across || 1E9) || $label_width  + $label_left_margin + $label_right_margin;
#   $label_step_down   ||= ( $page_printable_height + $label_vertical_intersticial   ) / ($count_down   || 1E9) || $label_height + $label_top_margin  + $label_bottom_margin;

#   $label_width  ||= $label_step_across -  $label_left_margin - $label_right_margin;
#   $label_height ||= $label_step_down   -  $label_top_margin - $label_bottom_margin;

#   $label_printable_width  = $label_width  - $label_left_margin - $label_right_margin;
#   $label_printable_height = $label_height - $label_top_margin  - $label_bottom_margin;

#   my ($display_page_size) = (
#       $page_size || (),
#       (                grep { my $ps = $paper_sizes{$_}; near $display_page_width, $ps->[1], 200 and near $display_page_height, $ps->[0], 200 } keys %paper_sizes ),
#       ( map { $_.'R' } grep { my $ps = $paper_sizes{$_}; near $display_page_width, $ps->[0], 200 and near $display_page_height, $ps->[1], 200 } keys %paper_sizes ),
#       ( sprintf "custom[%.2f × %.2f mm]", $display_page_height/mm, $display_page_width/mm ),
#   );
#   warn sprintf "First Page\n"
#              . " page size: %.2fmm × %.2fmm (w×h) (%s)\n"
#              . " printable: %.2fmm × %.2fmm (w×h)\n"
#              . " labels/page: %d × %d (a×d)\n"
#              . " label size: %.2fmm × %.2fmm (w×h)\n"
#              . " label step: %.2fmm × %.2fmm (a×d)\n"
#              . " offset: %.2fmm × %.2fmm (a×d)\n"
#              ,
#               $display_page_width/mm, $display_page_height/mm, $display_page_size,
#               $page_printable_width/mm, $page_printable_height/mm,
#               $count_across, $count_down,
#               $label_width/mm, $label_height/mm,
#               $label_step_across/mm, $label_step_down/mm,
#               $x_start/mm, $y_start/mm,
#       if $verbose;

    return +{
            page_size   => $page_size,
            page_width  => $page_width,
            page_height => $page_height,

            start_x     => $start_x,
            end_x       => $end_x,
            step_x      => $step_x,
            count_x     => $count_x,

            start_y     => $start_y,
            end_y       => $end_y,
            step_y      => $step_y,
            count_y     => $count_y,
        };
}

use export qw(
                %paper_sizes
                %r_paper_sizes
                get_page_configuration
            );
              # dimensions_from_papersize
              # papersize_from_dimensions

#
# Clients usually need to know, in each dimension, only:
#   + the starting offset of the first printable area;
#   + the limit of the first printable area (expressed either as another
#     offset, or as the difference between the starting and finishing offsets);
#   + the "step" to reach the next printable area;
#   + the count of printable areas.
# For the most part, they can remain ignorant of the non-printable areas.
# (However the actual page size needs to be conveyed to the PDF module.)
#
# Having said that, margins to satisfy human expectations, as well as an
# artifact of sloppy alignment of the printing; they are not a fixed property
# of the medium itself.
#
# A normal page has a single printable area, with margins that largely reflect
# human expectation, and they may be used to present metadata, such as page
# numbers or instructions.
#
# Labels may be inset from the edge of their feeder substrate "page", and may
# have intersticial spacing. And in some cases they *may* have printable
# margins outside the nominal surface, which is useful to show instructions.
# (The Avery labels have "half height labels" at the top and bottom of each
# page that are normally ignored; and because they don't have intersticial
# spacing, on-label instructions could span multiple labels.)
#
# There are several ways to measure a page of labels.
# The most precise way to establish dimensions is to measure overall
# dimensions, and divide by the number of labels in that direction.
#
# For width:
#  left-inset (declared as page-left-margin)
#  right-inset (declared as page-right-margin)
#
#

1;
