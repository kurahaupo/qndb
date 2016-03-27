#!/module/for/perl
# vim: set et sw=4 sts=4 nowrap :

use strict;
use 5.010;
use warnings;
use utf8;

package M::Book;

use Carp 'croak';
use POSIX 'strftime';

use constant CHECK_ARGS => 1;

use verbose;

use math_constants qw[ PHI ];
use list_functions qw[ max min uniq ];
use quaker_info qw(
                    $mm_keys_re
                    @mm_order
                    %mm_titles
                    %skip_mm_listing
                    %skip_wg_listing
                    %wg_abbrev
                    @wg_order
                  );

use CSV::gmail;

use PDF::scale_factors;
use PDF::paginator;

use M::IO qw( _open_output _close_output );

use M::Selection qw(
                     &sort_by_givenname
                     &sort_by_surname
                     $skip_newsletters_only
                     $skip_suppressed_listing
                   );
use M::Selection qw( $skip_suppressed_post );

our $do_book = 0;
my $do_book_index_all;
my $do_book_index_by_mm;
my $do_book_index_by_wg;
my $do_book_listing_all;
my $do_book_listing_by_mm;
my $do_book_listing_by_wg;
my $book_phones_first = 1;
my $use_page_numbers;

########################################
# Book formatting options

our $book_intercolumn_margin; #  = 10*mm;
my $book_interdetail_spacing = 1.75*mm;

my $book_sort_by_givenname;  # } will output BOTH lists if both these are selected
my $book_sort_by_surname;    # }

my $book_fontname  = 'Helvetica';
my $book_email_fontname  = 'Courier';
my $book_fontsize = 8.5*pt;     # depends on page size scaling
my $book_pagenumber_fontsize = $book_fontsize / PHI;
my $book_margin_fontsize = $book_fontsize * sqrt(PHI);

sub use_preset {
    my $pt = pop;

    state $x = warn Dumper($paper_sizes) if $verbose > 4 && $debug;

    state $page_product = {
        ( map { ( $_     => { num_labels_across => 2, num_labels_down => 3, } ) } keys %$paper_sizes ),
        ( map { ( $_.'R' => { num_labels_across => 3, num_labels_down => 2, } ) } keys %$paper_sizes ),

        'book' => {
                page_size          => 'a5',
              # page_height        => 210.224*mm,
              # page_width         => 148.651*mm,

                page_left_margin   => 13*mm,
                page_right_margin  => 13*mm,
                page_bottom_margin => 10*mm,
                page_top_margin    => 10*mm,
                book_intercolumn_margin => 7*mm,
            },

        };

    state $y = warn Dumper($page_product) if $verbose > 4 && $debug;

    my $p = $page_product->{$pt} || return; #die "Unknown label or paper product '$pt'\nAvailable presets are @{[sort keys %$page_product]}\n";
    (
        $book_intercolumn_margin,
    ) = @$p{qw{
        book_intercolumn_margin
    }};
}

use run_options (
    'book-index-all'            => \$do_book_index_all,
    'book-index-by-mm'          => \$do_book_index_by_mm,
    'book-index-by-wg'          => \$do_book_index_by_wg,
    'book-listing-all'          => \$do_book_listing_all,
    'book-listing-by-mm'        => \$do_book_listing_by_mm,
    'book-listing-by-wg'        => \$do_book_listing_by_wg,
    '!book-names-first'         => \$book_phones_first,
    'book-phones-first'         => \$book_phones_first,
    'page-numbering!'           => \$use_page_numbers,

    'sort-book-by-givenname'    => \$book_sort_by_givenname,
    'sort-book-by-surname'      => \$book_sort_by_surname,

   '+preset=s'                  => \&use_preset,

    '='                         => sub {  $book_sort_by_surname //= ! $book_sort_by_givenname;
                                          $do_book ||= $do_book_index_by_wg
                                                          || $do_book_index_by_mm
                                                          || $do_book_index_all
                                                          || $do_book_listing_by_wg
                                                          || $do_book_listing_by_mm
                                                          || $do_book_listing_all
                                                          || 0;
                                          $skip_newsletters_only   //= $do_book;
                                          $skip_suppressed_listing //= $do_book;
                                          1;
                                       },

    'help-book'                 => <<EndOfHelp,
"book" options:
    --book-index-all
    --book-index-by-mm
    --book-index-by-wg
    --book-listing-all
    --book-listing-by-mm
    --book-listing-by-wg
    --book-names-first          tabulate main list as: name, phone, address
    --book-phones-first         tabulate main list as: phone, name, address
    --sort-book-by-{surname|givenname}  NB: will output BOTH lists if both these are selected
    (plus all "pdf-output" options)

See:
    $0 --help-pdf
    $0 --help-generic
EndOfHelp

);

use verbose;

