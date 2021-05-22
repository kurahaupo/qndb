

/*********** Website ***********

mysql> desc field_data_field_user_website;
+---------------------------+------------------+------+-----+---------+-------+
| Field                     | Type             | Null | Key | Default | Extra |
+---------------------------+------------------+------+-----+---------+-------+
| entity_type               | varchar(128)     | NO   | PRI |         |       |
| bundle                    | varchar(128)     | NO   | MUL |         |       |
| deleted                   | tinyint(4)       | NO   | PRI | 0       |       |
| entity_id                 | int(10) unsigned | NO   | PRI | NULL    |       |
| revision_id               | int(10) unsigned | YES  | MUL | NULL    |       |
| language                  | varchar(32)      | NO   | PRI |         |       |
| delta                     | int(10) unsigned | NO   | PRI | NULL    |       |
| field_user_website_value  | varchar(255)     | YES  |     | NULL    |       |
| field_user_website_format | varchar(255)     | YES  | MUL | NULL    |       |
+---------------------------+------------------+------+-----+---------+-------+

*/

select 'experl_user_websites' as `Creating View`;

create or replace view experl_user_websites as
      select entity_id                      as website_uid,
             revision_id                    as website_rev,
             language                       as website_language,
             delta                          as website_delta,
             field_user_website_value       as website,
             field_user_website_format      as website_format
        from field_data_field_user_website
       where entity_type              = 'user'
         and bundle                   = 'user'
         and not deleted
         and field_user_website_value != ''
;
