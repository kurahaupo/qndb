
/*

mysql> desc field_data_field_user_kin;
+----------------------------+------------------+------+-----+---------+-------+
| Field                      | Type             | Null | Key | Default | Extra |
+----------------------------+------------------+------+-----+---------+-------+
| entity_type                | varchar(128)     | NO   | PRI |         |       | = 'user'
| bundle                     | varchar(128)     | NO   | MUL |         |       |
| deleted                    | tinyint(4)       | NO   | PRI | 0       |       |
| entity_id                  | int(10) unsigned | NO   | PRI | NULL    |       | = (first) user.uid
| revision_id                | int(10) unsigned | YES  | MUL | NULL    |       |
| language                   | varchar(32)      | NO   | PRI |         |       |
| delta                      | int(10) unsigned | NO   | PRI | NULL    |       |
| field_user_kin_value       | int(11)          | YES  | MUL | NULL    |       | = FDFU_kin_relationship.entity_id = FDFU_kin_user_ref.entity_id
| field_user_kin_revision_id | int(11)          | YES  | MUL | NULL    |       |
+----------------------------+------------------+------+-----+---------+-------+

mysql> select * from field_data_field_user_kin where entity_id in ( 185, 186, 1085, 1144, 1165, 1288, 1329 );
+-------------+--------+---------+-----------+-------------+----------+-------+----------------------+----------------------------+
| entity_type | bundle | deleted | entity_id | revision_id | language | delta | field_user_kin_value | field_user_kin_revision_id |
+-------------+--------+---------+-----------+-------------+----------+-------+----------------------+----------------------------+
| user        | user   |       0 |       185 |         185 | und      |     0 |                 4781 |                       6281 |
| user        | user   |       0 |       185 |         185 | und      |     1 |                 4835 |                       6386 |
| user        | user   |       0 |       185 |         185 | und      |     2 |                 4841 |                       6398 |
| user        | user   |       0 |       185 |         185 | und      |     3 |                 4850 |                       6413 |
| user        | user   |       0 |       186 |         186 | und      |     0 |                 4847 |                       6407 |
| user        | user   |       0 |      1144 |        1144 | und      |     0 |                 3481 |                       4313 |
| user        | user   |       0 |      1144 |        1144 | und      |     1 |                 3489 |                       4329 |
| user        | user   |       0 |      1144 |        1144 | und      |     2 |                 4823 |                       6362 |
| user        | user   |       0 |      1165 |        1165 | und      |     0 |                 3487 |                       4325 |
| user        | user   |       0 |      1329 |        1329 | und      |     0 |                 4820 |                       6356 |
+-------------+--------+---------+-----------+-------------+----------+-------+----------------------+----------------------------+

mysql> desc field_data_field_user_kin_relationship;
+-----------------------------------+------------------+------+-----+---------+-------+
| Field                             | Type             | Null | Key | Default | Extra |
+-----------------------------------+------------------+------+-----+---------+-------+
| entity_type                       | varchar(128)     | NO   | PRI |         |       | = 'field_collection_item'
| bundle                            | varchar(128)     | NO   | MUL |         |       | = 'field_user_kin'
| deleted                           | tinyint(4)       | NO   | PRI | 0       |       |
| entity_id                         | int(10) unsigned | NO   | PRI | NULL    |       | = FDFU_kin.field_user_kin_value = FDFU_kin_user_ref.entity_id
| revision_id                       | int(10) unsigned | YES  | MUL | NULL    |       |
| language                          | varchar(32)      | NO   | PRI |         |       |
| delta                             | int(10) unsigned | NO   | PRI | NULL    |       |
| field_user_kin_relationship_value | varchar(255)     | YES  | MUL | NULL    |       | ('child', 'parent' etc)
+-----------------------------------+------------------+------+-----+---------+-------+

mysql> select * from field_data_field_user_kin_relationship where field_user_kin_relationship_value='proxy';
+-----------------------+----------------+---------+-----------+-------------+----------+-------+-----------------------------------+
| entity_type           | bundle         | deleted | entity_id | revision_id | language | delta | field_user_kin_relationship_value |
+-----------------------+----------------+---------+-----------+-------------+----------+-------+-----------------------------------+
| field_collection_item | field_user_kin |       0 |      5591 |        7634 | und      |     0 | proxy                             |
| field_collection_item | field_user_kin |       0 |      5603 |        7658 | und      |     0 | proxy                             |
+-----------------------+----------------+---------+-----------+-------------+----------+-------+-----------------------------------+

mysql> desc field_data_field_user_kin_user_ref;
+-----------------------------------+------------------+------+-----+---------+-------+
| Field                             | Type             | Null | Key | Default | Extra |
+-----------------------------------+------------------+------+-----+---------+-------+
| entity_type                       | varchar(128)     | NO   | PRI |         |       | = 'field_collection_item'
| bundle                            | varchar(128)     | NO   | MUL |         |       | = 'field_user_kin'
| deleted                           | tinyint(4)       | NO   | PRI | 0       |       |
| entity_id                         | int(10) unsigned | NO   | PRI | NULL    |       | = FDFU_kin.field_user_kin_value = FDFU_kin_relationship.entity_id
| revision_id                       | int(10) unsigned | YES  | MUL | NULL    |       |
| language                          | varchar(32)      | NO   | PRI |         |       |
| delta                             | int(10) unsigned | NO   | PRI | NULL    |       |
| field_user_kin_user_ref_target_id | int(10) unsigned | NO   | MUL | NULL    |       | = (second) user.id
+-----------------------------------+------------------+------+-----+---------+-------+

mysql> select * from field_data_field_user_kin_user_ref where field_user_kin_user_ref_target_id in ( 185, 186, 1085, 1144, 1165, 1288, 1329 );
+-----------------------+----------------+---------+-----------+-------------+----------+-------+-----------------------------------+
| entity_type           | bundle         | deleted | entity_id | revision_id | language | delta | field_user_kin_user_ref_target_id |
+-----------------------+----------------+---------+-----------+-------------+----------+-------+-----------------------------------+
| field_collection_item | field_user_kin |       0 |      4327 |        5529 | und      |     0 |                               185 |
| field_collection_item | field_user_kin |       0 |      4601 |        5942 | und      |     0 |                               185 |
| field_collection_item | field_user_kin |       0 |      4637 |        6011 | und      |     0 |                               185 |
| field_collection_item | field_user_kin |       0 |      4652 |        6038 | und      |     0 |                               185 |
| field_collection_item | field_user_kin |       0 |      4733 |        6188 | und      |     0 |                               185 |
| field_collection_item | field_user_kin |       0 |      4787 |        6293 | und      |     0 |                               185 |
| field_collection_item | field_user_kin |       0 |      4832 |        6380 | und      |     0 |                               185 |
| field_collection_item | field_user_kin |       0 |      4838 |        6392 | und      |     0 |                               185 |
| field_collection_item | field_user_kin |       0 |      4847 |        6407 | und      |     0 |                               185 |
| field_collection_item | field_user_kin |       0 |      4325 |        5525 | und      |     0 |                               186 |
| field_collection_item | field_user_kin |       0 |      4649 |        6032 | und      |     0 |                               186 |
| field_collection_item | field_user_kin |       0 |      4742 |        6206 | und      |     0 |                               186 |
| field_collection_item | field_user_kin |       0 |      4790 |        6299 | und      |     0 |                               186 |
| field_collection_item | field_user_kin |       0 |      4850 |        6413 | und      |     0 |                               186 |
| field_collection_item | field_user_kin |       0 |      3487 |        4325 | und      |     0 |                              1144 |
| field_collection_item | field_user_kin |       0 |      4817 |        6350 | und      |     0 |                              1144 |
| field_collection_item | field_user_kin |       0 |      4820 |        6356 | und      |     0 |                              1144 |
| field_collection_item | field_user_kin |       0 |      4823 |        6362 | und      |     0 |                              1165 |
| field_collection_item | field_user_kin |       0 |      3489 |        4329 | und      |     0 |                              1329 |
+-----------------------+----------------+---------+-----------+-------------+----------+-------+-----------------------------------+

mysql> desc field_data_field_user_spouse
    ->;
+-----------------------------+------------------+------+-----+---------+-------+
| Field                       | Type             | Null | Key | Default | Extra |
+-----------------------------+------------------+------+-----+---------+-------+
| entity_type                 | varchar(128)     | NO   | PRI |         |       |
| bundle                      | varchar(128)     | NO   | MUL |         |       |
| deleted                     | tinyint(4)       | NO   | PRI | 0       |       |
| entity_id                   | int(10) unsigned | NO   | PRI | NULL    |       |
| revision_id                 | int(10) unsigned | YES  | MUL | NULL    |       |
| language                    | varchar(32)      | NO   | PRI |         |       |
| delta                       | int(10) unsigned | NO   | PRI | NULL    |       |
| field_user_spouse_target_id | int(10) unsigned | NO   | MUL | NULL    |       |
+-----------------------------+------------------+------+-----+---------+-------+

*/

