/*
 *  Not part of or used by the main script.
 *
 *  Generate the the whole contents of each postal address label, comprising:
 *      listname
 *      names
 *      postal address
 *
 *  Needs experl_user_all_subs
 *      experl_user_addresses     (from *addresses.sql)
 *      experl_user_addresses2    (from *addresses.sql)
 *      exp_user_pname            (from *full_users.sql)
 *      exp_user_gname            (from *full_users.sql)
 *      exp_user_sname            (from *full_users.sql)
 */

/*
 * View `exp1_user_names` combines surname, given name, and preferred name as
 * one joined query; must FOLLOW those definitions in 500_full_users.
 */

select 'exp1_user_names' as `Creating Internal View`;

create or replace view exp1_user_names as
      select uid                                                as names_uid,
             concat(ifnull(pref_name, given_name), ' ',surname) as full_name,
             pref_name,
             given_name,
             surname
        from users
   left join exp_user_pname on uid=pname_uid
   left join exp_user_gname on uid=gname_uid
   left join exp_user_sname on uid=sname_uid
;


select 'export_print_subs' as `creating view`;

create or replace view export_print_subs as
      select n.*,
             s.*,
             a.*
        from experl_user_all_subs           as s
   left join exp1_user_names                as n    on subs_uid = names_uid
   left join experl_user_addresses          as a    on subs_uid = address_uid
                                                   and address_use_as_postal
         where s.method = 'print';

select 'export_print_subs2' as `creating legacy view`;

create or replace view export_print_subs2 as
      select n.*,
             s.*,
             a.*
        from experl_user_all_subs           as s
   left join exp1_user_names                as n    on subs_uid = names_uid
   left join experl_user_addresses2         as a    on subs_uid = address_uid
                                                   and address_use_as_postal
         where s.method = 'print';
