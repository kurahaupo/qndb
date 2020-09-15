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
    $ref_fontname,
    $ref_fontsize,
    $ref_printable_width,
    $ref_printable_height,
    $ref_postcode_fontsize,
    $ref_line_spacing);

my $seen_imports;
sub import {
    my $self = shift;
    @_ == 0 && return;
    @_ == 10 || croak "Wrong number of args";
    #@_ == 14 || croak "Wrong number of args";
    (
      $ref_printable_width,
      $ref_printable_height,
      $ref_evenly_squash_to_fit,
      $ref_banner_font,
      $ref_banner_colour,
      $ref_banner_scale,
      $ref_fontname,
      $ref_fontsize,
      $ref_postcode_fontsize,
      $ref_line_spacing,
    ) = @_;
    ++$seen_imports;
    for my $j ( $ref_evenly_squash_to_fit,
                $ref_banner_font,
                $ref_banner_colour,
                $ref_banner_scale,
                $ref_fontname,
                $ref_fontsize,
                $ref_printable_width,   #$Ref_label_left_margin, $Ref_label_right_margin,
                $ref_printable_height,  #$Ref_label_top_margin, $Ref_label_bottom_margin,
                $ref_postcode_fontsize,
                $ref_line_spacing ) {
        $j && ref $j eq 'SCALAR' or croak "import passed '$j'";
    }
    warn sprintf "Importing from %s into %s (direct)\n", $self, scalar caller if $export::debug;
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
        my $printable_label_width = $$ref_printable_width;      # - $$Ref_label_left_margin - $$Ref_label_right_margin;
        my $printable_label_height = $$ref_printable_height;    # - $$Ref_label_top_margin - $$Ref_label_bottom_margin;
        my $printing_label_height = ( @lines + ($banner && $$ref_banner_scale || 0) ) / ( $$ref_line_spacing * $active_fontsize ),
        my $printing_label_width = max 1E-9, # just a smidge more than zero
                                       $banner && $text->advancewidth($banner)*$$ref_banner_scale || 0,
                                       map { $text->advancewidth($_) } @lines;
        my $squash_ratio = min 1,
                               $printable_label_height / $printing_label_height,
                               $printable_label_width / $printing_label_width;

        $active_fontsize *= $squash_ratio;
        if ($squash_ratio < 1 && ++(state $x) < 4 ) {
            warn sprintf "SQUASHING... [%s]\n", "@lines";
            warn sprintf "evenly_squash_to_fit=%s\n", $$ref_evenly_squash_to_fit // '(unset)';
            warn sprintf "banner_colour=%s\n", $$ref_banner_colour // '(unset)';
            warn sprintf "banner_font=%s\n", $$ref_banner_font // '(unset)';
            warn sprintf "banner_scale=%.2f%%\n", $$ref_banner_scale * 100;

            warn sprintf "fontname=%s\n", $$ref_fontname // '(unset)';
            warn sprintf "fontsize=%.3fmm, line_spacing=%.2f%%\n", $$ref_fontsize/mm, $$ref_line_spacing * 100;
            warn sprintf "postcode_fontsize=%.3fmm\n", $$ref_postcode_fontsize/mm;

            warn sprintf "printable label area = %.3fmm×%.3fmm (w×h)\n", $printable_label_width/mm, $printable_label_height/mm;

            warn sprintf "horizontal ratio %.3fmm/%.3fmm=%.2f%%\n",
                        $printable_label_width/mm, $printing_label_width/mm,
                        $printable_label_width / $printing_label_width * 100
                if $printable_label_width != $printing_label_width;
            for my $lineno ( 0 .. $#lines ) {
                my $l = $lines[$lineno];
                my $w = $text->advancewidth($l) || next;
                warn sprintf " = line #%d ratio %.3fmm/%.3fmm=%.2f%% [%s]\n",
                        $lineno,
                        $printable_label_width/mm, $w/mm,
                        $printable_label_width / $w * 100, $l;
            }
            warn sprintf "vertical ratio %.3fmm/%.3fmm=%.2f%%\n",
                        $printable_label_height/mm, $printing_label_height/mm,
                        $printable_label_height / $printing_label_height * 100
                if $printable_label_height != $printing_label_height;
            warn sprintf "SQUASHED; ratio=%.2f%%, active font size now %.3fmm\n", $squash_ratio * 100, $active_fontsize/mm;
        }
    }

    if (my $p = $r->{banner}) {
        if (my @v = $p =~ m/\%\{(\w+)\}/g) {
            warn "format '$p' keys [@v]\n" . Dumper($r) if $verbose > 2;
            $p =~ s/\%\{(\w+)\}/%/g;
            $p = sprintf $p, @$r{@v};
        }
        $active_fontsize = min $active_fontsize,
                               $$ref_printable_height / ($$ref_banner_scale * $$ref_line_spacing + @lines * $$ref_line_spacing);

        my $banner_fontsize = $active_fontsize*$$ref_banner_scale;
        $pq->font( $$ref_banner_font, $current_fontsize = $banner_fontsize ) if $banner_fontsize != $current_fontsize;
        $text->translate( $left, $top -= $banner_fontsize*$$ref_line_spacing );
        $text->text($p);
    }

    if (@lines) {
        for (0 .. $#lines) {
            $pq->font( $$ref_fontname, $current_fontsize = $active_fontsize ) if $active_fontsize != $current_fontsize;
            my $rescale = $$ref_printable_width / $text->advancewidth($_);
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
        $text->translate( $left + $$ref_printable_width,
                          $top - $$ref_printable_height + $$ref_postcode_fontsize );
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