select 'experl_user_kin' as `creating`;

create or replace view experl_user_kin as
     select ukin.entity_id                          as kin_uid,
            ukin.revision_id                        as kin_rev,
            ukin.language                           as kin_language,
            ukin.delta                              as kin_delta,
            ukint.field_user_kin_relationship_value as kin_rel_type,
            ukinr.field_user_kin_user_ref_target_id as kin_uid2
       from field_data_field_user_kin               as ukin
       join field_data_field_user_kin_user_ref      as ukinr on ukinr.bundle        = 'field_user_kin'
                                                            and ukinr.entity_type   = 'field_collection_item'
                                                            and not ukinr.deleted
                                                            and ukinr.revision_id   = ukin.field_user_kin_revision_id
                                                            and ukinr.entity_id     = ukin.field_user_kin_value
       join field_data_field_user_kin_relationship  as ukint on ukint.entity_type   = 'field_collection_item'
                                                            and ukint.bundle        = 'field_user_kin'
                                                            and not ukint.deleted
                                                            and ukint.entity_id     = ukin.field_user_kin_value
                                                            and ukint.revision_id   = ukin.field_user_kin_revision_id
      where ukin.entity_type = 'user'
        and ukin.bundle      = 'user'
        and not ukin.deleted
 union
     select entity_id                               as kin_uid,
            revision_id                             as kin_rev,
            language                                as kin_language,
            delta                                   as kin_delta,
            'spouse'                                as kin_rel_type,
            field_user_spouse_target_id             as kin_uid2
       from field_data_field_user_spouse
      where entity_type = 'user'
        and bundle      = 'user'
        and not deleted
;
