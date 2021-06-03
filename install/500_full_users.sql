/*********** ONE-TO-ONE adjunct components to user ***********/

/*********************

The subqueries here represent things that should occur only once per user, so
doing a LEFT JOIN won't result in multiple rows per user.

Note that experl_full_users has « GROUP BY users.uid », which enforces this; if there are
any multiple rows they will be ignored.

*/

/*********** Birthdate ***********

mysql> desc field_data_field_user_birthdate;
+----------------------------+------------------+------+-----+---------+-------+
| Field                      | Type             | Null | Key | Default | Extra |
+----------------------------+------------------+------+-----+---------+-------+
| entity_type                | varchar(128)     | NO   | PRI |         |       |
| bundle                     | varchar(128)     | NO   | MUL |         |       |
| deleted                    | tinyint(4)       | NO   | PRI | 0       |       |
| entity_id                  | int(10) unsigned | NO   | PRI | NULL    |       |
| revision_id                | int(10) unsigned | YES  | MUL | NULL    |       |
| language                   | varchar(32)      | NO   | PRI |         |       |
| delta                      | int(10) unsigned | NO   | PRI | NULL    |       |
| field_user_birthdate_value | int(11)          | YES  |     | NULL    |       |
+----------------------------+------------------+------+-----+---------+-------+

mysql> describe field_data_field_birthday_visibility;
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
| field_birthday_visibility_value | int(11)          | YES  | MUL | NULL    |       |
+---------------------------------+------------------+------+-----+---------+-------+
8 rows in set (0.05 sec)

*/

select 'exp_user_birthdate' as `Creating Internal View`;

create or replace view exp_user_birthdate as
       select b.entity_id                                   as birthdate_uid,
              b.revision_id                                 as birthdate_rev,
              b.language                                    as birthdate_language,
              b.delta                                       as birthdate_delta,
              b.field_user_birthdate_value                  as birthdate,
              ifnull(v.field_birthday_visibility_value, 0)  as birthday_visible
         from field_data_field_user_birthdate       as b
    left join field_data_field_birthday_visibility  as v on b.entity_type = v.entity_type
                                                        and b.entity_id   = v.entity_id
                                                        and b.bundle      = v.bundle
                                                        and b.delta       = v.delta
                                                        and not v.deleted
        where b.entity_type = 'user'
          and b.bundle      = 'user'
          and not b.deleted
          and b.field_user_birthdate_value != 0
;

/*

mysql> desc field_data_field_user_joined_year;
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
| field_user_joined_year_value | datetime         | YES  |     | NULL    |       |
+------------------------------+------------------+------+-----+---------+-------+

*/

select 'exp_user_joined_year' as `Creating Internal View`;

create or replace view exp_user_joined_year as
       select entity_id                         as joined_year_uid,
              revision_id                       as joined_year_rev,
              language                          as joined_year_language,
              delta                             as joined_year_delta,
              field_user_joined_year_value      as joined_year
         from field_data_field_user_joined_year
        where entity_type = 'user'
          and bundle      = 'user'
          and not deleted
;

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

select 'exp_user_mm_member' as `Creating Internal View`;

create or replace view exp_user_mm_member as
      select um.entity_id                       as mmm_uid,
             um.revision_id                     as mmm_rev,
             um.language                        as mmm_language,
             um.delta                           as mmm_delta,
             um.field_user_main_og_target_id    as mmm_xmid,
             mmt.field_short_name_value         as mmm_xmtag
        from field_data_field_user_main_og  as um
   left join field_data_field_short_name    as mmt  on mmt.entity_type = 'node'
                                                   and mmt.bundle      = 'meeting_group'
                                                   and not mmt.deleted
                                                   and mmt.entity_id   = um.field_user_main_og_target_id
       where um.entity_type = 'user'
         and um.bundle      = 'user'
         and not um.deleted
;

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

select 'exp_user_access_needs' as `Creating View`;

create or replace view exp_user_access_needs as
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

/* Names */

