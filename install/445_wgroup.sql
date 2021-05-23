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

*/

select 'exdata_wgroup_mm' as `Creating Internal Table`;

create or replace table exdata_wgroup_mm(
    wg_nid int(10) unsigned not null,
    mm_nid int(10) unsigned not null
) default charset=utf8;
insert into exdata_wgroup_mm
     values ( 2131, 48 ),   /* Christchurch Worship Group   CH     48   Christchurch Monthly Meeting (CH)                   */
            ( 1708, 48 ),   /* Golden Bay                   CH     48   Christchurch Monthly Meeting (CH)                   */
            ( 2130, 48 ),   /* Marlborough                  CH     48   Christchurch Monthly Meeting (CH)                   */
            ( 3545, 48 ),   /* Motueka                      CH     48   Christchurch Monthly Meeting (CH)                   */
            ( 2124, 48 ),   /* Nelson Recognised Meeting    CH     48   Christchurch Monthly Meeting (CH)                   */
            (   79, 48 ),   /* South Canterbury             CH     48   Christchurch Monthly Meeting (CH)                   */
            (   77, 48 ),   /* Westland                     CH     48   Christchurch Monthly Meeting (CH)                   */
            ( 2135, 47 ),   /* Dunedin Worship Group        DN     47   Dunedin Monthly Meeting (DN)                        */
            ( 2136, 47 ),   /* Invercargill                 DN     47   Dunedin Monthly Meeting (DN)                        */
            ( 2490, 46 ),   /* Raumati                      KP     46   Kāpiti Monthly Meeting (KP)                         */
            ( 2128, 46 ),   /* Kāpiti                       KP     46   Kāpiti Monthly Meeting (KP)                         */
            ( 1813, 45 ),   /* Whakatane                    MNI    45   Mid-North Island Monthly Meeting (MNI)              */
            ( 2114, 45 ),   /* Hamilton                     MNI    45   Mid-North Island Monthly Meeting (MNI)              */
            ( 2116, 45 ),   /* Tauranga                     MNI    45   Mid-North Island Monthly Meeting (MNI)              */
            ( 2117, 45 ),   /* Thames & Coromandel          MNI    45   Mid-North Island Monthly Meeting (MNI)              */
            ( 2103, 44 ),   /* Bay of Islands               NT     44   Northern Monthly Meeting (NT)                       */
            ( 2102, 44 ),   /* Kaitaia                      NT     44   Northern Monthly Meeting (NT)                       */
            ( 2106, 44 ),   /* Mt Eden                      NT     44   Northern Monthly Meeting (NT)                       */
            ( 2120, 44 ),   /* North Shore                  NT     44   Northern Monthly Meeting (NT)                       */
            ( 2112, 44 ),   /* Warkworth                    NT     44   Northern Monthly Meeting (NT)                       */
            ( 2104, 44 ),   /* Whangārei                    NT     44   Northern Monthly Meeting (NT)                       */
            ( 2107, 44 ),   /* Waiheke Island, Auckland     NT     44   Northern Monthly Meeting (NT)                       */
            (   97, 43 ),   /* Hawkes Bay                   PN     43   Palmerston North Monthly Meeting (PN)               */
            ( 2126, 43 ),   /* Palmerston North             PN     43   Palmerston North Monthly Meeting (PN)               */
            ( 4730, 43 ),   /* Kahuterawa Worship Group     PN     43   Palmerston North Monthly Meeting (PN)               */
            (  332, 42 ),   /* New Plymouth                 TN     42   Taranaki Monthly Meeting (TN)                       */
            ( 2090, 42 ),   /* Stratford                    TN     42   Taranaki Monthly Meeting (TN)                       */
            ( 2122, 40 ),   /* Quaker Settlement            WG     40   Whanganui Monthly Meeting (WG)                      */
            ( 2123, 40 ),   /* Whanganui                    WG     40   Whanganui Monthly Meeting (WG)                      */
            ( 2024, 41 ),   /* Wairarapa Worship Group      WN     41   Wellington Monthly Meeting (WN)                     */
            ( 2021, 41 ),   /* Hutt Valley Worship Group    WN     41   Wellington Monthly Meeting (WN)                     */
            ( 2127, 41 ),   /* Levin                        WN     41   Wellington Monthly Meeting (WN)                     */
            ( 2129, 41 ),   /* Wellington Worship Group     WN     41   Wellington Monthly Meeting (WN)                     */
            ( 5898, 5895 ); /* Not attending any NZ meeting XN   5895   Control Terms (Technical Services Team Use Only)    */
                            /*                              XP   2163   Practice Monthly Meeting                            */

select 'experl_user_wgroup' as `Creating View`;

create or replace view experl_user_wgroup as
      select w.entity_id                            as wgroup_uid,
             w.revision_id                          as wgroup_rev,
             w.language                             as wgroup_language,
             w.delta                                as wgroup_delta,
             w.field_user_worship_group_target_id   as wgroup_nid,
             n.title                                as wgroup_name,
             m.mm_nid                               as wgroup_xmid,
             mmt.field_short_name_value             as wgroup_xmtag
        from field_data_field_user_worship_group    as w
   left join node                                   as n   on w.field_user_worship_group_target_id = n.nid
                                                          and n.type = 'store_location'
   left join exdata_wgroup_mm                       as m   on w.field_user_worship_group_target_id = m.wg_nid
   left join field_data_field_short_name            as mmt on mmt.entity_type = 'node'
                                                        and mmt.bundle      = 'meeting_group'
                                                        and not mmt.deleted
                                                        and mmt.entity_id   = m.mm_nid
       where w.entity_type = 'user'
         and w.bundle      = 'user'
         and not w.deleted
;
