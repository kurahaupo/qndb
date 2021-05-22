/*
    Generate the contents of each list file to deposit on the email server.
        listname
        list email address
        subscriber email address
    Not part of or used by the main script.
    Needs experl_user_all_subs
*/

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
        from experl_user_all_subs           as s
   left join users                          as u    on u.uid = s.subs_uid
   left join expmap_xm_domain               as d    on s.xmtag = d.xmtag
   left join expmap_email_sub               as m    on s.xmtag = m.xmtag
                                                   and s.channel = m.channel
         where s.method = 'email';