/*

mysql> desc field_data_field_user_first_name;
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
| field_user_first_name_value  | varchar(255)     | YES  |     | NULL    |       |
| field_user_first_name_format | varchar(255)     | YES  | MUL | NULL    |       |
+------------------------------+------------------+------+-----+---------+-------+

mysql> desc field_data_field_user_preferred_name;
+----------------------------------+------------------+------+-----+---------+-------+
| Field                            | Type             | Null | Key | Default | Extra |
+----------------------------------+------------------+------+-----+---------+-------+
| entity_type                      | varchar(128)     | NO   | PRI |         |       |
| bundle                           | varchar(128)     | NO   | MUL |         |       |
| deleted                          | tinyint(4)       | NO   | PRI | 0       |       |
| entity_id                        | int(10) unsigned | NO   | PRI | NULL    |       |
| revision_id                      | int(10) unsigned | YES  | MUL | NULL    |       |
| language                         | varchar(32)      | NO   | PRI |         |       |
| delta                            | int(10) unsigned | NO   | PRI | NULL    |       |
| field_user_preferred_name_value  | varchar(255)     | YES  |     | NULL    |       |
| field_user_preferred_name_format | varchar(255)     | YES  | MUL | NULL    |       |
+----------------------------------+------------------+------+-----+---------+-------+

mysql> desc field_data_field_user_last_name;
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
| field_user_last_name_value  | varchar(255)     | YES  |     | NULL    |       |
| field_user_last_name_format | varchar(255)     | YES  | MUL | NULL    |       |
+-----------------------------+------------------+------+-----+---------+-------+

*/

select 'exp_user_gname' as `Creating Internal View`;

create or replace view exp_user_gname as
      select entity_id                      as gname_uid,
             revision_id                    as gname_rev,
             language                       as gname_language,
             delta                          as gname_delta,
             field_user_first_name_value    as given_name,
             field_user_first_name_format   as gname_format
        from field_data_field_user_first_name
       where entity_type                 = 'user'
         and bundle                      = 'user'
         and not deleted
         and field_user_first_name_value != '';

select 'exp_user_pname' as `Creating Internal View`;

create or replace view exp_user_pname as
      select entity_id                          as pname_uid,
             revision_id                        as pname_rev,
             language                           as pname_language,
             delta                              as pname_delta,
             field_user_preferred_name_value    as pref_name,
             field_user_preferred_name_format   as pname_format
        from field_data_field_user_preferred_name
       where entity_type                     = 'user'
         and bundle                          = 'user'
         and not deleted
         and field_user_preferred_name_value != '';

select 'exp_user_sname' as `Creating Internal View`;

create or replace view exp_user_sname as
      select entity_id                      as sname_uid,
             revision_id                    as sname_rev,
             language                       as sname_language,
             delta                          as sname_delta,
             field_user_last_name_value     as surname,
             field_user_last_name_format    as sname_format
        from field_data_field_user_last_name
       where entity_type                = 'user'
         and bundle                     = 'user'
         and not deleted
         and field_user_last_name_value != '';
/* End Names */


/*

mysql> desc users;
+------------------+------------------+------+-----+---------+-------+
| Field            | Type             | Null | Key | Default | Extra |
+------------------+------------------+------+-----+---------+-------+
| uid              | int(10) unsigned | NO   | PRI | 0       |       |
| name             | varchar(60)      | NO   | UNI |         |       |
| pass             | varchar(128)     | NO   |     |         |       |
| mail             | varchar(254)     | YES  | MUL |         |       |
| theme            | varchar(255)     | NO   |     |         |       |
| signature        | varchar(255)     | NO   |     |         |       |
| signature_format | varchar(255)     | YES  |     | NULL    |       |
| created          | int(11)          | NO   | MUL | 0       |       |
| access           | int(11)          | NO   | MUL | 0       |       |
| login            | int(11)          | NO   |     | 0       |       |
| status           | tinyint(4)       | NO   |     | 0       |       |
| timezone         | varchar(32)      | YES  |     | NULL    |       |
| language         | varchar(12)      | NO   |     |         |       |
| picture          | int(11)          | NO   | MUL | 0       |       |
| init             | varchar(254)     | YES  |     |         |       |
| data             | longblob         | YES  |     | NULL    |       |
| uuid             | char(36)         | NO   | MUL |         |       |
+------------------+------------------+------+-----+---------+-------+

mysql> desc field_data_field_user_old_id;
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
| field_user_old_id_value | int(11)          | YES  |     | NULL    |       |
+-------------------------+------------------+------+-----+---------+-------+

mysql> desc field_data_field_user_resigned;
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
| field_user_resigned_value | int(11)          | YES  | MUL | NULL    |       |
+---------------------------+------------------+------+-----+---------+-------+

mysql> desc field_data_field_user_inactive;
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
| field_user_inactive_value | int(11)          | YES  | MUL | NULL    |       |
+---------------------------+------------------+------+-----+---------+-------+

mysql> describe field_data_field_visibility;
+------------------------+------------------+------+-----+---------+-------+
| Field                  | Type             | Null | Key | Default | Extra |
+------------------------+------------------+------+-----+---------+-------+
| entity_type            | varchar(128)     | NO   | PRI |         |       |
| bundle                 | varchar(128)     | NO   | MUL |         |       |
| deleted                | tinyint(4)       | NO   | PRI | 0       |       |
| entity_id              | int(10) unsigned | NO   | PRI | NULL    |       |
| revision_id            | int(10) unsigned | YES  | MUL | NULL    |       |
| language               | varchar(32)      | NO   | PRI |         |       |
| delta                  | int(10) unsigned | NO   | PRI | NULL    |       |
| field_visibility_value | int(11)          | YES  | MUL | NULL    |       |
+------------------------+------------------+------+-----+---------+-------+
8 rows in set (0.16 sec)

*/

