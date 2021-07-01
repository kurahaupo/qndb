/*

Drupal does not provide a clean way to link worship groups to monthly meetings.
It's also rather hit-and-miss on standard abbreviations.

need set names utf8 so that uploaded data from here will work cleanly.

 */

set names utf8;
set @id_no = 0;     /* but don't actually use 'no meeting' */
set @id_yf = -1;
set @id_os = -2;    /* TODO: find a suitable node-id */
set @id_pw = -3;    /* practice worship group */
set @id_ym = -4;

set @id_pm = 2163;  /* practice mm */
set @id_ctl = 5895; /* control */

select 'exdata_mm_info' as `Creating Internal Table`;

/*drop table if exists exdata_mm_info;*/
create or replace table exdata_mm_info(
    mm_id               int         not null    primary key,
    mm_tag              varchar(3)  not null    unique,
    mm_name             varchar(32) not null    unique,
    mm_fake             boolean     not null,
    mm_possible_member  boolean     not null,
    mm_implicit_member  boolean     not null
) default charset=utf8;
/*truncate table exdata_mm_info;*/

insert into exdata_mm_info
     select n.nid,
            mt.field_short_name_value,
            n.title,
            n.nid in (@id_pm, @id_ctl),
            true,
            false
       from node                        as n
       join field_data_field_short_name as mt    on mt.entity_type = 'node'
                                                and mt.bundle      = 'meeting_group'
                                                and not mt.deleted
                                                and mt.entity_id   = n.nid
      where type = 'meeting_group'
        and nid != @id_ctl
;
insert into exdata_mm_info
     values ( @id_yf, 'YF', 'Young Friends',        false, false, false ),
            ( @id_os, 'OS', 'any overseas meeting', false, true,  true  ),
            ( @id_ym, 'YM', 'Yearly Meeting',       false, false, false );

            /* entry for "no meeting" intentionally excluded */

select 'exdata_wg_mm' as `Creating Temporary Table`;

