
/*********** Visible Email ***********

mysql> desc field_data_field_user_fax;
+-----------------------+------------------+------+-----+---------+-------+
| Field                 | Type             | Null | Key | Default | Extra |
+-----------------------+------------------+------+-----+---------+-------+
| entity_type           | varchar(128)     | NO   | PRI |         |       |
| bundle                | varchar(128)     | NO   | MUL |         |       |
| deleted               | tinyint(4)       | NO   | PRI | 0       |       |
| entity_id             | int(10) unsigned | NO   | PRI | NULL    |       |
| revision_id           | int(10) unsigned | YES  | MUL | NULL    |       |
| language              | varchar(32)      | NO   | PRI |         |       |
| delta                 | int(10) unsigned | NO   | PRI | NULL    |       |
| field_user_fax_value  | varchar(255)     | YES  |     | NULL    |       |
| field_user_fax_format | varchar(255)     | YES  | MUL | NULL    |       |
+-----------------------+------------------+------+-----+---------+-------+

*/

select 'experl_user_visible_emails' as `Creating Internal View`;

create or replace view experl_user_visible_emails as
      select entity_id                  as visible_email_uid,
          /* revision_id                as visible_email_rev, */
          /* language                   as visible_email_language, */
             delta                      as visible_email_delta,
             field_user_fax_value       as visible_email,
             field_user_fax_format      as visible_email_format
        from field_data_field_user_fax
       where entity_type          = 'user'
         and bundle               = 'user'
         and not deleted
         and field_user_fax_value like '%@%';