################################################################################

    sub is_code($) { UNIVERSAL::isa($_[0], 'CODE') }
    sub is_hash($) { UNIVERSAL::isa($_[0], 'HASH') }
    sub is_regex($) { UNIVERSAL::isa($_[0], 'Regexp') }
    sub is_array($) { UNIVERSAL::isa($_[0], 'ARRAY') }
    sub is_array_of($$;$) {
        my ($array,$chk,$all) = @_;
        is_array($array) or return 0;
        my $c = $_[1] || return 1;
        for my $elem ( @$array ) {
            $c->validate($elem)       or return 0 if UNIVERSAL::can($c, 'validate');
            $c->($elem)               or return 0 if is_code($c);
            $elem =~ $c               or return 0 if is_regex($c);
            UNIVERSAL::isa($elem, $c) or return 0;
        } continue {
            $_[2] || last;
        }
        return 1;
    }
    sub is_bool($)   { my $z = $_[0]; !ref $z && $z =~ m{^[01]$} }
    sub is_number($) { my $z = $_[0]; !ref $z && $z =~ m{^\-?\d+(?:\.\d+|)$} }

    sub yn($) { $_[0] ? 'yes' : 'no' }

    #
    # some simple manglers to provide recognizably distinct data
    #
    sub rot13($)   { $_[0] =~ tr{ A-M N-Z a-m n-z 0-4 5-9 }
                                { N-Z A-M n-z a-m 5-9 0-4 }r }
    sub phoneme($) { $_[0] =~ tr{ AE OU IY BP DT FV GK SZ LR MN CQ HJ WX ao eu iy bp dt fv gk sz lr mn cq hx jw 0123456789 }
                                { EA UO YI PB TD VF KG ZS RL NM QC JH XW oa ue yi pb td vf kg zs rl nm qc xh wj 9876543210 }r }
    sub bitflip($) { $_[0] =~ s{\w}{ pack "U", (ord($&)-2^1)+1 }er }
    sub backwards($) { scalar reverse $_[0] }

    #
    # render a list in columns, with pagination
    #
    sub render_columnated_list($$$$$;$$$) {
        my ( $pq, $render_one, $render_context, $rr, $items_across, $visible, $col, $top ) = @_;
        $col //= -1;    # start at top of first column
        $top //= 0;
        if (CHECK_ARGS) {
            @_ == 6 || @_ == 8 or croak "Wrong number of args";
            UNIVERSAL::isa($pq, PDF::paginator::) or croak "arg 1 is not a PDF::paginator";
            is_code $render_one or croak "arg 2 is not a sub";
            is_hash($render_context) or croak "arg 3 is not a hashref";
            is_array    $rr               or croak         "arg 4 is not an array";
            is_number $items_across or croak "arg 5 is not a number (items-across)";
            is_bool $visible or croak "arg 6 is not a bool (visible)";
            is_number $col or croak "arg 7 is not a number (column number)";
            is_number $top or croak "arg 8 is not a number (top-position)";
        }
        my $printable_page_width  = $page_width  - $page_left_margin - $page_right_margin;
        my $column_step = ($printable_page_width + $book_intercolumn_margin)  / $items_across;
        my $column_width  = $column_step - $book_intercolumn_margin;

        # running estimate of worst-case item height
        my $height_limit = 0;
        my $zi = 0;
        for my $r (@$rr) {
            my $item_height = 0;

            # Compute exact item height in advance if either (a) not visible
            # (dimensions are all that are wanted), or (b) we're getting close
            # to the bottom of the column; otherwise use an estimate based on
            # 4× the current worst-case.
            my $item_height_estimate = $height_limit * 4;
            if ( $top - $item_height_estimate < $page_bottom_margin || ! $visible ) {
                $item_height =
                $item_height_estimate = $render_one->( $pq, $r, $render_context, $column_width, 0 ); # INVISIBLE: only compute size
            }

            # Move to next column if there isn't enough room left for whole item
            if ( $top - $item_height_estimate < $page_bottom_margin || $col < 0 ) {
                $top  = $page_height - $page_top_margin;
                ++$col;
                # Move to next page if this page is full
                if ($col >= $items_across) {
                    warn "Throwpage\n" if $verbose > 1;
                    $pq->closepage if $visible;
                    $col = 0;
                }
            }
            if ($visible) {
                my $text = $pq->text;
                $text->fillcolor('black');
                my $left = $page_left_margin + $column_step * $col;
                (my $item_width, $item_height) = $render_one->( $pq, $r, $render_context, $column_width, 1, $top, $left ); # VISIBLE
                warn sprintf "COLUMNATION: item #%d ↑%.2fmm →%.2fmm ↕%.2fmm ↔%.2fmm\n", $zi++, $top/mm, $left/mm, $item_height/mm, $item_width/mm if $verbose > 2;
            }
            $top -= $item_height;
            $height_limit >= $item_height or $height_limit = $item_height;
        }
        return $col, $top;
    }

        sub group_by_type(@) {
            return @_ if not @_ && $_[0]->can('gtags');
            my @rr_roles;
            my @rr_meetings;
            my @rr_people;
            my @rr_others;
            for my $r ( @_ ) {
                if ($r->gtags('meeting')) {
                    push @rr_meetings, $r;
                }
                elsif ($r->gtags('role', 'admin')) {
                    push @rr_roles, $r;
                }
                elsif ($r->gtags('members', 'attenders', 'child', 'inactive')) {
                    push @rr_people, $r;
                }
                else {
                    push @rr_others, $r;
                }
            }
            return @rr_meetings, @rr_roles, @rr_people, @rr_others;
        }

    #
    # sort and render a list, possibly in multiple orders
    #
    sub render_sorted_columnated_list($$$$$;$$$) {
        my ( $pq, $render_one, $render_context, $rr, $items_across, $visible, $col, $top ) = @_;
        $visible //= 1;
        if (CHECK_ARGS) {
            @_ == 6 or @_ == 8 or croak "Wrong number of args";
            UNIVERSAL::isa($pq, PDF::paginator::) or croak "arg 1 is not a PDF::paginator";
            is_code $render_one or croak "arg 2 is not a sub";
            is_hash($render_context) or croak "arg 3 is not a hashref";
            is_array_of($rr, CSV::gmail::) or croak "arg 4 is not an array (of GMail records)";
            is_number $items_across or croak "arg 5 is not a number";
            is_bool $visible or croak "arg 6 is not a flag (visible)";
            is_number $col or croak "arg 7 is not a number (column number)" if @_ > 6;
            is_number $top or croak "arg 8 is not a number (top-position)" if @_ > 6;
        }
        if ($book_sort_by_surname) {
            @$rr = group_by_type sort_by_surname @$rr;
            $render_context->{ORDER} = 'surname';
            ($col, $top) = render_columnated_list( $pq, $render_one, $render_context, $rr, $items_across, $visible, $col, $top );
        }
        if ($book_sort_by_givenname) {
            @$rr = group_by_type sort_by_givenname @$rr;
            $render_context->{ORDER} = 'given_name';
            ($col, $top) = render_columnated_list( $pq, $render_one, $render_context, $rr, $items_across, $visible, $col, $top );
        }
        delete $render_context->{ORDER};
        return $col, $top;
    }

    my $mtg_abbrev_len = 5;

    #
    # You get listed in MM-elsewhere if
    #  1, you're tagged for it; or
    #  2, you're a member of the MM but *not* in any WG listing within that MM (including not MM-overseas)
    #
    sub elsewhere_filter($$) {
        my ($rrr, $mm) = @_;
        $rrr or return;
        return [ grep { $_->gtags( qr/^listing[- ]+$mm[- ]+elsewhere/ )
                   || ! $_->gtags( qr/^listing[- ]+$mm/ )
                     && $_->gtags( qr/^member[- ]+$mm/ )
                    } @$rrr ];
    }

