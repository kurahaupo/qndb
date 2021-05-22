
/* Roll all the address fields into a single view */

/*

mysql> desc field_data_field_user_address_1;
+----------------------------------------------+------------------+------+-----+---------+-------+
| Field                                        | Type             | Null | Key | Default | Extra |
+----------------------------------------------+------------------+------+-----+---------+-------+
| entity_type                                  | varchar(128)     | NO   | PRI |         |       |
| bundle                                       | varchar(128)     | NO   | MUL |         |       |
| deleted                                      | tinyint(4)       | NO   | PRI | 0       |       |
| entity_id                                    | int(10) unsigned | NO   | PRI | NULL    |       |
| revision_id                                  | int(10) unsigned | YES  | MUL | NULL    |       |
| language                                     | varchar(32)      | NO   | PRI |         |       |
| delta                                        | int(10) unsigned | NO   | PRI | NULL    |       |
| field_user_address_1_country                 | varchar(2)       | YES  |     |         |       |
| field_user_address_1_administrative_area     | varchar(255)     | YES  |     |         |       |
| field_user_address_1_sub_administrative_area | varchar(255)     | YES  |     |         |       |
| field_user_address_1_locality                | varchar(255)     | YES  |     |         |       |
| field_user_address_1_dependent_locality      | varchar(255)     | YES  |     |         |       |
| field_user_address_1_postal_code             | varchar(255)     | YES  |     |         |       |
| field_user_address_1_thoroughfare            | varchar(255)     | YES  |     |         |       |
| field_user_address_1_premise                 | varchar(255)     | YES  |     |         |       |
| field_user_address_1_sub_premise             | varchar(255)     | YES  |     |         |       |
| field_user_address_1_organisation_name       | varchar(255)     | YES  |     |         |       |
| field_user_address_1_name_line               | varchar(255)     | YES  |     |         |       |
| field_user_address_1_first_name              | varchar(255)     | YES  |     |         |       |
| field_user_address_1_last_name               | varchar(255)     | YES  |     |         |       |
| field_user_address_1_data                    | longtext         | YES  |     | NULL    |       |
+----------------------------------------------+------------------+------+-----+---------+-------+

mysql> desc field_data_field_user_address_2;
+----------------------------------------------+------------------+------+-----+---------+-------+
| Field                                        | Type             | Null | Key | Default | Extra |
+----------------------------------------------+------------------+------+-----+---------+-------+
| entity_type                                  | varchar(128)     | NO   | PRI |         |       |
| bundle                                       | varchar(128)     | NO   | MUL |         |       |
| deleted                                      | tinyint(4)       | NO   | PRI | 0       |       |
| entity_id                                    | int(10) unsigned | NO   | PRI | NULL    |       |
| revision_id                                  | int(10) unsigned | YES  | MUL | NULL    |       |
| language                                     | varchar(32)      | NO   | PRI |         |       |
| delta                                        | int(10) unsigned | NO   | PRI | NULL    |       |
| field_user_address_2_country                 | varchar(2)       | YES  |     |         |       |
| field_user_address_2_administrative_area     | varchar(255)     | YES  |     |         |       |
| field_user_address_2_sub_administrative_area | varchar(255)     | YES  |     |         |       |
| field_user_address_2_locality                | varchar(255)     | YES  |     |         |       |
| field_user_address_2_dependent_locality      | varchar(255)     | YES  |     |         |       |
| field_user_address_2_postal_code             | varchar(255)     | YES  |     |         |       |
| field_user_address_2_thoroughfare            | varchar(255)     | YES  |     |         |       |
| field_user_address_2_premise                 | varchar(255)     | YES  |     |         |       |
| field_user_address_2_sub_premise             | varchar(255)     | YES  |     |         |       |
| field_user_address_2_organisation_name       | varchar(255)     | YES  |     |         |       |
| field_user_address_2_name_line               | varchar(255)     | YES  |     |         |       |
| field_user_address_2_first_name              | varchar(255)     | YES  |     |         |       |
| field_user_address_2_last_name               | varchar(255)     | YES  |     |         |       |
| field_user_address_2_data                    | longtext         | YES  |     | NULL    |       |
+----------------------------------------------+------------------+------+-----+---------+-------+

mysql> desc field_data_field_user_address_3;
+----------------------------------------------+------------------+------+-----+---------+-------+
| Field                                        | Type             | Null | Key | Default | Extra |
+----------------------------------------------+------------------+------+-----+---------+-------+
| entity_type                                  | varchar(128)     | NO   | PRI |         |       |
| bundle                                       | varchar(128)     | NO   | MUL |         |       |
| deleted                                      | tinyint(4)       | NO   | PRI | 0       |       |
| entity_id                                    | int(10) unsigned | NO   | PRI | NULL    |       |
| revision_id                                  | int(10) unsigned | YES  | MUL | NULL    |       |
| language                                     | varchar(32)      | NO   | PRI |         |       |
| delta                                        | int(10) unsigned | NO   | PRI | NULL    |       |
| field_user_address_3_country                 | varchar(2)       | YES  |     |         |       |
| field_user_address_3_administrative_area     | varchar(255)     | YES  |     |         |       |
| field_user_address_3_sub_administrative_area | varchar(255)     | YES  |     |         |       |
| field_user_address_3_locality                | varchar(255)     | YES  |     |         |       |
| field_user_address_3_dependent_locality      | varchar(255)     | YES  |     |         |       |
| field_user_address_3_postal_code             | varchar(255)     | YES  |     |         |       |
| field_user_address_3_thoroughfare            | varchar(255)     | YES  |     |         |       |
| field_user_address_3_premise                 | varchar(255)     | YES  |     |         |       |
| field_user_address_3_sub_premise             | varchar(255)     | YES  |     |         |       |
| field_user_address_3_organisation_name       | varchar(255)     | YES  |     |         |       |
| field_user_address_3_name_line               | varchar(255)     | YES  |     |         |       |
| field_user_address_3_first_name              | varchar(255)     | YES  |     |         |       |
| field_user_address_3_last_name               | varchar(255)     | YES  |     |         |       |
| field_user_address_3_data                    | longtext         | YES  |     | NULL    |       |
+----------------------------------------------+------------------+------+-----+---------+-------+

mysql> desc field_data_field_user_address_4;
+----------------------------------------------+------------------+------+-----+---------+-------+
| Field                                        | Type             | Null | Key | Default | Extra |
+----------------------------------------------+------------------+------+-----+---------+-------+
| entity_type                                  | varchar(128)     | NO   | PRI |         |       |
| bundle                                       | varchar(128)     | NO   | MUL |         |       |
| deleted                                      | tinyint(4)       | NO   | PRI | 0       |       |
| entity_id                                    | int(10) unsigned | NO   | PRI | NULL    |       |
| revision_id                                  | int(10) unsigned | YES  | MUL | NULL    |       |
| language                                     | varchar(32)      | NO   | PRI |         |       |
| delta                                        | int(10) unsigned | NO   | PRI | NULL    |       |
| field_user_address_4_country                 | varchar(2)       | YES  |     |         |       |
| field_user_address_4_administrative_area     | varchar(255)     | YES  |     |         |       |
| field_user_address_4_sub_administrative_area | varchar(255)     | YES  |     |         |       |
| field_user_address_4_locality                | varchar(255)     | YES  |     |         |       |
| field_user_address_4_dependent_locality      | varchar(255)     | YES  |     |         |       |
| field_user_address_4_postal_code             | varchar(255)     | YES  |     |         |       |
| field_user_address_4_thoroughfare            | varchar(255)     | YES  |     |         |       |
| field_user_address_4_premise                 | varchar(255)     | YES  |     |         |       |
| field_user_address_4_sub_premise             | varchar(255)     | YES  |     |         |       |
| field_user_address_4_organisation_name       | varchar(255)     | YES  |     |         |       |
| field_user_address_4_name_line               | varchar(255)     | YES  |     |         |       |
| field_user_address_4_first_name              | varchar(255)     | YES  |     |         |       |
| field_user_address_4_last_name               | varchar(255)     | YES  |     |         |       |
| field_user_address_4_data                    | longtext         | YES  |     | NULL    |       |
+----------------------------------------------+------------------+------+-----+---------+-------+

mysql> desc field_data_field_user_physical_address;
+-----------------------------------+------------------+------+-----+---------+-------+
| Field                             | Type             | Null | Key | Default | Extra |
+-----------------------------------+------------------+------+-----+---------+-------+
| entity_type                       | varchar(128)     | NO   | PRI |         |       |
| bundle                            | varchar(128)     | NO   | MUL |         |       |
| deleted                           | tinyint(4)       | NO   | PRI | 0       |       |
| entity_id                         | int(10) unsigned | NO   | PRI | NULL    |       |
| revision_id                       | int(10) unsigned | YES  | MUL | NULL    |       |
| language                          | varchar(32)      | NO   | PRI |         |       |
| delta                             | int(10) unsigned | NO   | PRI | NULL    |       |
| field_user_physical_address_value | varchar(255)     | YES  |     | NULL    |       |
+-----------------------------------+------------------+------+-----+---------+-------+

mysql> desc field_data_field_user_postal_address;
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
| field_user_postal_address_value | varchar(255)     | YES  |     | NULL    |       |
+---------------------------------+------------------+------+-----+---------+-------+

mysql> select * from field_data_field_user_postal_address where entity_id = 849;
+-------------+--------+---------+-----------+-------------+----------+-------+---------------------------------+
| entity_type | bundle | deleted | entity_id | revision_id | language | delta | field_user_postal_address_value |
+-------------+--------+---------+-----------+-------------+----------+-------+---------------------------------+
| user        | user   |       0 |       849 |         849 | und      |     0 | edit-field-user-address-1       |
+-------------+--------+---------+-----------+-------------+----------+-------+---------------------------------+

*/

