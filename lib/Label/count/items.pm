#!/module/for/perl

use 5.010;
use strict;
use warnings;
use utf8;

package Label::count::items;
use parent 'Label::common';

use Carp 'croak';

our $label_banner_colour = 'orange';

my ( $ref_bottom_margin,
     $ref_fontname,
     $ref_height,
     $ref_left_margin,
     $ref_right_margin,
     $ref_top_margin,
     $ref_width,
     $ref_labels_ordered_in,
     $ref_line_spacing,
     $ref_num_labels_across,
     $ref_num_labels_down );

sub import {
    my $pkg = shift;
    @_ or return;
    @_ == 11 or croak "Wrong number of args";
    ( $ref_bottom_margin,
      $ref_fontname,
      $ref_height,
      $ref_left_margin,
      $ref_right_margin,
      $ref_top_margin,
      $ref_width,
      $ref_labels_ordered_in,
      $ref_line_spacing,
      $ref_num_labels_across,
      $ref_num_labels_down ) = @_;
}

sub colour { $label_banner_colour }

use verbose;
use PDF::scale_factors;

sub new {
    warn sprintf "%s(%s)\n", (caller(0))[3], join ",", map { "'$_'" } @_ if $verbose > 4 && $debug;
    my $class = shift;
    my ($inclusions, $total_count, $first_label_on_page, $last_label_on_page) = splice @_,0,4;
    $inclusions = [ split /,\s*/, $inclusions ] if ! ref $inclusions;
    $class->SUPER::new(
        banner          => sprintf( "%u", $last_label_on_page-$first_label_on_page+1, ),
        lines           => $inclusions,
        first_on_page   => $first_label_on_page,
        last_on_page    => $last_label_on_page,
        total_count     => $total_count,
        @_
    );
}
sub draw_label {
    warn sprintf "%s(%s)\n", (caller(0))[3], join ",", map { "'$_'" } @_ if $verbose > 4 && $debug;
    my ($r, $pq, $top, $left, $label_on_page) = @_;
    my $text = $pq->text;
    my $first_label_on_page = $r->{first_on_page};
    my $last_label_on_page = $r->{last_on_page};
    warn sprintf "Printing tiny labels #%u..%u", $first_label_on_page, $last_label_on_page if $verbose > 1;
    my $printable_label_width  = $$ref_width  - $$ref_left_margin - $$ref_right_margin;
    my $printable_label_height = $$ref_height - $$ref_top_margin  - $$ref_bottom_margin;
    my $labels_per_page = $$ref_num_labels_across * $$ref_num_labels_down;

    my $tiny_label_step_across = $printable_label_width / 3 / $$ref_num_labels_across;
    my $tiny_label_step_down   = $printable_label_height / $$ref_num_labels_down;
    my $tiny_fontsize = $tiny_label_step_down / $$ref_line_spacing;
    warn sprintf "Tiny labels fontsize=%.2fmm (%.2fpt), step-across=%.2fmm, step-down=%.2fmm ",
                $tiny_fontsize/mm, $tiny_fontsize/pt,
                $tiny_label_step_across/mm,
                $tiny_label_step_down/mm
        if $verbose > 2;
    $pq->font( $$ref_fontname, $tiny_fontsize );
    for my $tiny_l ( 0 .. $labels_per_page-1 ) {
        my $tiny_col;
        my $tiny_row;
        if ($$ref_labels_ordered_in eq 'columns') {
            $tiny_row  = $tiny_l             % $$ref_num_labels_down;
            $tiny_col  = ($tiny_l-$tiny_row) / $$ref_num_labels_down;
        }
        else {
            $tiny_col  = $tiny_l             % $$ref_num_labels_across;
            $tiny_row  = ($tiny_l-$tiny_col) / $$ref_num_labels_across;
        }
        my $tiny_top  = $top  - $$ref_top_margin                               - $tiny_label_step_down   * $tiny_row;
        my $tiny_right = $left + $$ref_left_margin + $printable_label_width*2/3 + $tiny_label_step_across * ($tiny_col+1);
        warn sprintf "Printing tiny label #%s →%.2fmm,↑%.2fmm", $tiny_l, $tiny_right/mm, $tiny_top/mm if $verbose > 2;
        $text->translate( $tiny_right, $tiny_top - $tiny_label_step_down );
        if ( $tiny_l == $label_on_page ) {
            $text->fillcolor($label_banner_colour);
            $text->text_right("O");
        }
        elsif ( $tiny_l >= $first_label_on_page && $tiny_l <= $last_label_on_page ) {
            $text->fillcolor('black');
            $text->text_right("X");
        }
        else {
            $text->fillcolor('black');
            $text->text_right("-");
        }
    }
    $r->SUPER::draw_label($pq, $top, $left, $label_on_page);
}

1;
