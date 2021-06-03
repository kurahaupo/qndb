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
-d $ttf_dir or croak "Truetype fonts not in $ttf_dir;\nPlease modify \$ttf_dir in ".__FILE__." to indicate correct location\n";
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

my @xx =    ( '',            (undef) x 3,                                   );  # no variants

# with leading dash
my @Dbbo =  ( '-Book',      '-Bold',    '-BookOblique',     '-BoldOblique', );
my @Dbbx =  ( '-Book',      '-Bold',    (undef),            (undef),        );  # Bold but no italic/oblique
my @Dbi =   ( '',           '-Bold',    '-Italic',          '-BoldItalic',  );
my @Dqbi =  ( '-Regular',   '-Bold',    '-Italic',          '-BoldItalic',  );  # like bold+italic, except with "-Regular" instead of empty
my @Dbio =  ( '',           '-Bold',    '-Italic',          '-BoldItalic',  '-Oblique', '-BoldOblique', );  # functions are @Dbi
my @Dbo =   ( '',           '-Bold',    '-Oblique',         '-BoldOblique', );
my @Dbx =   ( '',           '-Bold',    (undef),             undef,,        );
my @Dmbi =  ( '-Medium',    '-Bold',    '-MediumItalic',    '-BoldItalic',  );
my @Dmbo =  ( '-Medium',    '-Bold',    '-MediumOblique',   '-BoldOblique', );
my @Drbi =  ( '-R',         '-B',       '-RI',              '-BI'           );  # upper-case single letter suffix: R/B + I with '-'
my @Drbo =  ( '-Regular',   '-Bold',    '-RegularOblique',  '-BoldOblique', );
my @Drbx =  ( '-Regular',   '-Bold',    (undef),             undef,,        );  # no italic/oblique
my @Dxbo =  ( (undef),      '-Bold',    (undef),            '-BoldOblique', );  # Oblique but no un-Bold

# with no lead
my @Nqbi1=  ( 'R',          'B',        'I',                'BI',           );  # single letter suffices, with R instead of empty
my @Nrbi1l= ( 'r',          'b',        'ri',               'bi'            );  # lower-case single letter suffix: r/b + i without '-'
my @Nbi =   ( '',           'Bold',     'Italic',           'BoldItalic',   );  # like regular Bold+Italic but no '-' before suffix
my @Nbo =   ( '',           'Bold',     'Oblique',          'BoldOblique',  );  # like regular Bold+Oblique but no '-' before suffix
my @Nqbo =  ( 'Regular',    'Bold',     'Oblique',          'BoldOblique',  );  # like Bold+Oblique, but with 'Regular' instead of empty, and without '- before suffix
my @Nbx =   ( '',           'Bold',     (undef),            (undef),        );  # Bold but no italic/oblique; no '-' before suffix
my @Nbxl =  ( '',           'bold',     (undef),            (undef),        );  # bold but no italic/oblique; no '-' before suffix
my @Nxi1 =   ( '',           (undef),   'I',                (undef),        );  # I but no B; no '-' before suffix
my @Nxi =   ( '',           (undef),    'Italic',           (undef),        );  # Italic but no Bold; no '-' before suffix
my @Nxo =   ( '',           (undef),    'Oblique',          (undef),        );  # Oblique but no Bold; no '-' before suffix

# with leading underscore (or two)
my @UUbi =  ( '',           '_Bold',    '_Italic',          '_Bold_Italic', );  # like Bold+Italic, but with _ before suffix