select 'exp_normalise_user_addresses' as `creating`;

create or replace view exp_normalise_user_addresses as
      select a.entity_id                                    as address_uid,
             a.revision_id                                  as address_vid,
             convert(1, unsigned)                           as address_slot,
             a.language                                     as address_language,
             a.field_user_address_1_first_name              as address_first_name,
             a.field_user_address_1_last_name               as address_last_name,
             a.field_user_address_1_name_line               as address_name_line,
             a.field_user_address_1_organisation_name       as address_organisation_name,
             a.field_user_address_1_sub_premise             as address_sub_premise,
             a.field_user_address_1_premise                 as address_line_two,
             a.field_user_address_1_sub_administrative_area as address_sub_administrative_area,
             a.field_user_address_1_administrative_area     as address_administrative_area,
             a.field_user_address_1_thoroughfare            as address_thoroughfare,
             a.field_user_address_1_dependent_locality      as address_dependent_locality,
             a.field_user_address_1_locality                as address_locality,
             a.field_user_address_1_postal_code             as address_postal_code,
             a.field_user_address_1_country                 as address_country,
             a.field_user_address_1_data                    as address_data,
             null /*unlabelled #1*/                         as address_label,
             phy.entity_id is not null                      as address_show_in_book,
             pos.entity_id is not null                      as address_use_as_postal
        from field_data_field_user_address_1        as a
   left join field_data_field_user_physical_address as phy  on phy.entity_id                            = a.entity_id
                                                           and phy.entity_type                          = 'user'
                                                           and phy.bundle                               = 'user'
                                                           and not phy.deleted
                                                           and phy.field_user_physical_address_value    = 'edit-field-user-address-1'
   left join field_data_field_user_postal_address   as pos  on pos.entity_id                            = a.entity_id
                                                           and pos.entity_type                          = 'user'
                                                           and pos.bundle                               = 'user'
                                                           and not pos.deleted
                                                           and pos.field_user_postal_address_value      = 'edit-field-user-address-1'
       where a.entity_type = 'user'
         and a.bundle      = 'user'
         and not a.deleted
 union
      select a.entity_id                                    as address_uid,
             a.revision_id                                  as address_vid,
             convert(2, unsigned)                           as address_slot,
             a.language                                     as address_language,
             a.field_user_address_2_first_name              as address_first_name,
             a.field_user_address_2_last_name               as address_last_name,
             a.field_user_address_2_name_line               as address_name_line,
             a.field_user_address_2_organisation_name       as address_organisation_name,
             a.field_user_address_2_sub_premise             as address_sub_premise,
             a.field_user_address_2_premise                 as address_line_two,
             a.field_user_address_2_sub_administrative_area as address_sub_administrative_area,
             a.field_user_address_2_administrative_area     as address_administrative_area,
             a.field_user_address_2_thoroughfare            as address_thoroughfare,
             a.field_user_address_2_dependent_locality      as address_dependent_locality,
             a.field_user_address_2_locality                as address_locality,
             a.field_user_address_2_postal_code             as address_postal_code,
             a.field_user_address_2_country                 as address_country,
             a.field_user_address_2_data                    as address_data,
             null /*unlabelled #2*/                         as address_label,
             phy.entity_id is not null                      as address_show_in_book,
             pos.entity_id is not null                      as address_use_as_postal
        from field_data_field_user_address_2        as a
   left join field_data_field_user_physical_address as phy  on phy.entity_id                            = a.entity_id
                                                           and phy.entity_type                          = 'user'
                                                           and phy.bundle                               = 'user'
                                                           and not phy.deleted
                                                           and phy.field_user_physical_address_value    = 'edit-field-user-address-2'
   left join field_data_field_user_postal_address   as pos  on pos.entity_id                            = a.entity_id
                                                           and pos.entity_type                          = 'user'
                                                           and pos.bundle                               = 'user'
                                                           and not pos.deleted
                                                           and pos.field_user_postal_address_value      = 'edit-field-user-address-2'
       where a.entity_type = 'user'
         and a.bundle      = 'user'
         and not a.deleted
 union
      select a.entity_id                                    as address_uid,
             a.revision_id                                  as address_vid,
             convert(3, unsigned)                           as address_slot,
             a.language                                     as address_language,
             a.field_user_address_3_first_name              as address_first_name,
             a.field_user_address_3_last_name               as address_last_name,
             a.field_user_address_3_name_line               as address_name_line,
             a.field_user_address_3_organisation_name       as address_organisation_name,
             a.field_user_address_3_sub_premise             as address_sub_premise,
             a.field_user_address_3_premise                 as address_line_two,
             a.field_user_address_3_sub_administrative_area as address_sub_administrative_area,
             a.field_user_address_3_administrative_area     as address_administrative_area,
             a.field_user_address_3_thoroughfare            as address_thoroughfare,
             a.field_user_address_3_dependent_locality      as address_dependent_locality,
             a.field_user_address_3_locality                as address_locality,
             a.field_user_address_3_postal_code             as address_postal_code,
             a.field_user_address_3_country                 as address_country,
             a.field_user_address_3_data                    as address_data,
             null /*unlabelled #3*/                         as address_label,
             phy.entity_id is not null                      as address_show_in_book,
             pos.entity_id is not null                      as address_use_as_postal
        from field_data_field_user_address_3        as a
   left join field_data_field_user_physical_address as phy  on phy.entity_id                            = a.entity_id
                                                           and phy.entity_type                          = 'user'
                                                           and not phy.deleted
                                                           and phy.field_user_physical_address_value    = 'edit-field-user-address-3'
   left join field_data_field_user_postal_address   as pos  on pos.entity_id                            = a.entity_id
                                                           and pos.entity_type                          = 'user'
                                                           and pos.bundle                               = 'user'
                                                           and not pos.deleted
                                                           and pos.field_user_postal_address_value      = 'edit-field-user-address-3'
       where a.entity_type = 'user'
         and a.bundle      = 'user'
         and not a.deleted
 union
      select a.entity_id                                    as address_uid,
             a.revision_id                                  as address_vid,
             convert(4, unsigned)                           as address_slot,
             a.language                                     as address_language,
             a.field_user_address_4_first_name              as address_first_name,
             a.field_user_address_4_last_name               as address_last_name,
             a.field_user_address_4_name_line               as address_name_line,
             a.field_user_address_4_organisation_name       as address_organisation_name,
             a.field_user_address_4_sub_premise             as address_sub_premise,
             a.field_user_address_4_premise                 as address_line_two,
             a.field_user_address_4_sub_administrative_area as address_sub_administrative_area,
             a.field_user_address_4_administrative_area     as address_administrative_area,
             a.field_user_address_4_thoroughfare            as address_thoroughfare,
             a.field_user_address_4_dependent_locality      as address_dependent_locality,
             a.field_user_address_4_locality                as address_locality,
             a.field_user_address_4_postal_code             as address_postal_code,
             a.field_user_address_4_country                 as address_country,
             a.field_user_address_4_data                    as address_data,
             null /*unlabelled #3*/                         as address_label,
             phy.entity_id is not null                      as address_show_in_book,
             pos.entity_id is not null                      as address_use_as_postal
        from field_data_field_user_address_4        as a
   left join field_data_field_user_physical_address as phy  on phy.entity_id                            = a.entity_id
                                                           and phy.entity_type                          = 'user'
                                                           and phy.bundle                               = 'user'
                                                           and not phy.deleted
                                                           and phy.field_user_physical_address_value    = 'edit-field-user-address-4'
   left join field_data_field_user_postal_address   as pos  on pos.entity_id                            = a.entity_id
                                                           and pos.entity_type                          = 'user'
                                                           and pos.bundle                               = 'user'
                                                           and not pos.deleted
                                                           and pos.field_user_postal_address_value      = 'edit-field-user-address-4'
       where a.entity_type = 'user'
         and a.bundle      = 'user'
         and not a.deleted;

