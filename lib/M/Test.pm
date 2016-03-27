#!/module/for/perl
# vim: set et sw=4 sts=4 nowrap :

use 5.010;
use strict;
use warnings;
use utf8;

package M::Test;

use verbose;
use list_functions qw[ min ];
use PDF::scale_factors;

use PDF::paginator;

use M::IO qw( _open_output _close_output );

my @_colors = qw[#88f #f00 gray red orange green blue purple yellow cyan brown tan];
sub color($) {
    $_colors[ $_[0] % @_colors ]
}

our $do_test = 0;

sub generate_test($) {
    my $out = shift;

    my $pq = new PDF::paginator:: ( page_size => [$page_size || ($page_width, $page_height)] );

    # if pagesize was given as eg "A5", convert that back to actual dimensions
    $page_width = $pq->{page_width};
    $page_height = $pq->{page_height};

    my $printable_page_height = $page_height - $page_top_margin - $page_bottom_margin;
    my $printable_page_width  = $page_width  - $page_left_margin - $page_right_margin;
    my $fontname = 'Helvetica';
    my $fontsize = 8.5*pt;
    my $lineheight = $fontsize * min 1, $line_spacing/(1+$extra_para_spacing);

    warn sprintf "Pagination info\n"
               . "page size: %.2fmm × %.2fmm (%s)\n"
               . "printable page size: %.2fmm × %.2fmm\n"
               ,
                $page_width/mm, $page_height/mm, $page_size,
                $printable_page_width/mm, $printable_page_height/mm,
        if $verbose;

#   $pq->pdf->MoveTo( 0, 0 );
#   $pq->pdf->LineTo( $page_width, $page_height );
#   $pq->pdf->MoveTo( $page_width, 0 );
#   $pq->pdf->LineTo( 0, $page_height );
#   $pq->closepage;

    for my $a ( 0..47 ) {
        my $gfx = $pq->gfx;
      # $gfx->strokecolor(color($a+24));
        $gfx->fillcolor(color $a);
        $gfx->move( $page_width*(rand(6)+$a%6+1)/16, $page_height*(rand(6)+$a/6%6+1)/16 );
        $gfx->line( $page_width*(rand(6)+$a%6+1)/16, $page_height*(rand(6)+$a/6%6+3)/16 );
        $gfx->line( $page_width*(rand(6)+$a%6+3)/16, $page_height*(rand(6)+$a/6%6+3)/16 );
        $gfx->line( $page_width*(rand(6)+$a%6+3)/16, $page_height*(rand(6)+$a/6%6+1)/16 );
      # $gfx->line( $page_width*4/8, $page_height*4/8 );
        $gfx->close;
        $gfx->fill;
        #$gfx->stroke;
    }
    $pq->closepage;

    for my $r ( 0..23 ) {
        for my $v ( 0..2 ) {
            for my $h ( 0..2 ) {
                my $color = color($v+$h+$r);
                $pq->text_at( sprintf('test text r=%s h=%s v=%s', $r, $h, $v),
                              x => $page_width*$h/2,
                              y => $page_height*(1-$v/2),
                              fn => 'Helvetica',
                              fs => $r*pt,
                              r => $r*2/7,
                              halign => $h,
                              valign => $v,
                              maxw => 15*cm,
                            # xscale => 0.75,
                            # yscale => 1.5,
                              color => $color,
                            );
            }
        }
    }
    $pq->closepage;

    delete $pq->{upon_end_page};

    ( $out, my $out_name, my $close_when_done ) = _open_output $out, 1;
    print "Writing PDF to $out_name ($out)\n";
    print {$out} $pq->stringify;
    _close_output $out, $out_name, $close_when_done;
}

use run_options (
    'test'                        => \$do_test,
);

use export qw( generate_test $do_test );

1;
