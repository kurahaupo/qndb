



/*

mysql> desc field_data_field_user_notes;
+------------------------------+------------------+------+-----+---------+-------+
| Field                        | Type             | Null | Key | Default | Extra |
+------------------------------+------------------+------+-----+---------+-------+
| entity_type                  | varchar(128)     | NO   | PRI |         |       | = 'user'
| bundle                       | varchar(128)     | NO   | MUL |         |       | = 'user'
| deleted                      | tinyint(4)       | NO   | PRI | 0       |       |
| entity_id                    | int(10) unsigned | NO   | PRI | NULL    |       | = users.uid
| revision_id                  | int(10) unsigned | YES  | MUL | NULL    |       |
| language                     | varchar(32)      | NO   | PRI |         |       |
| delta                        | int(10) unsigned | NO   | PRI | NULL    |       |
| field_user_notes_value       | int(11)          | YES  | MUL | NULL    |       |
| field_user_notes_revision_id | int(11)          | YES  | MUL | NULL    |       |
+------------------------------+------------------+------+-----+---------+-------+

mysql> desc field_data_field_user_notes_date;
+-----------------------------+------------------+------+-----+---------+-------+
| Field                       | Type             | Null | Key | Default | Extra |
+-----------------------------+------------------+------+-----+---------+-------+
| entity_type                 | varchar(128)     | NO   | PRI |         |       | = 'field_collection_item'
| bundle                      | varchar(128)     | NO   | MUL |         |       | = 'field_user_notes'
| deleted                     | tinyint(4)       | NO   | PRI | 0       |       |
| entity_id                   | int(10) unsigned | NO   | PRI | NULL    |       |
| revision_id                 | int(10) unsigned | YES  | MUL | NULL    |       |
| language                    | varchar(32)      | NO   | PRI |         |       |
| delta                       | int(10) unsigned | NO   | PRI | NULL    |       |
| field_user_notes_date_value | datetime         | YES  |     | NULL    |       |
+-----------------------------+------------------+------+-----+---------+-------+

mysql> desc field_data_field_user_notes_text;
+------------------------------+------------------+------+-----+---------+-------+
| Field                        | Type             | Null | Key | Default | Extra |
+------------------------------+------------------+------+-----+---------+-------+
| entity_type                  | varchar(128)     | NO   | PRI |         |       | = 'field_collection_item'
| bundle                       | varchar(128)     | NO   | MUL |         |       | = 'field_user_notes'
| deleted                      | tinyint(4)       | NO   | PRI | 0       |       |
| entity_id                    | int(10) unsigned | NO   | PRI | NULL    |       |
| revision_id                  | int(10) unsigned | YES  | MUL | NULL    |       |
| language                     | varchar(32)      | NO   | PRI |         |       |
| delta                        | int(10) unsigned | NO   | PRI | NULL    |       |
| field_user_notes_text_value  | longtext         | YES  |     | NULL    |       |
| field_user_notes_text_format | varchar(255)     | YES  | MUL | NULL    |       |
+------------------------------+------------------+------+-----+---------+-------+

*/

select 'experl_user_notes' as `Creating View`;

create or replace view experl_user_notes as
      select nn.entity_id                       as notes_uid,
             nn.revision_id                     as notes_rev,
             nn.language                        as notes_language,
             nn.delta                           as notes_delta,
             nn.field_user_notes_value          as notes_index,
             nn.field_user_notes_revision_id    as notes_index_rev,
             nd.entity_id                       as notes_did,
             nd.revision_id                     as notes_drev,
             nd.language                        as notes_dlanguage,
             nd.delta                           as notes_ddelta,
             nd.field_user_notes_date_value     as notes_date,
             nt.entity_id                       as notes_tid,
             nt.revision_id                     as notes_trev,
             nt.language                        as notes_tlanguage,
             nt.delta                           as notes_tdelta,
             nt.field_user_notes_text_value     as notes,
             nt.field_user_notes_text_format    as notes_format
        from field_data_field_user_notes        as nn
        join field_data_field_user_notes_date   as nd   on nd.entity_type = 'field_collection_item'
                                                       and nd.bundle      = 'field_user_notes'
                                                       and not nd.deleted
                                                       and nd.entity_id   = nn.field_user_notes_value
        join field_data_field_user_notes_text   as nt   on nt.entity_type = 'field_collection_item'
                                                       and nt.bundle      = 'field_user_notes'
                                                       and not nt.deleted
                                                       and nt.entity_id   = nn.field_user_notes_value
       where nn.entity_type = 'user'
         and nn.bundle      = 'user'
         and not nn.deleted;