select 'experl_user_addresses2' as `creating`;

create or replace view experl_user_addresses2 as
      select address_uid,
             address_vid,
             address_slot,
             address_language,
             concat(
                    ifnull( concat(   /*'FIRST_AND_LAST_NAMES:',    */ address_first_name, ' ',  address_last_name, '\n'),
                     ifnull( concat(  /*'FIRST_NAME:',              */ address_first_name, '\n'),
                      ifnull( concat( /*'LAST_NAME:',               */ address_last_name, '\n'),
                       ''))),
                    ifnull(concat(    /*'NAME_LINE:',               */ address_name_line, '\n'), ''),
                    ifnull(concat(    /*'ORGANISATION_NAME:',       */ address_organisation_name, '\n'), ''),
                    ifnull(concat(    /*'SUB_PREMISE:',             */ address_sub_premise, '\n'), ''),
                    ifnull(concat(    /*'PREMISE:',                 */ address_line_two, '\n'), ''),
                    ifnull(concat(    /*'THOROUGHFARE:',            */ address_thoroughfare, '\n'), ''),
                    ifnull(concat(    /*'DEPENDENT_LOCALITY:',      */ address_dependent_locality, '\n'), ''),
                    ifnull(concat(    /*'LOCALITY:',                */ address_locality, '\n'), ''),
                    ifnull(concat(    /*'SUB_ADMINISTRATIVE_AREA:', */ address_sub_administrative_area, '\n'), ''),
                    ifnull(concat(    /*'ADMINISTRATIVE_AREA:',     */ address_administrative_area, '\n'), ''),
                    ifnull(concat(    /*'POSTCODE:',                */ address_postal_code, '\n'), ''),
                    ifnull(concat(    /*'CC:',                      */ address_country), 'NZ*')
                    ) as address,
             address_data,
             address_label,
             address_show_in_book,
             address_use_as_postal
        from exp_normalise_user_addresses;


