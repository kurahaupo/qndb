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

our $ttf_dir = '/usr/share/fonts/truetype/';
our $ttf_suffix = '.ttf';

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

sub set_next_page_number {
    my $p = shift;
    $p->{next_page_number} = (shift // 1);
}

sub _startpage {
    my $p = shift;
    my $pdf = $p->pdf;
    warn "Next Page\n" if $verbose;
    my $page = $p->{page} = $pdf->page(@_);
    my $pagenum = $p->{next_page_number};
    $page->mediabox(@{ $p->{page_size} });
    ( undef, undef, $p->{page_width}, $p->{page_height} ) = $page->get_mediabox();
    $p->{page_item_num} = 0;
    if (my $cb = $p->{upon_start_page}) {
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
    my $page = $p->{page} or return;  # no current page
    $p->{next_page_number};
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
    my $page = $p->{page} or return;  # no current page
    my $pagenum = $p->{next_page_number}++;
    if (my $cb = $p->{upon_end_page}) {
        #my $pagenum = $p->pdf->pages || 0;
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
#   https://en.wikipedia.org/wiki/PDF#Text
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
#   available in all PDF readers and so need not be embedded in a PDF.
#   PDF viewers must know about the metrics of these fonts.
#   Other fonts may be substituted if they are not embedded in a PDF.
#
########################################

# The "standard 14" type faces only include codepoints from ISO-8859-1 (the
# lowest 256 from ISO-10646/Unicode), so we add support for embeddable TrueType
# fonts as well.

use constant {
    b_Bold      => 1,
    b_Italic    => 2,
#   b_Monospace => 4,
    b_Underline => 8,
};

my %font_info;

{
package PDF::paginator::font_info_ ;

sub fd($$) {
    my ($prefix, $plain, $bold, $italic) = ('-', '', @_);
    [ $plain                      ? $prefix . $plain           : '',
      defined( $bold            ) ? $prefix . $bold            : undef,
      defined( $italic          ) ? $prefix . $plain . $italic : undef,
      defined( $bold && $italic ) ? $prefix . $bold . $italic  : undef ]
}

sub fd6($$$) {
    my ($prefix, $plain, $bold, $italic, $italic2) = ('-', '', @_);
    [ $plain                      ? $prefix . $plain           : '',
      defined( $bold            ) ? $prefix . $bold            : undef,
      defined( $italic          ) ? $prefix . $plain . $italic : undef,
      defined( $bold && $italic ) ? $prefix . $bold . $italic  : undef,
      defined( $italic2          ) ? $prefix . $plain . $italic2 : undef,
      defined( $bold && $italic2 ) ? $prefix . $bold . $italic2  : undef,
    ]
}

sub fda($$$) {
    my ($prefix, $plain, $bold, $italic, $plain_alt) = ('-', '', @_);
    $plain_alt //= $plain;
    [ $plain_alt                  ? $prefix . $plain_alt       : '',
      defined( $bold            ) ? $prefix . $bold            : undef,
      defined( $italic          ) ? $prefix . $plain . $italic : undef,
      defined( $bold && $italic ) ? $prefix . $bold . $italic  : undef ]
}

sub f0a($$$) {
    my ($prefix, $plain, $bold, $italic, $plain_alt) = ('', '', @_);
    $plain_alt //= $plain;
    $prefix //= '';
    [ $plain_alt                  ? $prefix . $plain_alt       : '',
      defined( $bold            ) ? $prefix . $bold            : undef,
      defined( $italic          ) ? $prefix . $plain . $italic : undef,
      defined( $bold && $italic ) ? $prefix . $bold . $italic  : undef ]
}

sub f0($$$) {
    my ($prefix, $plain, $bold, $italic) = ('', @_);
    $prefix //= '';
    [ $plain                      ? $prefix . $plain           : '',
      defined( $bold            ) ? $prefix . $bold            : undef,
      defined( $italic          ) ? $prefix . $plain . $italic : undef,
      defined( $bold && $italic ) ? $prefix . $bold . $italic  : undef ]
}

sub fv($$$$) {
    my ($prefix, $plain, $bold, $italic) = @_;
    $prefix //= '';
    [ $plain                      ? $prefix . $plain           : '',
      defined( $bold            ) ? $prefix . $bold            : undef,
      defined( $italic          ) ? $prefix . $plain . $italic : undef,
      defined( $bold && $italic ) ? $prefix . $bold . $italic  : undef ]
}

# D - dash
# N - nodash
# U - underscore
# UU - underscore before each part, so _Italic_Bold
# q - 'R' or 'Regular for plain but not when italic/oblique
# b - bold
# i - italic
# o - oblique
# 1 - single letter (R rather than Regular)
# l - lowercase (italic rather than Italic)

# with leading dash that's suppressed on empty

sub Dbi()    { return vs => fd( 'Bold', 'Italic' ),                   'path'; }
sub Dbio()   { return vs => fd6( 'Bold', 'Italic', 'Oblique' ),       'path'; }
sub Dqbi()   { return vs => fda( 'Bold', 'Italic', 'Regular' ),       'path'; }     # like bold+italic, except with "-Regular" instead of empty
sub DqbiM()  { return vs => fda( 'Bold', 'Italic', 'Regular' ), mono => 1, 'path'; } # like bold+italic, except with "-Regular" instead of empty
sub Dbo()    { return vs => fd( 'Bold', 'Oblique' ),                  'path'; }
sub DboM()   { return vs => fd( 'Bold', 'Oblique' ),       mono => 1, 'path'; }
sub Dbx()    { return vs => fd( 'Bold', undef ),                      'path'; }

# no separating punctuation before the suffix

sub NxM()    { return vs => [ '' ],                         mono => 1,  'path'; }
sub Nx()     { return vs => [ '' ], 'path'; }
sub Nxi1()   { return vs => [ '', undef, 'I', undef ],                  'path'; }   # I but no B; no '-' before suffix
sub Nxo()    { return vs => [ '', undef, 'Oblique', undef ],            'path'; }   # Oblique but no Bold; no '-' before suffix
sub Nrdo()   { return vs => [ '', undef, 'Oblique', undef ],            'path'; }   # Oblique but no Bold; no '-' before suffix
sub Nbxl2()  { return vs => f0( '', '-bold', undef ),                   'path'; }   # bold but no italic/oblique; no '-' before suffix
sub Nbi()    { return vs => f0( '', 'Bold', 'Italic' ),                 'path'; }   # like regular Bold+Italic but no '-' before suffix
sub Nbo()    { return vs => f0( '', 'Bold', 'Oblique' ),                'path'; }   # ; Bold; Oblique; Bold+Oblique
sub NboM()   { return vs => f0( '', 'Bold', 'Oblique' ),     mono => 1, 'path'; }   # like regular Bold+Oblique but no '-' before suffix
sub Nbx()    { return vs => f0( '', 'Bold', undef ),                    'path'; }   # Bold but no italic/oblique; no '-' before suffix
sub Nbxl()   { return vs => f0( '', 'bold', undef ),                    'path'; }   # bold but no italic/oblique; no '-' before suffix
sub Dbbo()   { return vs => f0( '-Book', '-Bold', 'Oblique' ),          'path'; }   # Book/Bold + Oblique
sub Dbbx()   { return vs => f0( '-Book', '-Bold', undef ),              'path'; }   # Book/Bold but no italic/oblique
sub Dmbi()   { return vs => f0( '-Medium', '-Bold', 'Italic' ),         'path'; }   
sub Dmbo()   { return vs => f0( '-Medium', '-Bold', 'Oblique' ),        'path'; }   
sub Drbi()   { return vs => f0( '-R', '-B', 'I' ),                      'path'; }   # upper-case single letter suffix: R/B + I with '-'
sub DrbiM()  { return vs => f0( '-R', '-B', 'I' ),           mono => 1, 'path'; }   # upper-case single letter suffix: R/B + I with '-'
sub Drbo()   { return vs => f0( '-Regular', '-Bold', 'Oblique' ),       'path'; }   
sub Drbx()   { return vs => f0( '-Regular', '-Bold', undef ),           'path'; }   # no italic/oblique
sub Dnbx()   { return vs => f0( '-n', '-b', undef ),                    'path'; }   # -n; -b; ;  (no italic)
sub Nrbi1l() { return vs => f0( 'r', 'b', 'i' ),                        'path'; }   # lower-case single letter suffix: r/b + i without '-'
sub Nqbi1()  { return vs => f0a( 'B', 'I', 'R' ),                       'path'; }   # single letter suffices, with R instead of empty
sub Nqbi()   { return vs => f0a( 'Bold', 'Italic', 'Regular' ),         'path'; }   # like fNbo but with 'Regular' instead of empty, and without '- before suffix
sub Nqbo()   { return vs => f0a( 'Bold', 'Oblique', 'Regular' ),        'path'; }   # like fNbo but with 'Regular' instead of empty, and without '- before suffix
sub Dxti()   { return vs => f0a( undef, '-i', '-t' ),                   'path'; }   # -t; ; -i;  (no bold)

# with leading underscore (or two)

%font_info = (

    AbyssinicaSIL               => { Nx,      'abyssinica/AbyssinicaSIL-R' },       # (no variants )
    Courier                     => { std14 => 'Courier', DboM, undef },
    DavidCLM                    => { Dmbi,    'culmus/DavidCLM' },
    DejaVuSans                  => { Dbo,     'dejavu/DejaVuSans' },
    DejaVuSansCondensed         => { Dbo,     'dejavu/DejaVuSansCondensed' },
    DejaVuSansExtraLight        => { Nx,      'dejavu/DejaVuSans-ExtraLight' },     # (no variants )
    DejaVuSansMono              => { DboM,    'dejavu/DejaVuSansMono' },
    DejaVuSerif                 => { Dbi,     'dejavu/DejaVuSerif' },
    DejaVuSerifCondensed        => { Dbi,     'dejavu/DejaVuSerifCondensed' },
    DroidNaskh                  => { Drbx,    'droid/DroidNaskh' },                 # -Regular; -Bold
    DroidSans                   => { Dbx,     'droid/DroidSans' },                  # ; -Bold
    DroidSansArmenian           => { Nx,      'droid/DroidSansArmenian' },          # (no variants )
    DroidSansEthiopic           => { Drbx,    'droid/DroidSansEthiopic' },          # -Regular; -Bold
    DroidSansFallbackFull       => { Nx,      'droid/DroidSansFallbackFull' },      # (no variants )
    DroidSansGeorgian           => { Nx,      'droid/DroidSansGeorgian' },          # (no variants )
    DroidSansHebrew             => { Drbx,    'droid/DroidSansHebrew' },            # -Regular; -Bold
    DroidSansJapanese           => { Nx,      'droid/DroidSansJapanese' },          # (no variants )
    DroidSansMono               => { NxM,     'droid/DroidSansMono' },              # (no variants )
    DroidSansThai               => { Nx,      'droid/DroidSansThai' },              # (no variants )
    DroidSerif                  => { Dqbi,    'droid/DroidSerif' },                 # -Regular; -Bold; -Italic; -BoldItalic
    FrankRuehlCLM               => { Dmbo,    'culmus/FrankRuehlCLM' },
    FreeMono                    => { NboM,    'freefont/FreeMono' },                # ; Bold; Oblique; BoldOblique
    FreeSans                    => { Nbo,     'freefont/FreeSans' },                # ; Bold; Oblique; BoldOblique
    FreeSerif                   => { Nbi,     'freefont/FreeSerif' },               # ; Bold; Italic; BoldItalic
    Garuda                      => { Dbo,     'tlwg/Garuda' },                      # ; -Bold; -Oblique; -BoldOblique
    Gen102                      => { path => 'gentium/Gen', vs => [ 'R102', 'AR102', 'I102', 'AI102' ] },   # GenAI102.ttf; GenAR102.ttf; GenI102.ttf; GenR102.ttf
    GenBas                      => { Nqbi1,   'gentium-basic/GenBas' },             # R; B; I; BI
    GenBkBas                    => { Nqbi1,   'gentium-basic/GenBkBas' },           # R; B; I; BI
    HadasimCLM                  => { Drbo,    'culmus/HadasimCLM' },
    Helvetica                   => { std14 => 'Helvetica', Dbo, undef, },
    JamrulNormal                => { Nx,      'ttf-bengali-fonts/JamrulNormal' },   # (no variants )
    KacstArt                    => { Nx,      'kacst/KacstArt' },                   # (no variants )
    KacstBook                   => { Nx,      'kacst/KacstBook' },                  # (no variants )
    KacstDecorative             => { Nx,      'kacst/KacstDecorative' },            # (no variants )
    KacstDigital                => { Nx,      'kacst/KacstDigital' },               # (no variants )
    KacstFarsi                  => { Nx,      'kacst/KacstFarsi' },                 # (no variants )
    KacstLetter                 => { Nx,      'kacst/KacstLetter' },                # (no variants )
    KacstNaskh                  => { Nx,      'kacst/KacstNaskh' },                 # (no variants )
    KacstOffice                 => { Nx,      'kacst/KacstOffice' },                # (no variants )
    KacstOne                    => { Dbx,     'kacst-one/KacstOne' },               # ; -Bold
    KacstPen                    => { Nx,      'kacst/KacstPen' },                   # (no variants )
    KacstPoster                 => { Nx,      'kacst/KacstPoster' },                # (no variants )
    KacstQurn                   => { Nx,      'kacst/KacstQurn' },                  # (no variants )
    KacstScreen                 => { Nx,      'kacst/KacstScreen' },                # (no variants )
    KacstTitle                  => { Nx,      'kacst/KacstTitle' },                 # (no variants )
    KacstTitleL                 => { Nx,      'kacst/KacstTitleL' },                # (no variants )
    KeterYG                     => { Dmbo,    'culmus/KeterYG' },
    KhmerOS                     => { Nx,      'ttf-khmeros-core/KhmerOS' },         # (no variants )
    KhmerOSsys                  => { Nx,      'ttf-khmeros-core/KhmerOSsys' },      # (no variants )
    Kinnari                     => { Dbio,    'tlwg/Kinnari' },                     # ; -Bold; -Italic; -BoldItalic; -Oblique; -BoldOblique (ignore Oblique )
    LiberationMono              => { DqbiM,   'liberation/LiberationMono' },        # -Regular; -Bold; -Italic; -BoldItalic
    LiberationSans              => { Dqbi,    'liberation/LiberationSans' },        # -Regular; -Bold; -Italic; -BoldItalic
    LiberationSansNarrow        => { Dqbi,    'liberation/LiberationSansNarrow' },  # -Regular; -Bold; -Italic; -BoldItalic
    LiberationSerif             => { Dqbi,    'liberation/LiberationSerif' },       # -Regular; -Bold; -Italic; -BoldItalic
    LikhanNormal                => { Nx,      'ttf-bengali-fonts/LikhanNormal' },   # (no variants )
    Loma                        => { Dbo,     'tlwg/Loma' },                        # ; -Bold; -Oblique; -BoldOblique
    Meera_04                    => { Nx,      'ttf-indic-fonts-core/Meera_04' },    # (no variants )
    MgOpenCanonica              => { Nqbi,    'mgopen/MgOpenCanonica' },            # Regular; Bold; Italic; BoldItalic
    MgOpenCosmetica             => { Nqbo,    'mgopen/MgOpenCosmetica' },           # Regular; Bold; Oblique; BoldOblique
    MgOpenModata                => { Nqbo,    'mgopen/MgOpenModata' },              # Regular; Bold; Oblique; BoldOblique
    MgOpenModerna               => { Nqbo,    'mgopen/MgOpenModerna' },             # Regular; Bold; Oblique; BoldOblique
    MiriamCLM                   => { Dbbx,    'culmus/MiriamCLM' },
    MiriamMonoCLM               => { Dbbo,    'culmus/MiriamMonoCLM', mono => 1 },  # -Book; -Bold; -BookOblique; -BoldOblique
    MuktiNarrow                 => { Nbx,     'ttf-indic-fonts-core/MuktiNarrow' }, # ; Bold
    NanumBarunGothic            => { Nbx,     'nanum/NanumBarunGothic' },           # ; Bold
    NanumGothic                 => { Nbx,     'nanum/NanumGothic' },                # ; Bold
    NanumMyeongjo               => { Nbx,     'nanum/NanumMyeongjo' },              # ; Bold
    Norasi                      => { Dbio,    'tlwg/Norasi' },                      # ; -Bold; -Italic; -BoldItalic; -Oblique; -BoldOblique (ignore Oblique )
    Padauk                      => { Nbxl2,   'padauk/Padauk' },                    # ; -bold
    Padauk_book                 => { Nbxl,    'padauk/Padauk-book' },               # -book; -bookbold
    Phetsarath_OT               => { Nx,      'lao/Phetsarath_OT' },                # (no variants )
    Pothana2000                 => { Nx,      'ttf-indic-fonts-core/Pothana2000' }, # (no variants )
    Purisa                      => { Dbo,     'tlwg/Purisa' },                      # ; -Bold; -Oblique; -BoldOblique
    Rachana_04                  => { Nx,      'ttf-indic-fonts-core/Rachana_04' },  # (no variants )
    Rekha                       => { Nx,      'ttf-indic-fonts-core/Rekha' },       # (no variants )
    SILEOT                      => { Nx,      'ezra/SILEOT' },                      # (no variants )
    SILEOTSR                    => { Nx,      'ezra/SILEOTSR' },                    # (no variants )
    Saab                        => { Nx,      'ttf-punjabi-fonts/Saab' },           # (no variants )
    Samyak_Oriya                => { Nx,      'ttf-oriya-fonts/Samyak-Oriya' },     # (no variants )
    Sawasdee                    => { Dbo,     'tlwg/Sawasdee' },                    # ; -Bold; -Oblique; -BoldOblique
    Shofar                      => { path =>'culmus/Shofar', vs => f0( 'Regular', 'Demi-Bold', 'Oblique' ) },   # Regular; Demi-Bold; RegularOblique; Demi-BoldOblique
    SimpleCLM                   => { Dmbo,    'culmus/SimpleCLM' },                 # -Medium; -Bold; -MediumOblique; -BoldOblique
    StamAshkenazCLM             => { Nx,      'culmus/StamAshkenazCLM' },           # (no variants )
    StamSefaradCLM              => { Nx,      'culmus/StamSefaradCLM' },            # (no variants )
    Symbol                      => { std14 => 'Symbol', vs => [ '' ] },             # ( no variants )
    TakaoPGothic                => { Nx,      'takao-gothic/TakaoPGothic' },        # (no variants )
    TibetanMachineUni           => { Nx,      'tibetan-machine/TibetanMachineUni' }, # (no variants )
    Times                       => { std14 => 'Times', Dbi, undef },                # vs => fv( '-', '', 'Bold', 'Italic' )
    TlwgMono                    => { DboM,    'tlwg/TlwgMono' },                    # ; -Bold; -Oblique; -BoldOblique
    TlwgTypewriter              => { Dbo,     'tlwg/TlwgTypewriter' },              # ; -Bold; -Oblique; -BoldOblique
    TlwgTypist                  => { Dbo,     'tlwg/TlwgTypist' },                  # ; -Bold; -Oblique; -BoldOblique
    TlwgTypo                    => { Dbo,     'tlwg/TlwgTypo' },                    # ; -Bold; -Oblique; -BoldOblique
    Ubuntu                      => { Drbi,    'ubuntu-font-family/Ubuntu' },        # -R; -B; -RI; -BI
    UbuntuMono                  => { DrbiM,   'ubuntu-font-family/UbuntuMono' },    # -R; -B; -RI; -BI
    Ubuntu_C                    => { Nx,      'ubuntu-font-family/Ubuntu-C' },      # -C
    Ubuntu_L                    => { Nxi1,    'ubuntu-font-family/Ubuntu-L' },      # -L; -LI;
    Ubuntu_M                    => { Nxi1,    'ubuntu-font-family/Ubuntu-M' },      # -M; -MI;
    Umpush                      => { Dbo,     'tlwg/Umpush' },                      # ; -Bold; -Oblique; -BoldOblique
    Umpush_Light                => { Nxo,     'tlwg/Umpush-Light' },                # -Light; -LightOblique
    Vemana                      => { Nx,      'ttf-indic-fonts-core/Vemana' },      # (no variants )
    Waree                       => { Dbo,     'tlwg/Waree' },                       # ; -Bold; -Oblique; -BoldOblique
    Zapf_Dingbats               => { std14 => 'Zapf Dingbats', vs => [ '' ] },      # (no variants)
    ani                         => { Nx,      'ttf-bengali-fonts/ani' },            # (no variants)
    cmex10                      => { Nx,      'lyx/cmex10' },                       # (no variants)
    cmmi10                      => { Nx,      'lyx/cmmi10' },                       # (no variants)
    cmr10                       => { Nx,      'lyx/cmr10' },                        # (no variants)
    cmsy10                      => { Nx,      'lyx/cmsy10' },                       # (no variants)
    esint10                     => { Nx,      'lyx/esint10' },                      # (no variants)
    eufm10                      => { Nx,      'lyx/eufm10' },                       # (no variants)
    gargi                       => { Nx,      'ttf-indic-fonts-core/gargi' },       # (no variants)
    indic_Kedage                => { Dnbx,    'ttf-indic-fonts-core/Kedage' },
    indic_Malige                => { Dnbx,    'ttf-indic-fonts-core/Malige' },
    kannada_Kedage              => { Dxti,    'ttf-kannada-fonts/Kedage' },
    kannada_Malige              => { Dxti,    'ttf-kannada-fonts/Malige' },
    lklug                       => { Nx,      'sinhala/lklug' },                    # (no variants)
    lohit_as                    => { Nx,      'ttf-bengali-fonts/lohit_as' },       # (no variants)
    lohit_bn                    => { Nx,      'ttf-indic-fonts-core/lohit_bn' },    # (no variants)
    lohit_gu                    => { Nx,      'ttf-indic-fonts-core/lohit_gu' },    # (no variants)
    lohit_hi                    => { Nx,      'ttf-indic-fonts-core/lohit_hi' },    # (no variants)
    lohit_kn                    => { Nx,      'ttf-kannada-fonts/lohit_kn' },       # (no variants)
    lohit_or                    => { Nx,      'ttf-oriya-fonts/lohit_or' },         # (no variants)
    lohit_pa                    => { Nx,      'ttf-punjabi-fonts/lohit_pa' },       # (no variants)
    lohit_ta                    => { Nx,      'ttf-indic-fonts-core/lohit_ta' },    # (no variants)
    lohit_te                    => { Nx,      'ttf-telugu-fonts/lohit_te' },        # (no variants)
    luxim                       => { Nrbi1l,  'ttf-xfree86-nonfree/luxim' },        # r; b; ri; bi
    luxir                       => { Nrbi1l,  'ttf-xfree86-nonfree/luxir' },        # r; b; ri; bi
    luxis                       => { Nrbi1l,  'ttf-xfree86-nonfree/luxis' },        # r; b; ri; bi
    mitra                       => { Nx,      'ttf-bengali-fonts/mitra' },          # (no variants)
    mry_KacstQurn               => { Nx,      'kacst/mry_KacstQurn' },              # (no variants)
    msam10                      => { Nx,      'lyx/msam10' },                       # (no variants)
    msbm10                      => { Nx,      'lyx/msbm10' },                       # (no variants)
    openoffice                  => { Nx,      'openoffice/opens___' },              # (no variants)
    rsfs10                      => { Nx,      'lyx/rsfs10' },                       # (no variants)
    utkal                       => { Nx,      'ttf-indic-fonts-core/utkal' },       # (no variants)
    wasy10                      => { Nx,      'lyx/wasy10' },                       # (no variants)

);

if ($^C || $^W) {

    our $ttf_dir;
    our $ttf_suffix;
    BEGIN {
    *ttf_dir = \$PDF::paginator::ttf_dir;
    *ttf_suffix = \$PDF::paginator::ttf_suffix;
    }

    use Carp 'croak';
    -d $ttf_dir or croak "Truetype fonts not in $ttf_dir;\nPlease modify \$ttf_dir in ".__FILE__." to indicate correct location\n";

    my %present = map { ( $_ => 1 ) } my @present = glob $ttf_dir.'*/*'.$ttf_suffix;

    my $err = 0;
    my @claimed;
    for my $fn ( keys %font_info ) {
        my $fi = $font_info{$fn};
        $fi->{std14} and next;
        #warn "Verifying font $fn\n";
        my $path = $fi->{path};
        my $vs = $fi->{vs};
        ref $vs or die "vs is not array for font $fn";
        for my $fi ( 0 .. $#$vs ) {
            my $fs = $vs->[$fi] // do { $fi or die "Font $fn undef on variant 0"; next };
            my $filename = $ttf_dir.$path.$fs.$ttf_suffix;
            $present{$filename} or ++$err, warn "Font $fn variant $fi missing $filename";
            push @claimed, $filename;
        }
    }
    $err and die "Unmatched font files $err";

    if ($ENV{QDB_check_unclaimed_fonts}) {
        # Check for unclaimed files.
        # This doesn't really serve any purpose other than to check that the
        # logic is finding them all. "Extra" font files won't be used.
        delete @present{@claimed};
        for (sort keys %present) {
            -l $_ and next;
            warn "Unclaimed font file $_\n";
            ++$err;
        }
        $err and warn "Unclaimed (extra) fonts: $err files";
    }

    warn "Checked for fonts in $ttf_dir with suffix $ttf_suffix, glob matched @{[ 0+@present ]}\n";

}
}

# Phone numbers should request Monospace except that digit grouping should use
# half-width spaces.
# Email addresses and web sites should request Courier, which is always
# monospaced.

#
# Most fonts have Bold, Oblique, and BoldOblique, variants. Some (Times) have
# Italic rather than Oblique, meaning that it has slightly different forms, not
# just "leaning" versions of the regular ones.
# Among the core fonts, Symbol & Zapf Dingbats have no variants.
#
# Some (non core) fonts also include variants such Sans, Serif, Mono,
# Condensed; these are simply treated as separate font names here.
#
# ("Roman" and "Regular" are redundant names for the base font.)
#

#
# Args:
#   (invocant)
#   font name
#   font size
# and either
#   font variation aka font style (the b_* constants above)
# or
#   bold flag
#   italic flag
#   monospace flag
#
# The font variation value is calculated as
#   ((bold && 1) | (italic && 2))
#

sub font($$$$;$$) {
    my $pq = shift;
    my $basefont = shift;
    my $size = shift;
    my $fontstyle = $_[0] || 0;
    if ( @_ >= 2 ) {
        $fontstyle = 0;
        $fontstyle |= b_Bold   if $_[0];
        $fontstyle |= b_Italic if $_[1];
    } else {
        $fontstyle &= b_Bold | b_Italic;
    }
    my $fi = $font_info{$basefont};
    my $std14 = $fi->{std14};
    my $name = $std14 || $fi->{path};

    $name .= $fi->{vs}[$fontstyle]
          // $fi->{vs}[$fontstyle^b_Italic]
          // $fi->{vs}[$fontstyle^b_Bold]
          // '';

    my $f = $pq->{fontcache}{$name} ||=
            $fi->{std14} ? $pq->pdf->corefont($name)
                         : do {
                            my $filename = $ttf_dir.$name.$ttf_suffix;
                            eval {
                                $pq->pdf->ttfont($filename)
                            } or do {
                                use Data::Dumper;
                                croak sprintf "No font %s variant %s from file %s\n\tDump=%s", $basefont, $fontstyle, $filename, Dumper($fi);
                            };
                        } || $pq->pdf->corefont($basefont) || croak "Cannot load font $name";

    $pq->{last_set_fontname} = $f;
    $pq->{last_set_fontstyle} = $fontstyle;
    $pq->{last_set_fontsize} = $size;
    $pq->text->font($f,$size);
}

sub _get_current_font_description {
    my $pq = shift;
    my $fs = $pq->{last_set_fontstyle};
    my $fn = $pq->{last_set_fontname};
    my $fz = $pq->{last_set_fontsize};
    return sprintf "fontstyle %x=%s [%s %d]\n", $fs, join('-', unpack 'b4', $fs), $fn, $fz;
}

########################################
#
#** on hijacking the Unicode Variant Selectors **
#
#   To achieve some basic text flow, we use codepoints \ufe00..\ufe07 to
#   control bold, italic, and underline attributes.
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
    $pq->font( $fontname, $fontsize, $fontstyle );
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
            $fontstyle = (ord($part) - b_ord);
            $pq->font( $fontname, $fontsize, $fontstyle );
            warn sprintf 'TEXTSIZE '.$pq->_get_current_font_description if $verbose > 3;
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
    $pq->font( $fontname, $fontsize, $fontstyle );
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
            $pq->font( $fontname, $fontsize, $fontstyle );
            warn sprintf 'TEXTFLOW '.$pq->_get_current_font_description if $verbose > 3;
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
    $pq->font( $fontname, $fontsize, $fontstyle );

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