%font_info = (

    AbyssinicaSIL               => { vs => \@xx,    path => 'abyssinica/AbyssinicaSIL-R', },    # (no variants)
    ani                         => { vs => \@xx,    path => 'ttf-bengali-fonts/ani', },         # (no variants)
    Balker                      => { vs => \@xx,    path => 'dustin/Balker', },                 # (no variants)
    cmex10                      => { vs => \@xx,    path => 'lyx/cmex10', },                    # (no variants)
    cmmi10                      => { vs => \@xx,    path => 'lyx/cmmi10', },                    # (no variants)
    cmr10                       => { vs => \@xx,    path => 'lyx/cmr10', },                     # (no variants)
    cmsy10                      => { vs => \@xx,    path => 'lyx/cmsy10', },                    # (no variants)
    Courier                     => { vs => \@Dbo,   std14 => 1, mono => 1, },
    DavidCLM                    => { vs => \@Dmbi,  path => 'culmus/DavidCLM', },
    DejaVuSans                  => { vs => \@Dbo,   path => 'dejavu/DejaVuSans', },
    DejaVuSansCondensed         => { vs => \@Dbo,   path => 'dejavu/DejaVuSansC', },
    DejaVuSansMono              => { vs => \@Dbo,   path => 'dejavu/DejaVuSansM', mono => 1, },
    DejaVuSerif                 => { vs => \@Dbo,   path => 'dejavu/DejaVuSerif', },
    DejaVuSerifCondensed        => { vs => \@Dbo,   path => 'dejavu/DejaVuSerif', },
    Domestic_Manners            => { vs => \@xx,    path => 'dustin/Domestic_Manners', },       # (no variants)
    DroidNaskh                  => { vs => \@Drbx,  path => 'droid/DroidNaskh', },              # -Regular; -Bold
    DroidSans                   => { vs => \@Dbx,   path => 'droid/DroidSans', },               # ; -Bold
    DroidSansArmenian           => { vs => \@xx,    path => 'droid/DroidSansArmenian', },       # (no variants)
    DroidSansEthiopic           => { vs => \@Drbx,  path => 'droid/DroidSansEthiopic', },       # -Regular; -Bold
    DroidSansFallbackFull       => { vs => \@xx,    path => 'droid/DroidSansFallbackFull', },   # (no variants)
    DroidSansGeorgian           => { vs => \@xx,    path => 'droid/DroidSansGeorgian', },       # (no variants)
    DroidSansHebrew             => { vs => \@Drbx,  path => 'droid/DroidSansHebrew', },         # -Regular; -Bold
    DroidSansJapanese           => { vs => \@xx,    path => 'droid/DroidSansJapanese', },       # (no variants)
    DroidSansMono               => { vs => \@xx,    path => 'droid/DroidSansMono', mono => 1, }, # (no variants)
    DroidSansThai               => { vs => \@xx,    path => 'droid/DroidSansThai', },           # (no variants)
    DroidSerif                  => { vs => \@Dqbi, path => 'droid/DroidSerif', },               # -Regular; -Bold; -Italic; -BoldItalic
    Dustismo_Roman              => { vs => \@UUbi,  path => 'dustin/Dustismo_Roman', },         # ; _Bold; _Italic; _Italic_Bold
    El_Abogado_Loco             => { vs => \@xx,    path => 'dustin/El_Abogado_Loco', },        # (no variants)
    esint10                     => { vs => \@xx,    path => 'lyx/esint10', },                   # (no variants)
    eufm10                      => { vs => \@xx,    path => 'lyx/eufm10', },                    # (no variants)
    flatline                    => { vs => \@xx,    path => 'dustin/flatline', },               # (no variants)
    FrankRuehlCLM               => { vs => \@Dmbo,  path => 'culmus/FrankRuehlCLM', },
    FreeMono                    => { vs => \@Nbo,   path => 'freefont/FreeMono',  mono => 1, }, # ; Bold; Oblique; BoldOblique
    FreeSans                    => { vs => \@Nbo,   path => 'freefont/FreeSans',  },            # ; Bold; Oblique; BoldOblique
    FreeSerif                   => { vs => \@Nbi,   path => 'freefont/FreeSerif', },            # ; Bold; Italic; BoldItalic
    gargi                       => { vs => \@xx,    path => 'ttf-indic-fonts-core/gargi', },    # (no variants)
    Garuda                      => { vs => \@Dbo,   path => 'tlwg/Garuda', },                   # ; -Bold; -Oblique; -BoldOblique
    GenBas                      => { vs => \@Nqbi1, path => 'gentium-basic/GenBas',  },         # R; B; I; BI
    GenBkBas                    => { vs => \@Nqbi1, path => 'gentium-basic/GenBkBas', },        # R; B; I; BI
    HadasimCLM                  => { vs => \@Drbo,  path => 'culmus/HadasimCLM', },
    Helvetica                   => { vs => \@Dbo,   std14 => 1, },
    It_wasn_t_me                => { vs => \@xx,    path => 'dustin/It_wasn_t_me', },           # (no variants)
    JamrulNormal                => { vs => \@xx,    path => 'ttf-bengali-fonts/JamrulNormal', }, # (no variants)
    Junkyard                    => { vs => \@xx,    path => 'dustin/Junkyard', },               # (no variants)
    KacstArt                    => { vs => \@xx,    path => 'kacst/KacstArt', },                # (no variants)
    KacstBook                   => { vs => \@xx,    path => 'kacst/KacstBook', },               # (no variants)
    KacstDecorative             => { vs => \@xx,    path => 'kacst/KacstDecorative', },         # (no variants)
    KacstDigital                => { vs => \@xx,    path => 'kacst/KacstDigital', },            # (no variants)
    KacstFarsi                  => { vs => \@xx,    path => 'kacst/KacstFarsi', },              # (no variants)
    KacstLetter                 => { vs => \@xx,    path => 'kacst/KacstLetter', },             # (no variants)
    KacstNaskh                  => { vs => \@xx,    path => 'kacst/KacstNaskh', },              # (no variants)
    KacstOffice                 => { vs => \@xx,    path => 'kacst/KacstOffice', },             # (no variants)
    KacstOne                    => { vs => \@Dbx,   path => 'kacst-one/KacstOne', },            # ; -Bold
    KacstPen                    => { vs => \@xx,    path => 'kacst/KacstPen', },                # (no variants)
    KacstPoster                 => { vs => \@xx,    path => 'kacst/KacstPoster', },             # (no variants)
    KacstQurn                   => { vs => \@xx,    path => 'kacst/KacstQurn', },               # (no variants)
    KacstScreen                 => { vs => \@xx,    path => 'kacst/KacstScreen', },             # (no variants)
    KacstTitle                  => { vs => \@xx,    path => 'kacst/KacstTitle', },              # (no variants)
    KacstTitleL                 => { vs => \@xx,    path => 'kacst/KacstTitleL', },             # (no variants)
    KeterYG                     => { vs => \@Dmbo,  path => 'culmus/KeterYG', },
    KhmerOS                     => { vs => \@xx,    path => 'ttf-khmeros-core/KhmerOS', },      # (no variants)
    KhmerOSsys                  => { vs => \@xx,    path => 'ttf-khmeros-core/KhmerOSsys', },   # (no variants)
    Kinnari                     => { vs => \@Dbio,  path => 'tlwg/Kinnari', },                  # ; -Bold; -Italic; -BoldItalic; -Oblique; -BoldOblique
    Lato                        => { vs => \@Dqbi, path => 'lato/Lato', },                      # -Regular; -Bold; -Italic; -BoldItalic
    LiberationMono              => { vs => \@Dqbi, path => 'liberation/LiberationMono', mono => 1, }, # -Regular; -Bold; -Italic; -BoldItalic
    LiberationSans              => { vs => \@Dqbi, path => 'liberation/LiberationSans', },      # -Regular; -Bold; -Italic; -BoldItalic
    LiberationSansNarrow        => { vs => \@Dqbi, path => 'liberation/LiberationSansNarrow', }, # -Regular; -Bold; -Italic; -BoldItalic
    LiberationSerif             => { vs => \@Dqbi, path => 'liberation/LiberationSerif', },     # -Regular; -Bold; -Italic; -BoldItalic
    LikhanNormal                => { vs => \@xx,    path => 'ttf-bengali-fonts/LikhanNormal', }, # (no variants)
    lklug                       => { vs => \@xx,    path => 'sinhala/lklug', },                 # (no variants)
    lohit_as                    => { vs => \@xx,    path => 'ttf-bengali-fonts/lohit_as', },    # (no variants)
    lohit_bn                    => { vs => \@xx,    path => 'ttf-indic-fonts-core/lohit_bn', }, # (no variants)
    lohit_gu                    => { vs => \@xx,    path => 'ttf-indic-fonts-core/lohit_gu', }, # (no variants)
    lohit_hi                    => { vs => \@xx,    path => 'ttf-indic-fonts-core/lohit_hi', }, # (no variants)
    lohit_kn                    => { vs => \@xx,    path => 'ttf-kannada-fonts/lohit_kn', },    # (no variants)
    lohit_or                    => { vs => \@xx,    path => 'ttf-oriya-fonts/lohit_or', },      # (no variants)
    lohit_pa                    => { vs => \@xx,    path => 'ttf-punjabi-fonts/lohit_pa', },    # (no variants)
    lohit_ta                    => { vs => \@xx,    path => 'ttf-indic-fonts-core/lohit_ta', }, # (no variants)
    lohit_te                    => { vs => \@xx,    path => 'ttf-telugu-fonts/lohit_te', },     # (no variants)
    Loma                        => { vs => \@Dbo,   path => 'tlwg/Loma', },                     # ; -Bold; -Oblique; -BoldOblique
    luxim                       => { vs => \@Nrbi1l, path => 'ttf-xfree86-nonfree/luxim', },    # r; b; ri; bi
    luxir                       => { vs => \@Nrbi1l, path => 'ttf-xfree86-nonfree/luxir', },    # r; b; ri; bi
    luxis                       => { vs => \@Nrbi1l, path => 'ttf-xfree86-nonfree/luxis', },    # r; b; ri; bi
    MarkedFool                  => { vs => \@xx,    path => 'dustin/MarkedFool', },             # (no variants)
    Meera_04                    => { vs => \@xx,    path => 'ttf-indic-fonts-core/Meera_04', }, # (no variants)
    MgOpenCanonica              => { vs => \@Nqbo,  path => 'mgopen/MgOpenCanonica', },         # Regular; Bold; Italic; BoldItalic
    MgOpenCosmetica             => { vs => \@Nqbo,  path => 'mgopen/MgOpenCosmetica', },        # Regular; Bold; Oblique; BoldOblique
    MgOpenModata                => { vs => \@Nqbo,  path => 'mgopen/MgOpenModata', },           # Regular; Bold; Oblique; BoldOblique
    MgOpenModerna               => { vs => \@Nqbo,  path => 'mgopen/MgOpenModerna', },          # Regular; Bold; Oblique; BoldOblique
    MiriamCLM                   => { vs => \@Dbbx,  path => 'culmus/MiriamCLM', },
    MiriamMonoCLM               => { vs => \@Dbbo,  path => 'culmus/MiriamMonoCLM', mono => 1, }, # -Book; -Bold; -BookOblique; -BoldOblique
    mitra                       => { vs => \@xx,    path => 'ttf-bengali-fonts/mitra', },       # (no variants)
    mry_KacstQurn               => { vs => \@xx,    path => 'kacst/mry_KacstQurn', },           # (no variants)
    msam10                      => { vs => \@xx,    path => 'lyx/msam10', },                    # (no variants)
    msbm10                      => { vs => \@xx,    path => 'lyx/msbm10', },                    # (no variants)
    MuktiNarrow                 => { vs => \@Nbx,   path => 'ttf-indic-fonts-core/MuktiNarrow', }, # ; Bold
    NanumBarunGothic            => { vs => \@Nbx,   path => 'nanum/NanumBarunGothic', },        # ; Bold
    NanumGothic                 => { vs => \@Nbx,   path => 'nanum/NanumGothic', },             # ; Bold
    NanumMyeongjo               => { vs => \@Nbx,   path => 'nanum/NanumMyeongjo', },           # ; Bold
    Norasi                      => { vs => \@Dbio,  path => 'tlwg/Norasi', },                   # ; -Bold; -Italic; -BoldItalic; -Oblique; -BoldOblique
    opens___                    => { vs => \@xx,    path => 'openoffice/opens___', },           # (no variants)
    Padauk                      => { vs => \@Nbxl,  path => 'padauk/Padauk', },                 # ; bold
    PenguinAttack               => { vs => \@xx,    path => 'dustin/PenguinAttack', },          # (no variants)
    Phetsarath_OT               => { vs => \@xx,    path => 'lao/Phetsarath_OT', },             # (no variants)
    Pothana2000                 => { vs => \@xx,    path => 'ttf-indic-fonts-core/Pothana2000', }, # (no variants)
    progenisis                  => { vs => \@xx,    path => 'dustin/progenisis', },             # (no variants)
    Purisa                      => { vs => \@Dbo,   path => 'tlwg/Purisa', },                   # ; -Bold; -Oblique; -BoldOblique
    Rachana_04                  => { vs => \@xx,    path => 'ttf-indic-fonts-core/Rachana_04', }, # (no variants)
    Rekha                       => { vs => \@xx,    path => 'ttf-indic-fonts-core/Rekha', },    # (no variants)
    rsfs10                      => { vs => \@xx,    path => 'lyx/rsfs10', },                    # (no variants)
    Saab                        => { vs => \@xx,    path => 'ttf-punjabi-fonts/Saab', },        # (no variants)
    Sawasdee                    => { vs => \@Dbo,   path => 'tlwg/Sawasdee', },                 # ; -Bold; -Oblique; -BoldOblique
    ShofarDemi                  => { vs => \@Dxbo,  path => 'culmus/ShofarDemi', },             # -Bold; -BoldOblique
    ShofarRegular               => { vs => \@Nxo,   path => 'culmus/ShofarRegular', },          # ; Oblique, without '-'
    SILEOT                      => { vs => \@xx,    path => 'ezra/SILEOT', },                   # (no variants)
    SILEOTSR                    => { vs => \@xx,    path => 'ezra/SILEOTSR', },                 # (no variants)
    SimpleCLM                   => { vs => \@Dmbo,  path => 'culmus/SimpleCLM', },              # -Medium; -Bold; -MediumOblique; -BoldOblique
    StamAshkenazCLM             => { vs => \@xx,    path => 'culmus/StamAshkenazCLM', },        # (no variants)
    StamSefaradCLM              => { vs => \@xx,    path => 'culmus/StamSefaradCLM', },         # (no variants)
    Swift                       => { vs => \@xx,    path => 'dustin/Swift', },                  # (no variants)
    Symbol                      => { vs => \@xx,    std14 => 1, },                              # (no variants)
    TakaoPGothic                => { vs => \@xx,    path => 'takao-gothic/TakaoPGothic', },     # (no variants)
    TibetanMachineUni           => { vs => \@xx,    path => 'tibetan-machine/TibetanMachineUni', }, # (no variants)
    Times                       => { vs => \@Dbi,   std14 => 1, },
    TlwgMono                    => { vs => \@Dbo,   path => 'tlwg/TlwgMono', mono => 1, },      # ; -Bold; -Oblique; -BoldOblique
    TlwgTypewriter              => { vs => \@Dbo,   path => 'tlwg/TlwgTypewriter', },           # ; -Bold; -Oblique; -BoldOblique
    TlwgTypist                  => { vs => \@Dbo,   path => 'tlwg/TlwgTypist', },               # ; -Bold; -Oblique; -BoldOblique
    TlwgTypo                    => { vs => \@Dbo,   path => 'tlwg/TlwgTypo', },                 # ; -Bold; -Oblique; -BoldOblique
    Ubuntu                      => { vs => \@Drbi,  path => 'ubuntu-font-family/Ubuntu', },     # -R; -B; -RI; -BI
    UbuntuMono                  => { vs => \@Drbi,  path => 'ubuntu-font-family/UbuntuMono', mono => 1, }, # -R; -B; -RI; -BI
   'Ubuntu-L'                   => { vs => \@Nxi1,  path => 'ubuntu-font-family/Ubuntu-L', },   # -L; -LI;
   'Ubuntu-M'                   => { vs => \@Nxi1,  path => 'ubuntu-font-family/Ubuntu-M', },   # -M; -MI;
   'Ubuntu-C'                   => { vs => \@xx,    path => 'ubuntu-font-family/Ubuntu-C', },   # -C
    Umpush                      => { vs => \@Dbo,   path => 'tlwg/Umpush', },                   # ; -Bold; -Oblique; -BoldOblique
   'Umpush-Light'               => { vs => \@Nxo,   path => 'tlwg/Umpush-Light', },             # -Light; -LightOblique
    utkal                       => { vs => \@xx,    path => 'ttf-indic-fonts-core/utkal', },    # (no variants)
    Vemana                      => { vs => \@xx,    path => 'ttf-indic-fonts-core/Vemana', },   # (no variants)
    Waree                       => { vs => \@Dbo,   path => 'tlwg/Waree', },                    # ; -Bold; -Oblique; -BoldOblique
    Wargames                    => { vs => \@xx,    path => 'dustin/Wargames', },               # (no variants)
    wasy10                      => { vs => \@xx,    path => 'lyx/wasy10', },                    # (no variants)
    Winks                       => { vs => \@xx,    path => 'dustin/Winks', },                  # (no variants)
   'DejaVuSans-ExtraLight'      => { vs => \@xx,    path => 'dejavu/DejaVuSans', },             # (no variants)
   'Lato-Black'                 => { vs => \@Nxi,   path => 'lato/Lato-Black', },               # -Black; -BlackItalic
   'Lato-Hairline'              => { vs => \@Nxi,   path => 'lato/Lato-Hairline', },            # -Hairline; -HairlineItalic
   'Lato-Heavy'                 => { vs => \@Nxi,   path => 'lato/Lato-Heavy', },               # -Heavy; -HeavyItalic
   'Lato-Light'                 => { vs => \@Nxi,   path => 'lato/Lato-Light', },               # -Light; -LightItalic
   'Lato-Medium'                => { vs => \@Nxi,   path => 'lato/Lato-Medium', },              # -Medium; -MediumItalic
   'Lato-Semibold'              => { vs => \@Nxi,   path => 'lato/Lato-Semibold', },            # -Semibold; -SemiboldItalic
   'Lato-Thin'                  => { vs => \@Nxi,   path => 'lato/Lato-Thin', },                # -Thin; -ThinItalic
   'Padauk-book'                => { vs => \@Nbxl,  path => 'padauk/Padauk-book', },            # -book; -bookbold
   'Samyak-Oriya'               => { vs => \@xx,    path => 'ttf-oriya-fonts/Samyak-Oriya', },  # (no variants)
   'Zapf Dingbats'              => { vs => \@xx,    std14 => 1, },                              # (no variants)

);
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
    my $name = $std14 ? $basefont : $fi->{path};

    $name .= $fi->{vs}[$fontstyle]
          // $fi->{vs}[$fontstyle^b_Italic]
          // $fi->{vs}[$fontstyle^b_Bold]
          // '';

    my $f = $pq->{fontcache}{$name} ||=
            $fi->{std14} ? $pq->pdf->corefont($name)
                         : do {
                            my $filename = $ttf_dir.$name.$ttf_suffix;
                            $pq->pdf->ttfont($filename);
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