select 'experl_user_addresses' as `creating`;

create or replace view experl_user_addresses as
      select a.entity_id                                            as address_uid,
             ai.revision_id                                         as address_vid,
             ifnull(a.delta+1, 0)                                   as address_slot,
             ai.language                                            as address_language,
             ai.delta                                               as address_delta,
             ai.field_preformatted_address_value                    as address,
             al.field_label_value                                   as address_label,
             ifnull(ap.field_use_as_postal_address_value, 0)   != 0 as address_use_as_postal,
             ifnull(ab.field_print_in_book_value, 0)           != 0 as address_show_in_book
        from field_data_field_addresses             as a
   left join field_data_field_label                 as al   on a.field_addresses_value=al.entity_id
                                                           and al.entity_type = 'field_collection_item'
                                                           and al.bundle      = 'field_addresses'
                                                           and not al.deleted
   left join field_data_field_preformatted_address  as ai   on a.field_addresses_value=ai.entity_id
                                                           and ai.entity_type = 'field_collection_item'
                                                           and ai.bundle      = 'field_addresses'
                                                           and not ai.deleted
   left join field_data_field_use_as_postal_address as ap   on a.field_addresses_value=ap.entity_id
                                                           and ap.entity_type = 'field_collection_item'
                                                           and ap.bundle      = 'field_addresses'
                                                           and not ap.deleted
   left join field_data_field_print_in_book         as ab   on a.field_addresses_value=ab.entity_id
                                                           and ab.entity_type = 'field_collection_item'
                                                           and ab.bundle      = 'field_addresses'
                                                           and not ab.deleted
       where a.entity_type = 'user'
         and a.bundle      = 'user'
         and not a.deleted
