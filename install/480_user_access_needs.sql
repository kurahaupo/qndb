
/*

mysql> desc field_data_field_user_access_needs;
+--------------------------------+------------------+------+-----+---------+-------+
| Field                          | Type             | Null | Key | Default | Extra |
+--------------------------------+------------------+------+-----+---------+-------+
| entity_type                    | varchar(128)     | NO   | PRI |         |       |
| bundle                         | varchar(128)     | NO   | MUL |         |       |
| deleted                        | tinyint(4)       | NO   | PRI | 0       |       |
| entity_id                      | int(10) unsigned | NO   | PRI | NULL    |       |
| revision_id                    | int(10) unsigned | YES  | MUL | NULL    |       |
| language                       | varchar(32)      | NO   | PRI |         |       |
| delta                          | int(10) unsigned | NO   | PRI | NULL    |       |
| field_user_access_needs_value  | varchar(255)     | YES  |     | NULL    |       |
| field_user_access_needs_format | varchar(255)     | YES  | MUL | NULL    |       |
+--------------------------------+------------------+------+-----+---------+-------+

*/

select 'experl_user_access_needs' as `Creating View`;

create or replace view experl_user_access_needs as
       select entity_id                         as access_needs_uid,
              revision_id                       as access_needs_rev,
              language                          as access_needs_language,
              delta                             as access_needs_delta,
              field_user_access_needs_value     as access_needs,
              field_user_access_needs_format    as access_needs_format
         from field_data_field_user_access_needs
        where entity_type = 'user'
          and bundle      = 'user'
          and not deleted
;
