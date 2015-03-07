#!/module/for/perl

package PDF::stash;

use 5.010;
use strict;
use warnings;
use utf8;


use Carp 'croak';
use verbose;
use PDF::scale_factors;

sub new {
    my $class = shift;
    my $pq = shift;
    bless { pq => $pq, e => [], w => 0, h => 0, margins => [], style => 0, @_ }, $class;
}

sub size {
    my $tt = shift;
    return $tt->{h} if !wantarray;
    return $tt->{h}, $tt->{w}; # @{$tt->{margins}};
}

sub at {
    my ($tt, $y_pos, $x_pos) = @_;
    for my $e ( @{ $tt->{e} } ) {
        my ($str, $font, $size, $style, $yoff, $xoff, $yscale, $xscale) = @$e;
        $xoff += $x_pos;
        $yoff += $y_pos;
        # TODO finish this
        die "UNIMPLEMENTED";
    }
    return my ($h, $w, $t, $b, $l, $r);
}

sub flow {
    my ($tt, $str, $fmt, $loc) = @_;
    my $pq = $tt->{pq};

    # TODO finish this
    die "UNIMPLEMENTED";

#   my ($pq, $fontname, $fontsize, $line_spacing, $str, $width_limit, $top, $left, $col, $v_off) = @_;
#   $#_ == 7 or croak "text_flow: wrong number of args";
#   my $lineheight = $fontsize*$line_spacing;
#   $str or do {
#       warn sprintf "TEXTFLOW text=[%s] font=%.2fmm -> size=(↔%.2fmm,↕%.2fmm) (1 empty line)\n",
#                   _qm $str, $fontsize/mm,
#                   0, $lineheight/mm,
#           if $verbose > 3;
#       return 0, $lineheight;
#   };
#   flush STDERR;
#   my $fontstyle = 0;
#   my $underline = 0;
#   my $text = $pq->text;
#   my $lines = 1;
#   my $ypos = $top - $lineheight;
#   my $width = 0;
#   $col //= 0;
#   $pq->font( $fontname.$font_variants[$fontstyle], $fontsize );
#   warn sprintf "TEXTFLOW position  →%.2fmm,↑%.2fmm\n",
#           $left/mm, $ypos/mm,
#       if $verbose > 3;
#   $text->translate( $left, $ypos );
#
#   PART: for ( my @parts = split /(\n|$TRE)/, $str ; @parts ;) {
#       my $part = shift @parts;
#       $part eq '' and next PART;
#       if ( $part eq "\n" ) {
#           warn sprintf "TEXTFLOW newline ending line %u at column %.2fmm\n", $lines, $col/mm if $verbose > 3;
#           $width >= $col or $width = $col;
#           ++$lines;
#           $ypos -= $lineheight;
#           $col = 0;
#           warn sprintf "TEXTFLOW position →%.2fmm,↑%.2fmm\n",
#                   $left/mm, ($ypos)/mm,
#               if $verbose > 3;
#           $text->translate( $left, $ypos );
#           next PART;
#       }
#       if ( $part =~ /^$TRE$/ ) {
#           $fontstyle = (ord($part) - b_ord);
#           $underline = $fontstyle & b_Underline;
#           $fontstyle %= @font_variants;
#           my $xfontname = $fontname.$font_variants[$fontstyle];
#           $pq->font( $xfontname, $fontsize );
#           warn sprintf "TEXTFLOW fontstyle %x=%s [%s]\n", $fontstyle, join('-', unpack 'b4', $fontstyle), $xfontname if $verbose > 3;
#           next PART;
#       }
#       my $part_width = $text->advancewidth($part);
#       if ($width_limit) {
#           my $t = $part;
#           warn sprintf "TEXTFLOW linewrap text=[%s] ↔%.2f/%.2fmm\n", _qm($t), $part_width/mm, ($width_limit-$col)/mm,
#               if $verbose > 3 && $part_width > $width_limit-$col;
#           while ( $part_width > $width_limit-$col ) {
#               $t =~ s#[\N{ZWNJ} ]+[^\N{ZWNJ} ]*$## or $col == 0 ? $t =~ s#.$## : ($t = '') or last;
#               $part_width = $text->advancewidth($t);
#           }
#           if ($t ne '' || $col > 0) {
#               (my $u = substr($part, length($t))) =~ s#^[\N{ZWNJ} ]+##;
#               $t =~ s#\N{NBSP}# #g;
#               warn sprintf "TEXTFLOW wrapdone text=[%s]+[%s] ↔%.2f/%.2fmm\n", _qm($t), _qm($u), $part_width/mm, ($width_limit-$col)/mm,
#                   if $verbose > 3 && $u ne '';
#               unshift @parts, "\n", "  $u" if $u ne ''; # or @parts && $parts[0] ne "\n";
#               $part = $t;
#           }
#           else {
#               warn sprintf "TEXTFLOW cantwrap text=[%s] col=%.2fmm\n", $t, $col/mm if $verbose > 3;
#           }
#       }
#       $text->text($part, $underline ? ( -underline => 'auto' ) : ());
#       $col += $part_width;
#   }
#   $width >= $col or $width = $col;
#   warn sprintf "TEXTFLOW text=[%s] font=%.2fmm pos=(→%.2fmm,↑%.2fmm) -> size=(↔%.2fmm,↕%.2fmm) (%u lines) return=(↔%.2fmm,↕%.2fmm)\n",
#               _qm $str, $fontsize/mm,
#               $left/mm, $top/mm,
#               $width/mm, ($ypos - $top)/mm,
#               $lines,
#               $col/mm, ($lines > 1 && $top - $ypos - $lineheight)/mm,
#       if $verbose > 3;
#   return $width, $top - $ypos, $col, $lines > 1 && $top - $ypos - $lineheight;
#   return $fmt, $loc;
}

#sub DESTROY { }
1;
