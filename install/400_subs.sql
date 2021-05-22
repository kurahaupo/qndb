/*
    Note: the exp_unpivot* views are only used internally, by the experl_user_all_subs
          view created here
*/

select 'Subscriptions' as `CREATING `;

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

/* join the (unpivoted) MM subs & MM deliveries, and union with the YM subs */

select 'experl_user_all_subs' as `creating`;

create or replace view experl_user_all_subs as
      select s.uid                      as subs_uid,
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

