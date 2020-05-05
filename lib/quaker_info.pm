#!/module/for/perl

use 5.010;

use strict;
use warnings;
use utf8;

package quaker_info;

our %mm_names = map { /^([A-Z]{2,3}) - / ? ( $1 => $_ ) : ( $_ => $_ ) }
    'BP - Bay of Plenty',
    'CH - Christchurch',
    'DN - Dunedin',
    'KP - Kapiti',
    'MNI - Mid North Island',
    'NT - Northern',
    'PN - Palmerston North',
    'TN - Taranaki',
    'WG - Whanganui',
    'WN - Wellington',
    'YF - Young Friends',
    'NO - not in any meeting',
;

# Arrange Monthly Meetings in North-to-South order
our @mm_order = qw( NT MNI WG TN PN KP WN CH DN YF NO );

our %skip_mm_listing = (
#       AK => 1,
#       BOPA => 1,
    );

# Arrange Worship Groups in North-to-South order
our @wg_order = (

    'NT - Kaitaia',
    'NT - Bay of Islands',
    'NT - Whangarei',
    'NT - North Shore',
    'NT - Mt Eden',
    'NT - Howick',
    'NT - Waiheke',
    'NT - Warkworth',
    'NT - elsewhere',
    'NT - overseas',

    'MNI - Thames & Coromandel',
    'MNI - Waikato',
    'MNI - Tauranga',
    'MNI - Rotorua-Taupo',
    'MNI - Whakatane',
    'MNI - elsewhere',
    'MNI - overseas',

    'PN - Palmerston North',
    'PN - Hawkes Bay',
    'PN - Levin',
    'PN - elsewhere',
    'PN - overseas',

    'WG - Whanganui',
    'WG - elsewhere',
    'WG - overseas',

    'TN - Taranaki',
    'TN - elsewhere',
    'TN - overseas',

    'KP - Kapiti',
    'KP - Paraparaumu',
    'KP - elsewhere',
    'KP - overseas',

    'WN - Wellington',
    'WN - Wairarapa',
    'WN - Hutt Valley',
    'WN - elsewhere',
    'WN - overseas',

    'CH - Golden Bay',
    'CH - Marlborough',
    'CH - Nelson',
    'CH - Canterbury',
    'CH - South Canterbury',
    'CH - Westland',
    'CH - elsewhere',
    'CH - overseas',

    'DN - Otago',
    'DN - Southland',
    'DN - elsewhere',
    'DN - overseas',

    'YF',
    'YF - overseas',

    'NO - not in any worship group',

);

our %skip_wg_listing = (
    'YF - overseas' => 1,
    );

our $mm_keys_re = eval sprintf "qr/\\b(?:%s)\\b/o", join '|', keys %mm_names;

