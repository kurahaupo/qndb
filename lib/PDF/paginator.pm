#!/module/for/perl
# vim: set nowrap :

use 5.010;
use strict;
use warnings;
use utf8;

package PDF::paginator;

################################################################################
#
# Manage the PDF pagination separately from the list-rendering
#
# (the text cursor is per-page, so make sure we get a fresh one for each page)
#

use Carp 'croak';
use PDF::API2;

use verbose;
use PDF::scale_factors;

########################################
# Generic PDF output options (shared between labels and book generation)

our $page_size;                 # = 'a4';
our $page_height;               # = 297.302*mm;
our $page_width;                # = 210.224*mm;
                                
our $page_left_margin;          # = 18*mm;
our $page_right_margin;         # = 18*mm;
our $page_bottom_margin;        # = 14*mm;
our $page_top_margin;           # = 14*mm;

our $line_spacing = 1.25;       # ratio of font-size to line-pitch

my $baseline_adjust = 0;        # range approx -0.4 to 0

our $extra_para_spacing = 0.25; # used between records in book format

our $paper_sizes = {
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
    };

use export qw( $page_size $page_height $page_width $page_left_margin
               $page_right_margin $page_bottom_margin
               $page_top_margin $line_spacing $extra_para_spacing
               $paper_sizes
             );

########################################

sub use_preset {
    my $pt = pop;

    state $x = warn Dumper($paper_sizes) if $verbose > 4 && $debug;

    state $page_product = {
        ( map { ( $_     => { page_size => $_,     page_height => $paper_sizes->{$_}->[0], page_width => $paper_sizes->{$_}->[1], } ) } keys %$paper_sizes ),
        ( map { ( $_.'R' => { page_size => $_.'R', page_height => $paper_sizes->{$_}->[1], page_width => $paper_sizes->{$_}->[0], } ) } keys %$paper_sizes ),

        'book' => {
                page_size          => 'a5',
              # page_height        => 210.224*mm,
              # page_width         => 148.651*mm,

                page_left_margin   => 13*mm,
                page_right_margin  => 13*mm,
                page_bottom_margin => 10*mm,
                page_top_margin    => 10*mm,
            },

        'avery-l7160' => {
                page_size            => 'a4',
                page_height          => 297.302*mm,
                page_width           => 210.224*mm,
                page_top_margin      => 17.0*mm, label_top_margin     =>  1.5*mm,
                page_bottom_margin   => 13.0*mm, label_bottom_margin  =>  1.5*mm,
                page_left_margin     =>  5.0*mm, label_left_margin    =>  5.7*mm,
                page_right_margin    =>  6.0*mm, label_right_margin   =>  7.7*mm,
            },
        };

    state $y = warn Dumper($page_product) if $verbose > 4 && $debug;

    my $p = $page_product->{$pt} || return; #die "Unknown label or paper product '$pt'\nAvailable presets are @{[sort keys %$page_product]}\n";
    (
        $page_size, $page_height, $page_width,
        $page_top_margin, $page_bottom_margin, $page_left_margin, $page_right_margin,
    ) = @$p{qw{
        page_size page_height page_width
        page_top_margin page_bottom_margin page_left_margin page_right_margin
    }};
}

use run_options (
    'A=i'                 => sub { $page_size = $_[0].$_[1]; $page_width = $page_height = undef },  #A4 etc
    'B=i'                 => sub { $page_size = $_[0].$_[1]; $page_width = $page_height = undef },  #B4 etc
   '%page-height|ph=s'    => sub { $page_size = undef; $page_height = pop },
    'page-size=s'         => sub { $page_size = pop; $page_width = $page_height = undef },  #A4, B3, etc
   '%page-width|pw=s'     => sub { $page_size = undef; $page_width  = pop },

   '+preset=s'            => \&use_preset,
);

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

# get the "gfx" attribute of the current page (starting a new page if necessary)
sub gfx {
    my $p = shift;
    $p->{gfx} ||= $p->page->gfx();
}

