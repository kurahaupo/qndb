/*SET autocommit=0;   /* don't actually make changes until COMMIT is used */

set @deflang = 'und';
set @ACTION_DRY_RUN = 0;
set @ACTION_ROLLBACK = 1;
set @ACTION_NO_TRANS = 2;
set @ACTION_COMMIT = 3;

/*
 *  Turns out we need ADMIN access to create a function,
 *  but not to create a stored procedure; go figure...
 */

delimiter ';;'

create or replace procedure add_collection_item( in i_fname varchar(32),
                                                 out o_iid integer unsigned,
                                                 out o_rid integer unsigned,
                                                 out o_uuid varchar(36) )
        modifies sql data
        sql security invoker
begin   /* {{ */
    /* why oh why is this so messy? */
    set o_uuid = uuid();
    insert into field_collection_item
                       (item_id, revision_id, field_name, archived, uuid)
                values (null,    0,           i_fname,    false,    o_uuid);
    set o_iid = last_insert_id();
    insert into field_collection_item_revision
                       (revision_id, item_id)
                values (null,        o_iid);
    set o_rid = last_insert_id();
    update field_collection_item set revision_id = o_rid where item_id = o_iid and field_name = i_fname;
end     /* }} */
;;

create or replace procedure test_add_collection_item()
        modifies sql data
        sql security invoker
begin   /* {{ */
    declare xiid integer unsigned;
    declare xrid integer unsigned;
    declare xuuid varchar(40);
    start transaction;  /* [[ */
    call add_collection_item('field_addresses', xiid, xrid, xuuid);
    select xiid  as `new item_id`,
           xrid  as `new revision_id`,
           xuuid as `new uuid`;
    rollback;           /* ]] */
end     /* }} */
;;

create or replace procedure purge_test_data( in action_mode integer )
        modifies sql data
        sql security invoker
