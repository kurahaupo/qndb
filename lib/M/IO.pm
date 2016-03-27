#!/module/for/perl
# vim: set et sw=4 sts=4 nowrap :

use 5.010;
use strict;
use warnings;
use utf8;

package M::IO;

use Fcntl qw( SEEK_CUR SEEK_SET );

use verbose;

########################################
# Writing to output files

our $force_overwrite;
my $output_bom = 0;
my $output_crlf;
my @wr_binmode;
my @wr_bom;

########################################
# Decoding & parsing input files

my $csv_fs_char;
my $csv_quote_char;
my $csv_escape_char;
my $force_decoding;
my $presume_decoding;
my $use_encoding;

if (my $lang = $ENV{LANG}) {
    $presume_decoding =
    $use_encoding = 'UTF-8' if $lang =~ /\.UTF-8$/;
}

use run_options (
    'output-bom|bom!'   => \$output_bom,
    'output-crlf|crlf!' => \$output_crlf,

    '=' => sub {
                if ( $use_encoding && $use_encoding ne 'OCTET' ) {
                    @wr_binmode = ":encoding($use_encoding)";
                    @wr_bom = "\x{feff}" if $output_bom;
                    binmode STDERR, "@wr_binmode";
                }
                $output_crlf and push @wr_binmode, ":crlf";
                unshift @wr_binmode, ":raw" if @wr_binmode;
                warn "WRITE BINMODE=@wr_binmode\n" if $verbose > 1 && @wr_binmode;
                1;
            },

    'csv'                         => sub { $csv_fs_char = ',' },
    'tsv'                         => sub { $csv_fs_char = "\t"; $csv_escape_char = $csv_quote_char = ""; },
    'fs-char|sep-char=s'          => \$csv_fs_char,
    'quote-char=s'                => \$csv_quote_char,

    'encode-octet|encode-byte|eb' => sub { $use_encoding = 'OCTET' },
    'encode-utf16be|eu16b'        => sub { $use_encoding = 'UTF-16BE' },
    'encode-utf16le|eu16l'        => sub { $use_encoding = 'UTF-16LE' },
    'encode-utf8|eu8'             => sub { $use_encoding = 'UTF-8' },
    'encoding=s'                  =>      \$use_encoding,
    'escape-char=s'               => \$csv_escape_char,
    'force-decode-octet|force-decode-byte|fdb' => sub { $force_decoding = 'OCTET' },
    'force-decode-utf16be|fdu16b' => sub { $force_decoding = 'UTF-16BE' },
    'force-decode-utf16le|fdu16l' => sub { $force_decoding = 'UTF-16LE' },
    'force-decode-utf8|fdu8'      => sub { $force_decoding = 'UTF-8' },
    'force-decoding=s'            =>      \$force_decoding,

    'decode-octet|decode-byte|db' => sub { $presume_decoding = 'OCTET' },
    'decode-utf16be|du16b'        => sub { $presume_decoding = 'UTF-16BE' },
    'decode-utf16le|du16l'        => sub { $presume_decoding = 'UTF-16LE' },
    'decode-utf8|du8'             => sub { $presume_decoding = 'UTF-8' },
    'decoding=s'                  =>      \$presume_decoding,

    'octet|byte|b'                => sub { $presume_decoding = $use_encoding = 'OCTET' },
    'utf16be|u16b'                => sub { $presume_decoding = $use_encoding = 'UTF-16BE' },
    'utf16le|u16l'                => sub { $presume_decoding = $use_encoding = 'UTF-16LE' },
    'utf8|u8|u'                   => sub { $presume_decoding = $use_encoding = 'UTF-8' },

    'force-overwrite|f!'          => \$force_overwrite,

    'help-output'                 => <<EndOfHelp,
"text-output" options:
    --[no-]output-bom       --[no-]bom
    --[no-]output-crlf      --[no-]crlf
    --encoding={OCTET|UTF-{8|16|16LE|16BE|32|32LE|32BE}}
        --encode-octet --encode-byte    --eb        (--encoding=OCTET)
        --encode-utf16be                --eu16b     (--encoding=UTF-16BE)
        --encode-utf16le                --eu16l     (--encoding=UTF-16LE)
        --encode-utf8                   --eu8       (--encoding=UTF-8)
    --output=FILENAME -oFILENAME

  * conjoint input & output text options
        --octet  --byte  -b                         (--decoding=OCTET    --encoding=OCTET)
        --utf8  --u8                                (--decoding=UTF-8    --encoding=UTF-8)
        --utf16be  --u16b                           (--decoding=UTF-16BE --encoding=UTF-16BE)
        --utf16le  --u16l                           (--decoding=UTF-16LE --encoding=UTF-16LE)
EndOfHelp

    'help-input'                  => <<EndOfHelp,
"input" options:
    --decoding                  assume input encoding if it cannot be deduced
    --force-decoding            assume input encoding overriding any deduction
    --decoding={OCTET|UTF-{8|16|16LE|16BE|32|32LE|32BE}}
        --decode-octet --decode-byte    --db (--decode-octet)
        --decode-utf16be                --du16b (--decode-utf16be)
        --decode-utf16le                --du16l (--decode-utf16le)
        --decode-utf8                   --du8 (--decode-utf-8)
    --csv                       assume input is comma-separated
    --tsv                       assume input is tab-separated
    --fs-char=CHAR --sep-char=CHAR  field separating character
    --quote-char=CHAR               quote character
    --escape-char=CHAR              escape character
EndOfHelp
);