sub generate_book($$;$) {
    my $out = shift;
    my $rr0 = shift;
    my $in_name = shift || '(stdin)';

#   use_preset 'book';

    my $rev_ymd;
    if ($in_name =~ /-((20\d\d)([01]\d)([0-3]\d))\./) {
        $rev_ymd = $1
    } else {
        $rev_ymd = strftime '%Y%m%d', localtime $^T;
        $rev_ymd =~ /^((20\d\d)([01]\d)([0-3]\d))$/;
    }
    my ($rev_year, $rev_month, $rev_day) = ($2,$3,$4);
    my $rev_dmmy = strftime "%d%b%Y", (0)x3, $rev_day, $rev_month-1, $rev_year-1900;

    my $copyright = sprintf "Compilation copyright ©%u The Religious Society of Friends Aotearoa New Zealand, all rights reserved. For personal use only. Revised %s", $rev_year, $rev_dmmy;

    my $rr = suppress_unwanted_records $rr0;
    @$rr = grep { $_->gtags( 'members', 'attenders', 'child', 'inactive', 'meeting' ) } @$rr;

    my %by_mm;
    my %by_wg;
    for my $r (@$rr) {
        if ( my @meetings = $r->gtags( qr/^listing[- ]+((?:$mm_keys_re|YF)\b.*)/ ) ) {
            @meetings = uniq @meetings if @meetings > 1;
            for my $m (@meetings) {
                push @{$by_wg{$m}}, $r;
            }
        }
        elsif ( ! $r->gtags( 'meeting' ) ) {
            push @{$by_wg{'NO - not in any worship group'}}, $r;
        }
        if ( my @meetings = $r->gtags( qr/^(?:listing|member)[- ]+($mm_keys_re)/ ) ) {
            @meetings = uniq @meetings if @meetings > 1;
            for my $m (@meetings) {
                push @{$by_mm{$m}}, $r;
            }
        }
        elsif ( ! $r->gtags( 'meeting' ) ) {
            push @{$by_mm{'NO - not in any meeting'}}, $r;
        }
    }
    {
        # Find meeting tags, make sure they're in the "@wg_order" list
        my @wg = keys %by_wg;
        my %w1 = map { ( $_ => 1 ) } @wg;
        my %w2 = map { ( $_ => 1 ) } @wg_order;
        delete @w1{ @wg_order };
        delete @w2{ @wg };
        ! %w1 or die sprintf "WG_ORDER is missing %s\n", join ',', sort keys %w1;
        ! %w2 or warn sprintf "WG_ORDER has excess %s\n", join ',', sort keys %w2;
    }


    my $pq = new PDF::paginator:: ( page_size => [$page_size || ($page_width, $page_height)] );

    # if pagesize was given as eg "A5", convert that back to actual dimensions
    $page_width = $pq->{page_width};
    $page_height = $pq->{page_height};

    my $printable_page_height = $page_height - $page_top_margin - $page_bottom_margin;
    my $printable_page_width  = $page_width  - $page_left_margin - $page_right_margin;
    my $fontname = $book_fontname;
    my $email_fontname = $book_email_fontname;
    my $fontsize = $book_fontsize;
    my $small_fontsize = $book_fontsize; #*2/3;
    my $lineheight = $fontsize * min 1, $line_spacing/(1+$extra_para_spacing);

    warn sprintf "Pagination info\n"
               . "page size: %.2fmm × %.2fmm (%s)\n"
               . "printable page size: %.2fmm × %.2fmm\n"
               ,
                $page_width/mm, $page_height/mm, $page_size,
                $printable_page_width/mm, $printable_page_height/mm,
        if $verbose;

    my $TB   = $pq->TB;
    my $TBI  = $pq->TBI;
    my $TBIU = $pq->TBIU;
    my $TBU  = $pq->TBU;
    my $TI   = $pq->TI;
    my $TIU  = $pq->TIU;
    my $TU   = $pq->TU;
    my $TN   = $pq->TN;

    my $render_column_heading = sub {
        my ( $pq, $r, $render_context, $column_width, $visible, $top, $left ) = @_;
        if (CHECK_ARGS) {
            if ($visible) {
                @_ == 7 or croak sprintf "Wrong number of args; expected %d with 'visible', got %d", 7, 0+@_;
            } else {
                @_ == 5 or croak sprintf "Wrong number of args; expected %d with 'invisible', got %d", 5, 0+@_;
            }
            UNIVERSAL::isa($pq, PDF::paginator::) or croak "arg 1 is not a PDF::paginator";
            ! defined $r or croak "arg 2 should be undef but is not\n";
            is_hash($render_context) or croak "arg 3 is not a hashref";
            is_number $column_width or croak "arg 4 is not a number (item-width)" if @_ >= 4;
            is_bool $visible or croak "arg 5 is not a flag (visible)" if @_ >= 5;
            is_number $top or croak "arg 6 is not a number (top-position)" if $visible;
            is_number $left or croak "arg 7 is not a number (left-position)" if $visible;
        }
        if ($verbose) {
            if ($visible) {
                warn sprintf "RENDER heading ↔%.2fmm →%.2fmm ↑%.2fmm\n", $column_width/mm, $left/mm, $top/mm
                    if $verbose > 2;
            }
            else {
                warn sprintf "SIZING heading ↔%.2fmm\n", $column_width/mm
                    if $verbose > 2;
            }
        }

        my $heading_text = $render_context->{heading} or return 0, 0;
        $heading_text = $TB . $heading_text . $TN if $render_context->{heading_bold};

        my $heading_fontname = $render_context->{heading_font} || $fontname;
        my $heading_fontsize = $render_context->{heading_size} || $fontsize;
        my $heading_line_spacing = $render_context->{heading_spacing} || $line_spacing;
        my $text = $pq->text;
        my $item_height;

        if ( $visible ) {
            (undef, $item_height) = $pq->text_flow($heading_fontname, $heading_fontsize, $heading_line_spacing, $heading_text, $column_width, $top, $left);
        } else {
            (undef, $item_height) = $pq->text_size($heading_fontname, $heading_fontsize, $heading_line_spacing, $heading_text, $column_width);
        }
        warn sprintf "HEADING: ↑%.2fmm →%.2fmm ↕%.2fmm ↔%.2fmm\n", $top/mm, $left/mm, $item_height/mm, $column_width/mm if $verbose > 2;
        return $column_width, $item_height;
    };

    # Copyright
    push @{$pq->{upon_end_page}}, sub {
            my ($pq, $pagenum) = @_;
            my $right_page = $pagenum % 2;
            $pq->text_at($copyright, { fn => $book_fontname, fs => $book_pagenumber_fontsize, y => $page_height-$page_top_margin/2, x => $page_width/2, halign => 1, valign => 1, italic => 1, });
        };

    # Page numbering
    if ($use_page_numbers) {
        # Number each page
        push @{$pq->{upon_end_page}}, sub {
            my ($pq, $pagenum) = @_;
            my $right_page = $pagenum % 2;
            $pq->text_at($pagenum, { fn => $book_fontname, fs => $book_pagenumber_fontsize, y => $page_bottom_margin/2, x => $page_width/2, halign => 1, valign => 1, italic => 1, });
        };
    }

    # Margin stamping
    push @{$pq->{upon_end_page}}, sub {
            my ($pq, $pagenum) = @_;
            my $page_data = $pq->{pagedata} or return;
            my $margin_notes = $page_data->{margin_notes_list} || $page_data->{margin_notes} or return;
            my $right_page = $pagenum % 2;
            my $mm_lh = $book_margin_fontsize*$line_spacing;
            my $top =  $page_height - $page_top_margin - $mm_lh;
            my $left = $right_page ? $page_width-$page_right_margin/2
                                   : $page_left_margin/2;
            if (ref $margin_notes) {
                $margin_notes = $right_page ? join ", ",         @$margin_notes
                                            : join ", ", reverse @$margin_notes;
            }
            $pq->text_at($margin_notes, {   fn => $fontname,
                                            fs => $book_margin_fontsize,
                                            y => $top,
                                            x => $left,
                                            r => $right_page ? 3 : 1,
                                            valign => 0,
                                            halign => 1,
                                        } );
        };

    # Render the first letter of the surname of:
    #   * the FIRST record in the top-left corner of a left page,
    #   * the LAST record in the top-right corner of a right page
    # Note that this will produce gibberish if you have (parts of) more than one list on a page
    my $first_or_last_on_page = sub {
        my ($pq, $pagenum) = @_;
        my $page_data = $pq->{pagedata} or return;
        my $right_page = $pagenum % 2;
        my $mm_lh = $book_margin_fontsize*$line_spacing;
        my $top = $page_height - $page_top_margin + $mm_lh;
        my $left;
        my $from_letter = $page_data->{first}{initial};
        my $to_letter = $page_data->{last}{initial};
        my $margin_notes = join '-', $from_letter, $to_letter eq $from_letter ? () : $to_letter;
        if ($right_page) {
            $left = $page_width-$page_right_margin/2;
        } else {
            $left = $page_left_margin/2;
        }
        $pq->text_at($margin_notes, { fn => $fontname, fs => $book_margin_fontsize, y => $top, x => $left, halign => 1, });
    };

    my %detail_widths = (
        phone   => 0.20,
        name    => 0.30,
        details => 0.50, );

    my @detail_order = $book_phones_first ? qw( phone name details )
                                          : qw( name phone details );

    my @detail_offsets = (0, @detail_widths{@detail_order[0..$#detail_order-1]});
    $detail_offsets[$_] += $detail_offsets[$_-1] for 1..$#detail_offsets;

    my %detail_offsets; @detail_offsets{@detail_order} = @detail_offsets;

    my $render_person_details = sub {
        my ( $pq, $r, $render_context, $column_width, $visible, $top, $left ) = @_;
        if (CHECK_ARGS) {
            if ($visible) {
                @_ == 7 or croak sprintf "Wrong number of args; expected %d with 'visible', got %d", 7, 0+@_;
            } else {
                @_ == 5 or croak sprintf "Wrong number of args; expected %d with 'invisible', got %d", 5, 0+@_;
            }
            UNIVERSAL::isa($pq, PDF::paginator::) or croak "arg 1 is not a PDF::paginator ref";
            UNIVERSAL::isa($r, CSV::gmail::) or croak "arg 2 is not a gmail record";
            is_hash($render_context) or croak "arg 3 is not a hashref";
            is_number $column_width or croak "arg 4 is not a number (item-width)" if @_ >= 4;
            is_bool $visible or croak "arg 5 is not a flag (visible)" if @_ >= 5;
            is_number $top or croak "arg 6 is not a number (top-position)" if $visible;
            is_number $left or croak "arg 7 is not a number (left-position)" if $visible;
        }

        my $inactive = $r->gtags('inactive','child');
        my $ismeeting = $r->gtags('meeting');
        my $ismember = $r->gtags('members');
        my $name = $r->name;
        my $family_name = $name->{family_name};
        $name = "$name";
        $name =~ s/\([^()]*\)//g;

        my $page_data = $pq->{pagedata} ||= {};

        # add to margin notes
        if ( my $margin_note = $render_context->{margin_note} ) {
            if ( ! $page_data->{seen_margin_note}{$margin_note}++ ) {
                my $mn = $page_data->{margin_notes_list} ||= [];
                push @$mn, $margin_note;
            }
        }

        my $order_name = $render_context->{ORDER} eq 'surname' ? $family_name : $name;
        my $order_initial = substr $order_name, 0, 1;

        # record name info of last entry on page
        $page_data->{last} = {  initial     => $order_initial,
                                oname       => $order_name,
                                full_name   => $name,
                                family_name => $family_name, };
        # record name info of first entry on page
        $page_data->{first} ||= $page_data->{last};

        if ($name) {
            my $N = $ismember ? $TU  : $inactive ? $TI  : $TN;
            my $B = $ismember ? $TBU : $inactive ? $TBI : $TB;
            if ($ismeeting || !$family_name) {
                $name = $B.$name.$TN;
            }
            else {
                $name =~ s/(.*)($family_name)(.*)/$N$1$B$2$N$3$TN/;
            }
        }

        my @phones = map { localize_phone $_ } $r->listed_phone;
        my $emails = join " ", uniq $r->listed_email;
        my $phones = join "\n", map { s/(?<=\d) (?=\d)/\N{NBSP}/gr } @phones;
        my $addresses = join "\n", ( map { s/\n/, /gr } $r->listed_address );

        my @subcolumn_offset = map { $_ * ($column_width + $book_interdetail_spacing) } @detail_offsets{qw( phone name details )}, 1;
        my @subcolumn_width  = map { $_ * ($column_width + $book_interdetail_spacing) - $book_interdetail_spacing } @detail_widths{qw( phone name details )};
        my ($h1,$h2,$h3) = (0) x 3;
        if ($visible) {
            (undef, $h1) = $pq->text_flow($fontname, $fontsize, $line_spacing, $phones,    $subcolumn_width[0], $top, $left + $subcolumn_offset[0]);
            (undef, $h2) = $pq->text_flow($fontname, $fontsize, $line_spacing, $name,      $subcolumn_width[1], $top, $left + $subcolumn_offset[1]);
            if ($addresses) {
                (undef, my $h4) = $pq->text_flow($fontname, $fontsize, $line_spacing, $addresses, $subcolumn_width[2], $top, $left + $subcolumn_offset[2]);
                $h3 += $h4;
            }
            if ($emails) {
                (undef, my $h4) = $pq->text_flow($email_fontname, $fontsize, $line_spacing, $emails,  $subcolumn_width[2], $top-$h3, $left + $subcolumn_offset[2]);
                $h3 += $h4;
            }
        }
        else {
            (undef, $h1) = $pq->text_size($fontname, $fontsize, $line_spacing, $phones,    $subcolumn_width[0]);
            (undef, $h2) = $pq->text_size($fontname, $fontsize, $line_spacing, $name,      $subcolumn_width[1]);
            if ($addresses) {
                (undef, my $h4) = $pq->text_size($fontname, $fontsize, $line_spacing, $addresses, $subcolumn_width[2]);
                $h3 += $h4;
            }
            if ($emails) {
                (undef, my $h4) = $pq->text_size($email_fontname, $fontsize, $line_spacing, $emails, $subcolumn_width[2]);
                $h3 += $h4;
            }
        }
        my $item_height = $lineheight*$extra_para_spacing + max $h1, $h2, $h3;
        if ($verbose) {
            my $fmt = $visible ? "RENDER details ↕%.2fmm=%.2f*%.2f*(%.2f,%.2f,%.2f) ↔%.2fmm ↑%.2fmm →%.2fmm"
                               : "SIZING details ↕%.2fmm=%.2f*%.2f*(%.2f,%.2f,%.2f) ↔%.2fmm";
            warn sprintf "$fmt\n", $item_height/mm, ($lineheight/mm, $extra_para_spacing, $h1, $h2, $h3),
                                    $column_width/mm,
                                    ($top//0)/mm, ($left//0)/mm
                if $verbose > 2;
        }
        # create pagenum cross references for later use by indexing
        push @{$r->{_page_xrefs}}, $pq->pagenum if $visible;
        return $column_width, $item_height;
    };

    my $render_person_index = sub {
        my ( $pq, $r, $render_context, $column_width, $visible, $top, $left ) = @_;
        if (CHECK_ARGS) {
            if ($visible) {
                @_ == 7 or croak sprintf "Wrong number of args; expected %d with 'visible', got %d", 7, 0+@_;
            } else {
                @_ == 5 or croak sprintf "Wrong number of args; expected %d with 'invisible', got %d", 5, 0+@_;
            }
            UNIVERSAL::isa($pq, PDF::paginator::) or croak "arg 1 is not a PDF::paginator ref";
            UNIVERSAL::isa($r, CSV::gmail::) or croak "arg 2 is not a gmail record";
            is_hash($render_context) or croak "arg 3 is not a hashref";
            is_number $column_width or croak "arg 4 is not a number (item-width)" if @_ >= 4;
            is_bool $visible or croak "arg 5 is not a flag (visible)" if @_ >= 5;
            is_number $top or croak "arg 6 is not a number (top-position)" if $visible;
            is_number $left or croak "arg 7 is not a number (left-position)" if $visible;
        }

        # retrieve pagenum cross references
        my @page_xrefs;
        if ( $use_page_numbers ) {
            @page_xrefs = @{$r->{_page_xrefs} ||= []};
            if (@page_xrefs == 1) {
                @page_xrefs = sprintf "p.%u", @page_xrefs;
            } elsif ( @page_xrefs > 1 ) {
                @page_xrefs = sprintf "pp.%s", join ",\N{ZWNJ}", @page_xrefs;
            }
            $_ = $TI . $_ . $TN for @page_xrefs;
        }

        if ($verbose) {
            if ($visible) {
                warn sprintf "RENDER index ↔%.2fmm →%.2fmm ↑%.2fmm\n", $column_width/mm, $left/mm, $top/mm
                    if $verbose > 2;
            }
            else {
                warn sprintf "SIZING index ↔%.2fmm\n", $column_width/mm
                    if $verbose > 2;
            }
        }

        my $text = $pq->text;
        my $width = 0;

        my $inactive = $r->gtags('inactive','child');
        my $ismeeting = $r->gtags('meeting');
        my $ismember = $r->gtags('members');
        my $name = $r->name;
        my $family_name = $name->{family_name};
        $name = "$name";
        $name =~ s/\([^()]*\)//g;

        my $page_data = $pq->{pagedata} ||= {};

        # add to margin notes
        if ( my $margin_note = $render_context->{margin_note} ) {
            if ( ! $page_data->{seen_margin_note}{$margin_note}++ ) {
                my $mn = $page_data->{margin_notes_list} ||= [];
                push @$mn, $margin_note;
            }
        }

        my $order_name = $render_context->{ORDER} eq 'surname' ? $family_name : $name;
        my $order_initial = substr $order_name, 0, 1;

        # record name info of last entry on page
        $page_data->{last} = {  initial     => $order_initial,
                                oname       => $order_name,
                                full_name   => $name,
                                family_name => $family_name, };
        # record name info of first entry on page
        $page_data->{first} ||= $page_data->{last};

        if ($name) {
            my $N = $ismember ? $TU  : $inactive ? $TI  : $TN;
            my $B = $ismember ? $TBU : $inactive ? $TBI : $TB;
            if ($ismeeting || !$family_name) {
                $name = $B.$name.$TN;
            }
            else {
                $name =~ s/(.*)($family_name)(.*)/$N$1$B$2$N$3$TN/;
            }
        }

        my @listings = map { $wg_abbrev{$_} && $wg_abbrev{$_}[$mtg_abbrev_len] || $_ }
                           $r->gtags(qr/^listing[- ]+(\w\w\w?\b.*)/) if ! $ismeeting;

        my @phones = map { localize_phone $_ } $r->listed_phone;

        my $dat = join '  ', $name,
                             @listings,
                             @page_xrefs,
                             @phones,
                             ;

        my (undef, $item_height) = $visible ? $pq->text_flow($fontname, $fontsize, $line_spacing, $dat, $column_width, $top, $left)
                                            : $pq->text_size($fontname, $fontsize, $line_spacing, $dat, $column_width);

        warn sprintf "ITEM: ↑%.2fmm →%.2fmm ↕%.2fmm ↔%.2fmm\n", $top/mm, $left/mm, $item_height/mm, $column_width/mm if $verbose > 2;
        return $column_width, $item_height;
    };

    if ($do_book_listing_all) {
        warn "doing book LISTING - all\n" if $verbose;
        # Margin name index letters
        my %render_context = (  margin_note     => "(full alphanetical listing)",
                                heading         => "Everyone",
                                heading_bold    => 1,
                                heading_size    => $fontsize * PHI,
                             );
        push @{$pq->{upon_end_page}}, $first_or_last_on_page;   # need closepage after each group with this
        my ($col, $top) = render_columnated_list    ($pq, $render_column_heading, \%render_context, [undef], 1, 1, undef, undef);
        ($col, $top) = render_sorted_columnated_list($pq, $render_person_details, \%render_context, $rr, 1, 1, $col, $top);
        $pq->closepage;
        pop @{$pq->{upon_end_page}};
    }

    if ($do_book_listing_by_mm) {
        warn "doing book LISTING - by MM\n" if $verbose;
        push @{$pq->{upon_end_page}}, $first_or_last_on_page;   # need closepage after each group with this
        for my $mm ( @mm_order ) {
            $skip_mm_listing{$mm} and next;
            my $rrr = $by_mm{$mm} or next;
            warn sprintf "doing book LISTING - for MM '%s'\n", $mm if $verbose;
            my $heading = $mm_titles{$mm};
            my %render_context = (  margin_note     => $heading,
                                    heading         => $heading,
                                    heading_bold    => 1,
                                    heading_size    => $fontsize * PHI,
                                 );
            $pq->closepage;
            my ($col, $top) = render_columnated_list    ($pq, $render_column_heading, \%render_context, [undef], 1, 1, undef, undef);
            ($col, $top) = render_sorted_columnated_list($pq, $render_person_details, \%render_context, $rrr, 1, 1, $col, $top);
        }
        $pq->closepage;
        pop @{$pq->{upon_end_page}};
    }

    if ($do_book_listing_by_wg) {
        warn "doing book LISTING - by WG\n" if $verbose;
        my $col;
        my $top = 0;
        for my $wg ( @wg_order ) {
            $skip_wg_listing{$wg} and next;
            my ($mm, $heading) = split /[- ]+/, $wg, 2;
            my $margin_note = $heading //= '';

            my $rrr;
            if ( $heading eq 'elsewhere' ) {
                $rrr = elsewhere_filter $by_mm{$mm}, $mm or next;
                $heading = sprintf "%s, in other parts of NZ", $mm_titles{$mm};
                $margin_note = sprintf "%s MM in NZ", $mm;
            } else {
                $rrr = $by_wg{$wg} or next;
                if ( $heading eq 'overseas' ) {
                    $heading = sprintf "%s, overseas", $mm_titles{$mm};
                    $margin_note = sprintf "%s MM overseas", $mm;
                } elsif ($mm eq 'YF') {
                    $heading = join ' ', 'Young Friends', $heading || ();
                }
            }

            warn sprintf "doing book LISTING - for WG '%s'\n", $heading if $verbose;

            my %render_context = (  margin_note     => $margin_note,
                                    heading         => $heading,
                                    heading_bold    => 1,
                                    heading_size    => $fontsize * PHI,
                                 );
            if ( $top < $fontsize*$line_spacing*(6+@$rrr/2) ) { $top = 0 }    # skip to next column if not enough room for 6 lines or if the following list is "large"
            else { $top -= $fontsize*$line_spacing*2 }              # leave 2 blank lines between end of previous group and heading for next group
            ($col, $top) = render_columnated_list       ($pq, $render_column_heading, \%render_context, [undef], 1, 1, $col, $top);
            ($col, $top) = render_sorted_columnated_list($pq, $render_person_details, \%render_context, $rrr, 1, 1, $col, $top);
        }
        $pq->closepage;
    }

    if ($do_book_index_all) {
        warn "doing book INDEX - all\n" if $verbose;
        # Margin name index letters
        push @{$pq->{upon_end_page}}, $first_or_last_on_page;   # need closepage after each group with this
        my %render_context = (  margin_note     => "full alphanetical index",
                                heading         => "Everyone",
                                heading_bold    => 1,
                                heading_size    => $fontsize * PHI,
                             );
        my ($col, $top) = render_columnated_list    ($pq, $render_column_heading, \%render_context, [undef], 1, 1, undef, undef);
        ($col, $top) = render_sorted_columnated_list($pq, $render_person_index, \%render_context, $rr, 3, 1, $col, $top);
        $pq->closepage;
        pop @{$pq->{upon_end_page}};
    }

    if ($do_book_index_by_mm) {
        warn "doing book INDEX - by MM\n" if $verbose;
        push @{$pq->{upon_end_page}}, $first_or_last_on_page;   # need closepage after each group with this
        for my $mm ( @mm_order ) {
            $skip_mm_listing{$mm} and next;
            warn sprintf "doing book INDEX - for MM '%s'\n", $mm if $verbose;
            my $rrr = $by_mm{$mm} or next;
            $pq->closepage;
            my $h = $mm_titles{$mm};
            my %render_context = (  margin_note     => $h,
                                    heading         => $h,
                                    heading_bold    => 1,
                                    heading_size    => $fontsize * PHI,
                                 );
            my ($col, $top) = render_columnated_list    ($pq, $render_column_heading, \%render_context, [undef], 1, 1, undef, undef);
            ($col, $top) = render_sorted_columnated_list($pq, $render_person_index, \%render_context, $rrr, 3, 1, $col, $top);
            $pq->closepage;
        }
        pop @{$pq->{upon_end_page}};
    }

    if ($do_book_index_by_wg) {
        warn "doing book INDEX - by WG\n" if $verbose;
        my $col;
        my $top = 0;
        for my $wg ( @wg_order ) {
            $skip_wg_listing{$wg} and next;
            my ($mm, $heading) = split /[- ]+/, $wg, 2;
            my $margin_note = $heading;

            my $rrr;
            if ( $heading eq 'elsewhere' ) {
                $rrr = elsewhere_filter $by_mm{$mm}, $mm or next;
                $heading = sprintf "%s, in other parts of NZ", $mm_titles{$mm};
                $margin_note = sprintf "%s MM in NZ", $mm;
            } else {
                $rrr = $by_wg{$wg} or next;
                if ( $heading eq 'overseas' ) {
                    $heading = sprintf "%s, overseas", $mm_titles{$mm};
                    $margin_note = sprintf "%s MM overseas", $mm;
                } elsif ($mm eq 'YF') {
                    $heading = join ' ', 'Young Friends', $heading || ();
                }
            }

            warn sprintf "doing book INDEX - for WG '%s'\n", $heading if $verbose;

            my %render_context = (  margin_note     => $margin_note,
                                    heading         => $heading,
                                    heading_bold    => 1,
                                    heading_size    => $fontsize * PHI,
                                 );
            if ( $top < $fontsize*$line_spacing*(6+@$rrr/2) ) { $top = 0 }    # skip to next column if not enough room for 6 lines or if the following list is "large"
            else { $top -= $fontsize*$line_spacing*2 }              # leave 2 blank lines between end of previous group and heading for next group
            ($col, $top) = render_columnated_list       ($pq, $render_column_heading, \%render_context, [undef], 3, 1, $col, $top);
            ($col, $top) = render_sorted_columnated_list($pq, $render_person_index, \%render_context, $rrr, 3, 1, $col, $top);
        }
        $pq->closepage;
    }

    $pq->closepage;
    delete $pq->{upon_end_page};

    ( $out, my $out_name, my $close_when_done ) = _open_output $out, 1;
    print "Writing PDF to $out_name ($out)\n";
    print {$out} $pq->stringify;
    _close_output $out, $out_name, $close_when_done;
}

use export qw( generate_book $do_book );

1;