begin   /* {{ */

    declare dry_run boolean default action_mode = @ACTION_DRY_RUN;
    declare would_delete varchar(16) default case when dry_run then 'Propose deletion' else 'Delete' end;
    declare wrap_transaction boolean default action_mode in ( @ACTION_ROLLBACK, @ACTION_COMMIT );
    declare do_commit boolean default action_mode = @ACTION_COMMIT;

    if wrap_transaction then    /* {{ */
        start transaction;  /* [[ */
    end if;                     /* }} */

    select 'Purge test data' as `Run Stored Procedure`,
           dry_run           as `Dry Run?`,
           wrap_transaction  as `Use transaction?`,
           do_commit         as `Commit transaction?`;

    select would_delete as `Action`,
                   'field_data_field_label'     as `Table`, count(*) as `Rows`
               from field_data_field_label     where bundle = 'field_addresses'
    union
    select would_delete as `Action`,
                   'field_revision_field_label' as `Table`, count(*) as `Rows`
               from field_revision_field_label where bundle = 'field_addresses';
    if dry_run then /* {{ */
        select would_delete as `Action`, field_data_field_label.*     from field_data_field_label     where bundle = 'field_addresses' limit 9;
        select would_delete as `Action`, field_revision_field_label.* from field_revision_field_label where bundle = 'field_addresses' limit 9;
    else            /* }{ */
        delete from field_data_field_label     where bundle = 'field_addresses';
        delete from field_revision_field_label where bundle = 'field_addresses';
    end if;         /* }} */

    select would_delete as `Action`,
                   'field_data_field_user_address'     as `Table`, count(*) as `Rows`
               from field_data_field_user_address     where bundle = 'field_addresses'
    union
    select would_delete as `Action`,
                   'field_revision_field_user_address' as `Table`, count(*) as `Rows`
               from field_revision_field_user_address where bundle = 'field_addresses';
    if dry_run then /* {{ */
        select would_delete as `Action`, field_data_field_user_address.*     from field_data_field_user_address     where bundle = 'field_addresses' limit 9;
        select would_delete as `Action`, field_revision_field_user_address.* from field_revision_field_user_address where bundle = 'field_addresses' limit 9;
    else            /* }{ */
        delete from field_data_field_user_address     where bundle = 'field_addresses';
        delete from field_revision_field_user_address where bundle = 'field_addresses';
    end if;         /* }} */

    select would_delete as `Action`,
                   'field_data_field_use_as_postal_address'     as `Table`, count(*) as `Rows`
               from field_data_field_use_as_postal_address     where bundle = 'field_addresses'
    union
    select would_delete as `Action`,
                   'field_revision_field_use_as_postal_address' as `Table`, count(*) as `Rows`
               from field_revision_field_use_as_postal_address where bundle = 'field_addresses';
    if dry_run then /* {{ */
        select would_delete as `Action`, field_data_field_use_as_postal_address.*     from field_data_field_use_as_postal_address     where bundle = 'field_addresses' limit 9;
        select would_delete as `Action`, field_revision_field_use_as_postal_address.* from field_revision_field_use_as_postal_address where bundle = 'field_addresses' limit 9;
    else            /* }{ */
        delete from field_data_field_use_as_postal_address     where bundle = 'field_addresses';
        delete from field_revision_field_use_as_postal_address where bundle = 'field_addresses';
    end if;         /* }} */

    select would_delete as `Action`,
                   'field_data_field_addresses'     as `Table`, count(*) as `Rows`
               from field_data_field_addresses     where bundle = 'field_addresses'
    union
    select would_delete as `Action`,
                   'field_revision_field_addresses' as `Table`, count(*) as `Rows`
               from field_revision_field_addresses where bundle = 'field_addresses';
    if dry_run then /* {{ */
        select would_delete as `Action`, field_data_field_addresses.*     from field_data_field_addresses     where bundle = 'field_addresses' limit 9;
        select would_delete as `Action`, field_revision_field_addresses.* from field_revision_field_addresses where bundle = 'field_addresses' limit 9;
    else            /* }{ */
        delete from field_data_field_addresses     where bundle = 'field_addresses';
        delete from field_revision_field_addresses where bundle = 'field_addresses';
    end if;         /* }} */

    select would_delete as `Action`,
                   'field_data_field_print_in_book'     as `Table`, count(*) as `Rows`
               from field_data_field_print_in_book     where bundle = 'field_addresses'
    union
    select would_delete as `Action`,
                   'field_revision_field_print_in_book' as `Table`, count(*) as `Rows`
               from field_revision_field_print_in_book where bundle = 'field_addresses';
    if dry_run then /* {{ */
        select would_delete as `Action`, field_data_field_print_in_book.*     from field_data_field_print_in_book     where bundle = 'field_addresses' limit 9;
        select would_delete as `Action`, field_revision_field_print_in_book.* from field_revision_field_print_in_book where bundle = 'field_addresses' limit 9;
    else            /* }{ */
        delete from field_data_field_print_in_book     where bundle = 'field_addresses';
        delete from field_revision_field_print_in_book where bundle = 'field_addresses';
    end if;         /* }} */

    select would_delete as `Action`,
                   'field_collection_item'          as `Table`, count(*) as `Rows`
               from field_collection_item where field_name = 'field_addresses'
               union
    select would_delete as `Action`,
                   'field_collection_item_revision' as `Table`, count(*) as `Rows` from field_collection_item_revision where item_id in ( select item_id
               from field_collection_item where field_name = 'field_addresses' );
    if dry_run then /* {{ */
        select would_delete as `Action`, field_collection_item_revision.* from field_collection_item_revision where item_id in ( select item_id
                                                                 from field_collection_item where field_name = 'field_addresses' ) limit 9;
        select would_delete as `Action`, field_collection_item.* from field_collection_item where field_name = 'field_addresses' limit 9;
    else            /* }{ */
        delete from field_collection_item_revision where item_id in ( select item_id
               from field_collection_item where field_name = 'field_addresses' );
        delete from field_collection_item where field_name = 'field_addresses';
    end if;         /* }} */

    if wrap_transaction then    /* {{ */
        if do_commit then   /* {{ */
            commit;     /* ][ */
        else                /* }{ */
            rollback;   /* ]] */
        end if;             /* }} */
    end if;                     /* }} */

end     /* }} */
;;

create or replace procedure purge_user_addresses( in xuid integer unsigned,
                                                  in action_mode integer )
        modifies sql data
        sql security invoker
