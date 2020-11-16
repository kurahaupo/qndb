/*
 *** Run the following shell code to create the DROP commands
 *
 * (This should not normally be needed, but is here in case it's ever necessary
 * to force the issue.)

echo 'select 'OLD VIEWS' as `DROPPING`;'

printf "select '%s' as `dropping`;"  '$summary'
echo 'drop view if exists `$summary`;'
mysql 2>/dev/null --db=quakers <<< "show tables like 'exp%';" |
 sed -e '/^Tables_in_/d;
         h;
         s#.*#select '\''&'\'' as `dropping`;#;
         p;
         g;
         /[^_[:alnum:]]/ s#.*#`&`#;
         /^expmap_/bm;
         s#.*#drop view if exists &;#;
         b;
         :m;
         s#.*#drop table if exists &;#;
         '
*/

select 'NEW VIEWS' as `CREATING `;

/*

/* unpivot the MM delivery-method table → one row per non-zero column */

select 'exp_unpivot_mm_del' as `creating`;

create or replace view exp_unpivot_mm_del as
      select uid,
             'email'            as method
        from user_subscription_preference
       where email
 union
      select uid,
             'print'            as method
        from user_subscription_preference
       where print;

/* unpivot the MM subscription table → one row per non-zero column */

/* Can't use "mid" for "meeting ID" because MID() is a MySQL string function.
 * Use xmid & xmtag, because they apply to both MM & YM
 */
select 'exp_unpivot_mm_subs' as `creating`;

create or replace view exp_unpivot_mm_subs as
     select uid,
            field_short_name_value as xmtag,
            channel
       from (
                   select uid,
                          nid                as xmid,
                          'newsletters'      as channel
                     from user_subscription_meeting
                    where newsletter
              union
                   select uid,
                          nid                as xmid,
                          'agenda'           as channel
                     from user_subscription_meeting
                    where agenda
              union
                   select uid,
                          nid                as xmid,
                          'minutes'          as channel
                     from user_subscription_meeting
                    where minutes
              union
                   select uid,
                          nid                as xmid,
                          'updates'          as channel
                     from user_subscription_meeting
                    where updates
            ) as s
  left join field_data_field_short_name as mmt on mmt.entity_id = xmid
                                              and not mmt.deleted;

/**** Same again for YM ****/

/* unpivot the YM subscription table → one row per non-zero column */

select 'exp_unpivot_ym_subs' as `creating`;

create or replace view exp_unpivot_ym_subs as
      select uid,
             'YM'               as xmtag,
             subscription_id    as channel,
             'email'            as method
        from user_subscription_national
       where email
 union
      select uid,
             'YM'               as xmtag,
             subscription_id    as channel,
             'print'            as method
        from user_subscription_national
       where print;

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

select 'exp_user_acc_needs' as `creating`;

create or replace view exp_user_acc_needs as
      select entity_id                          as acc_needs_uid,
             revision_id                        as acc_needs_rev,
             language                           as acc_needs_language,
             delta                              as acc_needs_delta,
             field_user_access_needs_value      as acc_needs,
             field_user_access_needs_format     as acc_needs_format
        from field_data_field_user_access_needs
       where entity_type = 'user'
         and bundle      = 'user'
         and not deleted;

/*********** ONE-TO-ONE adjunct components to user ***********/

/*

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

*/

select 'exp_user_birthdate' as `creating`;

create or replace view exp_user_birthdate as
      select entity_id                  as birthdate_uid,
             revision_id                as birthdate_rev,
             language                   as birthdate_language,
             delta                      as birthdate_delta,
             field_user_birthdate_value as birthdate
        from field_data_field_user_birthdate
       where entity_type = 'user'
         and bundle      = 'user'
         and not deleted
         and field_user_birthdate_value != 0;

/*

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

select 'exp_user_email' as `creating`;

create or replace view exp_user_email as
      select entity_id                  as visible_email_uid,
             revision_id                as visible_email_rev,
             language                   as visible_email_language,
             delta                      as visible_email_delta,
             field_user_fax_value       as visible_email,
             field_user_fax_format      as visible_email_format
        from field_data_field_user_fax
       where entity_type          = 'user'
         and bundle               = 'user'
         and not deleted
         and field_user_fax_value like '%@%';

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

select 'exp_user_joined_year' as `creating`;

create or replace view exp_user_joined_year as
      select entity_id                      as joined_year_uid,
             revision_id                    as joined_year_rev,
             language                       as joined_year_language,
             delta                          as joined_year_delta,
             field_user_joined_year_value   as joined_year
        from field_data_field_user_joined_year
       where entity_type = 'user'
         and bundle      = 'user'
         and not deleted;

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

select 'exp_user_med_needs' as `creating`;

create or replace view exp_user_med_needs as
      select entity_id                          as med_needs_uid,
             revision_id                        as med_needs_rev,
             language                           as med_needs_language,
             delta                              as med_needs_delta,
             field_user_medical_needs_value     as med_needs,
             field_user_medical_needs_format    as med_needs_format
        from field_data_field_user_medical_needs
       where entity_type = 'user'
         and bundle      = 'user'
         and not deleted;

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

select 'exp_user_gname' as `creating`;

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

select 'exp_user_pname' as `creating`;

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

select 'exp_user_sname' as `creating`;

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

select 'exp1_user_names' as `creating`;

create or replace view exp1_user_names as
      select uid                                                as names_uid,
             concat(ifnull(pref_name, given_name), ' ',surname) as full_name,
             pref_name,
             given_name,
             surname
        from users
   left join exp_user_pname on uid=pname_uid
   left join exp_user_gname on uid=gname_uid
   left join exp_user_sname on uid=sname_uid;

/* End Names */

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

select 'exp_user_mm_member' as `creating`;

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
         and not um.deleted;

/*

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

select 'exp_user_website' as `creating`;

create or replace view exp_user_website as
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
         and field_user_website_value != '';

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

*/

select 'exp_all_users' as `creating`;

create or replace view exp_all_users as
      select u.*,
             ifnull(o.field_user_old_id_value, u.uid + 4096)    as old_uid,
             u.status                                       = 0 as blocked,
             ifnull(r.field_user_resigned_value, false)         as resigned,
             ifnull(d.field_user_deceased_value, false)         as deceased,
             ifnull(i.field_user_inactive_value, false)         as inactive
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
       where u.name is not null
         and u.name != ''
    group by u.uid;

/* people who aren't dead */

select 'exp_active_users' as `creating`;

create or replace view exp_active_users as
      select *
        from exp_all_users
       where not blocked
         and not deceased;

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
             phy.entity_id is not null                      as address_use_as_physical,
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
             phy.entity_id is not null                      as address_use_as_physical,
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
             phy.entity_id is not null                      as address_use_as_physical,
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
             phy.entity_id is not null                      as address_use_as_physical,
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

select 'export_user_addresses2' as `creating`;

create or replace view export_user_addresses2 as
      select address_uid,
             address_vid,
             address_slot,
             address_language,
             concat(
                    ifnull( concat('FIRST_AND_LAST_NAMES:',     address_first_name, ' ',  address_last_name, '\n'),
                     ifnull( concat('FIRST_NAME:',              address_first_name, '\n'),
                      ifnull( concat('LAST_NAME:',              address_last_name, '\n'),
                       ''))),
                    ifnull(concat('NAME_LINE:',                 address_name_line, '\n'), ''),
                    ifnull(concat('ORGANISATION_NAME:',         address_organisation_name, '\n'), ''),
                    ifnull(concat('SUB_PREMISE:',               address_sub_premise, '\n'), ''),
                    ifnull(concat('PREMISE:',                   address_line_two, '\n'), ''),
                    ifnull(concat('THOROUGHFARE:',              address_thoroughfare, '\n'), ''),
                    ifnull(concat('DEPENDENT_LOCALITY:',        address_dependent_locality, '\n'), ''),
                    ifnull(concat('LOCALITY:',                  address_locality, '\n'), ''),
                    ifnull(concat('SUB_ADMINISTRATIVE_AREA:',   address_sub_administrative_area, '\n'), ''),
                    ifnull(concat('ADMINISTRATIVE_AREA:',       address_administrative_area, '\n'), ''),
                    ifnull(concat('POSTCODE:',                  address_postal_code, '\n'), ''),
                    ifnull(concat('CC:',                        address_country), 'NZ*')
                    ) as address,
             address_data,
             address_use_as_physical,
             address_use_as_postal
        from exp_normalise_user_addresses;


select 'export_user_addresses' as `creating`;

create or replace view export_user_addresses as
      select a.entity_id                                            as address_uid,
             ai.revision_id                                         as address_vid,
             ifnull(a.delta+1, 0)                                   as address_slot,
             ai.language                                            as address_language,
             ai.delta                                               as address_delta,
             ai.field_user_address_value                            as address,
             al.field_label_value                                   as address_label,
             ifnull(ap.field_use_as_postal_address_value, 0)   != 0 as address_postal,
             ifnull(ab.field_print_in_book_value, 0)           != 0 as address_in_book
        from field_data_field_addresses             as a
   left join field_data_field_label                 as al   on a.field_addresses_value=al.entity_id
                                                           and al.entity_type = 'field_collection_item'
                                                           and al.bundle      = 'field_addresses'
                                                           and not al.deleted
   left join field_data_field_user_address          as ai   on a.field_addresses_value=ai.entity_id
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

select 'export_user_kin' as `creating`;

create or replace view export_user_kin as
      select ukin.entity_id                             as kin_uid,
             ukin.revision_id                           as kin_rev,
             ukin.language                              as kin_language,
             ukin.delta                                 as kin_delta,
             ukint.field_user_kin_relationship_value    as kin_rel_type,
             ukinr.field_user_kin_user_ref_target_id    as kin_uid2
        from field_data_field_user_kin              as ukin
        join field_data_field_user_kin_user_ref     as ukinr    on ukinr.bundle         = 'field_user_kin'
                                                               and ukinr.entity_type    = 'field_collection_item'
                                                               and not ukinr.deleted
                                                               and ukinr.revision_id    = ukin.field_user_kin_revision_id
                                                               and ukinr.entity_id      = ukin.field_user_kin_value
        join field_data_field_user_kin_relationship as ukint    on ukint.entity_type    = 'field_collection_item'
                                                               and ukint.bundle         = 'field_user_kin'
                                                               and not ukint.deleted
                                                               and ukint.entity_id      = ukin.field_user_kin_value
                                                               and ukint.revision_id    = ukin.field_user_kin_revision_id
       where ukin.entity_type = 'user'
         and ukin.bundle      = 'user'
         and not ukin.deleted
 union
      select entity_id                      as kin_uid,
             revision_id                    as kin_rev,
             language                       as kin_language,
             delta                          as kin_delta,
             'spouse'                       as kin_rel_type,
             field_user_spouse_target_id    as kin_uid2
        from field_data_field_user_spouse
       where entity_type = 'user'
         and bundle      = 'user'
         and not deleted;

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

select 'export_user_notes' as `creating`;

create or replace view export_user_notes as
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

select 'export_user_phones' as `creating`;

create or replace view export_user_phones as
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

select 'export_user_wgroup' as `creating`;

create or replace view export_user_wgroup as
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
         and not w.deleted;

/* join the (unpivoted) MM subs & MM deliveries, and union with the YM subs */

select 'exp2_all_subs' as `creating`;