/*drop table if exists exdata_wg_mm;*/
create or replace temporary table exdata_wg_mm(
    wg_id   integer     not null    unique,
    wg_tag  varchar(5)  not null    unique,
    wg_xmid integer     not null,
    wg_order smallint   not null auto_increment primary key,
        unique key (wg_id,wg_xmid),
        key (wg_xmid)
) default charset=utf8;
truncate table exdata_wg_mm;
SET insert_id=4;
insert into exdata_wg_mm(wg_xmid, wg_id, wg_tag)
     values

            (     44,   2103, 'ByIsl' ),    /* Bay of Islands               NT     44   Northern Monthly Meeting (NT)                       */
            (     44,   2102, 'Ktaia' ),    /* Kaitaia                      NT     44   Northern Monthly Meeting (NT) (Kerikeri)            */
            (     44,   2106, 'MtEdn' ),    /* Mt Eden                      NT     44   Northern Monthly Meeting (NT)                       */
            (     44,   2107, 'Waihk' ),    /* Waiheke Island, Auckland     NT     44   Northern Monthly Meeting (NT) (Palm Beach)          */
            (     44,   2120, 'NthSh' ),    /* North Shore                  NT     44   Northern Monthly Meeting (NT) (Takapuna)            */
            (     44,   2112, 'Wkwth' ),    /* Warkworth                    NT     44   Northern Monthly Meeting (NT)                       */
            (     44,   2104, 'Ŵŋrei' ),    /* Whangārei                    NT     44   Northern Monthly Meeting (NT)                       */

            (     45,   2117, 'ThmCo' ),    /* Thames & Coromandel          MNI    45   Mid-North Island Monthly Meeting (MNI) (Thames)     */
            (     45,   2114, 'Hamtn' ),    /* Hamilton                     MNI    45   Mid-North Island Monthly Meeting (MNI)              */
            (     45,   1813, 'Ŵktan' ),    /* Whakatane                    MNI    45   Mid-North Island Monthly Meeting (MNI)              */
            (     45,   2116, 'Trnga' ),    /* Tauranga                     MNI    45   Mid-North Island Monthly Meeting (MNI)              */

            (     42,    332, 'NPlym' ),    /* New Plymouth                 TN     42   Taranaki Monthly Meeting (TN)                       */
            (     42,   2090, 'Strfd' ),    /* Stratford                    TN     42   Taranaki Monthly Meeting (TN)                       */

            (     40,   2122, 'QStlm' ),    /* Quaker Settlement            WG     40   Whanganui Monthly Meeting (WG) (Otamatea)           */
            (     40,   2123, 'Ŵŋnui' ),    /* Whanganui                    WG     40   Whanganui Monthly Meeting (WG)                      */

            (     43,     97, 'HwkBy' ),    /* Hawkes Bay                   PN     43   Palmerston North Monthly Meeting (PN) (Hastings+?)  */
            (     43,   2126, 'PalmN' ),    /* Palmerston North             PN     43   Palmerston North Monthly Meeting (PN) (West End)    */
            (     43,   4730, 'Khtwa' ),    /* Kahuterawa Worship Group     PN     43   Palmerston North Monthly Meeting (PN)               */
            (     43,   2127, 'Levin' ),    /* Levin                        PN     43   Palmerston North Monthly Meeting (PN)               */

            (     46,   2128, 'Kāpti' ),    /* Kāpiti                       KP     46   Kāpiti Monthly Meeting (KP) (Paraparaumu)           */
            (     46,   2490, 'Raumt' ),    /* Raumati                      KP     46   Kāpiti Monthly Meeting (KP) (Raumati Beach)         */

            (     41,   2024, 'Wrapa' ),    /* Wairarapa Worship Group      WN     41   Wellington Monthly Meeting (WN) (Masterton)         */
            (     41,   2021, 'HutVy' ),    /* Hutt Valley Worship Group    WN     41   Wellington Monthly Meeting (WN) (Petone)            */
            (     41,   2129, 'Wgtn'  ),    /* Wellington Worship Group     WN     41   Wellington Monthly Meeting (WN) (Mt Victoria)       */

            (     48,   1708, 'GldnB' ),    /* Golden Bay                   CH     48   Christchurch Monthly Meeting (CH) (Pakawau)         */
            (     48,   2124, 'Nelsn' ),    /* Nelson Recognised Meeting    CH     48   Christchurch Monthly Meeting (CH) (Blenheim)        */
            (     48,   3545, 'Motka' ),    /* Motueka                      CH     48   Christchurch Monthly Meeting (CH)                   */
            (     48,   2130, 'Malbr' ),    /* Marlborough                  CH     48   Christchurch Monthly Meeting (CH)                   */
            (     48,   2131, 'Chch'  ),    /* Christchurch Worship Group   CH     48   Christchurch Monthly Meeting (CH)                   */
            (     48,     77, 'WestL' ),    /* Westland                     CH     48   Christchurch Monthly Meeting (CH) (Greymouth)       */
            (     48,     79, 'SthCn' ),    /* South Canterbury             CH     48   Christchurch Monthly Meeting (CH)                   */

            (     47,   2135, 'DnEdn' ),    /* Dunedin Worship Group        DN     47   Dunedin Monthly Meeting (DN)                        */
            (     47,   2136, 'Ivcgl' ),    /* Invercargill                 DN     47   Dunedin Monthly Meeting (DN)                        */

            ( @id_yf, @id_yf, 'YŋFrd' ),    /* Linked to Young Friends      YF      -   -                                                   */
            ( @id_os, @id_os, 'OSeas' ),    /* Member of overseas meeting   OS      -   -                                                   */
            ( @id_pm, @id_pw, 'XPrct' ),    /*                              XX   2163   Practice Monthly Meeting                            */
            ( @id_ym, @id_ym, 'XNatl' );    /* Linked directly to YM        YM      -   -                                                   */

            /* entries for "no meeting" intentionally excluded */

select 'exdata_wg_info' as `Creating Internal Table`;

/* drop table if exists exdata_wg_info; */
create or replace table exdata_wg_info(
    wg_id       integer     not null    primary key,
    wg_tag      varchar(5)  not null    unique,
    wg_name     varchar(32) not null    unique,
    wg_fullname varchar(32) not null    unique,
    wg_xmid     integer     not null,
    wg_xmtag    varchar(3)  not null,
    wg_xmname   varchar(32) not null,
    wg_order    smallint unsigned    not null unique,
        unique key (wg_id,wg_tag,wg_name,wg_xmid,wg_xmtag),
        unique key (wg_id,wg_tag,wg_xmid,wg_xmtag),
        unique key (wg_id,wg_xmid),
        unique key (wg_id,wg_tag),
        key (wg_xmid,wg_xmtag),
        key (wg_xmid),
        key (wg_xmtag)
) default charset=utf8;
insert into exdata_wg_info
     select w.wg_id,
            w.wg_tag,
            n.title,
            n.title,
            m.mm_id,
            m.mm_tag,
            m.mm_name,
            w.wg_order
       from exdata_wg_mm    as w
       join exdata_mm_info  as m    on w.wg_xmid = m.mm_id
       join node            as n    on nid = w.wg_id
                                   and type = 'store_location'