begin   /* {{ */

    declare dry_run boolean default action_mode = @ACTION_DRY_RUN;
    declare would_delete varchar(16) default case when dry_run then 'Propose deletion' else 'Delete' end;
    declare wrap_transaction boolean default action_mode in ( @ACTION_ROLLBACK, @ACTION_COMMIT );
    declare do_commit boolean default action_mode = @ACTION_COMMIT;

    if wrap_transaction then    /* {{ */
        start transaction;  /* [[ */
    end if;                     /* }} */

    /**************/

    select would_delete as `Action`,
              'field_revision_field_user_address' as `Table`, count(*) as `Rows`
          from field_revision_field_user_address
         where entity_type = 'field_collection_item'
           and bundle      = 'field_addresses'
           and entity_id  in (
                               select field_addresses_value
                                 from field_revision_field_addresses
                                where entity_type = 'user'
                                  and bundle      = 'user'
                                  and entity_id   = xuid
                             )
    union
    select would_delete as `Action`,
              'field_data_field_user_address' as `Table`, count(*) as `Rows`
          from field_data_field_user_address
         where entity_type = 'field_collection_item'
           and bundle      = 'field_addresses'
           and entity_id  in (
                               select field_addresses_value
                                 from field_data_field_addresses
                                where entity_type = 'user'
                                  and bundle      = 'user'
                                  and entity_id   = xuid
                             );

    if dry_run then /* {{ */

        select would_delete as `Action`,
               field_revision_field_user_address.*
          from field_revision_field_user_address
         where entity_type = 'field_collection_item'
           and bundle      = 'field_addresses'
           and entity_id  in (
                               select field_addresses_value
                                 from field_revision_field_addresses
                                where entity_type = 'user'
                                  and bundle      = 'user'
                                  and entity_id   = xuid
                             )
         limit 9;

        select would_delete as `Action`,
               field_data_field_user_address.*
          from field_data_field_user_address
         where entity_type = 'field_collection_item'
           and bundle      = 'field_addresses'
           and entity_id  in (
                               select field_addresses_value
                                 from field_data_field_addresses
                                where entity_type = 'user'
                                  and bundle      = 'user'
                                  and entity_id   = xuid
                             )
         limit 9;

    else            /* }{ */

        delete
          from field_revision_field_user_address
         where entity_type = 'field_collection_item'
           and bundle      = 'field_addresses'
           and entity_id  in (
                                    select field_addresses_value
                                      from field_revision_field_addresses
                                     where entity_type = 'user'
                                       and bundle      = 'user'
                                       and entity_id   = xuid
                                  );

        delete
          from field_data_field_user_address
         where entity_type = 'field_collection_item'
           and bundle      = 'field_addresses'
           and entity_id  in (
                               select field_addresses_value
                                 from field_data_field_addresses
                                where entity_type = 'user'
                                  and bundle      = 'user'
                                  and entity_id   = xuid
                             );

    end if;         /* }} */

    /**************/

    select would_delete as `Action`,
              'field_data_field_use_as_postal_address' as `Table`, count(*) as `Rows`
          from field_data_field_use_as_postal_address
         where entity_type = 'field_collection_item'
           and bundle      = 'field_addresses'
           and entity_id  in (
                               select field_addresses_value
                                 from field_data_field_addresses
                                where entity_type = 'user'
                                  and bundle      = 'user'
                                  and entity_id   = xuid
                             )
    union
    select would_delete as `Action`,
              'field_revision_field_use_as_postal_address' as `Table`, count(*) as `Rows`
          from field_revision_field_use_as_postal_address
         where entity_type = 'field_collection_item'
           and bundle      = 'field_addresses'
           and entity_id  in (
                               select field_addresses_value
                                 from field_revision_field_addresses
                                where entity_type = 'user'
                                  and bundle      = 'user'
                                  and entity_id   = xuid
                             );

    if dry_run then /* {{ */

        select would_delete as `Action`,
               field_data_field_use_as_postal_address.*
          from field_data_field_use_as_postal_address
         where entity_type = 'field_collection_item'
           and bundle      = 'field_addresses'
           and entity_id  in (
                               select field_addresses_value
                                 from field_data_field_addresses
                                where entity_type = 'user'
                                  and bundle      = 'user'
                                  and entity_id   = xuid
                             )
         limit 9;

        select would_delete as `Action`,
               field_revision_field_use_as_postal_address.*
          from field_revision_field_use_as_postal_address
         where entity_type = 'field_collection_item'
           and bundle      = 'field_addresses'
           and entity_id  in (
                               select field_addresses_value
                                 from field_revision_field_addresses
                                where entity_type = 'user'
                                  and bundle      = 'user'
                                  and entity_id   = xuid
                             )
         limit 9;

    else            /* }{ */

        delete
          from field_data_field_use_as_postal_address
         where entity_type = 'field_collection_item'
           and bundle      = 'field_addresses'
           and entity_id  in (
                               select field_addresses_value
                                 from field_data_field_addresses
                                where entity_type = 'user'
                                  and bundle      = 'user'
                                  and entity_id   = xuid
                             );

        delete
          from field_revision_field_use_as_postal_address
         where entity_type = 'field_collection_item'
           and bundle      = 'field_addresses'
           and entity_id  in (
                               select field_addresses_value
                                 from field_revision_field_addresses
                                where entity_type = 'user'
                                  and bundle      = 'user'
                                  and entity_id   = xuid
                             );

    end if;         /* }} */

    /**************/

    select would_delete as `Action`,
              'field_collection_item_revision' as `Table`, count(*) as `Rows`
          from field_collection_item_revision
         where item_id in (
                           select field_addresses_value
                             from field_data_field_addresses
                            where entity_type = 'user'
                              and bundle      = 'user'
                              and entity_id   = xuid
                          );

    if dry_run then /* {{ */

        select would_delete as `Action`,
               field_collection_item_revision.*
          from field_collection_item_revision
         where item_id in (
                           select field_addresses_value
                             from field_data_field_addresses
                            where entity_type = 'user'
                              and bundle      = 'user'
                              and entity_id   = xuid
                          )
         limit 9;

    else            /* }{ */

        delete
          from field_collection_item_revision
         where item_id in (
                           select field_addresses_value
                             from field_data_field_addresses
                            where entity_type = 'user'
                              and bundle      = 'user'
                              and entity_id   = xuid
                          );

    end if;         /* }} */

    /**************/

    select would_delete as `Action`,
              'field_collection_item' as `Table`, count(*) as `Rows`
          from field_collection_item
         where field_name = 'field_addresses'
           and item_id   in (
                               select field_address_value
                                 from field_data_field_addresses
                                where entity_type = 'user'
                                  and bundle      = 'user'
                                  and entity_id   = xuid
                            );

    if dry_run then /* {{ */

        select would_delete as `Action`,
               field_collection_item.*
          from field_collection_item
         where field_name = 'field_addresses'
           and item_id   in (
                               select field_address_value
                                 from field_data_field_addresses
                                where entity_type = 'user'
                                  and bundle      = 'user'
                                  and entity_id   = xuid
                            )
         limit 9;

    else            /* }{ */

        delete
          from field_collection_item
         where field_name = 'field_addresses'
           and item_id in (
                           select field_addresses_value
                             from field_data_field_addresses
                            where entity_type = 'user'
                              and bundle      = 'user'
                              and entity_id   = xuid
                          );

    end if;         /* }} */

    /**************/

    select would_delete as `Action`,
              'field_revision_field_addresses' as `Table`, count(*) as `Rows`
          from field_revision_field_addresses
         where entity_type = 'user'
           and bundle      = 'user'
           and entity_id   = xuid
    union
    select would_delete as `Action`,
              'field_data_field_addresses' as `Table`, count(*) as `Rows`
          from field_data_field_addresses
         where entity_type = 'user'
           and bundle      = 'user'
           and entity_id   = xuid;

    if dry_run then /* {{ */

        select would_delete as `Action`,
               field_revision_field_addresses.*
          from field_revision_field_addresses
         where entity_type = 'user'
           and bundle      = 'user'
           and entity_id   = xuid
         limit 9;

        select would_delete as `Action`,
               field_data_field_addresses.*
          from field_data_field_addresses
         where entity_type = 'user'
           and bundle      = 'user'
           and entity_id   = xuid
          limit 9;

    else            /* }{ */

        delete
          from field_revision_field_addresses
         where entity_type = 'user'
           and bundle      = 'user'
           and entity_id   = xuid;

        delete
          from field_data_field_addresses
         where entity_type = 'user'
           and bundle      = 'user'
           and entity_id   = xuid;

    end if;         /* }} */

    /**************/

    if wrap_transaction then    /* {{ */
        if do_commit then   /* {{ */
            commit;     /* ][ */
        else                /* }{ */
            rollback;   /* ]] */
        end if;             /* }} */
    end if;                     /* }} */