/*
    `exp_all_users` links the users table with the core set of
    status control flags: inactive, deceased, and resigned, as those
    are very often required for subsequent joins.
*/

select 'exp_all_users' as `Creating Internal View`;

create or replace view exp_all_users as
      select u.*,
             ifnull(o.field_user_old_id_value, u.uid + 4096)    as old_uid,
             u.status                                       = 0 as blocked,
             ifnull(r.field_user_resigned_value, false)         as resigned,
             ifnull(d.field_user_deceased_value, false)         as deceased,
             ifnull(i.field_user_inactive_value, false)         as inactive,
             ifnull(v.field_visibility_value, false)            as visible
        from users                          as u
   left join field_data_field_user_old_id   as o    on o.entity_id   = u.uid
                                                   and o.entity_type = 'user'
                                                   and o.bundle      = 'user'
                                                   and not o.deleted
   left join field_data_field_user_resigned as r    on r.entity_id   = u.uid
                                                   and r.entity_type = 'user'
                                                   and r.bundle      = 'user'
                                                   and not r.deleted
   left join field_data_field_user_deceased as d    on d.entity_id   = u.uid
                                                   and d.entity_type = 'user'
                                                   and d.bundle      = 'user'
                                                   and not d.deleted
   left join field_data_field_user_inactive as i    on i.entity_id   = u.uid
                                                   and i.entity_type = 'user'
                                                   and i.bundle      = 'user'
                                                   and not i.deleted
   left join field_data_field_visibility    as v    on v.entity_id   = u.uid
                                                   and v.entity_type = 'user'
                                                   and v.bundle      = 'user'
                                                   and not v.deleted
       where u.name is not null
         and u.name != ''
    group by u.uid;

/* people who aren't dead */

select 'exp_active_users' as `Creating Internal View`;

create or replace view exp_active_users as
      select *
        from exp_all_users
       where not blocked
         and not deceased;

/*********************** USER RECORDS ***********************
 *
 * Select from `users` and left-join with all the singleton adjunct  tables.
 *
 * Since this relies on all the other tables, it has to come last
 */

select 'experl_full_users' as `Creating View`;

create or replace view experl_full_users as
      select u.*,
             concat(ifnull(pref_name, given_name), ' ',surname) as full_name,
             pn.pref_name,
             gn.given_name,
             sn.surname,
             /*ve.visible_email,*/
             /*wb.website,*/
             bd.birthdate,
             jy.joined_year,
             mm.mmm_xmid    as mm_id,
             mm.mmm_xmtag   as mm_tag
        from exp_active_users as u
   left join exp_user_pname            as pn on uid = pname_uid
   left join exp_user_gname            as gn on uid = gname_uid
   left join exp_user_sname            as sn on uid = sname_uid
   /*left join exp_user_visible_email    as ve on uid = visible_email_uid*/
   /*left join exp_user_website          as wb on uid = website_uid*/
   left join exp_user_birthdate        as bd on uid = birthdate_uid
   left join exp_user_joined_year      as jy on uid = joined_year_uid
   left join exp_user_mm_member        as mm on uid = mmm_uid
    group by u.uid
;

/*

mysql> describe field_data_field_visibility;
+------------------------+------------------+------+-----+---------+-------+
| Field                  | Type             | Null | Key | Default | Extra |
+------------------------+------------------+------+-----+---------+-------+
| entity_type            | varchar(128)     | NO   | PRI |         |       |
| bundle                 | varchar(128)     | NO   | MUL |         |       |
| deleted                | tinyint(4)       | NO   | PRI | 0       |       |
| entity_id              | int(10) unsigned | NO   | PRI | NULL    |       |
| revision_id            | int(10) unsigned | YES  | MUL | NULL    |       |
| language               | varchar(32)      | NO   | PRI |         |       |
| delta                  | int(10) unsigned | NO   | PRI | NULL    |       |
| field_visibility_value | int(11)          | YES  | MUL | NULL    |       |
+------------------------+------------------+------+-----+---------+-------+
8 rows in set (0.05 sec)

*/