################################################################################
#
# Parse input file(s)
#
# Mostly we automatically adapt to the input format, so we can read
#  - CSV dumps from Drupal
#  - CSV dumps from Gmail (both UTF8 and UTF16LE)
#  - CSV input for the interrim label generator
#

sub open_file_for_reading($) {
    my $in_name = "(stdin)";
    my $in = shift;

    my $fsep = $csv_fs_char;
    my $echar = $csv_escape_char;
    my $qchar = $csv_quote_char;

    if (!ref $in) {
        # param is *not* a filehandle
        if (!$in || $in eq '-') {
            # param is '' or '-', use stdin
            $in = *STDIN{IO};
        }
        else {
            # param is filename, so open it
            $in_name = $in;
            $in = undef;
        }
    }

    my $s = '';
    my $seekable;
    my $seek_to = 0;
    my $look_ahead = sub {
        my ($n) = @_;
        # Open the file if it isn't yet
        open $in, '<:raw', $in_name or die "Can't open $in_name; $!\n" if !$in;
        # Note whether it's seekable; do this before attempting to read any data
        # so that we don't disrupt buffering later.
        $seekable //= seek $in, 0, SEEK_CUR;
        # Read & return the requested number of bytes
        $n -= length $s;
        if ( $n > 0 ) {
            local $/ = \$n;
            $s .= (<$in> // '');
        }
        return $s;
    };
    my $look_match = sub {
        my ($m) = @_;
        my $l = length $m;
        while ( $l > length $s ) {
            $s eq substr($m,0,length $s) or return;
            $look_ahead->(1+length $s);
        }
        substr($s,0,$l) eq $m or return;
        $seek_to = $l;
        return 1;
    };

    warn "STARTING file '$in_name'\n" if $verbose;

    my @rd_binmode;
    my $rd_crlf = 1;
    my $decoding;

    #
    # Override all autodetection including Byte Order Marks, when given
    # --force-decode=XXXX; this isn't normally needed, but might be
    # necessary if the input can't be rewound such as for a pipe, or if
    # by pure bad luck the input appears to start with a BOM when in fact
    # that's data.
    #
    # In this case, we don't need to inspect the input stream at all...
    #
    if    ( $force_decoding                   ) { $decoding = $force_decoding }

    #
    # Deduce the encoding by reading the first chunk and looking for a Unicode
    # Byte Order Mark (BOM, \ufeff).
    #
    elsif ( $look_match->("\xef\xbf\xbe"    ) ) { $decoding = 'UTF-8' }
    elsif ( $look_match->("\xff\xfe\x00\x00") ) { $decoding = 'UTF-32LE' }
    elsif ( $look_match->("\x00\x00\xfe\xff") ) { $decoding = 'UTF-32BE' }
    elsif ( $look_match->("\xfe\xff"        ) ) { $decoding = 'UTF-16BE' }
    elsif ( $look_match->("\xff\xfe"        ) ) { $decoding = 'UTF-16LE' }

    #
    # In the absence of a BOM, use the decoding given as --decoding=XXXX.
    #
    elsif ( $presume_decoding                 ) { $decoding = $presume_decoding }

    #
    # Guess based on the input stream: assume UTF-8 if nothing in the stream
    # conflicts with it; otherwise infer the word size and endianness from the
    # pattern of NULs.
    #
    else {
        #
        # If seekable use a big chunk to improve detection reliability; if
        # not seekable use a small chunk to maximize the chance that
        # pushback will work.
        #
        # (This assumes that the first row starts with an ASCII character,
        # which is usually valid if the first row is actually a header with
        # field labels.)
        #
        my $s = $look_ahead->( $seekable ? 8192 : 512 );
        if ( $s !~ m{ [^\x80-\xff][\x80-\xbf]
                    | [\xc0-\xff][^\x80-\xbf]
                    | [\xe0-\xff].[^\x80-\xbf]
                    | [\xf0-\xff]..[^\x80-\xbf]
                    | [\xf8-\xff]...[^\x80-\xbf]
                    | [\xfc-\xff]....[^\x80-\xbf]
                    | [\x00\xc0\xc1\xfe\xff]      }x ) { $decoding = 'UTF-8';    }
        elsif ( $s =~ m{^ \x00\x00\x00[\x20-\x7f] }x ) { $decoding = 'UTF-32BE'; }
        elsif ( $s =~ m{^ \x00[\x20-\x7f]         }x ) { $decoding = 'UTF-16BE'; }
        elsif ( $s =~ m{^ [\x20-\x7f]\x00\x00\x00 }x ) { $decoding = 'UTF-32LE'; }
        elsif ( $s =~ m{^ [\x20-\x7f]\x00         }x ) { $decoding = 'UTF-16LE'; }
        else                                           { $decoding = 'OCTET';    }
        warn sprintf "Guessing %s for %s (no BOM)\n", $decoding, $in_name;
    }

    #
    # Take this opportunity to look for tab characters to infer their use
    # as the field separator, and for carriage-return characters to infer
    # cr-lf line endings.
    #
    $fsep = $&, $echar = $qchar = "" if !$fsep && $look_ahead->(512) =~ m/\t/;
    $rd_crlf //= $look_ahead->(512) =~ m{\r\n} ? 1 : 0;

    #
    # Seek (or push-back) to start of input, but after any BOM.
    #
    # Note that seeking may cause a buffer flush even if it's unsuccessful,
    # which might then cause the pushback to fail, so avoid trying to seeking
    # if we already know it will fail.
    #
    if ($seek_to != length $s) {
        if ( not $seekable && seek $in, $seek_to, SEEK_SET ) {
            for ( unpack 'C*', reverse substr $s, $seek_to ) {
                $in->ungetc($_) or die "Can neither seek nor pushback within $in_name; $!\n"
            }
        }
    }

    push @rd_binmode, ":encoding($decoding)" if $decoding && $decoding ne 'OCTET';
    push @rd_binmode, ":crlf" if $rd_crlf;
    unshift @rd_binmode, ':raw' if @rd_binmode;
    warn "READ BINMODE=@rd_binmode\n" if $verbose > 1 && @rd_binmode;
    if (!$in) {
        open $in, "<@rd_binmode", $in_name or die "Can't open $in_name [@rd_binmode]; $!\n";
    }
    else {
        binmode $in, "@rd_binmode" or die "Can't set binmode(@rd_binmode) on $in_name; $!\n" if @rd_binmode;
    }

    return $in, $in_name, $fsep, $echar, $qchar;
}


sub _open_output($;$) {
    my $output = shift;
    my $raw = shift;
    my @binmode = $raw ? () : @wr_binmode;
    my @bom     = $raw ? () : @wr_bom;
    flush STDOUT;
    flush STDERR;
    if ($output && ! ref $output && $output ne '-') {
        $force_overwrite || ! -e $output or die "Output file '$output' already exists; use --force-overwrite\n";
        open my $outx, ">@binmode", $output or die "Can't create $output; $!\n";
        print $outx @bom if @bom;
        return $outx, $output, 1;
    }
    else {
        state %first;
        ref $output or $output = *STDOUT{IO};
        if ( !$first{$output}++ ) {
            binmode $output, "@binmode" or warn "Can't set binmode on $output (@binmode); $!\n" if @binmode;
            print $output @bom if @bom;
        }
        return $output, '(stdout)', undef;
    }
}

sub _close_output($$$) {
    my ( $out, my $out_name, my $close_when_done ) = @_;
    close $out or die "Error while writing to $out_name; $!\n" if $close_when_done;
}

use export qw(open_file_for_reading _open_output _close_output $force_overwrite);

1;