;

drop table if exists exdata_wg_mm;

update exdata_wg_info
   set wg_name = regexp_replace(wg_name, ' Island, Auckland| Recognised Meeting| Worship Group|,.*', ''),
       wg_fullname = regexp_replace(wg_fullname, ',.*', '') ;

/*

Membership and Monthly Meetings

There are 4 ways to link to a monthly meeting:

    1. Your "home meeting".
       Unfortunately this is only recorded through Drupal's OG permissions
       system (in field_data_field_user_main_og)
       but that means we have to check which
       Any MM's where you have "participant" access level ()

       If you have one of these, then field_data_field_member_status says
       whether you are a formal member of this meeting.


    2. Being a member of an overseas meeting; *any* overseas meeting.
       field_data_field_membership_held_overseas simply says "yes" or "no".
       ("formal member" is always true if this is present).

    3. Young Friends; this behaves like a MM, except that it has no formal
       members.

    4. The MM's of each worship group that you attend.

There will of course be overlaps, and therefore it's necessary to use "group by
uid, xmtag", and to use "max(formal_member)".

We can be a bit more efficient by avoiding putting OS & YF inside that
group-by, since they cannot overlap with any other meetings.


mysql> desc field_data_field_user_main_og;
+------------------------------+------------------+------+-----+---------+-------+
| Field                        | Type             | Null | Key | Default | Extra |
+------------------------------+------------------+------+-----+---------+-------+
| entity_type                  | varchar(128)     | NO   | PRI |         |       |
| bundle                       | varchar(128)     | NO   | MUL |         |       |
| deleted                      | tinyint(4)       | NO   | PRI | 0       |       |
| entity_id                    | int(10) unsigned | NO   | PRI | NULL    |       |
| revision_id                  | int(10) unsigned | YES  | MUL | NULL    |       |
| language                     | varchar(32)      | NO   | PRI |         |       |
| delta                        | int(10) unsigned | NO   | PRI | NULL    |       |
| field_user_main_og_target_id | int(10) unsigned | NO   | MUL | NULL    |       |
+------------------------------+------------------+------+-----+---------+-------+

mysql> desc field_data_field_short_name;
+-------------------------+------------------+------+-----+---------+-------+
| Field                   | Type             | Null | Key | Default | Extra |
+-------------------------+------------------+------+-----+---------+-------+
| entity_type             | varchar(128)     | NO   | PRI |         |       |
| bundle                  | varchar(128)     | NO   | MUL |         |       |
| deleted                 | tinyint(4)       | NO   | PRI | 0       |       |
| entity_id               | int(10) unsigned | NO   | PRI | NULL    |       |
| revision_id             | int(10) unsigned | YES  | MUL | NULL    |       |
| language                | varchar(32)      | NO   | PRI |         |       |
| delta                   | int(10) unsigned | NO   | PRI | NULL    |       |
| field_short_name_value  | varchar(50)      | YES  |     | NULL    |       |
| field_short_name_format | varchar(255)     | YES  | MUL | NULL    |       |
+-------------------------+------------------+------+-----+---------+-------+

mysql> describe field_data_field_shown_to_young_friends;
+------------------------------------+------------------+------+-----+---------+-------+
| Field                              | Type             | Null | Key | Default | Extra |
+------------------------------------+------------------+------+-----+---------+-------+
| entity_type                        | varchar(128)     | NO   | PRI |         |       |
| bundle                             | varchar(128)     | NO   | MUL |         |       |
| deleted                            | tinyint(4)       | NO   | PRI | 0       |       |
| entity_id                          | int(10) unsigned | NO   | PRI | NULL    |       |
| revision_id                        | int(10) unsigned | YES  | MUL | NULL    |       |
| language                           | varchar(32)      | NO   | PRI |         |       |
| delta                              | int(10) unsigned | NO   | PRI | NULL    |       |
| field_shown_to_young_friends_value | int(11)          | YES  | MUL | NULL    |       |
+------------------------------------+------------------+------+-----+---------+-------+

mysql> describe field_data_field_membership_held_overseas;
+--------------------------------------+------------------+------+-----+---------+-------+
| Field                                | Type             | Null | Key | Default | Extra |
+--------------------------------------+------------------+------+-----+---------+-------+
| entity_type                          | varchar(128)     | NO   | PRI |         |       |
| bundle                               | varchar(128)     | NO   | MUL |         |       |
| deleted                              | tinyint(4)       | NO   | PRI | 0       |       |
| entity_id                            | int(10) unsigned | NO   | PRI | NULL    |       |
| revision_id                          | int(10) unsigned | YES  | MUL | NULL    |       |
| language                             | varchar(32)      | NO   | PRI |         |       |
| delta                                | int(10) unsigned | NO   | PRI | NULL    |       |
| field_membership_held_overseas_value | int(11)          | YES  | MUL | NULL    |       |
+--------------------------------------+------------------+------+-----+---------+-------+


mysql> describe field_data_field_member_status;
+-------------------------+------------------+------+-----+---------+-------+
| Field                   | Type             | Null | Key | Default | Extra |
+-------------------------+------------------+------+-----+---------+-------+
| entity_type             | varchar(128)     | NO   | PRI |         |       |
| bundle                  | varchar(128)     | NO   | MUL |         |       |
| deleted                 | tinyint(4)       | NO   | PRI | 0       |       |
| entity_id               | int(10) unsigned | NO   | PRI | NULL    |       |
| revision_id             | int(10) unsigned | YES  | MUL | NULL    |       |
| language                | varchar(32)      | NO   | PRI |         |       |
| delta                   | int(10) unsigned | NO   | PRI | NULL    |       |
| field_member_status_tid | int(10) unsigned | YES  | MUL | NULL    |       |
+-------------------------+------------------+------+-----+---------+-------+

*/