;

/*

mysql> desc field_data_field_addresses;
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
| field_addresses_value       | int(11)          | YES  | MUL | NULL    |       |
| field_addresses_revision_id | int(11)          | YES  | MUL | NULL    |       |
+-----------------------------+------------------+------+-----+---------+-------+
9 rows in set (0.22 sec)

mysql>  show tables like '%field_user_addr%';
+---------------------------------------+
| Tables_in_quakers (%field_user_addr%) |
+---------------------------------------+
| field_data_field_user_address         |
| field_data_field_user_address_1       |
| field_data_field_user_address_2       |
| field_data_field_user_address_3       |
| field_data_field_user_address_4       |
| field_revision_field_user_address     |
| field_revision_field_user_address_1   |
| field_revision_field_user_address_2   |
| field_revision_field_user_address_3   |
| field_revision_field_user_address_4   |
+---------------------------------------+
10 rows in set (0.04 sec)

mysql> desc field_data_field_user_address;
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
| field_user_address_value  | longtext         | YES  |     | NULL    |       |
| field_user_address_format | varchar(255)     | YES  | MUL | NULL    |       |
+---------------------------+------------------+------+-----+---------+-------+
9 rows in set (0.05 sec)

mysql> desc field_data_field_print_in_book;
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
| field_print_in_book_value | int(11)          | YES  | MUL | NULL    |       |
+---------------------------+------------------+------+-----+---------+-------+
8 rows in set (0.05 sec)

mysql> desc field_data_field_use_as_postal_address;
+-----------------------------------+------------------+------+-----+---------+-------+
| Field                             | Type             | Null | Key | Default | Extra |
+-----------------------------------+------------------+------+-----+---------+-------+
| entity_type                       | varchar(128)     | NO   | PRI |         |       |
| bundle                            | varchar(128)     | NO   | MUL |         |       |
| deleted                           | tinyint(4)       | NO   | PRI | 0       |       |
| entity_id                         | int(10) unsigned | NO   | PRI | NULL    |       |
| revision_id                       | int(10) unsigned | YES  | MUL | NULL    |       |
| language                          | varchar(32)      | NO   | PRI |         |       |
| delta                             | int(10) unsigned | NO   | PRI | NULL    |       |
| field_use_as_postal_address_value | int(11)          | YES  | MUL | NULL    |       |
+-----------------------------------+------------------+------+-----+---------+-------+
8 rows in set (0.05 sec)

mysql> desc field_data_field_label;
+--------------------+------------------+------+-----+---------+-------+
| Field              | Type             | Null | Key | Default | Extra |
+--------------------+------------------+------+-----+---------+-------+
| entity_type        | varchar(128)     | NO   | PRI |         |       |
| bundle             | varchar(128)     | NO   | MUL |         |       |
| deleted            | tinyint(4)       | NO   | PRI | 0       |       |
| entity_id          | int(10) unsigned | NO   | PRI | NULL    |       |
| revision_id        | int(10) unsigned | YES  | MUL | NULL    |       |
| language           | varchar(32)      | NO   | PRI |         |       |
| delta              | int(10) unsigned | NO   | PRI | NULL    |       |
| field_label_value  | varchar(20)      | YES  |     | NULL    |       |
| field_label_format | varchar(255)     | YES  | MUL | NULL    |       |
+--------------------+------------------+------+-----+---------+-------+
9 rows in set (0.05 sec)

*/
