#!/module/for/perl

use 5.010;
use strict;
use warnings;
use utf8;

package Label::common;

use Carp 'croak';
use Data::Dumper;

use verbose;
use PDF::scale_factors;
use list_functions 'min','max';


my ($ref_evenly_squash_to_fit,
    $ref_banner_font,
    $ref_banner_colour,
    $ref_banner_scale,
    $ref_bottom_margin,
    $ref_fontname,
    $ref_fontsize,
    $ref_height,
    $ref_left_margin,
    $ref_postcode_fontsize,
    $ref_right_margin,
    $ref_top_margin,
    $ref_width,
    $ref_line_spacing);

my $seen_imports;
sub import {
    my $pkg = shift;
    @_ == 0 && return;
    @_ == 14 || croak "Wrong number of args";
    ( $ref_evenly_squash_to_fit,
      $ref_banner_font,
      $ref_banner_colour,
      $ref_banner_scale,
      $ref_bottom_margin,
      $ref_fontname,
      $ref_fontsize,
      $ref_height,
      $ref_left_margin,
      $ref_postcode_fontsize,
      $ref_right_margin,
      $ref_top_margin,
      $ref_width,
      $ref_line_spacing ) = @_;
    ++$seen_imports;
    for my $j ( $ref_evenly_squash_to_fit,
                $ref_banner_font,
                $ref_banner_colour,
                $ref_banner_scale,
                $ref_bottom_margin,
                $ref_fontname,
                $ref_fontsize,
                $ref_height,
                $ref_left_margin,
                $ref_postcode_fontsize,
                $ref_right_margin,
                $ref_top_margin,
                $ref_width,
                $ref_line_spacing ) {
        $j && ref $j eq 'SCALAR' or croak "import passed '$j'";
    }
}

sub new {
    warn sprintf "%s(%s)\n", (caller(0))[3], join ",", map { "'$_'" } @_ if $verbose > 4 && $debug;
    my $class = shift;
    $seen_imports || croak "new called before import bindings";
    bless { @_ }, $class;
}

sub colour { $$ref_banner_colour }

sub draw_label {
    warn sprintf "%s(%s)\n", (caller(0))[3], join ",", map { "'$_'" } @_ if $verbose > 4 && $debug;
    my ($r, $pq, $top, $left, $label_on_page) = @_;
    $seen_imports || croak "new called before import bindings";

    my $text = $pq->text;
    $text->fillcolor($r->colour);

    my @lines = @{$r->{lines}};
    my $banner = $r->{banner};

    @lines || $banner || return;

    #warn Dumper($ref_fontsize);
    my $active_fontsize = $$ref_fontsize;
    my $current_fontsize = $$ref_fontsize;

    $pq->font( $$ref_fontname, $active_fontsize );

    if ($$ref_evenly_squash_to_fit) {
        # squash up when too many lines
        # evenly squash up ALL lines when any line is too wide
        my $printable_label_width  = $$ref_width  - $$ref_left_margin - $$ref_right_margin;
        my $printable_label_height = $$ref_height - $$ref_top_margin  - $$ref_bottom_margin;
        $active_fontsize *= min 1,
                                $printable_label_height / ( @lines + ($banner && $$ref_banner_scale || 0) ) / ( $$ref_line_spacing * $active_fontsize ),
                                $printable_label_width / max 1,
                                                             $banner && $text->advancewidth($banner)*$$ref_banner_scale || 0,
                                                             map { $text->advancewidth($_) } @lines;
    }

    if (my $p = $r->{banner}) {
        if (my @v = $p =~ m/\%\{(\w+)\}/g) {
            warn "format '$p' keys [@v]\n" . Dumper($r) if $verbose > 2;
            $p =~ s/\%\{(\w+)\}/%/g;
            $p = sprintf $p, @$r{@v};
        }
        $active_fontsize = min $active_fontsize,
                               $$ref_height / ($$ref_banner_scale * $$ref_line_spacing + @lines * $$ref_line_spacing);

        my $banner_fontsize = $active_fontsize*$$ref_banner_scale;
        $pq->font( $$ref_banner_font, $current_fontsize = $banner_fontsize ) if $banner_fontsize != $current_fontsize;
        $text->translate( $left, $top -= $banner_fontsize*$$ref_line_spacing );
        $text->text($p);
    }

    if (@lines) {
        for (0 .. $#lines) {
            $pq->font( $$ref_fontname, $current_fontsize = $active_fontsize ) if $active_fontsize != $current_fontsize;
            my $rescale = $$ref_width / $text->advancewidth($_);
            if ( $rescale < 1 ) {
                # squeeze up to make room...
                $pq->font( $$ref_fontname, $current_fontsize = $active_fontsize * $rescale );
            }
            $text->translate( $left, $top - (@lines - $#lines + $_)*$active_fontsize*$$ref_line_spacing );
            $text->text($lines[$_]);
        }
    }

    if (my $p = $r->{postcode}) {
        $pq->font( $$ref_fontname, $$ref_postcode_fontsize );
        $text->translate( $left + $$ref_width, $top - $$ref_height + $$ref_postcode_fontsize );
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
