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

select 'experl_user_wgroup' as `Creating View`;

create or replace view experl_user_wgroup as
      select w.entity_id                          as wgroup_uid,
             w.revision_id                        as wgroup_rev,
             w.language                           as wgroup_language,
             w.delta                              as wgroup_delta,
             w.field_user_worship_group_target_id as wgroup_nid,
             n.title                              as wgroup_name
        from field_data_field_user_worship_group as w
   left join node as n                            on w.field_user_worship_group_target_id = n.nid
                                                 and n.type = 'store_location'
       where w.entity_type = 'user'
         and w.bundle      = 'user'
         and not w.deleted
;
