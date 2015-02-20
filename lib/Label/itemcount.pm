#!/module/for/perl

use 5.010;
use strict;
use warnings;
use utf8;

package Label::itemcount;
use parent 'Label::common';

use verbose;
use PDF::scale_factors;

our $label_banner_colour = 'orange';

sub new {
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

sub colour { $label_banner_colour }

sub draw_label {
    my ($r, $pq, $top, $left, $label_on_page) = @_;
    my $text = $pq->text;
    my $first_label_on_page = $r->{first_on_page};
    my $last_label_on_page  = $r->{last_on_page};
    warn sprintf "Printing tiny labels #%u..%u", $first_label_on_page, $last_label_on_page
        if $verbose > 1;

    my $printable_label_width  = $r->{label_width}  - $r->{label_left_margin} - $r->{label_right_margin};
    my $printable_label_height = $r->{label_height} - $r->{label_top_margin}  - $r->{label_bottom_margin};
    my $labels_per_page = $r->{num_labels_across} * $r->{num_labels_down};

    my $tiny_label_step_across = $printable_label_width / 3 / $r->{num_labels_across};
    my $tiny_label_step_down   = $printable_label_height / $r->{num_labels_down};
    my $tiny_fontsize = $tiny_label_step_down / $r->{label_line_spacing};
    warn sprintf "Tiny labels fontsize=%.2fmm (%.2fpt), step-across=%.2fmm, step-down=%.2fmm ",
                $tiny_fontsize/mm, $tiny_fontsize/pt,
                $tiny_label_step_across/mm,
                $tiny_label_step_down/mm
        if $verbose > 2;

    $pq->font( $r->{label_fontname}, $tiny_fontsize );
    for my $tiny_l ( 0 .. $labels_per_page-1 ) {
        my $tiny_col;
        my $tiny_row;
        if ($r->{labels_ordered_in} eq 'columns') {
            $tiny_row  = $tiny_l             % $r->{num_labels_down};
            $tiny_col  = ($tiny_l-$tiny_row) / $r->{num_labels_down};
        }
        else {
            $tiny_col  = $tiny_l             % $r->{num_labels_across};
            $tiny_row  = ($tiny_l-$tiny_col) / $r->{num_labels_across};
        }
        my $tiny_top   = $top  - $r->{label_top_margin}                               - $tiny_label_step_down   * $tiny_row;
        my $tiny_right = $left + $r->{label_left_margin} + $printable_label_width*2/3 + $tiny_label_step_across * ($tiny_col+1);
        warn sprintf "Printing tiny label #%s →%.2fmm,↑%.2fmm", $tiny_l, $tiny_right/mm, $tiny_top/mm if $verbose > 2;
        $text->translate( $tiny_right, $tiny_top - $tiny_label_step_down );
        if ( $tiny_l == $label_on_page ) {
            $text->fillcolor($r->{label_banner_colour});
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
