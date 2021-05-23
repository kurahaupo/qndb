
/*

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

*/

select 'experl_user_mm_member' as `Creating Internal View`;

create or replace view experl_user_mm_member as
      select um.entity_id                       as mmm_uid,
             um.revision_id                     as mmm_rev,
             um.language                        as mmm_language,
             um.delta                           as mmm_delta,
             um.field_user_main_og_target_id    as mmm_xmid,
             mmt.field_short_name_value         as mmm_xmtag,
             1                                  as mmm_formal_member
        from field_data_field_user_main_og      as um
   left join field_data_field_short_name        as mmt  on mmt.entity_type = 'node'
                                                       and mmt.bundle      = 'meeting_group'
                                                       and not mmt.deleted
                                                       and mmt.entity_id   = um.field_user_main_og_target_id
       where um.entity_type = 'user'
         and um.bundle      = 'user'
         and not um.deleted
;
/* TODO: union this with the "affiliation" MM's; that is,
    also find the MM's where formal_member would be
    false.
 */