create or replace view exp2_all_subs as
      select s.uid,
             xmtag,
             method,
             channel,
             concat(xmtag, '_', channel) as sub_channel
        from exp_unpivot_mm_subs        as s
        join exp_unpivot_mm_del         as d    on d.uid = s.uid
 union
      select s.uid,
             'YM'                       as xmtag,
             method,
             channel,
             concat('YM_', channel)     as sub_channel
        from exp_unpivot_ym_subs        as s;

select 'expmap_xm_domain' as `re-creating`;

create or replace table expmap_xm_domain (
            xmtag       varchar(5) primary key,
            domain      varchar(255) not null);
insert into expmap_xm_domain (xmtag, domain) values
            ('YM',  'yearly-meeting.quakers.nz'),
            ('YF',  'young-friends.quakers.nz'),
            ('NT',  'northern.quakers.nz'),
            ('MNI', 'mid-north-island.quakers.nz'),
            ('PN',  'palmerston-north.quakers.nz'),
            ('TN',  'taranaki.quakers.nz'),
            ('WG',  'whanganui.quakers.nz'),
            ('KP',  'kapiti.quakers.nz'),
            ('WN',  'wellington.quakers.nz'),
            ('CH',  'christchurch.quakers.nz'),
            ('DN',  'otago.quakers.nz');

select 'expmap_email_sub' as `re-creating`;

create or replace table expmap_email_sub (
            xmtag       varchar(5) not null,
            channel     varchar(128) not null,
            primary key (xmtag, channel),
            key (xmtag),
            key (channel),
            list_email  varchar(255) not null);
insert into expmap_email_sub values
            /* newsletters            */
            /* agenda                 */
            /* minutes                */
            /* updates                */
            ('YM', 'anz_friends_newsletter', 'newsletter@yearly-meeting.quakers.nz'),
            ('YM', 'ym_documents',           'documents@yearly-meeting.quakers.nz'),
            ('YM', 'ym_clerks_letter',       'clerks-letter@yearly-meeting.quakers.nz');

select 'export_email_subs' as `creating`;

create or replace view export_email_subs as
      select lower(ifnull(m.list_email,
                          concat(s.channel,
                                 '@',
                                 ifnull(d.domain,
                                        concat(s.xmtag,
                                               '.quakers.nz'
                                              )
                                       )
                                )
                         )
                  )                         as list_email,
             u.mail                         as email,
             s.*
        from exp2_all_subs                  as s
   left join users                          as u    on u.uid = s.uid
   left join expmap_xm_domain               as d    on s.xmtag = d.xmtag
   left join expmap_email_sub               as m    on s.xmtag = m.xmtag
                                                   and s.channel = m.channel
         where s.method = 'email';

select 'export_print_subs' as `creating`;

create or replace view export_print_subs as
      select n.*,
             s.*,
             a.*
        from exp2_all_subs                  as s
   left join exp1_user_names                as n    on uid = names_uid
   left join exp_normalise_user_addresses   as a    on uid = address_uid
                                                   and address_use_as_postal
         where s.method = 'print';

/*********** EVERYTHING ***********/
/* Full export for merging with other databases */
/* All singleton data left-joined to the visible users */

select 'export_full_users' as `creating`;

create or replace view export_full_users as
      select u.*,
             exp_user_email.*,
             exp_user_website.*,
             exp_user_birthdate.*,
             exp1_user_names.*,
             exp_user_joined_year.*,
             exp_user_mm_member.*,
             exp_user_acc_needs.*,
             exp_user_med_needs.*
        from exp_all_users as u
   left join exp_user_email         on uid = visible_email_uid
   left join exp_user_website       on uid = website_uid
   left join exp_user_birthdate     on uid = birthdate_uid
   left join exp1_user_names        on uid = names_uid
   left join exp_user_joined_year   on uid = joined_year_uid
   left join exp_user_mm_member     on uid = mmm_uid
   left join exp_user_acc_needs     on uid = acc_needs_uid
   left join exp_user_med_needs     on uid = med_needs_uid
    group by u.uid;

select 'NEW TABLES' as `CREATING`;

select 'expmap_reverse_relations' as `Table`;

create or replace table expmap_reverse_relations (
    fwd_rel     varchar(32) primary key,
    rev_rel     varchar(32) unique key,
    symmetric   boolean,
    many_to     boolean,
    to_many     boolean
);
insert into expmap_reverse_relations ( fwd_rel, rev_rel, many_to, to_many )
     values ( 'child',      'parent',      true,  true  ),
            ( 'grandchild', 'grandparent', true,  true  ),
            ( 'spouse',     'spouse',      false, false ),
            ( 'ex-spouse',  'ex-spouse',   true,  true  );
update expmap_reverse_relations set symmetric = fwd_rel = rev_rel;
insert into expmap_reverse_relations
            ( fwd_rel, rev_rel, many_to, to_many, symmetric )
       select rev_rel, fwd_rel, to_many, many_to, symmetric
         from expmap_reverse_relations
        where not symmetric;

select '$summary' as `creating`;

/*
 *** Run the following shell code to create the $summary view

t='$summary'
echo "create or replace view \`$t\` as"
{
mysql 2>/dev/null quakers <<< 'show tables;' |
tee >( n=$( wc -l ) ; sleep 5 ; printf "       select %-50sas table_name, %8u as num_rows\n" "'$t'" "$n" >&3 ) |
 sed -e "/^Tables_in_/d;
         /${t//'$'}/d;
         s#.*# union select '&'\tas table_name, count(*) as num_rows from &#" |
  sort | expand -t 64
} 3>&1
echo ";"

*/