select 'exp_mlink_home' as `Creating Internal View`;

create or replace view exp_mlink_home as
     select um.entity_id                                     as ml_uid,
         /* um.revision_id                                   as ml_rev, */
         /* um.language                                      as ml_language, */
            um.delta                                         as ml_delta,
            mm.mm_id                                         as ml_xmid,
            mm.mm_tag                                        as ml_xmtag,
            mm.mm_name                                       as ml_xmname,
            ifnull(ms.field_member_status_tid = 30, false)   as ml_formal_member,
            'OG'                                             as ml_source
       from field_data_field_user_main_og    as um
  left join exdata_mm_info                   as mm   on mm.mm_id = um.field_user_main_og_target_id
  left join field_data_field_member_status   as ms   on ms.entity_type = 'user'
                                                    and ms.bundle      = 'user'
                                                    and not ms.deleted
                                                    and ms.entity_id   = um.field_user_main_og_target_id
      where um.entity_type = 'user'
        and um.bundle      = 'user'
        and not um.deleted
;

select 'exp_mlink_yf' as `Creating Internal View`;

create or replace view exp_mlink_yf as
     select entity_id        as ml_uid,
         /* revision_id      as ml_rev, */
         /* language         as ml_language, */
            delta            as ml_delta,
            -1               as ml_xmid,    /* @id_yf */
            'YF'             as ml_xmtag,
            'Young Friends'  as ml_xmname,
            false            as ml_formal_member,
            'YF'             as ml_source
       from field_data_field_shown_to_young_friends as yf
      where entity_type = 'user'
        and bundle      = 'user'
        and not deleted
        and field_shown_to_young_friends_value
;

select 'exp_mlink_wg' as `Creating Internal View`;

create or replace view exp_mlink_wg as
     select w.entity_id                          as ml_uid,
         /* w.revision_id                        as ml_rev, */
         /* w.language                           as ml_language, */
            w.delta                              as ml_delta,
            wi.wg_xmid                           as ml_xmid,
            wi.wg_xmtag                          as ml_xmtag,
            wi.wg_xmname                         as ml_xmname,
            false                                as ml_formal_member,
            'WG'                                 as ml_source
       from field_data_field_user_worship_group  as w
  left join exdata_wg_info                       as wi   on wi.wg_id        = w.field_user_worship_group_target_id
      where w.entity_type = 'user'
        and w.bundle      = 'user'
        and not w.deleted
;

select 'exp_mlink_os' as `Creating Internal View`;