end     /* }} */
;;

create or replace procedure test_user_addresses( in xuid integer unsigned,
                                                 in action_mode integer )
        modifies sql data
        sql security invoker
begin   /* {{ */

    declare dry_run boolean default action_mode = @ACTION_DRY_RUN;
    declare wrap_transaction boolean default action_mode in( @ACTION_ROLLBACK, @ACTION_COMMIT );
    declare do_commit boolean default action_mode >= @ACTION_COMMIT;

    declare xvid   integer unsigned default null;
    declare xiid   integer unsigned default 0;
    declare xrid   integer unsigned default 0;
    declare xdelta integer unsigned default 0;
    declare xuuid  varchar(36) default 'xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx';

    if wrap_transaction then    /* {{ */
        select 'Begin Transaction' as `Action`;
        start transaction;  /* [[ */
    end if;                     /* }} */

    set xvid = ( select vid from users where uid = xuid );

    set xdelta = ( select ifnull(max(delta)+1,0) from field_data_field_addresses where entity_id = xuid );

    select 'Test address migration' as `Action`,
            xuid                    as `UID`,
            xvid                    as `VID`,
            xdelta                  as `Delta`,
            dry_run                 as `Dry Run?`,
            wrap_transaction        as `Use Transaction?`,
            do_commit               as `Commit Transaction?`;

    call add_collection_item('field_addresses', xiid, xrid, xuuid);

    select 'Collection item added' as `Action`, xiid as `ItemID`, xrid as `Item Revision`;

    select 'Step 1' as `Action`, 'field_data_field_addresses' as `Table`,
           'user' as `entity_type`, 'user' as `bundle`,
           false as `deleted`, xuid as `entity_id`, xvid as `revision_id`,
           @deflang as `language`, xdelta as `delta`, xiid as `field_addresses_value`,
           xrid as `field_addresses_revision_id`;

    insert into field_data_field_addresses
                ( entity_type, bundle, deleted, entity_id, revision_id, language, delta,   field_addresses_value, field_addresses_revision_id )
         values ( 'user',      'user', false,   xuid,      xvid,        @deflang, xdelta,  xiid,                  xrid );
    insert into field_revision_field_addresses
         select *
           from field_data_field_addresses
          where entity_id = xuid
            and revision_id = xvid
            and delta = xdelta;

    select 'Step 2' as `Action`, 'field_data_field_label' as `Table`,
           'field_collection_item' as `entity_type`, 'field_addresses' as `bundle`,
           false as `deleted`, xiid as `entity_id`, xrid as `revision_id`,
           @deflang as `language`, 0 as `delta`,
           'Wibble' as `field_label_value`;

    insert into field_data_field_label
                ( entity_type,             bundle,            deleted, entity_id, revision_id, language, delta, field_label_value )
         values ( 'field_collection_item', 'field_addresses', false,   xiid,      xrid,        @deflang, 0,     'Wibble' );

    insert into field_revision_field_label
         select *
           from field_data_field_label
          where entity_id = xiid
            and revision_id = xrid;

    select 'Step 3' as `Action`, 'field_data_field_user_address' as `Table`,
             'field_collection_item' as `entity_type`, 'field_addresses' as
             `bundle`, false as `deleted`,    xiid as `entity_id`,      xrid as
             `revision_id`,        @deflang as `language`, 0 as `delta`,
             concat('test-address-migration:\nuid=',xuid,', vid=',xvid,', iid=',xiid,', rid=',xrid,'\nuuid=',xuuid,'\n',now())
                as `field_user_address_value`,
             null as `field_user_address_format`;

    insert into field_data_field_user_address
                ( entity_type,             bundle,            deleted,  entity_id, revision_id, language, delta,
                  field_user_address_value,
                  field_user_address_format )
         values ( 'field_collection_item', 'field_addresses', false,    xiid,      xrid,        @deflang, 0,
                  concat('test-address-migration:\nuid=',xuid,', vid=',xvid,', iid=',xiid,', rid=',xrid,'\nuuid=',xuuid,'\n',now()),
                  null );
    insert into field_revision_field_user_address
         select *
           from field_data_field_user_address
          where entity_id = xiid
            and revision_id = xrid;

    select 'Step 4' as `Action`, 'field_data_field_use_as_postal_address' as `Table`,
             'field_collection_item' as `entity_type`, 'field_addresses' as
             `bundle`, false as `deleted`, xiid as `entity_id`, xrid as
             `revision_id`, @deflang as `language`, 0 as `delta`, true as
             `field_use_as_postal_address_value`;
    insert into field_data_field_use_as_postal_address
                ( entity_type,             bundle,            deleted, entity_id, revision_id, language, delta, field_use_as_postal_address_value )
         values ( 'field_collection_item', 'field_addresses', false,   xiid,      xrid,        @deflang, 0,     true );
    insert into field_revision_field_use_as_postal_address
         select *
           from field_data_field_use_as_postal_address
          where entity_id = xiid and revision_id = xrid;

    select 'Step 5' as `Action`, 'field_data_field_print_in_book' as `Table`,
             'field_collection_item' as `entity_type`, 'field_addresses' as
             `bundle`, false as `deleted`,   xiid as `entity_id`,      xrid as
             `revision_id`,        @deflang as `language`, 0 as `delta`,
             true as `field_print_in_book_value`;
    insert into field_data_field_print_in_book
                ( entity_type,             bundle,            deleted, entity_id, revision_id, language, delta, field_print_in_book_value )
         values ( 'field_collection_item', 'field_addresses', false,   xiid,      xrid,        @deflang, 0,     true );
    insert into field_revision_field_print_in_book
         select *
           from field_data_field_print_in_book
          where entity_id = xiid
            and revision_id = xrid;

    select 'Finish' as `Action`;

    if wrap_transaction then    /* {{ */
        if do_commit then       /* {{ */
            select 'Commit' as `Action`;
            commit;     /* ][ */
        else                    /* }{ */
            select 'Rollback' as `Action`;
            rollback;   /* ]] */
        end if;                 /* }} */
    end if;                     /* }} */

