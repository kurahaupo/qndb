#!/module/for/perl

use 5.010;
use strict;
use warnings;
use utf8;

package quaker_info;

use verbose;

our %mm_names = map { ( /^([A-Z]{2,3}) - / ? $1 : $_ ) => $_ }
    'BP - Bay of Plenty',
    'CH - Christchurch',
    'DN - Dunedin',
    'KP - Kāpiti',
    'MNI - Mid North Island',
    'NT - Northern',
    'PN - Palmerston North',
    'TN - Taranaki',
    'WG - Whanganui',
    'WN - Wellington',
    'YF - Young Friends',
    'NO - not in any meeting',
    'XX - practice',
    'control - control',
;

# Arrange Monthly Meetings in North-to-South order
our @mm_order = qw( NT MNI WG TN PN KP WN CH DN YF NO XX control );

our %skip_mm_listing = (
#       AK => 1,
#       BOPA => 1,
    );

# Arrange Worship Groups in North-to-South order
our @wg_order = (

    'NT - Kaitaia',
    'NT - Bay of Islands',  # Kerikeri
    'NT - Whangārei',
    'NT - Warkworth',
    'NT - Waiheke',         # Palm Beach
    'NT - North Shore',     # Takapuna
    'NT - Mt Eden',
    'NT - elsewhere',
    'NT - overseas',

    'MNI - Thames & Coromandel', # Thames
    'MNI - Hamilton',
    'MNI - Tauranga',
    'MNI - Rotorua-Taupo',
    'MNI - Wairarapa',
    'MNI - elsewhere',
    'MNI - overseas',

    'TN - New Plymouth',
    'TN - Stratford',
    'TN - elsewhere',
    'TN - overseas',

    'WG - Settlement',      # Otamatea  } 3.7 km apart
    'WG - Whanganui',       #           }
    'WG - elsewhere',
    'WG - overseas',

    'PN - Hawkes Bay',      # Hastings (actually itinerant; also, north of Whanganui)
    'PN - Palmerston North', # West End
    'PN - Levin',
    'PN - Kahuterawa',
    'PN - elsewhere',
    'PN - overseas',

    'KP - Kāpiti',          # Paraparaumu   } 2.7 km apart
    'KP - Raumati',         # Raumati Beach } (but different days)
    'KP - elsewhere',
    'KP - overseas',

    'WN - Wairarapa',       # Masterton
    'WN - Hutt Valley',     # Petone
    'WN - Wellington',      # Mt Victoria
    'WN - elsewhere',
    'WN - overseas',

    'CH - Golden Bay',      # Pakawau
    'CH - Marlborough',     # Blenheim
    'CH - Motueka',
    'CH - Nelson',
    'CH - Christchurch',
    'CH - South Canterbury',
    'CH - Westland',        # Greymouth
    'CH - elsewhere',
    'CH - overseas',

    'DN - Dunedin',
    'DN - Invercargill',
    'DN - elsewhere',
    'DN - overseas',

    'YF',
    'YF - elsewhere',
    'YF - overseas',

    'NO - not in any worship group',

);

our %skip_wg_listing = (
    'YF - overseas' => 1,
    );

our $mm_keys_re = eval sprintf "qr/\\b(?:%s)\\b/o", join '|', keys %mm_names;

