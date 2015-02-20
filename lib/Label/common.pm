#!/module/for/perl

use 5.010;
use strict;
use warnings;
use utf8;

package Label::common;

use Carp 'croak';
use Data::Dumper;

use verbose;
use list_functions 'min', 'max';
use PDF::scale_factors;

my $debug = $ENV{PERL_debug_labels};

BEGIN { $SIG{__DIE__} = \&Carp::confess if $ENV{PERL_debug_labels} };

sub new {
    my $class = shift;
    my $r = bless { @_ }, $class;
    warn "new label details: ".Dumper($r) if $debug;
    return $r;
}

use constant colour => 'black';

sub draw_label {
    my ($r, $pq, $top, $left, $label_on_page) = @_;
    my $text = $pq->text;
    $text->fillcolor($r->colour);

    my @lines = @{$r->{lines}};
    my $banner = $r->{banner};

    @lines || $banner || return;

    my $label_fontname   = $r->{label_fontname} // croak('Missing "label_fontname"') || croak('Blank "label_fontname"');
    my $active_fontsize  =
    my $current_fontsize = $r->{label_fontsize} // croak('Missing "label_fontsize"') || croak('Blank "label_fontsize"');
    my $label_height     = $r->{label_height}   // croak("Missing 'label_height'")   || croak("Blank 'label_height'");
    my $label_width      = $r->{label_width}    // croak("Missing 'label_width'")    || croak("Blank 'label_width'");

    $pq->font( $label_fontname, $active_fontsize );

    my $printable_label_width  = $label_width  - $r->{label_left_margin} - $r->{label_right_margin};
    my $printable_label_height = $label_height - $r->{label_top_margin}  - $r->{label_bottom_margin};

    if ($r->{label_evenly_squash_to_fit}) {
        # squash up when too many lines
        # evenly squash up ALL lines when any line is too wide
        $active_fontsize *= min 1,
                                $printable_label_height / ( @lines + ($banner && $r->{label_banner_scale} || 0) ) / ( $r->{label_line_spacing} * $active_fontsize ),
                                $printable_label_width / max 1,
                                                               $banner && $text->advancewidth($banner)*$r->{label_banner_scale} || 0,
                                                               map { $text->advancewidth($_) } @lines;
    }

    if (my $p = $r->{banner}) {
        if (my @v = $p =~ m/\%\{(\w+)\}/g) {
            warn "format '$p' keys [@v]\n" . Dumper($r) if $verbose > 2;
            $p =~ s/\%\{(\w+)\}/%/g;
            $p = sprintf $p, @$r{@v};
        }
        $active_fontsize = min $active_fontsize,
                               $label_height / ($r->{label_banner_scale} * $r->{label_line_spacing} + @lines * $r->{label_line_spacing});

        my $banner_fontsize = $active_fontsize*$r->{label_banner_scale};
        $pq->font( $r->{label_banner_font}, $current_fontsize = $banner_fontsize ) if $banner_fontsize != $current_fontsize;
        $text->translate( $left, $top -= $banner_fontsize*$r->{label_line_spacing} );
        $text->text($p);
    }

    if (@lines) {
        for (0 .. $#lines) {
            $pq->font( $label_fontname, $current_fontsize = $active_fontsize ) if $active_fontsize != $current_fontsize;
            my $twidth = $text->advancewidth($_);
            my $rescale = $twidth ? $printable_label_width / $twidth : 1;
            if ( $rescale < 1 ) {
                # squeeze up to make room...
                $pq->font( $label_fontname, $current_fontsize = $active_fontsize * $rescale );
            }
            $text->translate( $left, $top - (@lines - $#lines + $_)*$active_fontsize*$r->{label_line_spacing} );
            $text->text($lines[$_]);
        }
    }

    if (my $p = $r->{postcode}) {
        $pq->font( $label_fontname, $r->{label_postcode_fontsize} );
        $text->translate( $left + $label_width, $top - $label_height + $r->{label_postcode_fontsize} );
        $text->text_right($p);
    }

    warn sprintf "Page %u label %u -> lines=%u font=%.2fmm (%.2fpt)\n",
                $pq->pages,
                $label_on_page,
                0+@lines,
                $active_fontsize/mm, $active_fontsize/pt
        if $verbose > 1;
}

1;