end     /* }} */
;;

create or replace procedure test_cursor_walk( in xuid integer unsigned )
begin   /* {{ */

    declare ac_uid        integer unsigned;
    declare ac_vid        integer unsigned;
    declare ac_slot       bigint(20);
    declare ac_language   varchar(32);
    declare ac_address     text;
    declare ac_data       longtext;
    declare ac_visible  boolean;
    declare ac_postal   boolean;

    declare get_address_finished boolean default false;

    declare user_address_slots cursor for
        select address_uid,             /* int(11) unsigned not null default 0     */
               address_vid,             /* int(11) unsigned          default NULL  */
               address_slot,            /* bigint(20)       not null default 0     */
               address_language,        /* varchar(32)      not null               */
               address, /* text             not null               */
               address_data,            /* longtext                  default NULL  */
               address_use_as_physical, /* bigint(20)       not null default 0     */
               address_use_as_postal    /* bigint(20)       not null default 0     */
          from export_user_addresses2
          join users on address_uid = uid
                    and address_vid = vid
         where address_uid = xuid;

    declare continue handler for not found set get_address_finished = true;

        select address_uid,             /* int(11) unsigned not null default 0     */
               address_vid,             /* int(11) unsigned          default NULL  */
               address_slot,            /* bigint(20)       not null default 0     */
               address_language,        /* varchar(32)      not null               */
               address, /* text             not null               */
               address_data,            /* longtext                  default NULL  */
               address_use_as_physical, /* bigint(20)       not null default 0     */
               address_use_as_postal,   /* bigint(20)       not null default 0     */
               uid,
               vid
          from export_user_addresses2
          join users on address_uid = uid
                    /*and address_vid = vid*/
         where address_uid = xuid;


    open user_address_slots ;
    get_address: loop   /* [[ */

        fetch user_address_slots
              into ac_uid,          /* address_uid */
                   ac_vid,          /* address_vid */
                   ac_slot,         /* address_slot */
                   ac_language,     /* address_language */
                   ac_address,      /* address */
                   ac_data,         /* address_data */
                   ac_visible,      /* address_use_as_physical */
                   ac_postal;       /* address_use_as_postal */

        if get_address_finished then    /* {{ */
    leave get_address;  /* ][ */
        end if;                         /* }} */

        select 'user_address_slots' as `Cursor`,
               ac_uid,            /* address_uid */
               ac_vid,            /* address_vid */
               ac_slot,           /* address_slot */
               ac_language,       /* address_language */
               ac_address,         /* address */
               ac_data,           /* address_data */
               ac_visible,      /* address_use_as_physical */
               ac_postal;       /* address_use_as_postal */

    end loop get_address;   /* ]] */

    close user_address_slots ;