our %mm_titles = map { ( $_ => ($mm_names{$_} =~ s/$mm_keys_re[- ]+//r).' MM' ) } keys %mm_names;

################################################################################

# strings that might come from a database or spreadsheet.
our %wg_map = (

    'CH - Canterbury'                   => 'CH - Christchurch',
    'CH - Christchurch Worship Group'   => 'CH - Christchurch',
    'CH - Nelson Recognised Meeting'    => 'CH - Nelson',

    'DN - Otago'                        => 'DN - Dunedin',
    'DN - Dunedin Worship Group'        => 'DN - Dunedin',
    'DN - Southland'                    => 'DN - Invercargill',

    'KP - Kapiti'                       => 'KP - Kāpiti',

    'MNI - Waikato'                     => 'MNI - Hamilton',
    'MNI - Whakatane'                   => 'MNI - Wairarapa',
    'MNI - Wairarapa Worship Group'     => 'MNI - Wairarapa',
    'MNI - Whakatane'                   => 'MNI - Wairarapa',

    'NONE'                              => 'NO - not in any worship group',
    'Not attending any NZ meeting'      => 'NO - not in any worship group',
    'control - Not attending any NZ meeting' => 'NO - not in any worship group',

    'NT - Waiheke Island, Auckland'     => 'NT - Waiheke',
    ' Auckland'                         => 'NT - Waiheke',      # NB: this is split from "Waiheke Island, Auckland"
    'NT - Waiheke Island'               => 'NT - Waiheke',      # NB: this is split from "Waiheke Island, Auckland"
    'NT - Whangarei'                    => 'NT - Whangārei',

    'PN - Kahuterawa Worship Group'     => 'PN - Kahuterawa',

    'WG - Quaker Settlement'            => 'WG - Settlement',

    'WN - Hutt Valley Worship Group'    => 'WN - Hutt Valley',
    'WN - Wellington Worship Group'     => 'WN - Wellington',
    'WN - Wairarapa Worship Group'      => 'WN - Wairarapa',

);

                                # prefer length 5 ──╮╭─╮╭─╮╭────╮╭─╮╭─╮╭────╮╭─────────╮
                                #         ╭─────────┼┼─╯╰─┼┼─╮╭─┼┼─╯╰─┼┼─╮╭─┼┼─────────╯
our %wg_abbrev = (              #         ╰─────────╯╰────╯╰─╯╰─╯╰────╯╰─╯╰─╯▽

        'NT - Bay of Islands'       => [ undef, 'B',   'BI', 'BoI', 'BayI', 'BayIs', 'BayOfl', 'BayOfIs', 'BayOfIsl', 'BayIsland', 'BayOfIslnd', 'BayOfIslnds', 'BayOfIslands', 'Bay ofIslands', 'Bay of Islands', ],
        'NT - Kaitaia'              => [ undef, undef, 'Kt', 'Kta', 'Ktai', 'Ktaia', 'Kaitai', 'Kaitaia', ],
        'NT - Mt Eden'              => [ undef, undef, 'ME', 'MtE', 'MtEd', 'MtEdn', 'MtEden', 'Mt Eden', ],
        'NT - North Shore'          => [ undef, undef, 'NS', 'NSh', 'NShr', 'NShre', 'NShore', 'NthShre', 'NthShore', 'NorthShre', 'NorthShore', 'North Shore', ],
        'NT - Waiheke'              => [ undef, undef, 'WI', 'WkI', 'Whke', 'Wheke', 'Waihke', 'Waiheke', ],
        'NT - Warkworth'            => [ undef, undef, 'Ww', 'Wkw', 'Wwth', 'Wkwth', 'Wrkwth', 'Warkwth', 'Warkwrth', 'Warkworth', ],
        'NT - Whangārei'            => [ undef, undef, 'Wr', 'Whr', 'Wrei', 'Whrei', 'Whgrei', 'Whgārei', 'Whngārei', 'Whangārei', ],
        'NT - elsewhere'            => [ undef, undef, '+N', '+NT', 'exNT', 'ex-NT', ],
        'NT - overseas'             => [ undef, undef, '*N', '*NT', 'osNT', 'os-NT', ],

        'MNI - Rotorua-Taupo'       => [ undef, 'R',   'RT', 'RrT', 'RrTp', 'RrTpo', 'RruTpo', 'RruaTpo', 'RtruaTpo', 'RruaTaupo', 'RotoruaTpo', 'RotoruaTaup', 'RotoruaTaupo', 'Rotorua Taupo', ],
        'MNI - Tauranga'            => [ undef, undef, 'Tg', 'Tga', 'Tnga', 'Trnga', 'Tranga', 'Taurnga', 'Tauranga', ],
        'MNI - Thames & Coromandel' => [ undef, undef, 'TC', 'ThC', 'TmCo', 'ThmCo', 'ThmCor', 'ThmCoro', 'ThamesCo', 'ThamesCor', 'ThamesCoro', 'ThamesCmndl', 'ThamesCrmndl', 'ThamesCormndl', 'ThamesCoromndl', 'ThamesCoromandl', 'ThamesCoromandle', 'Thames Coromandle', ],
        'MNI - Hamilton'            => [ undef, undef, 'Hm', 'Ham', 'Hmtn', 'Hamtn', 'Hamltn', 'Hamlton', 'Hamilton' ],
        'MNI - elsewhere'           => [ undef, undef, '+M', '+MN', 'exMN', 'ex-MN', ],
        'MNI - overseas'            => [ undef, undef, '*M', '*MN', 'osMN', 'os-MN', 'os-MNI', ],

        'PN - Hawkes Bay'           => [ undef, undef, 'HB', 'HkB', 'HwkB', 'HwkBy', 'HawkBy', 'HawksBy', 'HawkesBy', 'HawkesBay', 'Hawkes Bay', ],
        'PN - Levin'                => [ undef, undef, 'Lv', 'Lvn', 'Levn', 'Levin', ],
        'PN - Palmerston North'     => [ undef, 'P',   'PN', 'PmN', 'PNth', 'PmNth', 'PmtNth', 'PmstonN', 'PlmrstnN', 'PalmstonN', 'PalmstnNth', 'PalmstnNrth', 'PalmstnNorth', 'PalmrstnNorth', 'PalmrstonNorth', 'PalmerstonNorth', 'Palmerston North', ],
        'PN - elsewhere'            => [ undef, undef, '+P', '+PN', 'exPN', 'ex-PN', ],
        'PN - overseas'             => [ undef, undef, '*P', '*PN', 'osPN', 'os-PN', ],

        'WG - Whanganui'            => [ undef, undef, 'Wg', 'Wnu', 'Wnui', 'Whnui', 'Whgnui', 'Whganui', 'Whnganui', 'Whanganui', ],
        'WG - Settlement'           => [ undef, 'S',   'WS', 'WSt', 'WStl', 'WStlm', 'WSettl', 'WSettle', 'Settlmnt', 'Settlemnt', 'Settlement', ],
        'WG - elsewhere'            => [ undef, undef, undef,'+WG', 'exWG', 'ex-WG', ],
        'WG - overseas'             => [ undef, undef, undef,'*WG', 'osWG', 'os-WG', ],

        'TN - Taranaki'             => [ undef, 'T',   'Tn', 'Tnk', 'Tnki', 'Tnaki', 'Trnaki', 'Taranki', 'Taranaki', ],
        'TN - elsewhere'            => [ undef, undef, '+T', '+TN', 'exTN', 'ex-TN', ],
        'TN - overseas'             => [ undef, undef, '*T', '*TN', 'osTN', 'os-TN', ],

        'KP - Kāpiti'               => [ undef, 'K',   'Kp', 'Kpt', 'Kāpt', 'Kāpti', 'Kāpiti', ],
        'KP - elsewhere'            => [ undef, undef, '+K', '+KP', 'exKP', 'ex-KP', ],
        'KP - overseas'             => [ undef, undef, '*K', '*KP', 'osKP', 'os-KP', ],

        'WN - Wellington'           => [ undef, undef, 'Wn', 'Wtn', 'Wgtn', 'Wlgtn', 'Wlngtn', 'Wlngton', 'Welngton', 'Wellngton', 'Wellington', ],
        'WN - Wairarapa'            => [ undef, undef, 'Wp', 'Wrp', 'Wrpa', 'Wrrpa', 'Wairpa', 'Wairrpa', 'Wairarpa', 'Wairarapa', ],
        'WN - Hutt Valley'          => [ undef, undef, 'HV', 'HtV', 'HutV', 'HuttV', 'HuttVl', 'HuttVly', 'HuttValy', 'HuttVally', 'HuttValley', 'Hutt Valley', ],
        'WN - elsewhere'            => [ undef, undef, undef,'+WN', 'exWN', 'ex-WN', ],
        'WN - overseas'             => [ undef, undef, undef,'*WN', 'osWN', 'os-WN', ],

        'CH - Christchurch'         => [ undef, 'C',   'Ch', 'Chc', 'Chch', 'Chcch', 'Chchch', 'Chschch', 'Chrschch', 'Chrstchch', 'Christchch', 'Christchrch', 'Christchurch', ],
        'CH - Golden Bay'           => [ undef, 'G',   'GB', 'GoB', 'GldB', 'GldnB', 'GldnBy', 'GoldenB', 'GoldnBay', 'GoldenBay', 'Golden Bay', ],
        'CH - Marlborough'          => [ undef, 'M',   'Mb', 'Mbr', 'Mbro', 'Mboro', 'Mlboro', 'Marlbor', 'Marlboro', 'Marlborou', 'Marlbrough', 'Marlborough', ],
        'CH - Nelson'               => [ undef, 'N',   'Nn', 'Nsn', 'Nlsn', 'Nelsn', 'Nelson', ],
        'CH - South Canterbury'     => [ undef, undef, 'SC', 'SCt', 'SCtb', 'SCntb', 'SCntby', 'SthCnby', 'SthCntby', 'SthCantby', 'SthCantbry', 'SthCantbury', 'SthCantrbury', 'SthCanterbury', 'SouthCantrbury', 'SouthCanterbury', 'South Canterbury', ],
        'CH - Westland'             => [ undef, undef, 'Wl', 'Wld', 'Wlnd', 'Wland', 'Westld', 'Westlnd', 'Westland', ],
        'CH - elsewhere'            => [ undef, undef, '+C', '+CH', 'exCH', 'ex-CH', ],
        'CH - overseas'             => [ undef, undef, '*C', '*CH', 'osCH', 'os-CH', ],

        'DN - Dunedin'              => [ undef, 'D',   'Dn', 'Dun', 'Dndn', 'Dundn', 'Dunedn', 'Dunedin', ],
        'DN - Invercargill'         => [ undef, 'I',   'Iv', 'Inv', 'Invg', 'Invcg', 'Invcgl', 'Invcagl', 'Invcargl', 'Invrcargl', 'Invercargl', 'Invercargll', 'Invercargill', ],
        'DN - elsewhere'            => [ undef, undef, '+D', '+DN', 'exDN', 'ex-DN', ],
        'DN - overseas'             => [ undef, undef, '*D', '*DN', 'osDN', 'os-DN', ],

        'elsewhere',                => [ undef, '+',   'NZ', 'NZ ', 'NZ  ', 'other', ], # elsewhere in NZ
        'overseas',                 => [ undef, '*',   'os', 'o/s', 'o/s ', 'oseas', 'o/seas', 'ovrseas', 'overseas', ], # not in NZ

    );

CHECK {
    my %chk;
    for my $k ( keys %wg_abbrev ) {
        my $v = $wg_abbrev{$k};
        for my $i ( reverse 0 .. $#$v ) {
            my $a = $v->[$i] // next;
            my $l = length $a;
            $l == $i
                or $^C || $debug || $l > $i
                    and warn sprintf "Abbreviation '%s' is length %u, but should be %u\n", $a, $l, $i ;
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

    %skip_mm_listing
    @mm_order
    %mm_names
    %mm_titles
    $mm_keys_re

    %skip_wg_listing
    @wg_order
    %wg_abbrev
    %wg_map
    );

1;