create or replace view `$summary` as
       select '$summary'                                        as table_name,      680 as num_rows
 union select 'actions'                                         as table_name, count(*) as num_rows from actions
 union select 'authmap'                                         as table_name, count(*) as num_rows from authmap
 union select 'batch'                                           as table_name, count(*) as num_rows from batch
 union select 'block'                                           as table_name, count(*) as num_rows from block
 union select 'block_custom'                                    as table_name, count(*) as num_rows from block_custom
 union select 'block_node_type'                                 as table_name, count(*) as num_rows from block_node_type
 union select 'block_role'                                      as table_name, count(*) as num_rows from block_role
 union select 'blocked_ips'                                     as table_name, count(*) as num_rows from blocked_ips
 union select 'breakpoint_group'                                as table_name, count(*) as num_rows from breakpoint_group
 union select 'breakpoints'                                     as table_name, count(*) as num_rows from breakpoints
 union select 'cache'                                           as table_name, count(*) as num_rows from cache
 union select 'cache_admin_menu'                                as table_name, count(*) as num_rows from cache_admin_menu
 union select 'cache_block'                                     as table_name, count(*) as num_rows from cache_block
 union select 'cache_bootstrap'                                 as table_name, count(*) as num_rows from cache_bootstrap
 union select 'cache_entity_og_membership'                      as table_name, count(*) as num_rows from cache_entity_og_membership
 union select 'cache_entity_og_membership_type'                 as table_name, count(*) as num_rows from cache_entity_og_membership_type
 union select 'cache_entity_registration'                       as table_name, count(*) as num_rows from cache_entity_registration
 union select 'cache_entity_registration_state'                 as table_name, count(*) as num_rows from cache_entity_registration_state
 union select 'cache_entity_registration_type'                  as table_name, count(*) as num_rows from cache_entity_registration_type
 union select 'cache_features'                                  as table_name, count(*) as num_rows from cache_features
 union select 'cache_field'                                     as table_name, count(*) as num_rows from cache_field
 union select 'cache_filter'                                    as table_name, count(*) as num_rows from cache_filter
 union select 'cache_form'                                      as table_name, count(*) as num_rows from cache_form
 union select 'cache_geocoder'                                  as table_name, count(*) as num_rows from cache_geocoder
 union select 'cache_image'                                     as table_name, count(*) as num_rows from cache_image
 union select 'cache_libraries'                                 as table_name, count(*) as num_rows from cache_libraries
 union select 'cache_menu'                                      as table_name, count(*) as num_rows from cache_menu
 union select 'cache_metatag'                                   as table_name, count(*) as num_rows from cache_metatag
 union select 'cache_page'                                      as table_name, count(*) as num_rows from cache_page
 union select 'cache_path'                                      as table_name, count(*) as num_rows from cache_path
 union select 'cache_rules'                                     as table_name, count(*) as num_rows from cache_rules
 union select 'cache_token'                                     as table_name, count(*) as num_rows from cache_token
 union select 'cache_update'                                    as table_name, count(*) as num_rows from cache_update
 union select 'cache_views'                                     as table_name, count(*) as num_rows from cache_views
 union select 'cache_views_data'                                as table_name, count(*) as num_rows from cache_views_data
 union select 'captcha_points'                                  as table_name, count(*) as num_rows from captcha_points
 union select 'captcha_sessions'                                as table_name, count(*) as num_rows from captcha_sessions
 union select 'cck_field_settings'                              as table_name, count(*) as num_rows from cck_field_settings
 union select 'comment'                                         as table_name, count(*) as num_rows from comment
 union select 'context'                                         as table_name, count(*) as num_rows from context
 union select 'ctools_css_cache'                                as table_name, count(*) as num_rows from ctools_css_cache
 union select 'ctools_object_cache'                             as table_name, count(*) as num_rows from ctools_object_cache
 union select 'date_format_locale'                              as table_name, count(*) as num_rows from date_format_locale
 union select 'date_format_type'                                as table_name, count(*) as num_rows from date_format_type
 union select 'date_formats'                                    as table_name, count(*) as num_rows from date_formats
 union select 'ds_field_settings'                               as table_name, count(*) as num_rows from ds_field_settings
 union select 'ds_fields'                                       as table_name, count(*) as num_rows from ds_fields
 union select 'ds_layout_settings'                              as table_name, count(*) as num_rows from ds_layout_settings
 union select 'ds_vd'                                           as table_name, count(*) as num_rows from ds_vd
 union select 'ds_view_modes'                                   as table_name, count(*) as num_rows from ds_view_modes
 union select 'entity_delete_log'                               as table_name, count(*) as num_rows from entity_delete_log
 union select 'entity_delete_log_og'                            as table_name, count(*) as num_rows from entity_delete_log_og
 union select 'entity_rule_setting'                             as table_name, count(*) as num_rows from entity_rule_setting
 union select 'entityform'                                      as table_name, count(*) as num_rows from entityform
 union select 'entityform_type'                                 as table_name, count(*) as num_rows from entityform_type
 union select 'event_colors'                                    as table_name, count(*) as num_rows from event_colors
 union select 'exp1_user_names'                                 as table_name, count(*) as num_rows from exp1_user_names
 union select 'exp2_all_subs'                                   as table_name, count(*) as num_rows from exp2_all_subs
 union select 'exp_active_users'                                as table_name, count(*) as num_rows from exp_active_users
 union select 'exp_all_users'                                   as table_name, count(*) as num_rows from exp_all_users
 union select 'exp_normalise_user_addresses'                    as table_name, count(*) as num_rows from exp_normalise_user_addresses
 union select 'exp_unpivot_mm_del'                              as table_name, count(*) as num_rows from exp_unpivot_mm_del
 union select 'exp_unpivot_mm_subs'                             as table_name, count(*) as num_rows from exp_unpivot_mm_subs
 union select 'exp_unpivot_ym_subs'                             as table_name, count(*) as num_rows from exp_unpivot_ym_subs
 union select 'exp_user_acc_needs'                              as table_name, count(*) as num_rows from exp_user_acc_needs
 union select 'exp_user_birthdate'                              as table_name, count(*) as num_rows from exp_user_birthdate
 union select 'exp_user_email'                                  as table_name, count(*) as num_rows from exp_user_email
 union select 'exp_user_gname'                                  as table_name, count(*) as num_rows from exp_user_gname
 union select 'exp_user_joined_year'                            as table_name, count(*) as num_rows from exp_user_joined_year
 union select 'exp_user_med_needs'                              as table_name, count(*) as num_rows from exp_user_med_needs
 union select 'exp_user_mm_member'                              as table_name, count(*) as num_rows from exp_user_mm_member
 union select 'exp_user_pname'                                  as table_name, count(*) as num_rows from exp_user_pname
 union select 'exp_user_sname'                                  as table_name, count(*) as num_rows from exp_user_sname
 union select 'exp_user_website'                                as table_name, count(*) as num_rows from exp_user_website
 union select 'expmap_email_sub'                                as table_name, count(*) as num_rows from expmap_email_sub
 union select 'expmap_reverse_relations'                        as table_name, count(*) as num_rows from expmap_reverse_relations
 union select 'expmap_xm_domain'                                as table_name, count(*) as num_rows from expmap_xm_domain
 union select 'export_email_subs'                               as table_name, count(*) as num_rows from export_email_subs
 union select 'export_full_users'                               as table_name, count(*) as num_rows from export_full_users
 union select 'export_print_subs'                               as table_name, count(*) as num_rows from export_print_subs
 union select 'export_user_addresses'                           as table_name, count(*) as num_rows from export_user_addresses
 union select 'export_user_addresses2'                          as table_name, count(*) as num_rows from export_user_addresses2
 union select 'export_user_kin'                                 as table_name, count(*) as num_rows from export_user_kin
 union select 'export_user_notes'                               as table_name, count(*) as num_rows from export_user_notes
 union select 'export_user_phones'                              as table_name, count(*) as num_rows from export_user_phones
 union select 'export_user_wgroup'                              as table_name, count(*) as num_rows from export_user_wgroup
 union select 'field_collection_item'                           as table_name, count(*) as num_rows from field_collection_item
 union select 'field_collection_item_revision'                  as table_name, count(*) as num_rows from field_collection_item_revision
 union select 'field_config'                                    as table_name, count(*) as num_rows from field_config
 union select 'field_config_instance'                           as table_name, count(*) as num_rows from field_config_instance
 union select 'field_data_body'                                 as table_name, count(*) as num_rows from field_data_body
 union select 'field_data_comment_body'                         as table_name, count(*) as num_rows from field_data_comment_body
 union select 'field_data_event_calendar_date'                  as table_name, count(*) as num_rows from field_data_event_calendar_date
 union select 'field_data_event_calendar_status'                as table_name, count(*) as num_rows from field_data_event_calendar_status
 union select 'field_data_field_address'                        as table_name, count(*) as num_rows from field_data_field_address
 union select 'field_data_field_address_geo'                    as table_name, count(*) as num_rows from field_data_field_address_geo
 union select 'field_data_field_address_visibility'             as table_name, count(*) as num_rows from field_data_field_address_visibility
 union select 'field_data_field_addresses'                      as table_name, count(*) as num_rows from field_data_field_addresses
 union select 'field_data_field_allergies'                      as table_name, count(*) as num_rows from field_data_field_allergies
 union select 'field_data_field_appointment_vacancy'            as table_name, count(*) as num_rows from field_data_field_appointment_vacancy
 union select 'field_data_field_appt_date'                      as table_name, count(*) as num_rows from field_data_field_appt_date
 union select 'field_data_field_appt_desc'                      as table_name, count(*) as num_rows from field_data_field_appt_desc
 union select 'field_data_field_appt_end_desc'                  as table_name, count(*) as num_rows from field_data_field_appt_end_desc
 union select 'field_data_field_appt_minute'                    as table_name, count(*) as num_rows from field_data_field_appt_minute
 union select 'field_data_field_appt_position'                  as table_name, count(*) as num_rows from field_data_field_appt_position
 union select 'field_data_field_appt_start_desc'                as table_name, count(*) as num_rows from field_data_field_appt_start_desc
 union select 'field_data_field_appt_term_no'                   as table_name, count(*) as num_rows from field_data_field_appt_term_no
 union select 'field_data_field_appt_user'                      as table_name, count(*) as num_rows from field_data_field_appt_user
 union select 'field_data_field_appt_web_role'                  as table_name, count(*) as num_rows from field_data_field_appt_web_role
 union select 'field_data_field_arrival_date'                   as table_name, count(*) as num_rows from field_data_field_arrival_date
 union select 'field_data_field_associated_members'             as table_name, count(*) as num_rows from field_data_field_associated_members
 union select 'field_data_field_author'                         as table_name, count(*) as num_rows from field_data_field_author
 union select 'field_data_field_birthday_visibility'            as table_name, count(*) as num_rows from field_data_field_birthday_visibility
 union select 'field_data_field_board_category'                 as table_name, count(*) as num_rows from field_data_field_board_category
 union select 'field_data_field_board_file'                     as table_name, count(*) as num_rows from field_data_field_board_file
 union select 'field_data_field_book_categories'                as table_name, count(*) as num_rows from field_data_field_book_categories
 union select 'field_data_field_book_category'                  as table_name, count(*) as num_rows from field_data_field_book_category
 union select 'field_data_field_book_cover'                     as table_name, count(*) as num_rows from field_data_field_book_cover
 union select 'field_data_field_book_isbn'                      as table_name, count(*) as num_rows from field_data_field_book_isbn
 union select 'field_data_field_book_period'                    as table_name, count(*) as num_rows from field_data_field_book_period
 union select 'field_data_field_buyer_email'                    as table_name, count(*) as num_rows from field_data_field_buyer_email
 union select 'field_data_field_buyer_name'                     as table_name, count(*) as num_rows from field_data_field_buyer_name
 union select 'field_data_field_buyer_payment_method'           as table_name, count(*) as num_rows from field_data_field_buyer_payment_method
 union select 'field_data_field_buyer_phone'                    as table_name, count(*) as num_rows from field_data_field_buyer_phone
 union select 'field_data_field_contact_details'                as table_name, count(*) as num_rows from field_data_field_contact_details
 union select 'field_data_field_contact_email'                  as table_name, count(*) as num_rows from field_data_field_contact_email
 union select 'field_data_field_contact_info'                   as table_name, count(*) as num_rows from field_data_field_contact_info
 union select 'field_data_field_contact_person'                 as table_name, count(*) as num_rows from field_data_field_contact_person
 union select 'field_data_field_content_editor'                 as table_name, count(*) as num_rows from field_data_field_content_editor
 union select 'field_data_field_content_editor_og'              as table_name, count(*) as num_rows from field_data_field_content_editor_og
 union select 'field_data_field_copies_qty'                     as table_name, count(*) as num_rows from field_data_field_copies_qty
 union select 'field_data_field_date_first_formal_mem'          as table_name, count(*) as num_rows from field_data_field_date_first_formal_mem
 union select 'field_data_field_dietary_group'                  as table_name, count(*) as num_rows from field_data_field_dietary_group
 union select 'field_data_field_document'                       as table_name, count(*) as num_rows from field_data_field_document
 union select 'field_data_field_email'                          as table_name, count(*) as num_rows from field_data_field_email
 union select 'field_data_field_event_accommodation'            as table_name, count(*) as num_rows from field_data_field_event_accommodation
 union select 'field_data_field_event_accommodation_cost'       as table_name, count(*) as num_rows from field_data_field_event_accommodation_cost
 union select 'field_data_field_event_accommodation_hdr'        as table_name, count(*) as num_rows from field_data_field_event_accommodation_hdr
 union select 'field_data_field_event_accommodation_name'       as table_name, count(*) as num_rows from field_data_field_event_accommodation_name
 union select 'field_data_field_event_extra_fee'                as table_name, count(*) as num_rows from field_data_field_event_extra_fee
 union select 'field_data_field_event_extra_fee_cost'           as table_name, count(*) as num_rows from field_data_field_event_extra_fee_cost
 union select 'field_data_field_event_extra_fee_hdr'            as table_name, count(*) as num_rows from field_data_field_event_extra_fee_hdr
 union select 'field_data_field_event_extra_fee_name'           as table_name, count(*) as num_rows from field_data_field_event_extra_fee_name
 union select 'field_data_field_event_meal'                     as table_name, count(*) as num_rows from field_data_field_event_meal
 union select 'field_data_field_event_meal_cost'                as table_name, count(*) as num_rows from field_data_field_event_meal_cost
 union select 'field_data_field_event_meal_hdr'                 as table_name, count(*) as num_rows from field_data_field_event_meal_hdr
 union select 'field_data_field_event_meal_name'                as table_name, count(*) as num_rows from field_data_field_event_meal_name
 union select 'field_data_field_event_register_fee'             as table_name, count(*) as num_rows from field_data_field_event_register_fee
 union select 'field_data_field_event_register_fee_cost'        as table_name, count(*) as num_rows from field_data_field_event_register_fee_cost
 union select 'field_data_field_event_register_fee_hdr'         as table_name, count(*) as num_rows from field_data_field_event_register_fee_hdr
 union select 'field_data_field_event_register_fee_name'        as table_name, count(*) as num_rows from field_data_field_event_register_fee_name
 union select 'field_data_field_event_type'                     as table_name, count(*) as num_rows from field_data_field_event_type
 union select 'field_data_field_event_venue'                    as table_name, count(*) as num_rows from field_data_field_event_venue
 union select 'field_data_field_event_venue_geo'                as table_name, count(*) as num_rows from field_data_field_event_venue_geo
 union select 'field_data_field_fc_membership_transfer'         as table_name, count(*) as num_rows from field_data_field_fc_membership_transfer
 union select 'field_data_field_file_image_alt_text'            as table_name, count(*) as num_rows from field_data_field_file_image_alt_text
 union select 'field_data_field_file_image_title_text'          as table_name, count(*) as num_rows from field_data_field_file_image_title_text
 union select 'field_data_field_first_formal_mem_location'      as table_name, count(*) as num_rows from field_data_field_first_formal_mem_location
 union select 'field_data_field_first_name'                     as table_name, count(*) as num_rows from field_data_field_first_name
 union select 'field_data_field_heading'                        as table_name, count(*) as num_rows from field_data_field_heading
 union select 'field_data_field_image'                          as table_name, count(*) as num_rows from field_data_field_image
 union select 'field_data_field_image_gallery'                  as table_name, count(*) as num_rows from field_data_field_image_gallery
 union select 'field_data_field_is_private_content'             as table_name, count(*) as num_rows from field_data_field_is_private_content
 union select 'field_data_field_label'                          as table_name, count(*) as num_rows from field_data_field_label
 union select 'field_data_field_last_name'                      as table_name, count(*) as num_rows from field_data_field_last_name
 union select 'field_data_field_link'                           as table_name, count(*) as num_rows from field_data_field_link
 union select 'field_data_field_links'                          as table_name, count(*) as num_rows from field_data_field_links
 union select 'field_data_field_location_image'                 as table_name, count(*) as num_rows from field_data_field_location_image
 union select 'field_data_field_meeting_attendees'              as table_name, count(*) as num_rows from field_data_field_meeting_attendees
 union select 'field_data_field_meeting_board'                  as table_name, count(*) as num_rows from field_data_field_meeting_board
 union select 'field_data_field_meeting_board_extra'            as table_name, count(*) as num_rows from field_data_field_meeting_board_extra
 union select 'field_data_field_meeting_clerks'                 as table_name, count(*) as num_rows from field_data_field_meeting_clerks
 union select 'field_data_field_meeting_code'                   as table_name, count(*) as num_rows from field_data_field_meeting_code
 union select 'field_data_field_meeting_date'                   as table_name, count(*) as num_rows from field_data_field_meeting_date
 union select 'field_data_field_meeting_end_statement'          as table_name, count(*) as num_rows from field_data_field_meeting_end_statement
 union select 'field_data_field_meeting_guests'                 as table_name, count(*) as num_rows from field_data_field_meeting_guests
 union select 'field_data_field_meeting_minutes'                as table_name, count(*) as num_rows from field_data_field_meeting_minutes
 union select 'field_data_field_meeting_occasion'               as table_name, count(*) as num_rows from field_data_field_meeting_occasion
 union select 'field_data_field_meeting_status'                 as table_name, count(*) as num_rows from field_data_field_meeting_status
 union select 'field_data_field_meeting_type'                   as table_name, count(*) as num_rows from field_data_field_meeting_type
 union select 'field_data_field_meeting_venue'                  as table_name, count(*) as num_rows from field_data_field_meeting_venue
 union select 'field_data_field_meeting_year'                   as table_name, count(*) as num_rows from field_data_field_meeting_year
 union select 'field_data_field_member_status'                  as table_name, count(*) as num_rows from field_data_field_member_status
 union select 'field_data_field_membership_held_overseas'       as table_name, count(*) as num_rows from field_data_field_membership_held_overseas
 union select 'field_data_field_membership_transfer_date'       as table_name, count(*) as num_rows from field_data_field_membership_transfer_date
 union select 'field_data_field_minutes_appt_active_date'       as table_name, count(*) as num_rows from field_data_field_minutes_appt_active_date
 union select 'field_data_field_minutes_appt_date'              as table_name, count(*) as num_rows from field_data_field_minutes_appt_date
 union select 'field_data_field_minutes_appt_deactive_date'     as table_name, count(*) as num_rows from field_data_field_minutes_appt_deactive_date
 union select 'field_data_field_minutes_appt_end_desc'          as table_name, count(*) as num_rows from field_data_field_minutes_appt_end_desc
 union select 'field_data_field_minutes_appt_start_desc'        as table_name, count(*) as num_rows from field_data_field_minutes_appt_start_desc
 union select 'field_data_field_minutes_appt_term_no'           as table_name, count(*) as num_rows from field_data_field_minutes_appt_term_no
 union select 'field_data_field_minutes_appt_web_role'          as table_name, count(*) as num_rows from field_data_field_minutes_appt_web_role
 union select 'field_data_field_minutes_attachment'             as table_name, count(*) as num_rows from field_data_field_minutes_attachment
 union select 'field_data_field_minutes_date'                   as table_name, count(*) as num_rows from field_data_field_minutes_date
 union select 'field_data_field_minutes_from_group'             as table_name, count(*) as num_rows from field_data_field_minutes_from_group
 union select 'field_data_field_minutes_number'                 as table_name, count(*) as num_rows from field_data_field_minutes_number
 union select 'field_data_field_minutes_position'               as table_name, count(*) as num_rows from field_data_field_minutes_position
 union select 'field_data_field_minutes_related'                as table_name, count(*) as num_rows from field_data_field_minutes_related
 union select 'field_data_field_minutes_source'                 as table_name, count(*) as num_rows from field_data_field_minutes_source
 union select 'field_data_field_minutes_status'                 as table_name, count(*) as num_rows from field_data_field_minutes_status
 union select 'field_data_field_minutes_title'                  as table_name, count(*) as num_rows from field_data_field_minutes_title
 union select 'field_data_field_minutes_to_group'               as table_name, count(*) as num_rows from field_data_field_minutes_to_group
 union select 'field_data_field_minutes_type'                   as table_name, count(*) as num_rows from field_data_field_minutes_type
 union select 'field_data_field_minutes_users'                  as table_name, count(*) as num_rows from field_data_field_minutes_users
 union select 'field_data_field_minutes_users_agreed'           as table_name, count(*) as num_rows from field_data_field_minutes_users_agreed
 union select 'field_data_field_minutes_users_disagreed'        as table_name, count(*) as num_rows from field_data_field_minutes_users_disagreed
 union select 'field_data_field_minutes_users_neutral'          as table_name, count(*) as num_rows from field_data_field_minutes_users_neutral
 union select 'field_data_field_minutes_venue'                  as table_name, count(*) as num_rows from field_data_field_minutes_venue
 union select 'field_data_field_ms_transfer_from'               as table_name, count(*) as num_rows from field_data_field_ms_transfer_from
 union select 'field_data_field_ms_transfer_meeting_minute'     as table_name, count(*) as num_rows from field_data_field_ms_transfer_meeting_minute
 union select 'field_data_field_ms_transfer_to'                 as table_name, count(*) as num_rows from field_data_field_ms_transfer_to
 union select 'field_data_field_nomcom_appt'                    as table_name, count(*) as num_rows from field_data_field_nomcom_appt
 union select 'field_data_field_nomcom_appt_date'               as table_name, count(*) as num_rows from field_data_field_nomcom_appt_date
 union select 'field_data_field_nomcom_appt_end_desc'           as table_name, count(*) as num_rows from field_data_field_nomcom_appt_end_desc
 union select 'field_data_field_nomcom_appt_group'              as table_name, count(*) as num_rows from field_data_field_nomcom_appt_group
 union select 'field_data_field_nomcom_appt_position'           as table_name, count(*) as num_rows from field_data_field_nomcom_appt_position
 union select 'field_data_field_nomcom_appt_start_desc'         as table_name, count(*) as num_rows from field_data_field_nomcom_appt_start_desc
 union select 'field_data_field_nomcom_appt_users'              as table_name, count(*) as num_rows from field_data_field_nomcom_appt_users
 union select 'field_data_field_nomcom_meeting_minutes'         as table_name, count(*) as num_rows from field_data_field_nomcom_meeting_minutes
 union select 'field_data_field_nomcom_meeting_occasion'        as table_name, count(*) as num_rows from field_data_field_nomcom_meeting_occasion
 union select 'field_data_field_nomcom_minutes_related'         as table_name, count(*) as num_rows from field_data_field_nomcom_minutes_related
 union select 'field_data_field_nomcom_resign'                  as table_name, count(*) as num_rows from field_data_field_nomcom_resign
 union select 'field_data_field_nomcom_resign_date'             as table_name, count(*) as num_rows from field_data_field_nomcom_resign_date
 union select 'field_data_field_nomcom_resign_group'            as table_name, count(*) as num_rows from field_data_field_nomcom_resign_group
 union select 'field_data_field_nomcom_resign_users'            as table_name, count(*) as num_rows from field_data_field_nomcom_resign_users
 union select 'field_data_field_offline_formal_membership'      as table_name, count(*) as num_rows from field_data_field_offline_formal_membership
 union select 'field_data_field_og_membership_activation'       as table_name, count(*) as num_rows from field_data_field_og_membership_activation
 union select 'field_data_field_og_membership_date'             as table_name, count(*) as num_rows from field_data_field_og_membership_date
 union select 'field_data_field_og_membership_deactivation'     as table_name, count(*) as num_rows from field_data_field_og_membership_deactivation
 union select 'field_data_field_og_membership_end_desc'         as table_name, count(*) as num_rows from field_data_field_og_membership_end_desc
 union select 'field_data_field_og_membership_minute'           as table_name, count(*) as num_rows from field_data_field_og_membership_minute
 union select 'field_data_field_og_membership_orig_start'       as table_name, count(*) as num_rows from field_data_field_og_membership_orig_start
 union select 'field_data_field_og_membership_position'         as table_name, count(*) as num_rows from field_data_field_og_membership_position
 union select 'field_data_field_og_membership_start_desc'       as table_name, count(*) as num_rows from field_data_field_og_membership_start_desc
 union select 'field_data_field_og_membership_term_no'          as table_name, count(*) as num_rows from field_data_field_og_membership_term_no
 union select 'field_data_field_og_membership_users_group'      as table_name, count(*) as num_rows from field_data_field_og_membership_users_group
 union select 'field_data_field_og_membership_web_role'         as table_name, count(*) as num_rows from field_data_field_og_membership_web_role
 union select 'field_data_field_other_allergies'                as table_name, count(*) as num_rows from field_data_field_other_allergies
 union select 'field_data_field_other_meal_preference'          as table_name, count(*) as num_rows from field_data_field_other_meal_preference
 union select 'field_data_field_other_query_or_request'         as table_name, count(*) as num_rows from field_data_field_other_query_or_request
 union select 'field_data_field_paid_event'                     as table_name, count(*) as num_rows from field_data_field_paid_event
 union select 'field_data_field_phone'                          as table_name, count(*) as num_rows from field_data_field_phone
 union select 'field_data_field_postal_address'                 as table_name, count(*) as num_rows from field_data_field_postal_address
 union select 'field_data_field_preformatted_address'           as table_name, count(*) as num_rows from field_data_field_preformatted_address
 union select 'field_data_field_price'                          as table_name, count(*) as num_rows from field_data_field_price
 union select 'field_data_field_print_in_book'                  as table_name, count(*) as num_rows from field_data_field_print_in_book
 union select 'field_data_field_publish_date'                   as table_name, count(*) as num_rows from field_data_field_publish_date
 union select 'field_data_field_publisher'                      as table_name, count(*) as num_rows from field_data_field_publisher
 union select 'field_data_field_ref_book'                       as table_name, count(*) as num_rows from field_data_field_ref_book
 union select 'field_data_field_ref_meeting_minute_ffm'         as table_name, count(*) as num_rows from field_data_field_ref_meeting_minute_ffm
 union select 'field_data_field_registration_type'              as table_name, count(*) as num_rows from field_data_field_registration_type
 union select 'field_data_field_report_file'                    as table_name, count(*) as num_rows from field_data_field_report_file
 union select 'field_data_field_resource_file'                  as table_name, count(*) as num_rows from field_data_field_resource_file
 union select 'field_data_field_sale_book'                      as table_name, count(*) as num_rows from field_data_field_sale_book
 union select 'field_data_field_short_name'                     as table_name, count(*) as num_rows from field_data_field_short_name
 union select 'field_data_field_shown_to_young_friends'         as table_name, count(*) as num_rows from field_data_field_shown_to_young_friends
 union select 'field_data_field_tags'                           as table_name, count(*) as num_rows from field_data_field_tags
 union select 'field_data_field_use_as_postal_address'          as table_name, count(*) as num_rows from field_data_field_use_as_postal_address
 union select 'field_data_field_user_access_needs'              as table_name, count(*) as num_rows from field_data_field_user_access_needs
 union select 'field_data_field_user_address_1'                 as table_name, count(*) as num_rows from field_data_field_user_address_1
 union select 'field_data_field_user_address_2'                 as table_name, count(*) as num_rows from field_data_field_user_address_2
 union select 'field_data_field_user_address_3'                 as table_name, count(*) as num_rows from field_data_field_user_address_3
 union select 'field_data_field_user_address_4'                 as table_name, count(*) as num_rows from field_data_field_user_address_4
 union select 'field_data_field_user_birthdate'                 as table_name, count(*) as num_rows from field_data_field_user_birthdate
 union select 'field_data_field_user_deceased'                  as table_name, count(*) as num_rows from field_data_field_user_deceased
 union select 'field_data_field_user_documents'                 as table_name, count(*) as num_rows from field_data_field_user_documents
 union select 'field_data_field_user_fax'                       as table_name, count(*) as num_rows from field_data_field_user_fax
 union select 'field_data_field_user_first_name'                as table_name, count(*) as num_rows from field_data_field_user_first_name
 union select 'field_data_field_user_inactive'                  as table_name, count(*) as num_rows from field_data_field_user_inactive
 union select 'field_data_field_user_joined_year'               as table_name, count(*) as num_rows from field_data_field_user_joined_year
 union select 'field_data_field_user_kin'                       as table_name, count(*) as num_rows from field_data_field_user_kin
 union select 'field_data_field_user_kin_field_info'            as table_name, count(*) as num_rows from field_data_field_user_kin_field_info
 union select 'field_data_field_user_kin_relationship'          as table_name, count(*) as num_rows from field_data_field_user_kin_relationship
 union select 'field_data_field_user_kin_user_ref'              as table_name, count(*) as num_rows from field_data_field_user_kin_user_ref
 union select 'field_data_field_user_last_name'                 as table_name, count(*) as num_rows from field_data_field_user_last_name
 union select 'field_data_field_user_main_og'                   as table_name, count(*) as num_rows from field_data_field_user_main_og
 union select 'field_data_field_user_medical_needs'             as table_name, count(*) as num_rows from field_data_field_user_medical_needs
 union select 'field_data_field_user_mobile'                    as table_name, count(*) as num_rows from field_data_field_user_mobile
 union select 'field_data_field_user_notes'                     as table_name, count(*) as num_rows from field_data_field_user_notes
 union select 'field_data_field_user_notes_date'                as table_name, count(*) as num_rows from field_data_field_user_notes_date
 union select 'field_data_field_user_notes_text'                as table_name, count(*) as num_rows from field_data_field_user_notes_text
 union select 'field_data_field_user_old_id'                    as table_name, count(*) as num_rows from field_data_field_user_old_id
 union select 'field_data_field_user_phone'                     as table_name, count(*) as num_rows from field_data_field_user_phone
 union select 'field_data_field_user_physical_address'          as table_name, count(*) as num_rows from field_data_field_user_physical_address
 union select 'field_data_field_user_postal_address'            as table_name, count(*) as num_rows from field_data_field_user_postal_address
 union select 'field_data_field_user_preferred_name'            as table_name, count(*) as num_rows from field_data_field_user_preferred_name
 union select 'field_data_field_user_resigned'                  as table_name, count(*) as num_rows from field_data_field_user_resigned
 union select 'field_data_field_user_spouse'                    as table_name, count(*) as num_rows from field_data_field_user_spouse
 union select 'field_data_field_user_website'                   as table_name, count(*) as num_rows from field_data_field_user_website
 union select 'field_data_field_user_worship_group'             as table_name, count(*) as num_rows from field_data_field_user_worship_group
 union select 'field_data_field_venue_info'                     as table_name, count(*) as num_rows from field_data_field_venue_info
 union select 'field_data_field_venue_website'                  as table_name, count(*) as num_rows from field_data_field_venue_website
 union select 'field_data_field_video'                          as table_name, count(*) as num_rows from field_data_field_video
 union select 'field_data_field_visibility'                     as table_name, count(*) as num_rows from field_data_field_visibility
 union select 'field_data_field_west_meeting_minutes'           as table_name, count(*) as num_rows from field_data_field_west_meeting_minutes
 union select 'field_data_field_west_meeting_occasion'          as table_name, count(*) as num_rows from field_data_field_west_meeting_occasion
 union select 'field_data_field_west_minutes_related'           as table_name, count(*) as num_rows from field_data_field_west_minutes_related
 union select 'field_data_field_worship_group_location'         as table_name, count(*) as num_rows from field_data_field_worship_group_location
 union select 'field_data_field_ym_appendix'                    as table_name, count(*) as num_rows from field_data_field_ym_appendix
 union select 'field_data_field_ym_appendix_body'               as table_name, count(*) as num_rows from field_data_field_ym_appendix_body
 union select 'field_data_field_ym_appendix_title'              as table_name, count(*) as num_rows from field_data_field_ym_appendix_title
 union select 'field_data_field_ym_epistle'                     as table_name, count(*) as num_rows from field_data_field_ym_epistle
 union select 'field_data_field_ym_epistle_body'                as table_name, count(*) as num_rows from field_data_field_ym_epistle_body
 union select 'field_data_field_ym_epistle_title'               as table_name, count(*) as num_rows from field_data_field_ym_epistle_title
 union select 'field_data_field_ym_meeting_minutes'             as table_name, count(*) as num_rows from field_data_field_ym_meeting_minutes
 union select 'field_data_field_ym_meeting_occasion'            as table_name, count(*) as num_rows from field_data_field_ym_meeting_occasion
 union select 'field_data_field_ym_minutes_related'             as table_name, count(*) as num_rows from field_data_field_ym_minutes_related
 union select 'field_data_group_access'                         as table_name, count(*) as num_rows from field_data_group_access
 union select 'field_data_group_content_access'                 as table_name, count(*) as num_rows from field_data_group_content_access
 union select 'field_data_group_group'                          as table_name, count(*) as num_rows from field_data_group_group
 union select 'field_data_gsl_addressfield'                     as table_name, count(*) as num_rows from field_data_gsl_addressfield
 union select 'field_data_gsl_feature_filter_list'              as table_name, count(*) as num_rows from field_data_gsl_feature_filter_list
 union select 'field_data_gsl_geofield'                         as table_name, count(*) as num_rows from field_data_gsl_geofield
 union select 'field_data_gsl_props_misc'                       as table_name, count(*) as num_rows from field_data_gsl_props_misc
 union select 'field_data_gsl_props_phone'                      as table_name, count(*) as num_rows from field_data_gsl_props_phone
 union select 'field_data_gsl_props_web'                        as table_name, count(*) as num_rows from field_data_gsl_props_web
 union select 'field_data_og_group_ref'                         as table_name, count(*) as num_rows from field_data_og_group_ref
 union select 'field_data_og_membership_request'                as table_name, count(*) as num_rows from field_data_og_membership_request
 union select 'field_data_og_user_node'                         as table_name, count(*) as num_rows from field_data_og_user_node
 union select 'field_data_taxonomy_forums'                      as table_name, count(*) as num_rows from field_data_taxonomy_forums
 union select 'field_group'                                     as table_name, count(*) as num_rows from field_group
 union select 'field_revision_body'                             as table_name, count(*) as num_rows from field_revision_body
 union select 'field_revision_comment_body'                     as table_name, count(*) as num_rows from field_revision_comment_body
 union select 'field_revision_event_calendar_date'              as table_name, count(*) as num_rows from field_revision_event_calendar_date
 union select 'field_revision_event_calendar_status'            as table_name, count(*) as num_rows from field_revision_event_calendar_status
 union select 'field_revision_field_address'                    as table_name, count(*) as num_rows from field_revision_field_address
 union select 'field_revision_field_address_geo'                as table_name, count(*) as num_rows from field_revision_field_address_geo
 union select 'field_revision_field_address_visibility'         as table_name, count(*) as num_rows from field_revision_field_address_visibility
 union select 'field_revision_field_addresses'                  as table_name, count(*) as num_rows from field_revision_field_addresses
 union select 'field_revision_field_allergies'                  as table_name, count(*) as num_rows from field_revision_field_allergies
 union select 'field_revision_field_appointment_vacancy'        as table_name, count(*) as num_rows from field_revision_field_appointment_vacancy
 union select 'field_revision_field_appt_date'                  as table_name, count(*) as num_rows from field_revision_field_appt_date
 union select 'field_revision_field_appt_desc'                  as table_name, count(*) as num_rows from field_revision_field_appt_desc
 union select 'field_revision_field_appt_end_desc'              as table_name, count(*) as num_rows from field_revision_field_appt_end_desc
 union select 'field_revision_field_appt_minute'                as table_name, count(*) as num_rows from field_revision_field_appt_minute
 union select 'field_revision_field_appt_position'              as table_name, count(*) as num_rows from field_revision_field_appt_position
 union select 'field_revision_field_appt_start_desc'            as table_name, count(*) as num_rows from field_revision_field_appt_start_desc
 union select 'field_revision_field_appt_term_no'               as table_name, count(*) as num_rows from field_revision_field_appt_term_no
 union select 'field_revision_field_appt_user'                  as table_name, count(*) as num_rows from field_revision_field_appt_user
 union select 'field_revision_field_appt_web_role'              as table_name, count(*) as num_rows from field_revision_field_appt_web_role
 union select 'field_revision_field_arrival_date'               as table_name, count(*) as num_rows from field_revision_field_arrival_date
 union select 'field_revision_field_associated_members'         as table_name, count(*) as num_rows from field_revision_field_associated_members
 union select 'field_revision_field_author'                     as table_name, count(*) as num_rows from field_revision_field_author
 union select 'field_revision_field_birthday_visibility'        as table_name, count(*) as num_rows from field_revision_field_birthday_visibility
 union select 'field_revision_field_board_category'             as table_name, count(*) as num_rows from field_revision_field_board_category
 union select 'field_revision_field_board_file'                 as table_name, count(*) as num_rows from field_revision_field_board_file
 union select 'field_revision_field_book_categories'            as table_name, count(*) as num_rows from field_revision_field_book_categories
 union select 'field_revision_field_book_category'              as table_name, count(*) as num_rows from field_revision_field_book_category
 union select 'field_revision_field_book_cover'                 as table_name, count(*) as num_rows from field_revision_field_book_cover
 union select 'field_revision_field_book_isbn'                  as table_name, count(*) as num_rows from field_revision_field_book_isbn
 union select 'field_revision_field_book_period'                as table_name, count(*) as num_rows from field_revision_field_book_period
 union select 'field_revision_field_buyer_email'                as table_name, count(*) as num_rows from field_revision_field_buyer_email
 union select 'field_revision_field_buyer_name'                 as table_name, count(*) as num_rows from field_revision_field_buyer_name
 union select 'field_revision_field_buyer_payment_method'       as table_name, count(*) as num_rows from field_revision_field_buyer_payment_method
 union select 'field_revision_field_buyer_phone'                as table_name, count(*) as num_rows from field_revision_field_buyer_phone
 union select 'field_revision_field_contact_details'            as table_name, count(*) as num_rows from field_revision_field_contact_details
 union select 'field_revision_field_contact_email'              as table_name, count(*) as num_rows from field_revision_field_contact_email
 union select 'field_revision_field_contact_info'               as table_name, count(*) as num_rows from field_revision_field_contact_info
 union select 'field_revision_field_contact_person'             as table_name, count(*) as num_rows from field_revision_field_contact_person
 union select 'field_revision_field_content_editor'             as table_name, count(*) as num_rows from field_revision_field_content_editor
 union select 'field_revision_field_content_editor_og'          as table_name, count(*) as num_rows from field_revision_field_content_editor_og
 union select 'field_revision_field_copies_qty'                 as table_name, count(*) as num_rows from field_revision_field_copies_qty
 union select 'field_revision_field_date_first_formal_mem'      as table_name, count(*) as num_rows from field_revision_field_date_first_formal_mem
 union select 'field_revision_field_dietary_group'              as table_name, count(*) as num_rows from field_revision_field_dietary_group
 union select 'field_revision_field_document'                   as table_name, count(*) as num_rows from field_revision_field_document
 union select 'field_revision_field_email'                      as table_name, count(*) as num_rows from field_revision_field_email
 union select 'field_revision_field_event_accommodation'        as table_name, count(*) as num_rows from field_revision_field_event_accommodation
 union select 'field_revision_field_event_accommodation_cost'   as table_name, count(*) as num_rows from field_revision_field_event_accommodation_cost
 union select 'field_revision_field_event_accommodation_hdr'    as table_name, count(*) as num_rows from field_revision_field_event_accommodation_hdr
 union select 'field_revision_field_event_accommodation_name'   as table_name, count(*) as num_rows from field_revision_field_event_accommodation_name
 union select 'field_revision_field_event_extra_fee'            as table_name, count(*) as num_rows from field_revision_field_event_extra_fee
 union select 'field_revision_field_event_extra_fee_cost'       as table_name, count(*) as num_rows from field_revision_field_event_extra_fee_cost
 union select 'field_revision_field_event_extra_fee_hdr'        as table_name, count(*) as num_rows from field_revision_field_event_extra_fee_hdr
 union select 'field_revision_field_event_extra_fee_name'       as table_name, count(*) as num_rows from field_revision_field_event_extra_fee_name
 union select 'field_revision_field_event_meal'                 as table_name, count(*) as num_rows from field_revision_field_event_meal
 union select 'field_revision_field_event_meal_cost'            as table_name, count(*) as num_rows from field_revision_field_event_meal_cost
 union select 'field_revision_field_event_meal_hdr'             as table_name, count(*) as num_rows from field_revision_field_event_meal_hdr
 union select 'field_revision_field_event_meal_name'            as table_name, count(*) as num_rows from field_revision_field_event_meal_name
 union select 'field_revision_field_event_register_fee'         as table_name, count(*) as num_rows from field_revision_field_event_register_fee
 union select 'field_revision_field_event_register_fee_cost'    as table_name, count(*) as num_rows from field_revision_field_event_register_fee_cost
 union select 'field_revision_field_event_register_fee_hdr'     as table_name, count(*) as num_rows from field_revision_field_event_register_fee_hdr
 union select 'field_revision_field_event_register_fee_name'    as table_name, count(*) as num_rows from field_revision_field_event_register_fee_name
 union select 'field_revision_field_event_type'                 as table_name, count(*) as num_rows from field_revision_field_event_type
 union select 'field_revision_field_event_venue'                as table_name, count(*) as num_rows from field_revision_field_event_venue
 union select 'field_revision_field_event_venue_geo'            as table_name, count(*) as num_rows from field_revision_field_event_venue_geo
 union select 'field_revision_field_fc_membership_transfer'     as table_name, count(*) as num_rows from field_revision_field_fc_membership_transfer
 union select 'field_revision_field_file_image_alt_text'        as table_name, count(*) as num_rows from field_revision_field_file_image_alt_text
 union select 'field_revision_field_file_image_title_text'      as table_name, count(*) as num_rows from field_revision_field_file_image_title_text
 union select 'field_revision_field_first_formal_mem_location'  as table_name, count(*) as num_rows from field_revision_field_first_formal_mem_location
 union select 'field_revision_field_first_name'                 as table_name, count(*) as num_rows from field_revision_field_first_name
 union select 'field_revision_field_heading'                    as table_name, count(*) as num_rows from field_revision_field_heading
 union select 'field_revision_field_image'                      as table_name, count(*) as num_rows from field_revision_field_image
 union select 'field_revision_field_image_gallery'              as table_name, count(*) as num_rows from field_revision_field_image_gallery
 union select 'field_revision_field_is_private_content'         as table_name, count(*) as num_rows from field_revision_field_is_private_content
 union select 'field_revision_field_label'                      as table_name, count(*) as num_rows from field_revision_field_label
 union select 'field_revision_field_last_name'                  as table_name, count(*) as num_rows from field_revision_field_last_name
 union select 'field_revision_field_link'                       as table_name, count(*) as num_rows from field_revision_field_link
 union select 'field_revision_field_links'                      as table_name, count(*) as num_rows from field_revision_field_links
 union select 'field_revision_field_location_image'             as table_name, count(*) as num_rows from field_revision_field_location_image
 union select 'field_revision_field_meeting_attendees'          as table_name, count(*) as num_rows from field_revision_field_meeting_attendees
 union select 'field_revision_field_meeting_board'              as table_name, count(*) as num_rows from field_revision_field_meeting_board
 union select 'field_revision_field_meeting_board_extra'        as table_name, count(*) as num_rows from field_revision_field_meeting_board_extra
 union select 'field_revision_field_meeting_clerks'             as table_name, count(*) as num_rows from field_revision_field_meeting_clerks
 union select 'field_revision_field_meeting_code'               as table_name, count(*) as num_rows from field_revision_field_meeting_code
 union select 'field_revision_field_meeting_date'               as table_name, count(*) as num_rows from field_revision_field_meeting_date
 union select 'field_revision_field_meeting_end_statement'      as table_name, count(*) as num_rows from field_revision_field_meeting_end_statement
 union select 'field_revision_field_meeting_guests'             as table_name, count(*) as num_rows from field_revision_field_meeting_guests
 union select 'field_revision_field_meeting_minutes'            as table_name, count(*) as num_rows from field_revision_field_meeting_minutes
 union select 'field_revision_field_meeting_occasion'           as table_name, count(*) as num_rows from field_revision_field_meeting_occasion
 union select 'field_revision_field_meeting_status'             as table_name, count(*) as num_rows from field_revision_field_meeting_status
 union select 'field_revision_field_meeting_type'               as table_name, count(*) as num_rows from field_revision_field_meeting_type
 union select 'field_revision_field_meeting_venue'              as table_name, count(*) as num_rows from field_revision_field_meeting_venue
 union select 'field_revision_field_meeting_year'               as table_name, count(*) as num_rows from field_revision_field_meeting_year
 union select 'field_revision_field_member_status'              as table_name, count(*) as num_rows from field_revision_field_member_status
 union select 'field_revision_field_membership_held_overseas'   as table_name, count(*) as num_rows from field_revision_field_membership_held_overseas
 union select 'field_revision_field_membership_transfer_date'   as table_name, count(*) as num_rows from field_revision_field_membership_transfer_date
 union select 'field_revision_field_minutes_appt_active_date'   as table_name, count(*) as num_rows from field_revision_field_minutes_appt_active_date
 union select 'field_revision_field_minutes_appt_date'          as table_name, count(*) as num_rows from field_revision_field_minutes_appt_date
 union select 'field_revision_field_minutes_appt_deactive_date' as table_name, count(*) as num_rows from field_revision_field_minutes_appt_deactive_date
 union select 'field_revision_field_minutes_appt_end_desc'      as table_name, count(*) as num_rows from field_revision_field_minutes_appt_end_desc
 union select 'field_revision_field_minutes_appt_start_desc'    as table_name, count(*) as num_rows from field_revision_field_minutes_appt_start_desc
 union select 'field_revision_field_minutes_appt_term_no'       as table_name, count(*) as num_rows from field_revision_field_minutes_appt_term_no
 union select 'field_revision_field_minutes_appt_web_role'      as table_name, count(*) as num_rows from field_revision_field_minutes_appt_web_role
 union select 'field_revision_field_minutes_attachment'         as table_name, count(*) as num_rows from field_revision_field_minutes_attachment
 union select 'field_revision_field_minutes_date'               as table_name, count(*) as num_rows from field_revision_field_minutes_date
 union select 'field_revision_field_minutes_from_group'         as table_name, count(*) as num_rows from field_revision_field_minutes_from_group
 union select 'field_revision_field_minutes_number'             as table_name, count(*) as num_rows from field_revision_field_minutes_number
 union select 'field_revision_field_minutes_position'           as table_name, count(*) as num_rows from field_revision_field_minutes_position
 union select 'field_revision_field_minutes_related'            as table_name, count(*) as num_rows from field_revision_field_minutes_related
 union select 'field_revision_field_minutes_source'             as table_name, count(*) as num_rows from field_revision_field_minutes_source
 union select 'field_revision_field_minutes_status'             as table_name, count(*) as num_rows from field_revision_field_minutes_status
 union select 'field_revision_field_minutes_title'              as table_name, count(*) as num_rows from field_revision_field_minutes_title
 union select 'field_revision_field_minutes_to_group'           as table_name, count(*) as num_rows from field_revision_field_minutes_to_group
 union select 'field_revision_field_minutes_type'               as table_name, count(*) as num_rows from field_revision_field_minutes_type
 union select 'field_revision_field_minutes_users'              as table_name, count(*) as num_rows from field_revision_field_minutes_users
 union select 'field_revision_field_minutes_users_agreed'       as table_name, count(*) as num_rows from field_revision_field_minutes_users_agreed
 union select 'field_revision_field_minutes_users_disagreed'    as table_name, count(*) as num_rows from field_revision_field_minutes_users_disagreed
 union select 'field_revision_field_minutes_users_neutral'      as table_name, count(*) as num_rows from field_revision_field_minutes_users_neutral
 union select 'field_revision_field_minutes_venue'              as table_name, count(*) as num_rows from field_revision_field_minutes_venue
 union select 'field_revision_field_ms_transfer_from'           as table_name, count(*) as num_rows from field_revision_field_ms_transfer_from
 union select 'field_revision_field_ms_transfer_meeting_minute' as table_name, count(*) as num_rows from field_revision_field_ms_transfer_meeting_minute
 union select 'field_revision_field_ms_transfer_to'             as table_name, count(*) as num_rows from field_revision_field_ms_transfer_to
 union select 'field_revision_field_nomcom_appt'                as table_name, count(*) as num_rows from field_revision_field_nomcom_appt
 union select 'field_revision_field_nomcom_appt_date'           as table_name, count(*) as num_rows from field_revision_field_nomcom_appt_date
 union select 'field_revision_field_nomcom_appt_end_desc'       as table_name, count(*) as num_rows from field_revision_field_nomcom_appt_end_desc
 union select 'field_revision_field_nomcom_appt_group'          as table_name, count(*) as num_rows from field_revision_field_nomcom_appt_group
 union select 'field_revision_field_nomcom_appt_position'       as table_name, count(*) as num_rows from field_revision_field_nomcom_appt_position
 union select 'field_revision_field_nomcom_appt_start_desc'     as table_name, count(*) as num_rows from field_revision_field_nomcom_appt_start_desc
 union select 'field_revision_field_nomcom_appt_users'          as table_name, count(*) as num_rows from field_revision_field_nomcom_appt_users
 union select 'field_revision_field_nomcom_meeting_minutes'     as table_name, count(*) as num_rows from field_revision_field_nomcom_meeting_minutes
 union select 'field_revision_field_nomcom_meeting_occasion'    as table_name, count(*) as num_rows from field_revision_field_nomcom_meeting_occasion
 union select 'field_revision_field_nomcom_minutes_related'     as table_name, count(*) as num_rows from field_revision_field_nomcom_minutes_related
 union select 'field_revision_field_nomcom_resign'              as table_name, count(*) as num_rows from field_revision_field_nomcom_resign
 union select 'field_revision_field_nomcom_resign_date'         as table_name, count(*) as num_rows from field_revision_field_nomcom_resign_date
 union select 'field_revision_field_nomcom_resign_group'        as table_name, count(*) as num_rows from field_revision_field_nomcom_resign_group
 union select 'field_revision_field_nomcom_resign_users'        as table_name, count(*) as num_rows from field_revision_field_nomcom_resign_users
 union select 'field_revision_field_offline_formal_membership'  as table_name, count(*) as num_rows from field_revision_field_offline_formal_membership
 union select 'field_revision_field_og_membership_activation'   as table_name, count(*) as num_rows from field_revision_field_og_membership_activation
 union select 'field_revision_field_og_membership_date'         as table_name, count(*) as num_rows from field_revision_field_og_membership_date
 union select 'field_revision_field_og_membership_deactivation' as table_name, count(*) as num_rows from field_revision_field_og_membership_deactivation
 union select 'field_revision_field_og_membership_end_desc'     as table_name, count(*) as num_rows from field_revision_field_og_membership_end_desc
 union select 'field_revision_field_og_membership_minute'       as table_name, count(*) as num_rows from field_revision_field_og_membership_minute
 union select 'field_revision_field_og_membership_orig_start'   as table_name, count(*) as num_rows from field_revision_field_og_membership_orig_start
 union select 'field_revision_field_og_membership_position'     as table_name, count(*) as num_rows from field_revision_field_og_membership_position
 union select 'field_revision_field_og_membership_start_desc'   as table_name, count(*) as num_rows from field_revision_field_og_membership_start_desc
 union select 'field_revision_field_og_membership_term_no'      as table_name, count(*) as num_rows from field_revision_field_og_membership_term_no
 union select 'field_revision_field_og_membership_users_group'  as table_name, count(*) as num_rows from field_revision_field_og_membership_users_group
 union select 'field_revision_field_og_membership_web_role'     as table_name, count(*) as num_rows from field_revision_field_og_membership_web_role
 union select 'field_revision_field_other_allergies'            as table_name, count(*) as num_rows from field_revision_field_other_allergies
 union select 'field_revision_field_other_meal_preference'      as table_name, count(*) as num_rows from field_revision_field_other_meal_preference
 union select 'field_revision_field_other_query_or_request'     as table_name, count(*) as num_rows from field_revision_field_other_query_or_request
 union select 'field_revision_field_paid_event'                 as table_name, count(*) as num_rows from field_revision_field_paid_event
 union select 'field_revision_field_phone'                      as table_name, count(*) as num_rows from field_revision_field_phone
 union select 'field_revision_field_postal_address'             as table_name, count(*) as num_rows from field_revision_field_postal_address
 union select 'field_revision_field_preformatted_address'       as table_name, count(*) as num_rows from field_revision_field_preformatted_address
 union select 'field_revision_field_price'                      as table_name, count(*) as num_rows from field_revision_field_price
 union select 'field_revision_field_print_in_book'              as table_name, count(*) as num_rows from field_revision_field_print_in_book
 union select 'field_revision_field_publish_date'               as table_name, count(*) as num_rows from field_revision_field_publish_date
 union select 'field_revision_field_publisher'                  as table_name, count(*) as num_rows from field_revision_field_publisher
 union select 'field_revision_field_ref_book'                   as table_name, count(*) as num_rows from field_revision_field_ref_book
 union select 'field_revision_field_ref_meeting_minute_ffm'     as table_name, count(*) as num_rows from field_revision_field_ref_meeting_minute_ffm
 union select 'field_revision_field_registration_type'          as table_name, count(*) as num_rows from field_revision_field_registration_type
 union select 'field_revision_field_report_file'                as table_name, count(*) as num_rows from field_revision_field_report_file
 union select 'field_revision_field_resource_file'              as table_name, count(*) as num_rows from field_revision_field_resource_file
 union select 'field_revision_field_sale_book'                  as table_name, count(*) as num_rows from field_revision_field_sale_book
 union select 'field_revision_field_short_name'                 as table_name, count(*) as num_rows from field_revision_field_short_name
 union select 'field_revision_field_shown_to_young_friends'     as table_name, count(*) as num_rows from field_revision_field_shown_to_young_friends
 union select 'field_revision_field_tags'                       as table_name, count(*) as num_rows from field_revision_field_tags
 union select 'field_revision_field_use_as_postal_address'      as table_name, count(*) as num_rows from field_revision_field_use_as_postal_address
 union select 'field_revision_field_user_access_needs'          as table_name, count(*) as num_rows from field_revision_field_user_access_needs
 union select 'field_revision_field_user_address_1'             as table_name, count(*) as num_rows from field_revision_field_user_address_1
 union select 'field_revision_field_user_address_2'             as table_name, count(*) as num_rows from field_revision_field_user_address_2
 union select 'field_revision_field_user_address_3'             as table_name, count(*) as num_rows from field_revision_field_user_address_3
 union select 'field_revision_field_user_address_4'             as table_name, count(*) as num_rows from field_revision_field_user_address_4
 union select 'field_revision_field_user_birthdate'             as table_name, count(*) as num_rows from field_revision_field_user_birthdate
 union select 'field_revision_field_user_deceased'              as table_name, count(*) as num_rows from field_revision_field_user_deceased
 union select 'field_revision_field_user_documents'             as table_name, count(*) as num_rows from field_revision_field_user_documents
 union select 'field_revision_field_user_fax'                   as table_name, count(*) as num_rows from field_revision_field_user_fax
 union select 'field_revision_field_user_first_name'            as table_name, count(*) as num_rows from field_revision_field_user_first_name
 union select 'field_revision_field_user_inactive'              as table_name, count(*) as num_rows from field_revision_field_user_inactive
 union select 'field_revision_field_user_joined_year'           as table_name, count(*) as num_rows from field_revision_field_user_joined_year
 union select 'field_revision_field_user_kin'                   as table_name, count(*) as num_rows from field_revision_field_user_kin
 union select 'field_revision_field_user_kin_field_info'        as table_name, count(*) as num_rows from field_revision_field_user_kin_field_info
 union select 'field_revision_field_user_kin_relationship'      as table_name, count(*) as num_rows from field_revision_field_user_kin_relationship
 union select 'field_revision_field_user_kin_user_ref'          as table_name, count(*) as num_rows from field_revision_field_user_kin_user_ref
 union select 'field_revision_field_user_last_name'             as table_name, count(*) as num_rows from field_revision_field_user_last_name
 union select 'field_revision_field_user_main_og'               as table_name, count(*) as num_rows from field_revision_field_user_main_og
 union select 'field_revision_field_user_medical_needs'         as table_name, count(*) as num_rows from field_revision_field_user_medical_needs
 union select 'field_revision_field_user_mobile'                as table_name, count(*) as num_rows from field_revision_field_user_mobile
 union select 'field_revision_field_user_notes'                 as table_name, count(*) as num_rows from field_revision_field_user_notes
 union select 'field_revision_field_user_notes_date'            as table_name, count(*) as num_rows from field_revision_field_user_notes_date
 union select 'field_revision_field_user_notes_text'            as table_name, count(*) as num_rows from field_revision_field_user_notes_text
 union select 'field_revision_field_user_old_id'                as table_name, count(*) as num_rows from field_revision_field_user_old_id
 union select 'field_revision_field_user_phone'                 as table_name, count(*) as num_rows from field_revision_field_user_phone
 union select 'field_revision_field_user_physical_address'      as table_name, count(*) as num_rows from field_revision_field_user_physical_address
 union select 'field_revision_field_user_postal_address'        as table_name, count(*) as num_rows from field_revision_field_user_postal_address
 union select 'field_revision_field_user_preferred_name'        as table_name, count(*) as num_rows from field_revision_field_user_preferred_name
 union select 'field_revision_field_user_resigned'              as table_name, count(*) as num_rows from field_revision_field_user_resigned
 union select 'field_revision_field_user_spouse'                as table_name, count(*) as num_rows from field_revision_field_user_spouse
 union select 'field_revision_field_user_website'               as table_name, count(*) as num_rows from field_revision_field_user_website
 union select 'field_revision_field_user_worship_group'         as table_name, count(*) as num_rows from field_revision_field_user_worship_group
 union select 'field_revision_field_venue_info'                 as table_name, count(*) as num_rows from field_revision_field_venue_info
 union select 'field_revision_field_venue_website'              as table_name, count(*) as num_rows from field_revision_field_venue_website
 union select 'field_revision_field_video'                      as table_name, count(*) as num_rows from field_revision_field_video
 union select 'field_revision_field_visibility'                 as table_name, count(*) as num_rows from field_revision_field_visibility
 union select 'field_revision_field_west_meeting_minutes'       as table_name, count(*) as num_rows from field_revision_field_west_meeting_minutes
 union select 'field_revision_field_west_meeting_occasion'      as table_name, count(*) as num_rows from field_revision_field_west_meeting_occasion
 union select 'field_revision_field_west_minutes_related'       as table_name, count(*) as num_rows from field_revision_field_west_minutes_related
 union select 'field_revision_field_worship_group_location'     as table_name, count(*) as num_rows from field_revision_field_worship_group_location
 union select 'field_revision_field_ym_appendix'                as table_name, count(*) as num_rows from field_revision_field_ym_appendix
 union select 'field_revision_field_ym_appendix_body'           as table_name, count(*) as num_rows from field_revision_field_ym_appendix_body
 union select 'field_revision_field_ym_appendix_title'          as table_name, count(*) as num_rows from field_revision_field_ym_appendix_title
 union select 'field_revision_field_ym_epistle'                 as table_name, count(*) as num_rows from field_revision_field_ym_epistle
 union select 'field_revision_field_ym_epistle_body'            as table_name, count(*) as num_rows from field_revision_field_ym_epistle_body
 union select 'field_revision_field_ym_epistle_title'           as table_name, count(*) as num_rows from field_revision_field_ym_epistle_title
 union select 'field_revision_field_ym_meeting_minutes'         as table_name, count(*) as num_rows from field_revision_field_ym_meeting_minutes
 union select 'field_revision_field_ym_meeting_occasion'        as table_name, count(*) as num_rows from field_revision_field_ym_meeting_occasion
 union select 'field_revision_field_ym_minutes_related'         as table_name, count(*) as num_rows from field_revision_field_ym_minutes_related
 union select 'field_revision_group_access'                     as table_name, count(*) as num_rows from field_revision_group_access
 union select 'field_revision_group_content_access'             as table_name, count(*) as num_rows from field_revision_group_content_access
 union select 'field_revision_group_group'                      as table_name, count(*) as num_rows from field_revision_group_group
 union select 'field_revision_gsl_addressfield'                 as table_name, count(*) as num_rows from field_revision_gsl_addressfield
 union select 'field_revision_gsl_feature_filter_list'          as table_name, count(*) as num_rows from field_revision_gsl_feature_filter_list
 union select 'field_revision_gsl_geofield'                     as table_name, count(*) as num_rows from field_revision_gsl_geofield
 union select 'field_revision_gsl_props_misc'                   as table_name, count(*) as num_rows from field_revision_gsl_props_misc
 union select 'field_revision_gsl_props_phone'                  as table_name, count(*) as num_rows from field_revision_gsl_props_phone
 union select 'field_revision_gsl_props_web'                    as table_name, count(*) as num_rows from field_revision_gsl_props_web
 union select 'field_revision_og_group_ref'                     as table_name, count(*) as num_rows from field_revision_og_group_ref
 union select 'field_revision_og_membership_request'            as table_name, count(*) as num_rows from field_revision_og_membership_request
 union select 'field_revision_og_user_node'                     as table_name, count(*) as num_rows from field_revision_og_user_node
 union select 'field_revision_taxonomy_forums'                  as table_name, count(*) as num_rows from field_revision_taxonomy_forums
 union select 'file_display'                                    as table_name, count(*) as num_rows from file_display
 union select 'file_managed'                                    as table_name, count(*) as num_rows from file_managed
 union select 'file_metadata'                                   as table_name, count(*) as num_rows from file_metadata
 union select 'file_type'                                       as table_name, count(*) as num_rows from file_type
 union select 'file_usage'                                      as table_name, count(*) as num_rows from file_usage
 union select 'filter'                                          as table_name, count(*) as num_rows from filter
 union select 'filter_format'                                   as table_name, count(*) as num_rows from filter_format
 union select 'flexslider_optionset'                            as table_name, count(*) as num_rows from flexslider_optionset
 union select 'flexslider_picture_optionset'                    as table_name, count(*) as num_rows from flexslider_picture_optionset
 union select 'flood'                                           as table_name, count(*) as num_rows from flood
 union select 'forum'                                           as table_name, count(*) as num_rows from forum
 union select 'forum_index'                                     as table_name, count(*) as num_rows from forum_index
 union select 'history'                                         as table_name, count(*) as num_rows from history
 union select 'image_effects'                                   as table_name, count(*) as num_rows from image_effects
 union select 'image_styles'                                    as table_name, count(*) as num_rows from image_styles
 union select 'linkit_profiles'                                 as table_name, count(*) as num_rows from linkit_profiles
 union select 'masquerade'                                      as table_name, count(*) as num_rows from masquerade
 union select 'masquerade_users'                                as table_name, count(*) as num_rows from masquerade_users
 union select 'media_restrict_wysiwyg'                          as table_name, count(*) as num_rows from media_restrict_wysiwyg
 union select 'media_view_mode_wysiwyg'                         as table_name, count(*) as num_rows from media_view_mode_wysiwyg
 union select 'menu_custom'                                     as table_name, count(*) as num_rows from menu_custom
 union select 'menu_links'                                      as table_name, count(*) as num_rows from menu_links
 union select 'menu_links_visibility_role'                      as table_name, count(*) as num_rows from menu_links_visibility_role
 union select 'menu_node'                                       as table_name, count(*) as num_rows from menu_node
 union select 'menu_router'                                     as table_name, count(*) as num_rows from menu_router
 union select 'menu_token'                                      as table_name, count(*) as num_rows from menu_token
 union select 'metatag'                                         as table_name, count(*) as num_rows from metatag
 union select 'metatag_config'                                  as table_name, count(*) as num_rows from metatag_config
 union select 'migrate_field_mapping'                           as table_name, count(*) as num_rows from migrate_field_mapping
 union select 'migrate_group'                                   as table_name, count(*) as num_rows from migrate_group
 union select 'migrate_log'                                     as table_name, count(*) as num_rows from migrate_log
 union select 'migrate_map_storelocation'                       as table_name, count(*) as num_rows from migrate_map_storelocation
 union select 'migrate_map_users'                               as table_name, count(*) as num_rows from migrate_map_users
 union select 'migrate_map_usersrelation'                       as table_name, count(*) as num_rows from migrate_map_usersrelation
 union select 'migrate_message_storelocation'                   as table_name, count(*) as num_rows from migrate_message_storelocation
 union select 'migrate_message_users'                           as table_name, count(*) as num_rows from migrate_message_users
 union select 'migrate_message_usersrelation'                   as table_name, count(*) as num_rows from migrate_message_usersrelation
 union select 'migrate_status'                                  as table_name, count(*) as num_rows from migrate_status
 union select 'node'                                            as table_name, count(*) as num_rows from node
 union select 'node_access'                                     as table_name, count(*) as num_rows from node_access
 union select 'node_comment_statistics'                         as table_name, count(*) as num_rows from node_comment_statistics
 union select 'node_revision'                                   as table_name, count(*) as num_rows from node_revision
 union select 'node_type'                                       as table_name, count(*) as num_rows from node_type
 union select 'nodequeue_nodes'                                 as table_name, count(*) as num_rows from nodequeue_nodes
 union select 'nodequeue_queue'                                 as table_name, count(*) as num_rows from nodequeue_queue
 union select 'nodequeue_roles'                                 as table_name, count(*) as num_rows from nodequeue_roles
 union select 'nodequeue_subqueue'                              as table_name, count(*) as num_rows from nodequeue_subqueue
 union select 'nodequeue_types'                                 as table_name, count(*) as num_rows from nodequeue_types
 union select 'og_membership'                                   as table_name, count(*) as num_rows from og_membership
 union select 'og_membership_type'                              as table_name, count(*) as num_rows from og_membership_type
 union select 'og_role'                                         as table_name, count(*) as num_rows from og_role
 union select 'og_role_permission'                              as table_name, count(*) as num_rows from og_role_permission
 union select 'og_users_roles'                                  as table_name, count(*) as num_rows from og_users_roles
 union select 'pathauto_state'                                  as table_name, count(*) as num_rows from pathauto_state
 union select 'picture_mapping'                                 as table_name, count(*) as num_rows from picture_mapping
 union select 'print_node_conf'                                 as table_name, count(*) as num_rows from print_node_conf
 union select 'print_page_counter'                              as table_name, count(*) as num_rows from print_page_counter
 union select 'print_pdf_node_conf'                             as table_name, count(*) as num_rows from print_pdf_node_conf
 union select 'print_pdf_page_counter'                          as table_name, count(*) as num_rows from print_pdf_page_counter
 union select 'quaker_appointment_history'                      as table_name, count(*) as num_rows from quaker_appointment_history
 union select 'quaker_countries'                                as table_name, count(*) as num_rows from quaker_countries
 union select 'quaker_mm_appointments'                          as table_name, count(*) as num_rows from quaker_mm_appointments
 union select 'queue'                                           as table_name, count(*) as num_rows from queue
 union select 'rdf_mapping'                                     as table_name, count(*) as num_rows from rdf_mapping
 union select 'redirect'                                        as table_name, count(*) as num_rows from redirect
 union select 'registration'                                    as table_name, count(*) as num_rows from registration
 union select 'registration_collection_data'                    as table_name, count(*) as num_rows from registration_collection_data
 union select 'registration_entity'                             as table_name, count(*) as num_rows from registration_entity
 union select 'registration_state'                              as table_name, count(*) as num_rows from registration_state
 union select 'registration_type'                               as table_name, count(*) as num_rows from registration_type
 union select 'registry'                                        as table_name, count(*) as num_rows from registry
 union select 'registry_file'                                   as table_name, count(*) as num_rows from registry_file
 union select 'role'                                            as table_name, count(*) as num_rows from role
 union select 'role_permission'                                 as table_name, count(*) as num_rows from role_permission
 union select 'rules_config'                                    as table_name, count(*) as num_rows from rules_config
 union select 'rules_dependencies'                              as table_name, count(*) as num_rows from rules_dependencies
 union select 'rules_tags'                                      as table_name, count(*) as num_rows from rules_tags
 union select 'rules_trigger'                                   as table_name, count(*) as num_rows from rules_trigger
 union select 'search_dataset'                                  as table_name, count(*) as num_rows from search_dataset
 union select 'search_index'                                    as table_name, count(*) as num_rows from search_index
 union select 'search_node_links'                               as table_name, count(*) as num_rows from search_node_links
 union select 'search_total'                                    as table_name, count(*) as num_rows from search_total
 union select 'semaphore'                                       as table_name, count(*) as num_rows from semaphore
 union select 'sequences'                                       as table_name, count(*) as num_rows from sequences
 union select 'sessions'                                        as table_name, count(*) as num_rows from sessions
 union select 'shortcut_set'                                    as table_name, count(*) as num_rows from shortcut_set
 union select 'shortcut_set_users'                              as table_name, count(*) as num_rows from shortcut_set_users
 union select 'slick_optionset'                                 as table_name, count(*) as num_rows from slick_optionset
 union select 'system'                                          as table_name, count(*) as num_rows from system
 union select 'taxonomy_index'                                  as table_name, count(*) as num_rows from taxonomy_index
 union select 'taxonomy_term_data'                              as table_name, count(*) as num_rows from taxonomy_term_data
 union select 'taxonomy_term_hierarchy'                         as table_name, count(*) as num_rows from taxonomy_term_hierarchy
 union select 'taxonomy_vocabulary'                             as table_name, count(*) as num_rows from taxonomy_vocabulary
 union select 'trigger_assignments'                             as table_name, count(*) as num_rows from trigger_assignments
 union select 'url_alias'                                       as table_name, count(*) as num_rows from url_alias
 union select 'user_revision'                                   as table_name, count(*) as num_rows from user_revision
 union select 'user_subscription_meeting'                       as table_name, count(*) as num_rows from user_subscription_meeting
 union select 'user_subscription_national'                      as table_name, count(*) as num_rows from user_subscription_national
 union select 'user_subscription_preference'                    as table_name, count(*) as num_rows from user_subscription_preference
 union select 'users'                                           as table_name, count(*) as num_rows from users
 union select 'users_roles'                                     as table_name, count(*) as num_rows from users_roles
 union select 'variable'                                        as table_name, count(*) as num_rows from variable
 union select 'vef_video_styles'                                as table_name, count(*) as num_rows from vef_video_styles
 union select 'views_data_export'                               as table_name, count(*) as num_rows from views_data_export
 union select 'views_data_export_object_cache'                  as table_name, count(*) as num_rows from views_data_export_object_cache
 union select 'views_display'                                   as table_name, count(*) as num_rows from views_display
 union select 'views_send_spool'                                as table_name, count(*) as num_rows from views_send_spool
 union select 'views_view'                                      as table_name, count(*) as num_rows from views_view
 union select 'watchdog'                                        as table_name, count(*) as num_rows from watchdog
 union select 'webform'                                         as table_name, count(*) as num_rows from webform
 union select 'webform_component'                               as table_name, count(*) as num_rows from webform_component
 union select 'webform_conditional'                             as table_name, count(*) as num_rows from webform_conditional
 union select 'webform_conditional_actions'                     as table_name, count(*) as num_rows from webform_conditional_actions
 union select 'webform_conditional_rules'                       as table_name, count(*) as num_rows from webform_conditional_rules
 union select 'webform_emails'                                  as table_name, count(*) as num_rows from webform_emails
 union select 'webform_last_download'                           as table_name, count(*) as num_rows from webform_last_download
 union select 'webform_node_value'                              as table_name, count(*) as num_rows from webform_node_value
 union select 'webform_roles'                                   as table_name, count(*) as num_rows from webform_roles
 union select 'webform_submissions'                             as table_name, count(*) as num_rows from webform_submissions
 union select 'webform_submitted_data'                          as table_name, count(*) as num_rows from webform_submitted_data
 union select 'wysiwyg'                                         as table_name, count(*) as num_rows from wysiwyg
 union select 'wysiwyg_templates'                               as table_name, count(*) as num_rows from wysiwyg_templates
 union select 'wysiwyg_templates_content_types'                 as table_name, count(*) as num_rows from wysiwyg_templates_content_types
 union select 'wysiwyg_templates_default'                       as table_name, count(*) as num_rows from wysiwyg_templates_default
 union select 'wysiwyg_user'                                    as table_name, count(*) as num_rows from wysiwyg_user
 union select 'xmlsitemap'                                      as table_name, count(*) as num_rows from xmlsitemap
 union select 'xmlsitemap_sitemap'                              as table_name, count(*) as num_rows from xmlsitemap_sitemap
;
