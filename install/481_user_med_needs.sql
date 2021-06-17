
select 'experl_user_med_needs' as `Creating View`;

create or replace view experl_user_med_needs as
       select entity_id                         as med_needs_uid,
           /* revision_id                       as med_needs_rev, */
           /* language                          as med_needs_language, */
              delta                             as med_needs_delta,
              field_user_medical_needs_value    as med_needs,
              field_user_medical_needs_format   as med_needs_format
         from field_data_field_user_medical_needs
        where entity_type = 'user'
          and bundle      = 'user'
          and not deleted
;

/*

mysql> desc field_data_field_user_medical_needs;
+---------------------------------+------------------+------+-----+---------+-------+
| Field                           | Type             | Null | Key | Default | Extra |
+---------------------------------+------------------+------+-----+---------+-------+
| entity_type                     | varchar(128)     | NO   | PRI |         |       |
| bundle                          | varchar(128)     | NO   | MUL |         |       |
| deleted                         | tinyint(4)       | NO   | PRI | 0       |       |
| entity_id                       | int(10) unsigned | NO   | PRI | NULL    |       |
| revision_id                     | int(10) unsigned | YES  | MUL | NULL    |       |
| language                        | varchar(32)      | NO   | PRI |         |       |
| delta                           | int(10) unsigned | NO   | PRI | NULL    |       |
| field_user_medical_needs_value  | varchar(255)     | YES  |     | NULL    |       |
| field_user_medical_needs_format | varchar(255)     | YES  | MUL | NULL    |       |
+---------------------------------+------------------+------+-----+---------+-------+

*/
