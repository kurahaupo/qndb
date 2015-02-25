#!/module/for/perl

################################################################################
#
# Manage the PDF pagination separately from the list-rendering
#
# (the text cursor is per-page, so make sure we get a fresh one for each page)
#

use 5.010;
use strict;
use warnings;
use utf8;

package PDF::paginator;

use Carp 'croak';
use verbose;
use PDF::scale_factors;

sub _unmethod {
    ref $_[0] && UNIVERSAL::isa( $_[0], __PACKAGE__ ) && shift;
}

sub new {
    my $class = shift;
    my $p = bless { @_ }, $class;
    warn "Next Page\n" if $verbose;
    $p->_startpage;
    $p->pdf->preferences(-twocolumnright => 1);
    return $p;
}

sub pdf {
    my $p = shift;
    $p->{pdf} ||= PDF::API2->new(@_)
}

sub _startpage {
    my $p = shift;
    my $pdf = $p->pdf;
    warn "Next Page\n" if $verbose;
    my $page = $p->{page} = $pdf->page(@_);
    $page->mediabox(@{ $p->{page_size} });
    ( undef, undef, $p->{page_width}, $p->{page_height} ) = $page->get_mediabox();
    $p->{page_item_num} = 0;
    if (my $cb = $p->{upon_start_page}) {
        my $pagenum = $pdf->pages || 0;
        if (ref $cb eq 'CODE') {
            $cb->($p, $pagenum);
        } else {
            for my $cc (@$cb) {
                $cc->($p, $pagenum);
            }
        }
    }
}

sub pagenum {
    my $p = shift;
    $p->_startpage if ! $p->{page};
    my $pdf = $p->pdf;
    $pdf->pages || 0;
}

# get the current page (starting a new page if necessary)
sub page {
    my $p = shift;
    $p->_startpage if ! $p->{page};
    $p->{page};
}

# close the current page, so that the next call to "page" will start a new page
sub closepage {
    my $p = shift;
    $p->{page} or return;  # no current page
    if (my $cb = $p->{upon_end_page}) {
        my $pagenum = $p->pdf->pages || 0;
        if (ref $cb eq 'CODE') {
            $cb->($p, $pagenum);
        } else {
            for my $cc (@$cb) {
                $cc->($p, $pagenum);
            }
        }
    }
    delete $p->{text};
    delete $p->{page};
    delete $p->{pagedata};
}

# get the "text" attribute of the current page (starting a new page if necessary)
sub text {
    my $p = shift;
    $p->{text} ||= $p->page->text();
}

sub corefont {
    my $p = shift;
    my $name = shift;
    $p->{fontcache}{$name} ||= $p->pdf->corefont($name);
}

sub pages {
    my $p = shift;
    $p->pdf->pages || 0
}

sub stringify {
    my $p = shift;
    my $pdf = $p->{pdf} or return;
    $p->closepage;
    my $r = $pdf->stringify;
    %$p = ();
    return $r;
}

#sub write_into {
#    my $p = shift;
#    my $filename = shift;
#    my $pdf = $p->{pdf} or return;
#    $p->closepage;
#    my $r = $pdf->saveas($filename);
#    %$p = ();
#    return $r;
#}

