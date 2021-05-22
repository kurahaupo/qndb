/*

mysql> desc field_data_field_user_mobile;
+--------------------------+------------------+------+-----+---------+-------+
| Field                    | Type             | Null | Key | Default | Extra |
+--------------------------+------------------+------+-----+---------+-------+
| entity_type              | varchar(128)     | NO   | PRI |         |       |
| bundle                   | varchar(128)     | NO   | MUL |         |       |
| deleted                  | tinyint(4)       | NO   | PRI | 0       |       |
| entity_id                | int(10) unsigned | NO   | PRI | NULL    |       |
| revision_id              | int(10) unsigned | YES  | MUL | NULL    |       |
| language                 | varchar(32)      | NO   | PRI |         |       |
| delta                    | int(10) unsigned | NO   | PRI | NULL    |       |
| field_user_mobile_value  | varchar(255)     | YES  |     | NULL    |       |
| field_user_mobile_format | varchar(255)     | YES  | MUL | NULL    |       |
+--------------------------+------------------+------+-----+---------+-------+

mysql> desc field_data_field_user_phone;
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
| field_user_phone_value  | varchar(255)     | YES  |     | NULL    |       |
| field_user_phone_format | varchar(255)     | YES  | MUL | NULL    |       |
+-------------------------+------------------+------+-----+---------+-------+

*/

select 'experl_user_phones' as `Creating View`;

create or replace view experl_user_phones as
      select entity_id                  as phone_uid,
             'M'                        as phone_slot,
             true                       as phone_can_message,
             revision_id                as phone_rev,
             language                   as phone_language,
             delta                      as phone_delta,
             field_user_mobile_value    as phone,
             field_user_mobile_format   as phone_format
        from field_data_field_user_mobile
       where entity_type             = 'user'
         and bundle                  = 'user'
         and not deleted
         and field_user_mobile_value like '+%'
 union
      select entity_id                  as phone_uid,
             'H'                        as phone_slot,
             false                      as phone_can_message,
             revision_id                as phone_rev,
             language                   as phone_language,
             delta                      as phone_delta,
             field_user_phone_value     as phone,
             field_user_phone_format    as phone_format_
        from field_data_field_user_phone
       where entity_type = 'user'
         and bundle                 = 'user'
         and not deleted
         and field_user_phone_value like '+%';