create or replace view exp_mlink_os as
     select entity_id    as ml_uid,
         /* revision_id  as ml_rev, */
         /* language     as ml_language, */
            delta        as ml_delta,
            -2           as ml_xmid,    /* @id_os */
            'OS'         as ml_xmtag,
            'overseas'   as ml_xmname,
            true         as ml_formal_member,
            'OS'         as ml_source
       from field_data_field_membership_held_overseas as os
      where entity_type = 'user'
        and bundle      = 'user'
        and not deleted
;

/*

mysql> desc field_data_field_user_worship_group;
+------------------------------------+------------------+------+-----+---------+-------+
| Field                              | Type             | Null | Key | Default | Extra |
+------------------------------------+------------------+------+-----+---------+-------+
| entity_type                        | varchar(128)     | NO   | PRI |         |       |
| bundle                             | varchar(128)     | NO   | MUL |         |       |
| deleted                            | tinyint(4)       | NO   | PRI | 0       |       |
| entity_id                          | int(10) unsigned | NO   | PRI | NULL    |       |
| revision_id                        | int(10) unsigned | YES  | MUL | NULL    |       |
| language                           | varchar(32)      | NO   | PRI |         |       |
| delta                              | int(10) unsigned | NO   | PRI | NULL    |       |
| field_user_worship_group_target_id | int(10) unsigned | NO   | MUL | NULL    |       |
+------------------------------------+------------------+------+-----+---------+-------+

mysql> describe field_data_field_shown_to_young_friends;
+------------------------------------+------------------+------+-----+---------+-------+
| Field                              | Type             | Null | Key | Default | Extra |
+------------------------------------+------------------+------+-----+---------+-------+
| entity_type                        | varchar(128)     | NO   | PRI |         |       |
| bundle                             | varchar(128)     | NO   | MUL |         |       |
| deleted                            | tinyint(4)       | NO   | PRI | 0       |       |
| entity_id                          | int(10) unsigned | NO   | PRI | NULL    |       |
| revision_id                        | int(10) unsigned | YES  | MUL | NULL    |       |
| language                           | varchar(32)      | NO   | PRI |         |       |
| delta                              | int(10) unsigned | NO   | PRI | NULL    |       |
| field_shown_to_young_friends_value | int(11)          | YES  | MUL | NULL    |       |
+------------------------------------+------------------+------+-----+---------+-------+

*/

select 'experl_user_wgroup' as `Creating View`;

create or replace view experl_user_wgroup as
     select w.entity_id      as wgroup_uid,
         /* w.revision_id    as wgroup_rev, */
         /* w.language       as wgroup_language, */
            w.delta          as wgroup_delta,
            wi.wg_id         as wgroup_id,
            wi.wg_tag        as wgroup_tag,
            wi.wg_name       as wgroup_name,
            wi.wg_xmid       as wgroup_xmid,
            wi.wg_xmtag      as wgroup_xmtag,
            wi.wg_xmname     as wgroup_xmname
       from field_data_field_user_worship_group  as w
       join exdata_wg_info                       as wi   on w.field_user_worship_group_target_id = wi.wg_id
      where w.entity_type = 'user'
        and w.bundle      = 'user'
        and not w.deleted
 union
     select yf.ml_uid        as wgroup_uid,
            yf.ml_delta      as wgroup_delta,
            -1               as wgroup_id,      /* @id_yf */
            yf.ml_xmtag      as wgroup_tag,     /* 'YF' */
            'Young Friends'  as wgroup_name,
            yf.ml_xmid       as wgroup_xmid,    /* @id_yf */
            yf.ml_xmtag      as wgroup_xmtag,   /* 'YF' */
            'Young Friends'  as wgroup_xmname
       from exp_mlink_yf as yf
;

select 'experl_user_mlink' as `Creating View`;

create or replace view experl_user_mlink as
     select ml_uid                                   as mlink_uid,
         /* ml_rev                                   as mlink_rev, */
         /* ml_language                              as mlink_language, */
            ml_delta                                 as mlink_delta,
            ml_xmid                                  as mlink_xmid,
            ml_xmtag                                 as mlink_xmtag,
            ml_xmname                                as mlink_xmname,
            max(ml_formal_member)                    as mlink_formal_member,
            group_concat(ml_source separator ':')    as mlink_source
       from (     select * from exp_mlink_home
            union select * from exp_mlink_wg
            union select * from exp_mlink_yf
            union select * from exp_mlink_os ) as t
      where ml_xmid is not null
   group by mlink_uid, mlink_xmtag
;