# get the "text" attribute of the current page (starting a new page if necessary)
sub text {
    my $p = shift;
    $p->{text} ||= $p->page->text();
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
# Italic rather than Oblique (see above), while Symbol & Zapf Dingbats have no
# variants.
#

my @font_variants = ( '', '-Bold', '-Oblique', '-BoldOblique', );
my %font_variants = (
        Helvetica => [ undef, 'Helvetica-Bold', 'Helvetica-Oblique', 'Helvetica-BoldOblique' ],
        Times     => [ undef, 'Times-Bold',     'Times-Italic',      'Times-BoldItalic'      ],
        Courier   => [ undef, 'Courier-Bold',   'Courier-Oblique',   'Courier-BoldOblique'   ],
    );

use constant {
        b_Bold      => 1,
        b_Italic    => 2,
        b_Underline => 4,
        b_scale     => 8,
    };

sub font($$$$;$) {
    my $pq = shift;
    my $basefont = shift;
    my $size = shift;
    my $variation = $_[0] || 0;
    if ( @_ >= 2 ) {
        $variation = 0;
        $variation |= b_Bold   if $_[0];
        $variation |= b_Italic if $_[1];
    }
    my $fv = $font_variants{$basefont};
    my $name = $fv && $fv->[$variation] || $basefont;
    my $f = $pq->{fontcache}{$name} ||= $pq->pdf->corefont($name);
    $pq->text->font($f,$size);
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

    my $color       = $opts->{color} // 0;

    my $max_width   = $opts->{maxw};
    my $max_height  = $opts->{maxh};

    my $xscale      = $opts->{xscale};
    my $yscale      = $opts->{yscale};

  # my $skew_x      = $opts->{skew_x} // 0;
  # my $skew_y      = $opts->{skew_y} // 0;

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

    $xscale ||= $max_width  && $max_width  < $width  ? $max_width  / $width  : 1;
    $yscale ||= $max_height && $max_height < $height ? $max_height / $height : 1;

    $width  *= $xscale;
    $height *= $yscale;

    my $bl_x_off = $baseline_adjust * $height * -$sin;
    my $bl_y_off = $baseline_adjust * $height *  $cos;
    my $tl_x_off = $height * -$sin + $bl_x_off;
    my $tl_y_off = $height *  $cos + $bl_y_off;
    my $br_x_off = $width  *  $cos + $bl_x_off;
    my $br_y_off = $width  *  $sin + $bl_y_off;
    my $tr_x_off = $tl_x_off + $br_x_off - $bl_x_off;
    my $tr_y_off = $tl_y_off + $br_y_off - $bl_y_off;

    my $l_off = min $bl_x_off, $br_x_off, $tl_x_off, $tr_x_off;
    my $r_off = max $bl_x_off, $br_x_off, $tl_x_off, $tr_x_off;
    my $t_off = max $bl_y_off, $br_y_off, $tl_y_off, $tr_y_off;
    my $b_off = min $bl_y_off, $br_y_off, $tl_y_off, $tr_y_off;

    my $xpos = $xpoint - ( $halign == 0 ? $l_off : $halign == 2 ? $r_off : ($l_off+$r_off)/2 );
    my $ypos = $ypoint - ( $valign == 0 ? $t_off : $valign == 2 ? $b_off : ($t_off+$b_off)/2 );

    warn sprintf "TEXT_AT text=[%s] font=(size=%.2fmm,style=%u) :: scale=(%.2fち%.2f) refpoint=(→%.2fmm,↑%.2fmm) rotation=%.0f° align=(%s) -> origin=(→%.2fmm,↑%.2fmm) bound=(t=%.2fmm,b=%.2fmm,l=%.2ffm,r=%.2fmm)\n",
                _qm $str,
                $fontsize/mm, $fontstyle,
                $xscale, $yscale,
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

  # $text->translate($xpos, $ypos);
    $text->transform(
        -translate => [$xpos, $ypos],
        -rotate    => $rotation / PI * 180,
        -scale     => [$xscale, $yscale],
      # -skew      => [$skew_x, $skew_y],
    );
    $text->fillcolor($color) if defined $color;

    $text->text($str, $underline ? (-underline => 'auto') : ());

    return ();
}

#
# Given a chunk of text, convert it into a list of [text, font, style, offset]
# elements, which can be incrementally added to, for size, and rendered at a
# particular position.
#
# $pq->flow("Hello", { w => 20*mm })->bold->flow("Bye")->normal->
#

sub flow($$$$) {
    my $pq = shift;
    require PDF::stash::;
    my $t = new PDF::stash:: ($pq);
    $t = $t->flow(@_) if @_;
    return $t;
}

#sub DESTROY { }
1;
