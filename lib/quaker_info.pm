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

use export qw(
    %mm_names
    @mm_order
    %skip_mm_listing
    @wg_order
    %skip_wg_listing
    $mm_keys_re
    %mm_titles );

1;