sub _qm($) {
    &_unmethod;
    my $v = $_[0];
    state $qm = {
            map { ( eval("\"\\$_\"") => "\\$_" ) }
                qw{ \ " ' 0 a b e f l n o r t u z } # also: \cC \x{} \N{} \Q..\E \L..\E \U..\E
        };
    $v =~ s{[\\\n\t'"]}{$qm->{$&} // sprintf '\\x%.02x', ord($&)}egr;
}

########################################
# Font notes from:
#
#   https://en.wikipedia.org/wiki/Portable_Document_Format#Standard_Type_1_Fonts_.28Standard_14_Fonts.29
#   Standard Type 1 Fonts (Standard 14 Fonts)
#
#   Fourteen typefaces, known as the standard 14 fonts, have a special
#   significance in PDF documents:
#
#       Times (v3) (in regular, italic, bold, and bold italic)
#       Courier (in regular, oblique, bold and bold oblique)
#       Helvetica (v3) (in regular, oblique, bold and bold oblique)
#       Symbol
#       Zapf Dingbats
#
#   These fonts are sometimes called the base fourteen fonts.[57] These fonts,
#   or suitable substitute fonts with the same metrics, must always be
#   available in all PDF readers and so need not be embedded in a PDF.[58] PDF
#   viewers must know about the metrics of these fonts. Other fonts may be
#   substituted if they are not embedded in a PDF.
#
########################################

my @base_fonts = (
    'Helvetica',
    'Times',
    'Courier',
    'Symbol',
    'Zapf Dingbats',
);
#
# These font variant suffixes only apply to Helvetica & Courier; Times has
# Italic rather than Oblique (see above), while Symbol & Zapf Fingbats have no
# variants.
#

my @font_variants = ( '', '-Bold', '-Oblique', '-BoldOblique', );
my %font_variants = (
        Helvetica => [ undef, 'Helvetica-Bold', 'Helvetica-Oblique', 'Helvetica-BoldOblique' ],
        Times     => [ undef, 'Times-Bold',     'Times-Italic',      'Times-BoldItalic'      ],
        Courier   => [ undef, 'Courier-Bold',   'Courier-Oblique',   'Courier-BoldOblique'   ],
    );
sub font_variant($$;$) {
    &_unmethod;
    my ($basefont, $bold, $italic) = @_;
    my $variation = ( ( $bold || 0 ) | ( $italic ? 2 : 0 ) ) & 3;
    my $f = $font_variants{$basefont};
    return $f && $f->[$variation] || $basefont;
}

use constant {
        b_Bold      => 1,
        b_Italic    => 2,
        b_Underline => 4,
        b_scale     => 8,
    };

sub font {
    my $p = shift;
    my $name = shift;
    my $size = shift;
    my $variation = $_[0] || 0;
    if ( @_ >= 2 ) {
        $variation = 0;
        $variation |= b_Bold   if $_[0];
        $variation |= b_Italic if $_[1];
    }
    $p->text->font($p->corefont($name),$size);
}

########################################
#
#** on hijacking the Unicode Variant Selectors **
#
#   To achieve some basic text flow, we
#
#   According to the Unicode Consortium, the 16 codepoints \ufe00..\ufe0f
#   should act as suffixes to amend the glyph of the preceeding codepoint.
#
#   Instead we use them as a bit-mask to set the Bold, Italic and Underline
#   attributes; note that this only applies to the text_flow and text_size
#   methods; the text_at method does not support in-text variant selection.
#
#   Having used 8 of the 16 codes, we currently we have 1 spare bit.
#
#   In the future this might change, and they'll just code directly for the 14
#   base fonts, with underline encoded elsewhere.
#
#   Or we could instead pick a random high private-use range such as
#   \ue0000..\ue001f
#
########################################

use constant {
        b_ord       => 0xfe00,
    };

use constant {
        TN   => pack('U', b_ord),
        TB   => pack('U', b_ord | b_Bold),
        TI   => pack('U', b_ord | b_Italic),
        TBI  => pack('U', b_ord | b_Bold | b_Italic),
        TU   => pack('U', b_ord | b_Underline),
        TBU  => pack('U', b_ord | b_Bold | b_Underline),
        TIU  => pack('U', b_ord | b_Italic | b_Underline),
        TBIU => pack('U', b_ord | b_Bold | b_Italic | b_Underline),
    };

use constant {
        TIB  => TBI,
        TBUI => TBIU,
        TIBU => TBIU,
        TIUB => TBIU,
        TUBI => TBIU,
        TUIB => TBIU,
        TUB  => TBU,
        TUI  => TIU,
    };

our $TRE = qr/[\x{fe00}-\x{fe0f}]/;

#
# Assuming no height bound, how much space would a given chunk of text take,
# if it were given to text_flow (below)?
#

sub text_size($$$$$;$) {
    my ($pq, $fontname, $fontsize, $line_spacing, $str, $width_limit, $col, $v_off) = @_;
    my $lineheight = $fontsize*$line_spacing;
    $str or do {
        warn sprintf "TEXTSIZE text=[%s] font=%.2fmm -> size=(↔%.2fmm,↕%.2fmm) (1 empty line)\n",
                    _qm $str, $fontsize/mm,
                    0, $lineheight/mm,
            if $verbose > 3;
        return 0, $lineheight, 0, 0;
    };
    flush STDERR;
    my $fontstyle = 0;
    my $text = $pq->text;
    my $lines = 1;
    my $width = 0;
    $col //= 0;
    $v_off //= 0;
    $pq->font( $fontname.$font_variants[$fontstyle], $fontsize );
    PART: for ( my @parts = split /(\n|$TRE)/, $str ; @parts ;) {
        my $part = shift @parts;
        $part eq '' and next PART;
        if ( $part eq "\n" ) {
            warn sprintf "TEXTSIZE newline ending line %u at column %.2fmm\n", $lines, $col/mm if $verbose > 3;
            $width >= $col or $width = $col;
            ++$lines;
            $col = 0;
            next PART;
        }
        if ( $part =~ /^$TRE$/ ) {
            $fontstyle = (ord($part) - b_ord) % @font_variants;
            $pq->font( $fontname.$font_variants[$fontstyle], $fontsize );
            warn sprintf "TEXTSIZE fontstyle %x=%s [%s]\n", $fontstyle, join('-', unpack 'b4', $fontstyle), $fontname.$font_variants[$fontstyle] if $verbose > 3;
            next PART;
        }
        my $part_width = $text->advancewidth($part);
        if ($width_limit) {
            my $t = $part;
            warn sprintf "TEXTSIZE linewrap text=[%s] ↔%.2f/%.2fmm\n", _qm($t), $part_width/mm, ($width_limit-$col)/mm,
                if $verbose > 3 && $part_width > $width_limit-$col;
            while ( $part_width > $width_limit-$col ) {
                $t =~ s#[\N{ZWNJ} ]+[^\N{ZWNJ} ]*$## or $col == 0 ? $t =~ s#.$## : ($t = '') or last;
                $part_width = $text->advancewidth($t);
            }
            if ($t ne '' || $col > 0) {
                (my $u = substr($part, length($t))) =~ s#^[\N{ZWNJ} ]+##;
                $t =~ s#\N{NBSP}# #g;
                warn sprintf "TEXTSIZE wrapdone text=[%s]+[%s] ↔%.2f/%.2fmm\n", _qm($t), _qm($u), $part_width/mm, ($width_limit-$col)/mm,
                    if $verbose > 3 && $u ne '';
                unshift @parts, "\n", "  $u" if $u ne ''; # or @parts && $parts[0] ne "\n";
                $part = $t;
            }
            else {
                warn sprintf "TEXTSIZE cantwrap text=[%s] col=%.2fmm\n", $t, $col/mm if $verbose > 3;
            }
        }
        $col += $part_width;
    }
    $width >= $col or $width = $col;
    my $height = $lines * $lineheight + $v_off;
    warn sprintf "TEXTSIZE text=[%s] font=%.2fmm -> size=(↔%.2fmm,↕%.2fmm) (%u lines) return=(↔%.2fmm,↕%.2fmm)\n",
            _qm $str, $fontsize/mm,
            $width/mm, $lines * $lineheight/mm, $lines,
            $col/mm, ($height - $lineheight)/mm,
        if $verbose > 3;
    return $width, $height, $col, $height - $lineheight;
}

#
# Flow lines of text into a box; returns the width & height (same as text_size)
#

sub text_flow($$$$$$$$;$) {
    my ($pq, $fontname, $fontsize, $line_spacing, $str, $width_limit, $top, $left, $col, $v_off) = @_;
    $#_ == 7 or croak "text_flow: wrong number of args";
    my $lineheight = $fontsize*$line_spacing;
    $str or do {
        warn sprintf "TEXTFLOW text=[%s] font=%.2fmm -> size=(↔%.2fmm,↕%.2fmm) (1 empty line)\n",
                    _qm $str, $fontsize/mm,
                    0, $lineheight/mm,
            if $verbose > 3;
        return 0, $lineheight;
    };
    flush STDERR;
    my $fontstyle = 0;
    my $underline = 0;
    my $text = $pq->text;
    my $lines = 1;
    my $ypos = $top - $lineheight;
    my $width = 0;
    $col //= 0;
    $pq->font( $fontname.$font_variants[$fontstyle], $fontsize );
    warn sprintf "TEXTFLOW position  →%.2fmm,↑%.2fmm\n",
            $left/mm, $ypos/mm,
        if $verbose > 3;
    $text->translate( $left, $ypos );

    PART: for ( my @parts = split /(\n|$TRE)/, $str ; @parts ;) {
        my $part = shift @parts;
        $part eq '' and next PART;
        if ( $part eq "\n" ) {
            warn sprintf "TEXTFLOW newline ending line %u at column %.2fmm\n", $lines, $col/mm if $verbose > 3;
            $width >= $col or $width = $col;
            ++$lines;
            $ypos -= $lineheight;
            $col = 0;
            warn sprintf "TEXTFLOW position →%.2fmm,↑%.2fmm\n",
                    $left/mm, ($ypos)/mm,
                if $verbose > 3;
            $text->translate( $left, $ypos );
            next PART;
        }
        if ( $part =~ /^$TRE$/ ) {
            $fontstyle = (ord($part) - b_ord);
            $underline = $fontstyle & b_Underline;
            $fontstyle %= @font_variants;
            my $xfontname = $fontname.$font_variants[$fontstyle];
            $pq->font( $xfontname, $fontsize );
            warn sprintf "TEXTFLOW fontstyle %x=%s [%s]\n", $fontstyle, join('-', unpack 'b4', $fontstyle), $xfontname if $verbose > 3;
            next PART;
        }
        my $part_width = $text->advancewidth($part);
        if ($width_limit) {
            my $t = $part;
            warn sprintf "TEXTFLOW linewrap text=[%s] ↔%.2f/%.2fmm\n", _qm($t), $part_width/mm, ($width_limit-$col)/mm,
                if $verbose > 3 && $part_width > $width_limit-$col;
            while ( $part_width > $width_limit-$col ) {
                $t =~ s#[\N{ZWNJ} ]+[^\N{ZWNJ} ]*$## or $col == 0 ? $t =~ s#.$## : ($t = '') or last;
                $part_width = $text->advancewidth($t);
            }
            if ($t ne '' || $col > 0) {
                (my $u = substr($part, length($t))) =~ s#^[\N{ZWNJ} ]+##;
                $t =~ s#\N{NBSP}# #g;
                warn sprintf "TEXTFLOW wrapdone text=[%s]+[%s] ↔%.2f/%.2fmm\n", _qm($t), _qm($u), $part_width/mm, ($width_limit-$col)/mm,
                    if $verbose > 3 && $u ne '';
                unshift @parts, "\n", "  $u" if $u ne ''; # or @parts && $parts[0] ne "\n";
                $part = $t;
            }
            else {
                warn sprintf "TEXTFLOW cantwrap text=[%s] col=%.2fmm\n", $t, $col/mm if $verbose > 3;
            }
        }
        $text->text($part, $underline ? ( -underline => 'auto' ) : ());
        $col += $part_width;
    }
    $width >= $col or $width = $col;
    warn sprintf "TEXTFLOW text=[%s] font=%.2fmm pos=(→%.2fmm,↑%.2fmm) -> size=(↔%.2fmm,↕%.2fmm) (%u lines) return=(↔%.2fmm,↕%.2fmm)\n",
                _qm $str, $fontsize/mm,
                $left/mm, $top/mm,
                $width/mm, ($ypos - $top)/mm,
                $lines,
                $col/mm, ($lines > 1 && $top - $ypos - $lineheight)/mm,
        if $verbose > 3;
    return $width, $top - $ypos, $col, $lines > 1 && $top - $ypos - $lineheight;
}

#
# $pq->text_at("text", \%opts)
#
# Write a single line of text with full control, including box alignment, orientation, font style
# (attempt to arrange so that the top/left is not overlapped -- hopefully)
#
# + The text to be written must be given
#
# + The font & font-size must be given
#
# + Rotation if given is anticlockwise, and may be given in quadrants (r),
#   degrees (r°) or radians (rr); defaults to 0°.
#
# + X and Y positions must be given, and the text may be aligned below,
#   centred-on or above the y-position, and right-of, centred-on or left-of the
#   x-position. (If the text is not orthogonal, the diagonal points are used.)
#

use math_constants 'PI';
use list_functions qw{ min max sum };

#my @styleopts = qw{ bold italic };
sub text_at($$%) {
    my $pq = shift;
    my $str = shift;
    my $opts = @_ == 1 && ref $_[0] ? shift @_ : { @_ };

    $str =~ /\n|$TRE/ and croak "text_at does not support multiline or multifont text";

    defined $str && $str ne '' or do {
        warn sprintf "TEXT_AT (empty)\n" if $verbose > 3;
        return;
    };

    my $xpoint      = $opts->{x}                // croak "Missing x";
    my $ypoint      = $opts->{y}                // croak "Missing y";
    my $fontname    = $opts->{fontname}         //
                      $opts->{fn}               //
                        croak "Missing fontname";
    my $fontsize    = $opts->{fontsize}         //
                      $opts->{fs}               //
                        croak "Missing fontsize";
    my $fontstyle   = $opts->{fontstyle}        //
                        ( $opts->{bold} ? 1 : 0 ) | ( $opts->{italic} ? 2 : 0 );
    my $underline   = $opts->{underline} //
                        ($fontstyle >> 2 & 1);
    $fontstyle &= 3;

    my $halign      = $opts->{halign}           // 0;   # default to left (all parts of the text must be right of the specified position)
    my $valign      = $opts->{valign}           // 0;   # default to top (all parts of the text must be below the specified position)

    my $rotation    = $opts->{pi_rotation}      //      # rotation in radians [0..2π]
                      $opts->{rr}               //
                      ( $opts->{quad_rotation}  //      # rotation in quadrants [0..4]
                        $opts->{r}              //
                        ( $opts->{'r°'}         //
                          $opts->{deg_rotation} //      # rotation in degrees [0..360]
                          0                             # default to standard orientation
                        ) / 90                          # convert degrees to quadrants
                      ) / 2 * PI;                       # convert quadrants to radians

    # benchmarking (on an Intel x86_64 T7200) indicates that a ?: is around 5
    # times faster than trig, so this is usually a win
    my $sin = $rotation ? sin($rotation) : 0;
    my $cos = $rotation ? cos($rotation) : 1;

#   flush STDERR;
    $fontstyle //= 0;
    $fontname .= $font_variants[$fontstyle];
    $pq->font( $fontname, $fontsize );

    my $text = $pq->text;
    my $width = $text->advancewidth($str);
    my $height = $fontsize;

    my $bl_x_off = 0;
    my $bl_y_off = 0;
    my $tl_x_off = $height * -$sin;
    my $tl_y_off = $height *  $cos;
    my $br_x_off = $width  *  $cos;
    my $br_y_off = $width  *  $sin;
    my $tr_x_off = $tl_x_off + $br_x_off;
    my $tr_y_off = $tl_y_off + $br_y_off;

    my $l_off = min $bl_x_off, $br_x_off, $tl_x_off, $tr_x_off;
    my $r_off = max $bl_x_off, $br_x_off, $tl_x_off, $tr_x_off;
    my $t_off = max $bl_y_off, $br_y_off, $tl_y_off, $tr_y_off;
    my $b_off = min $bl_y_off, $br_y_off, $tl_y_off, $tr_y_off;

    my $xpos = $xpoint - ( $halign == 0 ? $l_off : $halign == 2 ? $r_off : ($l_off+$r_off)/2 );
    my $ypos = $ypoint - ( $valign == 0 ? $t_off : $valign == 2 ? $b_off : ($t_off+$b_off)/2 );

    warn sprintf "TEXT_AT text=[%s] font=(size=%.2fmm,style=%u) :: refpoint=(→%.2fmm,↑%.2fmm) rotation=%.0f° align=(%s) -> origin=(→%.2fmm,↑%.2fmm) bound=(t=%.2fmm,b=%.2fmm,l=%.2ffm,r=%.2fmm)\n",
                _qm $str,
                $fontsize/mm, $fontstyle,
                $xpoint/mm, $ypoint/mm,
                $rotation / PI * 180,
                [['┌','┬','┐'],
                 ['├','┼','┤'],
                 ['└','┴','┘'],]->[$valign][$halign],   #substr('╔╦╗╠╬╣╚╩╝', $valign*3+$halign, 1),
                $xpos/mm, $ypos/mm,
                $ypoint-$t_off, $ypoint-$b_off,
                $xpoint-$l_off, $xpoint-$r_off,
                ($ypos - $ypoint)/mm,
        if $verbose > 3;

    $text->transform(
        -translate => [$xpos, $ypos],
        -rotate    => $rotation / PI * 180,
      # -scale     => [$sx, $sy],
      # -skew      => [$sa, $sb],
    );

    $text->text($str, $underline ? (-underline => 'auto') : ());

    return ();
}

#sub DESTROY { }
1;
