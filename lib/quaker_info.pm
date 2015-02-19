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
    'WG - Whanganui Taranaki',
  # 'WK - Waikato Hauraki',
    'WN - Wellington',
    'YF - Young Friends',
    'NO - not in any meeting',
;

# Arrange Monthly Meetings in North-to-South order
our @mm_order = qw( NT MNI WG PN KP WN CH DN NO );

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
    'NT - West Auckland',
    'NT - Howick',
    'NT - Waiheke',
    'NT - elsewhere',
    'NT - overseas',

    'MNI - Thames & Coromandel',
   #'MNI - Thames',
    'MNI - Waikato',
    'MNI - Tauranga',
   #'MNI - Rotorua',
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
    'WG - Taranaki',
    'WG - elsewhere',
    'WG - overseas',

    'KP - Kapiti',
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

        'CH - Canterbury'           => [ undef, 'C', 'Cn', 'Cnb', 'Cnby', 'Cntby', 'Cantby', 'Cantbry', 'Cantbury', 'Cantrbury', 'Canterbury', ], # CH
        'CH - Golden Bay'           => [ undef, 'G', 'GB', 'GoB', 'GldB', 'GldnB', 'GldnBy', 'GoldenB', 'GoldnBay', 'GoldenBay', 'Golden Bay', ], # CH
        'CH - Marlborough'          => [ undef, 'M', 'Mb', 'Mbr', 'Mbro', 'Mboro', 'Mlboro', 'Marlbor', 'Marlboro', 'Marlborou', 'Marlbrough', 'Marlborough', ], # CH
        'CH - Nelson'               => [ undef, 'N', 'Nn', 'Nsn', 'Nlsn', 'Nelsn', 'Nelson', ], # CH
        'CH - South Canterbury'     => [ undef, 'Ṡ', 'SC', 'SCt', 'SCtb', 'SCntb', 'SCntby', 'SthCnby', 'SthCntby', 'SthCantby', 'SthCantbry', 'SthCantbury', 'SthCantrbury', 'SthCanterbury', 'SouthCantrbury', 'South Cantrbury', ], # CH
        'CH - Westland'             => [ undef, 'Ẇ', 'Wl', 'Wld', 'Wlnd', 'Wland', 'Westld', 'Westlnd', 'Westland', ], # CH
        'CH - elsewhere'            => [ undef, 'C', 'CE', 'xCH', 'exCH', 'ex-CH', 'CH-els', 'CH-else', ],
        'CH - overseas'             => [ undef, 'C', 'CO', 'oCH', 'osCH', 'os-CH', 'o/s-CH', ],
        'DN - Otago'                => [ undef, 'O', 'Ot', 'Otg', 'Otgo', 'Otago', ], # DN
        'DN - Southland'            => [ undef, 'S', 'Sl', 'Sld', 'Sthl', 'Sthld', 'Sthlnd', 'Sthland', 'Southlnd', 'Southland', ], # DN
        'DN - elsewhere'            => [ undef, 'D', 'DE', 'xDN', 'exDN', 'ex-DN', 'DN-els', 'DN-else', ],
        'DN - overseas'             => [ undef, 'D', 'DO', 'oDN', 'osDN', 'os-DN', 'o/s-DN', ],
        'KP - Kapiti'               => [ undef, 'K', 'Kp', 'Kpt', 'Kapt', 'Kapti', 'Kapiti', ], # KP
        'KP - elsewhere'            => [ undef, 'K', 'KE', 'xKP', 'exKP', 'ex-KP', 'KP-els', 'KP-else', ],
        'KP - overseas'             => [ undef, 'K', 'KO', 'oKP', 'osKP', 'os-KP', 'o/s-KP', ],
        'MN - Ielsewhere'           => [ undef, 'M', 'ME', 'xMN', 'exMN', 'ex-MN', 'MN-els', 'MN-else', ],
        'MN - Ioverseas'            => [ undef, 'M', 'MO', 'oMN', 'osMN', 'os-MN', 'o/s-MN', 'MNI-OS', ],
        'MNI - Rotorua-Taupo'       => [ undef, 'R', 'RT', 'RrT', 'RrTp', 'RrTpo', 'RruTpo', 'RruaTpo', 'RtruaTpo', 'RruaTaupo', 'RotoruaTpo', 'RotoruaTaup', 'RotoruaTaupo', 'Rotorua Taupo', ], # MNI
        'MNI - Tauranga'            => [ undef, 'Ť', 'Tg', 'Tga', 'Tnga', 'Trnga', 'Tranga', 'Taurnga', 'Tauranga', ], # MNI
        'MNI - Thames & Coromandel' => [ undef, 'Ṫ', 'TC', 'ThC', 'TmCo', 'ThmCo', 'ThmCor', 'ThmCoro', 'ThamesCo', 'ThamesCor', 'ThamesCoro', 'ThamesCmndl', 'ThamesCrmndl', 'ThamesCormndl', 'ThamesCoromndl', 'ThamesCoromandl', 'ThamesCoromandle', 'Thames Coromandle', ], # NT
        'MNI - Waikato'             => [ undef, 'H', 'Wk', 'Wko', 'Wkto', 'Wkato', 'Waikto', 'Waikato', ], # NMI
        'MNI - Wairarapa'           => [ undef, 'Ẅ', 'Wr', 'Wrp', 'Wrpa', 'Wrapa', 'Wairpa', 'Wairrpa', 'Wairarpa', 'Wairarapa', ], # WN
        'NT - Bay of Islands'       => [ undef, 'B', 'BI', 'BoI', 'BoIs', 'BofIs', 'BofIsl', 'BofIsld', 'BofIslnd', 'BofIsland', 'BayofIslnd', 'BayofIslnds', 'BayofIslands', 'Bayof Islands', 'Bay of Islands', ], # MNI
        'NT - Howick'               => [ undef, 'H', 'Hw', 'Hwk', 'Hwck', 'Howck', 'Howick', ], # NT
        'NT - Kaitaia'              => [ undef, 'K', 'Kt', 'Kta', 'Kait', 'Ktaia', 'Kataia', 'Kaitaia', ], # NT
        'NT - Mt Eden'              => [ undef, 'Ṁ', 'ME', 'MtE', 'MtEd', 'MtEdn', 'MtEden', 'Mt Eden', ], # NT
        'NT - North Shore'          => [ undef, 'Ṅ', 'NS', 'NSh', 'NShr', 'NShre', 'NShore', 'NthShre', 'NthShore', 'NorthShre', 'NorthShore', 'North Shore', ], # NT
        'NT - Waiheke'              => [ undef, 'Ẁ', 'WI', 'WkI', 'Whke', 'Wheke', 'Waihke', 'Waiheke', ], # NT
        'NT - West Auckland'        => [ undef, '×', 'WA', 'WAk', 'WstA', 'WstAk', 'WstAkl', 'WstAuck', 'WestAuck', 'WAuckland', 'WestAuckld', 'WestAucklnd', 'WestAuckland', 'West Auckland', ], # NT
        'NT - Whangarei'            => [ undef, 'Ẉ', 'Wr', 'Wgr', 'Wrei', 'Whrei', 'Whgrei', 'Whgarei', 'Whngarei', 'Whangarei', ], # NT
        'NT - elsewhere'            => [ undef, 'N', 'NE', 'xNT', 'exNT', 'ex-NT', 'NT-els', 'NT-else', ],
        'NT - overseas'             => [ undef, 'N', 'NO', 'oNT', 'osNT', 'os-NT', 'o/s-NT', ],
        'PN - Hawkes Bay'           => [ undef, 'Ḣ', 'HB', 'HkB', 'HwkB', 'HwkBy', 'HawkBy', 'HawksBy', 'HawkesBy', 'HawkesBay', 'Hawkes Bay', ], # PN
        'PN - Levin'                => [ undef, 'L', 'Lv', 'Lvn', 'Levn', 'Levin', ], # PN
        'PN - Palmerston North'     => [ undef, 'P', 'PN', 'PmN', 'PNth', 'PmNth', 'PmtNth', 'PmstonN', 'PlmrstnN', 'PalmstonN', 'PalmstnNth', 'PalmstnNrth', 'PalmstnNorth', 'Palmstn North', ], # PN
        'PN - elsewhere'            => [ undef, 'P', 'PE', 'xPN', 'exPN', 'ex-PN', 'PN-els', 'PN-else', ],
        'PN - overseas'             => [ undef, 'P', 'PO', 'oPN', 'osPN', 'os-PN', 'o/s-PN', ],
        'WG - Taranaki'             => [ undef, 'T', 'Tn', 'Tnk', 'Tnki', 'Tnaki', 'Trnaki', 'Taranki', 'Taranaki', ], # WG
        'WG - Whanganui'            => [ undef, 'Ŵ', 'Wg', 'Wnu', 'Wnui', 'Whnui', 'Whgnui', 'Whganui', 'Whnganui', 'Whanganui', ], # WG
        'WG - elsewhere'            => [ undef, 'W', 'WE', 'xWG', 'exWG', 'ex-WG', 'WG-els', 'WG-else', ],
        'WG - overseas'             => [ undef, 'W', 'WO', 'oWG', 'osWG', 'os-WG', 'o/s-WG', ],
        'WN - Wellington'           => [ undef, 'Ẃ', 'Wn', 'Wtn', 'Wgtn', 'Wlgtn', 'Wlngtn', 'Wlngton', 'Wllngton', 'Wellngton', 'Wellington', ], # WN
        'WN - elsewhere'            => [ undef, 'W', 'WE', 'xWN', 'exWN', 'ex-WN', 'WN-els', 'WN-else', ],
        'WN - overseas'             => [ undef, 'W', 'WO', 'oWN', 'osWN', 'os-WN', 'o/s-WN', ],

        'BayofIslands'              => [ undef, 'B', 'BI', 'BoI', 'BoIs', 'BofIs', 'BofIsl', 'BofIsld', 'BofIslnd', 'BofIsland', 'BayofIslnd', 'BayofIslnds', ], # MNI
        'Canterbury'                => [ undef, 'C', 'Cn', 'Cnb', 'Cnby', 'Cntby', 'Cantby', 'Cantbry', 'Cantbury', 'Cantrbury', ], # CH
        'GoldenBay'                 => [ undef, 'G', 'GB', 'GoB', 'GldB', 'GldnB', 'GldnBy', 'GoldenB', 'GoldnBay', ], # CH
        'HawkesBay'                 => [ undef, 'Ḣ', 'HB', 'HkB', 'HwkB', 'HwkBy', 'HawkBy', 'HawksBy', 'HawkesBy', ], # PN
        'Howick'                    => [ undef, 'H', 'Hw', 'Hwk', 'Hwck', 'Howck', ], # NT
        'Kaitaia'                   => [ undef, 'K', 'Kt', 'Kta', 'Kait', 'Ktaia', 'Kataia', ], # NT
        'Kapiti'                    => [ undef, 'K', 'Kp', 'Kpt', 'Kapt', 'Kapti', ], # KP
        'Levin'                     => [ undef, 'L', 'Lv', 'Lvn', 'Levn', 'Levin', ], # PN
        'Marlborough'               => [ undef, 'M', 'Mb', 'Mbr', 'Mbro', 'Mboro', 'Mlboro', 'Marlbor', 'Marlboro', 'Marlborou', 'Marlbrough', ], # CH
        'MtEden'                    => [ undef, 'Ṁ', 'ME', 'MtE', 'MtEd', 'MtEdn', ], # NT
        'Nelson'                    => [ undef, 'N', 'Nn', 'Nsn', 'Nlsn', 'Nelsn', ], # CH
        'NorthShore'                => [ undef, 'Ṅ', 'NS', 'NSh', 'NShr', 'NShre', 'NShore', 'NthShre', 'NthShore', 'NorthShre', ], # NT
        'Otago'                     => [ undef, 'O', 'Ot', 'Otg', 'Otgo', 'Otago', ], # DN
        'PalmerstonNorth'           => [ undef, 'P', 'PN', 'PmN', 'PNth', 'PmNth', 'PmtNth', 'PmstonN', 'PlmrstnN', 'PalmstonN', 'PalmstnNth', 'PalmstnNrth', ], # PN
        'RotoruaTaupo'              => [ undef, 'R', 'RT', 'RrT', 'RrTp', 'RrTpo', 'RruTpo', 'RruaTpo', 'RtruaTpo', 'RruaTaupo', 'RotoruaTpo', 'RotoruaTaup', ], # MNI
        'SouthCanterbury'           => [ undef, 'Ṡ', 'SC', 'SCt', 'SCtb', 'SCntb', 'SCntby', 'SthCnby', 'SthCntby', 'SthCantby', 'SthCantbry', 'SthCantbury', 'SthCantrbury', 'SthCanterbury', 'SouthCantrbury', ], # CH
        'Southland'                 => [ undef, 'S', 'Sl', 'Sld', 'Sthl', 'Sthld', 'Sthlnd', 'Sthland', 'Southlnd', ], # DN
        'Taranaki'                  => [ undef, 'T', 'Tn', 'Tnk', 'Tnki', 'Tnaki', 'Trnaki', 'Taranki', ], # WG
        'Tauranga'                  => [ undef, 'Ť', 'Tg', 'Tga', 'Tnga', 'Trnga', 'Tranga', 'Taurnga', ], # MNI
        'ThamesCoromandel'          => [ undef, 'Ṫ', 'TC', 'ThC', 'TmCo', 'ThmCo', 'ThmCor', 'ThmCoro', 'ThamesCo', 'ThamesCor', 'ThamesCoro', 'ThamesCmndl', 'ThamesCrmndl', 'ThamesCormndl', 'ThamesCoromndl', 'ThamesCoromandl', ], # NT
        'Waiheke'                   => [ undef, 'Ẁ', 'WI', 'WkI', 'Whke', 'Wheke', 'Waihke', ], # NT
        'Waikato'                   => [ undef, 'H', 'Wk', 'Wko', 'Wkto', 'Wkato', 'Waikto', ], # NMI
        'Wairarapa'                 => [ undef, 'Ẅ', 'Wr', 'Wrp', 'Wrpa', 'Wrapa', 'Wairpa', 'Wairrpa', 'Wairarpa', ], # WN
        'Wellington'                => [ undef, 'Ẃ', 'Wn', 'Wtn', 'Wgtn', 'Wlgtn', 'Wlngtn', 'Wlngton', 'Wllngton', 'Wellngton', ], # WN
        'WestAuckland'              => [ undef, '×', 'WA', 'WAk', 'WstA', 'WstAk', 'WstAkl', 'WstAuck', 'WestAuck', 'WAuckland', 'WestAuckld', 'WestAucklnd', ], # NT
        'Westland'                  => [ undef, 'Ẇ', 'Wl', 'Wld', 'Wlnd', 'Wland', 'Westld', 'Westlnd', ], # CH
        'Whanganui'                 => [ undef, 'Ŵ', 'Wg', 'Wnu', 'Wnui', 'Wgnui', 'Whgnui', 'Whganui', 'Whnganui', ], # WG
        'Whangarei'                 => [ undef, 'Ẉ', 'Wr', 'Whr', 'Wrei', 'Whrei', 'Whgrei', 'Whgarei', 'Whngarei', ], # NT
        'elsewhere',                => [ undef, '+', 'nz', '+',   '(nz)', 'other', '+',      '+',       '+',        'elsewhere', ], # elsewhere in NZ
        'overseas',                 => [ undef, '*', 'os', 'o/s', '*',    '(o/s)', 'o/seas', 'ovrseas', 'overseas', ], # not in NZ
    );

################################################################################

use export qw(
    %mm_names
    @mm_order
    %skip_mm_listing
    @wg_order
    %skip_wg_listing
    $mm_keys_re
    %mm_titles
    %wg_abbrev );

1;