our %mm_titles = map { ( $_ => ($mm_names{$_} =~ s/$mm_keys_re[- ]+//r).' MM' ) } keys %mm_names;

################################################################################

                                # prefer length 5 ──╮╭─╮╭─╮╭────╮╭─╮╭─╮╭────╮╭─────────╮
                                #         ╭─────────┼┼─╯╰─┼┼─╮╭─┼┼─╯╰─┼┼─╮╭─┼┼─────────╯
our %wg_abbrev = (              #         ╰─────────╯╰────╯╰─╯╰─╯╰────╯╰─╯╰─╯▽

        'NT - Bay of Islands'       => [ undef, 'B',   'BI', 'BoI', 'BayI', 'BayIs', 'BayOfl', 'BayOfIs', 'BayOfIsl', 'BayIsland', 'BayOfIslnd', 'BayOfIslnds', 'BayOfIslands', 'Bay ofIslands', 'Bay of Islands', ],
        'NT - Howick'               => [ undef, 'Ḣ',   'Hw', 'Hwk', 'Hwck', 'Howck', 'Howick', ],
        'NT - Kaitaia'              => [ undef, undef, 'Kt', 'Kta', 'Ktai', 'Ktaia', 'Kaitai', 'Kaitaia', ],
        'NT - Mt Eden'              => [ undef, 'Ṁ',   'ME', 'MtE', 'MtEd', 'MtEdn', 'MtEden', 'Mt Eden', ],
        'NT - North Shore'          => [ undef, 'Ṅ',   'NS', 'NSh', 'NShr', 'NShre', 'NShore', 'NthShre', 'NthShore', 'NorthShre', 'NorthShore', 'North Shore', ],
        'NT - Waiheke'              => [ undef, 'Ẁ',   'WI', 'WkI', 'Whke', 'Wheke', 'Waihke', 'Waiheke', ],
        'NT - Warkworth'            => [ undef, undef, 'Ww', 'Wkw', 'Wwth', 'Wkwth', 'Wrkwth', 'Warkwth', 'Warkwrth', 'Warkworth', ],
        'NT - Whangarei'            => [ undef, 'Ẉ',   'Wr', 'Whr', 'Wrei', 'Whrei', 'Whgrei', 'Whgarei', 'Whngarei', 'Whangarei', ],
        'NT - elsewhere'            => [ undef, undef, '+N', '+NT', 'exNT', 'ex-NT', ],
        'NT - overseas'             => [ undef, undef, '*N', '*NT', 'osNT', 'os-NT', 'o/s-NT', ],

        'MNI - Rotorua-Taupo'       => [ undef, 'R',   'RT', 'RrT', 'RrTp', 'RrTpo', 'RruTpo', 'RruaTpo', 'RtruaTpo', 'RruaTaupo', 'RotoruaTpo', 'RotoruaTaup', 'RotoruaTaupo', 'Rotorua Taupo', ],
        'MNI - Tauranga'            => [ undef, 'Ť',   'Tg', 'Tga', 'Tnga', 'Trnga', 'Tranga', 'Taurnga', 'Tauranga', ],
        'MNI - Thames & Coromandel' => [ undef, 'Ṫ',   'TC', 'ThC', 'TmCo', 'ThmCo', 'ThmCor', 'ThmCoro', 'ThamesCo', 'ThamesCor', 'ThamesCoro', 'ThamesCmndl', 'ThamesCrmndl', 'ThamesCormndl', 'ThamesCoromndl', 'ThamesCoromandl', 'ThamesCoromandle', 'Thames Coromandle', ],
        'MNI - Waikato'             => [ undef, 'W',   'Wk', 'Wko', 'Wkto', 'Wkato', 'Waikto', 'Waikato', ],
        'MNI - elsewhere'           => [ undef, undef, '+M', '+MN', 'exMN', 'ex-MN', ],
        'MNI - overseas'            => [ undef, undef, '*M', '*MN', 'osMN', 'os-MN', 'o/s-MN', 'o/s-MNI', ],

        'PN - Hawkes Bay'           => [ undef, 'H',   'HB', 'HkB', 'HwkB', 'HwkBy', 'HawkBy', 'HawksBy', 'HawkesBy', 'HawkesBay', 'Hawkes Bay', ],
        'PN - Levin'                => [ undef, 'L',   'Lv', 'Lvn', 'Levn', 'Levin', ],
        'PN - Palmerston North'     => [ undef, 'P',   'PN', 'PmN', 'PNth', 'PmNth', 'PmtNth', 'PmstonN', 'PlmrstnN', 'PalmstonN', 'PalmstnNth', 'PalmstnNrth', 'PalmstnNorth', 'PalmrstnNorth', 'PalmrstonNorth', 'PalmerstonNorth', 'Palmerston North', ],
        'PN - elsewhere'            => [ undef, undef, '+P', '+PN', 'exPN', 'ex-PN', ],
        'PN - overseas'             => [ undef, undef, '*P', '*PN', 'osPN', 'os-PN', 'o/s-PN', ],

        'WG - Whanganui'            => [ undef, 'Ŵ',   'Wg', 'Wnu', 'Wnui', 'Whnui', 'Whgnui', 'Whganui', 'Whnganui', 'Whanganui', ],
        'WG - elsewhere'            => [ undef, undef, '+Ŵ', '+WG', 'exWG', 'ex-WG', ],
        'WG - overseas'             => [ undef, undef, '*Ŵ', '*WG', 'osWG', 'os-WG', 'o/s-WG', ],

        'TN - Taranaki'             => [ undef, 'T',   'Tn', 'Tnk', 'Tnki', 'Tnaki', 'Trnaki', 'Taranki', 'Taranaki', ],
        'TN - elsewhere'            => [ undef, undef, '+T', '+TN', 'exTN', 'ex-TN', ],
        'TN - overseas'             => [ undef, undef, '*T', '*TN', 'osTN', 'os-TN', 'o/s-TN', ],

        'KP - Kapiti'               => [ undef, 'K',   'Kp', 'Kpt', 'Kapt', 'Kapti', 'Kapiti', ],
        'KP - elsewhere'            => [ undef, undef, '+K', '+KP', 'exKP', 'ex-KP', ],
        'KP - overseas'             => [ undef, undef, '*K', '*KP', 'osKP', 'os-KP', 'o/s-KP', ],

        'WN - Wellington'           => [ undef, 'Ẃ',   'Wn', 'Wtn', 'Wgtn', 'Wlgtn', 'Wlngtn', 'Wlngton', 'Wllngton', 'Wellngton', 'Wellington', ],
        'WN - Wairarapa'            => [ undef, 'Ẅ',   'Wp', 'Wrp', 'Wrpa', 'Wrapa', 'Wairpa', 'Wairrpa', 'Wairarpa', 'Wairarapa', ],
        'WN - Hutt Valley'          => [ undef, 'Ḧ',   'HV', 'HtV', 'HutV', 'HutVl', 'HuttVl', 'HuttVly', 'HuttVlly', 'HuttVally', 'HuttValley', 'Hutt Valley', ],
        'WN - elsewhere'            => [ undef, undef, '+Ẃ', '+WN', 'exWN', 'ex-WN', ],
        'WN - overseas'             => [ undef, undef, '*Ẃ', '*WN', 'osWN', 'os-WN', 'o/s-WN', ],

        'CH - Canterbury'           => [ undef, 'C',   'Cn', 'Cnb', 'Cnby', 'Cntby', 'Cantby', 'Cantbry', 'Cantbury', 'Cantrbury', 'Canterbury', ],
        'CH - Golden Bay'           => [ undef, 'G',   'GB', 'GoB', 'GldB', 'GldnB', 'GldnBy', 'GoldenB', 'GoldnBay', 'GoldenBay', 'Golden Bay', ],
        'CH - Marlborough'          => [ undef, 'M',   'Mb', 'Mbr', 'Mbro', 'Mboro', 'Mlboro', 'Marlbor', 'Marlboro', 'Marlborou', 'Marlbrough', 'Marlborough', ],
        'CH - Nelson'               => [ undef, 'N',   'Nn', 'Nsn', 'Nlsn', 'Nelsn', 'Nelson', ],
        'CH - South Canterbury'     => [ undef, 'Ṡ',   'SC', 'SCt', 'SCtb', 'SCntb', 'SCntby', 'SthCnby', 'SthCntby', 'SthCantby', 'SthCantbry', 'SthCantbury', 'SthCantrbury', 'SthCanterbury', 'SouthCantrbury', 'SouthCanterbury', 'South Canterbury', ],
        'CH - Westland'             => [ undef, 'Ẇ',   'Wl', 'Wld', 'Wlnd', 'Wland', 'Westld', 'Westlnd', 'Westland', ],
        'CH - elsewhere'            => [ undef, undef, '+C', '+CH', 'exCH', 'ex-CH', ],
        'CH - overseas'             => [ undef, undef, '*C', '*CH', 'osCH', 'os-CH', 'o/s-CH', ],

        'DN - Otago'                => [ undef, 'O',   'Ot', 'Otg', 'Otgo', 'Otago', ],
        'DN - Southland'            => [ undef, 'S',   'Sl', 'Sld', 'Sthl', 'Sthld', 'Sthlnd', 'Sthland', 'Southlnd', 'Southland', ],
        'DN - elsewhere'            => [ undef, undef, '+D', '+DN', 'exDN', 'ex-DN', ],
        'DN - overseas'             => [ undef, undef, '*D', '*DN', 'osDN', 'os-DN', 'o/s-DN', ],

        'elsewhere',                => [ undef, '+',   'nz', 'nz',  'nz',   'other', 'other',  'other',   'other',    'elsewhere', ], # elsewhere in NZ
        'overseas',                 => [ undef, '*',   'os', 'o/s', 'o/s',  'oseas', 'o/seas', 'ovrseas', 'overseas', ], # not in NZ

    );

CHECK {
    my %chk;
    for my $k ( keys %wg_abbrev ) {
        my $v = $wg_abbrev{$k};
        for my $i ( reverse 0 .. $#$v ) {
            my $a = $v->[$i] // next;
            length($a) <= $i or die sprintf "Abbreviation '%s' is too long, should be %u\n", $a, $i;
            length($a) == $i or warn sprintf "Abbreviation '%s' is shorter than %u\n", $a, $i;
            $i > 0 || next;
        }
        (my $kk = $k) =~ s/^$mm_keys_re[- ]+// or next;
        $kk =~ s/\W//g;
        $wg_abbrev{$kk} ||= $v;
        for my $a ( @$v ) {
            $a // next;
            push @{$chk{$a}}, $k;
        }
    }
    # make "overseas" just a part of "elsewhere"
    for my $mm (@mm_order) {
        $wg_abbrev{"$mm - overseas"} = $wg_abbrev{"$mm - elsewhere"}
    }
    for my $a ( grep { @{$chk{$_}} > 1 } sort keys %chk ) {
        my $v = $chk{$a};
        warn sprintf "Ambiguous abbreviation '%s' may be %s\n", $a, join " or ", map { "'$_'" } @$v;
    }
}

################################################################################

our %local_country = (
    'NZ' => 1,
    'New Zealand' => 1,
);

################################################################################

use export qw(
    %local_country
    %mm_names
    @mm_order
    %skip_mm_listing
    @wg_order
    %skip_wg_listing
    $mm_keys_re
    %mm_titles
    %wg_abbrev );

1;