end ;   /* }} */

create or replace procedure migrate_user_addresses( in xuid integer unsigned,
                                                    in action_mode integer unsigned,
                                                    in purge_first boolean )
        modifies sql data
        sql security invoker
begin   /* {{ */

    declare dry_run boolean default action_mode = @ACTION_DRY_RUN;
    declare would_insert varchar(17) default case action_mode when @ACTION_DRY_RUN then 'Propose insertion' else 'Insert' end;
    declare wrap_transaction boolean default action_mode in ( @ACTION_ROLLBACK, @ACTION_COMMIT );
    declare do_commit boolean default action_mode >= @ACTION_COMMIT;
    declare inner_action_mode integer unsigned default case when dry_run then @ACTION_DRY_RUN else @ACTION_NO_TRANS end;

    declare xiid   integer unsigned default 0;
    declare xrid   integer unsigned default 0;
    declare xuuid  varchar(36) default 'xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx';
    declare xdelta integer unsigned default 123456700;

    declare ac_uid        integer unsigned;
    declare ac_vid        integer unsigned;
    declare ac_slot       bigint(20);
    declare ac_language   varchar(32);
    declare ac_address     text;
    declare ac_data       longtext;
    declare ac_visible  boolean;
    declare ac_postal   boolean;

    declare get_address_finished boolean default false;

    declare user_address_slots cursor for
        select address_uid,              /* int(11) unsigned not null default 0     */
               address_vid,              /* int(11) unsigned          default NULL  */
               address_slot,             /* bigint(20)       not null default 0     */
               address_language,         /* varchar(32)      not null               */
               address,                  /* text             not null               */
               address_data,             /* longtext                  default NULL  */
               address_use_as_physical,  /* bigint(20)       not null default 0     */
               address_use_as_postal     /* bigint(20)       not null default 0     */
          from export_user_addresses2
          join users on address_uid = uid
                    and address_vid = vid
         where address_uid = xuid;

    declare continue handler for not found set get_address_finished = true;

    if dry_run then /* {{ */
        set would_insert  = 'Propose insertion';
    end if;         /* }} */

    select 'Migrate addresses from fixed blocks to flexi block' as `Run Stored Procedure`,
           xuid                                                 as `Target UID`,
           case action_mode
                when @ACTION_DRY_RUN  then 'Dry Run'
                when @ACTION_ROLLBACK then 'Rollback'
                when @ACTION_NO_TRANS then 'No Trans'
                when @ACTION_COMMIT   then 'Commit'
                                      else action_mode
           end                                                  as `Mode`,
           case when dry_run          then 'Yes' else 'No' end  as `Dry run?`,
           case when wrap_transaction then
               case when do_commit    then 'Commit'
                                      else 'Rollback' end
                                      else 'None' end           as `Transaction?`,
           case inner_action_mode
                when @ACTION_DRY_RUN  then 'Dry Run'
                when @ACTION_ROLLBACK then 'Rollback'
                when @ACTION_NO_TRANS then 'No Trans'
                when @ACTION_COMMIT   then 'Commit'
                                      else inner_action_mode
           end                                                  as `Inner Mode`;

    if wrap_transaction then    /* {{ */
        start transaction;  /* [[ */
    end if;                     /* }} */

    if purge_first then
        call purge_user_addresses( xuid, inner_action_mode );
    end if;

    /******************************************************************************/

    open user_address_slots;
    set get_address_finished = false;
    get_address: loop   /* [[ */

        fetch user_address_slots
              into ac_uid,      /* address_uid */
                   ac_vid,      /* address_vid */
                   ac_slot,     /* address_slot */
                   ac_language, /* address_language */
                   ac_address,  /* address */
                   ac_data,     /* address_data */
                   ac_visible,  /* address_use_as_physical */
                   ac_postal;   /* address_use_as_postal */

        if get_address_finished then    /* {{ */
    leave get_address;  /* ][ */
        end if;                         /* }} */

        select 'Selected'                       as `Action`,
                'user_address_slots'            as `Cursor`,
                ac_uid                          as `address_uid`,
                ac_vid                          as `address_vid`,
                ac_slot                         as `address_slot`,
                ac_language                     as `address_language`,
                replace(ac_address,'\n','\\n')  as `address`,
                ac_data                         as `address_data`,
                ac_visible                      as `address_use_as_physical`,
                ac_postal                       as `address_use_as_postal`;

        if dry_run then
            set xiid = 'dry_run_xiid' ;
            set xrid = 'dry_run_xrid' ;
            set xuuid = 'dry_run_xuuid' ;
        else
            call add_collection_item('field_addresses', xiid, xrid, xuuid);
            set xdelta = (
                select ifnull(max(delta)+1,0)
                  from field_data_field_addresses
                 where entity_id = xuid );
        end if ;

        select  'field_collection_item' as `Inserted`,
                'field_addresses'       as `Collection Field`,
                xiid                    as `Collection Item ID`,
                xrid                    as `Collection Item Revision`,
                xuuid                   as `Collection Item UUID`,
                xdelta                  as `Collection Item Delta`;

        select would_insert as `Action`,
               'field_data_field_addresses'  as `Table`,
               'user'                        as entity_type,
               'user'                        as bundle,
               false                         as deleted,
               ac_uid                        as entity_id,      /* == users.uid */
               ac_vid                        as revision_id,    /* == users.vid */
               'und'                         as language,
               xdelta                        as delta,
               xiid                          as field_addresses_value,
               xrid                          as field_addresses_revision_id ;

        if dry_run then
            select 'Skipping copy to revision table';
        else
            insert into field_data_field_addresses
                        ( entity_type,
                          bundle,
                          deleted,
                          entity_id,
                          revision_id,
                          language,
                          delta,
                          field_addresses_value,
                          field_addresses_revision_id )
                 values ( 'user',   /* entity_type */
                          'user',   /* bundle */
                          false,    /* deleted */
                          ac_uid,   /* entity_id   == users.uid */
                          ac_vid,   /* revision_id == users.vid */
                          'und',    /* language */
                          xdelta,   /* delta */
                          xiid,     /* field_addresses_value */
                          xrid );   /* field_addresses_revision_id */

            select 'Copying'                        as `Action`,
                   'field_data_field_addresses'     as `from Table`,
                   'field_revision_field_addresses' as `to Table`,
                   field_data_field_addresses.*
              from field_data_field_addresses
             where field_addresses_value = xiid
             limit 9;

            insert into field_revision_field_addresses
                 select *
                   from field_data_field_addresses
                  where field_addresses_value = xiid;

        end if ;

        select would_insert as `Action`,
               'field_data_field_user_address' as `Table`,
               'field_collection_item'         as entity_type,
               'field_addresses'               as bundle,
               false                           as deleted,
               xiid                            as entity_id,                  /* == field_addresses_value       */
               xrid                            as revision_id,                /* == field_addresses_revision_id */
               'und'                           as language,
               0                               as delta,                      /* == 0 (single-valued) */
               ac_address                      as field_user_address_value,   /* field_user_address_value (the preformatted address) */
               null                            as field_user_address_format;  /* field_user_address_format */

        if dry_run then
            select 'Skipping copy to revision table';
        else
            insert into field_data_field_user_address
                        ( entity_type,
                          bundle,
                          deleted,
                          entity_id,
                          revision_id,
                          language,
                          delta,
                          field_user_address_value,
                          field_user_address_format )
                 values ( 'field_collection_item',  /* entity_type */
                          'field_addresses',        /* bundle */
                          false,                    /* deleted */
                          xiid,                     /* entity_id == field_addresses_value */
                          xrid,                     /* revision_id == field_addresses_revision_id */
                          'und',                    /* language */
                          0,                        /* delta == 0 (single-valued) */
                          ac_address,               /* field_user_address_value (the preformatted address) */
                          null );                   /* field_user_address_format */


            select 'Copying'                            as `Action`,
                   'field_data_field_user_address'      as `from Table`,
                   'field_revision_field_user_address'  as `to Table`,
                   field_data_field_user_address.*
              from field_data_field_user_address
             where ENTITY_ID = xiid
             limit 9;

            insert into field_revision_field_user_address
                 select *
                   from field_data_field_user_address
                  where entity_id = xiid;
        end if ;

        select would_insert                             as `Action`,
               'field_data_field_use_as_postal_address' as `Table`,
               'field_collection_item'                  as entity_type,
               'field_addresses'                        as bundle,
               false                                    as deleted,
               xiid                                     as entity_id,              /* == field_addresses_value */
               xrid                                     as revision_id,            /* == field_addresses_revision_id */
               'und'                                    as language,
               0                                        as delta,                  /* == 0 (single-valued) */
               ac_postal                                as field_use_as_postal_address_value;

        if dry_run then
            select 'Skipping copy to revision table';
        else
            insert into field_data_field_use_as_postal_address
                        ( entity_type,
                          bundle,
                          deleted,
                          entity_id,
                          revision_id,
                          language,
                          delta,
                          field_use_as_postal_address_value )
                 values ( 'field_collection_item',  /* entity_type */
                          'field_addresses',        /* bundle */
                          false,                    /* deleted */
                          xiid,                     /* entity_id == field_addresses_value */
                          xrid,                     /* revision_id == field_addresses_revision_id */
                          'und',                    /* language */
                          0,                        /* delta == 0 (single-valued) */
                          ac_postal );              /* field_use_as_postal_address_value */

            select 'Copying'                                    as `Action`,
                   'field_revision_field_use_as_postal_address' as `from Table`,
                   'field_data_field_use_as_postal_address'     as `to Table`,
                   field_data_field_use_as_postal_address.*
              from field_data_field_use_as_postal_address
             where entity_id = xiid
             limit 9;

            insert into field_revision_field_print_in_book
            select *
              from field_data_field_print_in_book
             where entity_id = xiid;
        end if ;

        select would_insert                     as `Action`,
               'field_data_field_print_in_book' as `Table`,
               'field_collection_item'          as entity_type,
               'field_addresses'                as bundle,
               false                            as deleted,
               xiid                             as entity_id,              /* == field_addresses_value */
               xrid                             as revision_id,            /* == field_addresses_revision_id */
               'und'                            as language,
               0                                as delta,                  /* == 0 (single-valued) */
               ac_postal                        as field_print_in_book_value;

        if dry_run then
            select 'Skipping copy to revision table';
        else
            insert into field_data_field_print_in_book
                        ( entity_type,
                          bundle,
                          deleted,
                          entity_id,
                          revision_id,
                          language,
                          delta,
                          field_print_in_book_value )
                 values ( 'field_collection_item',  /* entity_type */
                          'field_addresses',        /* bundle */
                          false,                    /* deleted */
                          xiid,                     /* entity_id == field_addresses_value */
                          xrid,                     /* revision_id == field_addresses_revision_id */
                          'und',                    /* language */
                          0,                        /* delta == 0 (single-valued) */
                          ac_visible );             /* field_print_in_book_value */

            select 'Copying'                                    as `Action`,
                   'field_revision_field_print_in_book' as `from Table`,
                   'field_data_field_print_in_book'     as `to Table`,
                   field_data_field_print_in_book.*
              from field_data_field_print_in_book
             where entity_id = xiid
             limit 9;

            insert into field_revision_field_print_in_book
            select *
              from field_data_field_print_in_book
             where entity_id = xiid;
        end if ;

        select 'xdelta' as `Increment`, xdelta as `from`, xdelta+1 as `to`;
        set xdelta = xdelta+1;

    end loop get_address;   /* ]] */
    close user_address_slots;

    select 'Migrate addresses from fixed blocks to flexi block' as `Completed`;

    if wrap_transaction then    /* {{ */
        if do_commit then       /* {{ */
            commit;     /* ][ */
        else                    /* }{ */
            rollback;   /* ]] */
        end if;                 /* }} */
    end if;                     /* }} */

end     /* }} */
;;

delimiter ';'
