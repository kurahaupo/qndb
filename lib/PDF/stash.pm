#!/module/for/perl

package PDF::stash;

use 5.010;
use strict;
use warnings;
use utf8;


use Carp 'croak';
use verbose;
use PDF::scale_factors;

use PDF::paginator ();

sub new {
    my $class = shift;
    my $pq = shift;
    bless { pq => $pq, e => [], w => 0, h => 0, margins => [], style => 0, @_ }, $class;
}

sub bounds {
    my $tt = shift;
    return $tt->{h} if !wantarray;
    return $tt->{h}, $tt->{w}, $tt->{ypos}, $tt->{col};
}

sub font     { my $tt = shift; $tt->{fontname}  = shift; return $tt; }
sub size     { my $tt = shift; $tt->{fontsize}  = shift; return $tt; }
sub style    { my $tt = shift; $tt->{fontstyle} = shift; return $tt; }
sub plain    { my $tt = shift; $tt->{fontstyle} = 0;     return $tt; }
sub nobold   { my $tt = shift; $tt->{fontstyle} &=~ PDF::paginator::b_Bold;      return $tt; }
sub noitalic { my $tt = shift; $tt->{fontstyle} &=~ PDF::paginator::b_Italic;    return $tt; }
sub nouline  { my $tt = shift; $tt->{fontstyle} &=~ PDF::paginator::b_Underline; return $tt; }
sub bold     { my $tt = shift; $tt->{fontstyle} &=~ PDF::paginator::b_Bold;      $tt->{fontstyle} |= PDF::paginator::b_Bold      if shift // 1; return $tt; }
sub italic   { my $tt = shift; $tt->{fontstyle} &=~ PDF::paginator::b_Italic;    $tt->{fontstyle} |= PDF::paginator::b_Italic    if shift // 1; return $tt; }
sub uline    { my $tt = shift; $tt->{fontstyle} &=~ PDF::paginator::b_Underline; $tt->{fontstyle} |= PDF::paginator::b_Underline if shift // 1; return $tt; }

sub flow {
    my ($tt, $str, $fmt, $loc) = @_;
    my $pq = $tt->{pq};

    if ($fmt) {
        my %f = %$fmt;
        for my $k (qw(
                fontname=f=name
                fontsize=z==sz=size
                fontstyle=s=st=style
                linespacing=l=ls
                width_limit=w=wl
                qrotation=q=qrot
                xscale
                yscale
        )) {
            ($k,my @k) = split /=/, $k;
            for my $kk (@k,$k) {
                exists $f{$kk} or next;
                $tt->{$k} = delete $f{$kk};
                last;
            }
        }
        %f and croak "Invalid or duplicate formatting options: ".join(',',sort keys %f);
    }
    if ($loc) {
        $tt->{ypos} = $loc->[0] || 0;
        $tt->{xpos} = $loc->[1] || 0;
        $tt->{col} = $loc->[2] || $loc->[1] || 0;
    }

    my $fontname     = $tt->{fontname} || croak "Missing fontname";
    my $fontsize     = $tt->{fontsize} || croak "Missing fontsize";
    my $fontstyle    = $tt->{fontstyle} //= 0;
    my $line_spacing = $tt->{linespacing} //= 1.25;
    my $width_limit  = $tt->{width_limit};
    my $top          = $tt->{ypos}      //= 0;
    my $left         = $tt->{xpos}      //= 0;
    my $col          = $tt->{col}       //= 0;
    my $qrotation    = $tt->{qrotation} //= 0;
    my $height       = $tt->{h}         //= 0;
    my $width        = $tt->{w}         //= 0;
    my $xscale       = $tt->{xscale}    //= 1;
    my $yscale       = $tt->{yscale}    //= 1;

    my $text = $pq->text;

    my $lineheight = $fontsize*$line_spacing;
    defined $str && $str ne '' or do {
        warn sprintf "FLOW text=[%s] font=%.2fmm -> size=(↔%.2fmm,↕%.2fmm) (1 empty line)\n",
                    _qm $str, $fontsize/mm,
                    0, $lineheight/mm,
            if $verbose > 3;
        return 0, $lineheight;
    };
    my $lines = 1;
    my $ypos = $top - $lineheight;

    $pq->font( $fontname, $fontsize, $fontstyle );
    warn sprintf "FLOW position  →%.2fmm,↑%.2fmm\n",
            $left/mm, $ypos/mm,
        if $verbose > 3;

    PART: for ( my @parts = split /(\n|$PDF::paginator::TRE)/, $str ; @parts ;) {
        my $part = shift @parts;
        $part eq '' and next PART;
        if ( $part eq "\n" ) {
            warn sprintf "FLOW newline ending line %u at column %.2fmm\n", $lines, $col/mm if $verbose > 3;
            $width >= $col or $width = $col;
            ++$lines;
            $ypos -= $lineheight;
            $col = 0;
            warn sprintf "FLOW position →%.2fmm,↑%.2fmm\n",
                    $left/mm, ($ypos)/mm,
                if $verbose > 3;
            next PART;
        }
        if ( $part =~ /^$PDF::paginator::TRE$/ ) {
            $fontstyle = (ord($part) - PDF::paginator::b_ord);
            $pq->font( $fontname, $fontsize, $fontstyle );
            warn sprintf "FLOW fontstyle %x=%s\n", $fontstyle, join('-', unpack 'b4', $fontstyle) if $verbose > 3;
            next PART;
        }
        my $part_width = $text->advancewidth($part);
        if ($width_limit) {
            my $t = $part;
            warn sprintf "FLOW linewrap text=[%s] ↔%.2f/%.2fmm\n", _qm($t), $part_width/mm, ($width_limit-$col)/mm,
                if $verbose > 3 && $part_width > $width_limit-$col;
            while ( $part_width > $width_limit-$col ) {
                $t =~ s#[\N{ZWNJ} ]+[^\N{ZWNJ} ]*$## or $col == 0 ? $t =~ s#.$## : ($t = '') or last;
                $part_width = $text->advancewidth($t);
            }
            if ($t ne '' || $col > 0) {
                (my $u = substr($part, length($t))) =~ s#^[\N{ZWNJ} ]+##;
                $t =~ s#\N{NBSP}# #g;
                warn sprintf "FLOW wrapdone text=[%s]+[%s] ↔%.2f/%.2fmm\n", _qm($t), _qm($u), $part_width/mm, ($width_limit-$col)/mm,
                    if $verbose > 3 && $u ne '';
                unshift @parts, "\n", "  $u" if $u ne '';
                $part = $t;
            }
            else {
                warn sprintf "FLOW cantwrap text=[%s] col=%.2fmm\n", $t, $col/mm if $verbose > 3;
            }
        }
        $part ne '' or next;
        $height >= -$ypos or $height = -$ypos;
        push @{$tt->{e}}, [$part, $fontname, $fontsize, $fontstyle, $ypos, $left, $qrotation, $yscale, $xscale];
        $col += $part_width;
    }

    $width >= $col or $width = $col;
    warn sprintf "FLOW text=[%s] font=%.2fmm pos=(→%.2fmm,↑%.2fmm) -> size=(↔%.2fmm,↕%.2fmm) (%u lines) return=(↔%.2fmm,↕%.2fmm)\n",
                _qm $str, $fontsize/mm,
                $left/mm, $top/mm,
                $width/mm, ($ypos - $top)/mm,
                $lines,
                $col/mm, ($lines > 1 && $top - $ypos - $lineheight)/mm,
        if $verbose > 3;

    $tt->{ypos} = $top;
    $tt->{xpos} = $left;
    $tt->{col}  = $col;
    $tt->{h}    = $height;
    $tt->{w}    = $width;
    return $tt;
}

sub at {
    my ($tt, $y_pos, $x_pos, $q_rotation, $y_scale, $x_scale) = @_;
    my $pq = $tt->{pq};
    my $text = $pq->text;
    $y_pos //= 0;
    $x_pos //= 0;
    $q_rotation //= 0;
    $y_scale //= 1;
    $x_scale //= 1;
    for my $e ( @{ $tt->{e} } ) {
        my ($str, $fontname, $fontsize, $fontstyle, $ypos, $xpos, $qrotation, $yscale, $xscale) = @$e;
        if ($q_rotation) {
            # TODO: decide whether to support changing the centre of rotation
            use constant HalfPi => atan2(1, 1)*2;  # arctangent(1)=π/4 (1/8 of a circle)
            my $r = $q_rotation*HalfPi;
            my $s = sin $r; # TODO: figure out whether this should be positive or negative
            my $c = cos $r;
            ($xpos, $ypos) = ($c*$xpos + $s*$ypos, -$s*$xpos + $c*$ypos);
        }

        $xpos += $x_pos;
        $ypos += $y_pos;
        $qrotation += $q_rotation;
        ($yscale //= 1) *= $y_scale;
        ($xscale //= 1) *= $x_scale;

        $pq->font( $fontname, $fontsize, $fontstyle );
        my $underline = $fontstyle & PDF::paginator::b_Underline;

        $text->transform(
            -translate => [$xpos, $ypos],
            -rotate    => $qrotation * 90,
            -scale     => [$xscale, $yscale],
          # -skew      => [$sa, $sb],
        );
        $text->text($str, $underline ? ( -underline => 'auto' ) : ());
    }
    return my ($h, $w, $t, $b, $l, $r);
}

#sub DESTROY { }
1;
