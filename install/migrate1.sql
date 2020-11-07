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
    set o_iid = last_insert_id;
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

    declare xvid integer unsigned default null;
    declare xiid integer unsigned default 0;
    declare xrid integer unsigned default 0;
    declare xseq integer unsigned default 0;
    declare xuuid varchar(36) default 'xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx';

    if wrap_transaction then    /* {{ */
        select 'Begin Transaction' as `Action`;
        start transaction;  /* [[ */
    end if;                     /* }} */

    set xvid = ( select vid from users where uid = xuid );

    set xseq = ( select ifnull(max(delta)+1,0) from field_data_field_addresses where entity_id = xuid );

    select 'Test address migration' as `Action`,
            xuid                    as `UID`,
            xvid                    as `VID`,
            xseq                    as `Delta`,
            dry_run                 as `Dry Run?`,
            wrap_transaction        as `Use Transaction?`,
            do_commit               as `Commit Transaction?`;

    call add_collection_item('field_addresses', xiid, xrid, xuuid);

    select 'Collection item added' as `Action`, xiid as `ItemID`, xrid as `Item Revision`;

    select 'Step 1' as `Action`, 'field_data_field_addresses' as `Table`,
           'user' as `entity_type`, 'user' as `bundle`,
           false as `deleted`, xuid as `entity_id`, xvid as `revision_id`,
           @deflang as `language`, xseq as `delta`, xiid as `field_addresses_value`,
           xrid as `field_addresses_revision_id`;

    insert into field_data_field_addresses
                ( entity_type, bundle, deleted, entity_id, revision_id, language, delta, field_addresses_value, field_addresses_revision_id )
         values ( 'user',      'user', false,   xuid,      xvid,        @deflang, xseq,  xiid,                  xrid );
    insert into field_revision_field_addresses
         select *
           from field_data_field_addresses
          where entity_id = xuid
            and revision_id = xvid
            and delta = xseq;

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

    declare xiid integer unsigned default 0;
    declare xrid integer unsigned default 0;
    declare xuuid varchar(36) default 'xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx';
    declare xseq integer unsigned default 0;

    declare auid             integer unsigned;
    declare avid             integer unsigned;
    declare aslot            bigint(20);
    declare alanguage        varchar(32);
    declare address          text;
    declare adata            longtext;
    declare ause_as_physical boolean;
    declare ause_as_postal   boolean;

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
           dry_run                                              as `Dry run?`,
           wrap_transaction                                     as `Use transaction?`,
           do_commit                                            as `Commit transaction?`,
           inner_action_mode                                    as `Inner transaction mode`;

    if wrap_transaction then    /* {{ */
        start transaction;  /* [[ */
    end if;                     /* }} */

    if purge_first then
        call purge_user_addresses( xuid, inner_action_mode );
    end if;

    /******************************************************************************/

    open user_address_slots;
    set get_address_finished = false;
    get_address: loop

        fetch user_address_slots
              into auid,
                   avid,
                   aslot,
                   alanguage,
                   address,
                   adata,
                   ause_as_physical,
                   ause_as_postal;

        set xseq = (
            select ifnull(max(delta)+1,0)
              from field_data_field_addresses
             where entity_id = xuid );

        if get_address_finished then    /* {{ */
    leave get_address;
        end if;                         /* }} */

        call add_collection_item('field_addresses', xiid, xrid, xuuid);

        select 'field_collection_item'  as `Inserted`,
                xiid                    as `Collection Item ID`,
                xrid                    as `Collection Item Revision`,
                xseq                    as `Collection Item Delta`;

        select would_insert as `Action`,
               xiid                          as item_id,                   /* == field_addresses_value       */
               xrid                          as revision_id,               /* == field_addresses_revision_id */
               'field_addresses'             as field_name,
               false                         as archived,
               'as-yet-unknown random UUID'  as uuid
          from export_user_addresses2
          join users on address_uid = uid
                    and address_vid = vid
         where uid = xuid;

        select 'field_data_field_addresses' as `Inserting`;

        select would_insert as `Action`,
               'user'                        as entity_type,
               'user'                        as bundle,
               false                         as deleted,
               uid                           as entity_id,      /* == users.uid */
               vid                           as revision_id,    /* == users.vid */
               'und'                         as language,
               xseq                          as delta,
               xiid                          as field_addresses_value,
               xrid                          as field_addresses_revision_id
          from export_user_addresses2
          join users on address_uid = uid
                    and address_vid = vid
         where address_uid = xuid
         limit 9;

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
                      auid,     /* entity_id   == users.uid */
                      avid,     /* revision_id == users.vid */
                      'und',    /* language */
                      xseq,     /* delta */
                      xiid,     /* field_addresses_value */
                      xrid );   /* field_addresses_revision_id */

        set xseq = xseq+1;

        select 'field_revision_field_addresses' as `Inserting`;

        select 'COPY',
               field_data_field_addresses.*
          from field_data_field_addresses
         where field_addresses_value = xiid
         limit 9;

        insert into field_revision_field_addresses
        select *
          from field_data_field_addresses
         where field_addresses_value = xiid;

        select 'field_data_field_user_address' as `Inserting`;

        select would_insert as `Action`,
               'field_collection_item'       as entity_type,
               'field_addresses'             as bundle,
               false                         as deleted,
               xiid                          as entity_id,                /* == field_addresses_value       */
               xrid                          as revision_id,              /* == field_addresses_revision_id */
               'und'                         as language,
               0                             as delta,                    /* == 0 (single-valued) */
               address                       as field_user_address_value, /* field_user_address_value (the preformatted address) */
               null                          as field_user_address_format /* field_user_address_format */
          from export_user_addresses2
          join users on address_uid = uid
                    and address_vid = vid
         where uid = xuid;

        insert into field_data_field_user_address (
                                                entity_type,
                                                bundle,
                                                deleted,
                                                entity_id,
                                                revision_id,
                                                language,
                                                delta,
                                                field_user_address_value,
                                                field_user_address_format )
        select 'field_collection_item'       as entity_type,
               'field_addresses'             as bundle,
               false                         as deleted,
               xiid                          as entity_id,                /* == field_addresses_value       */
               xrid                          as revision_id,              /* == field_addresses_revision_id */
               'und'                         as language,
               0                             as delta,                    /* == 0 (single-valued) */
               address                       as field_user_address_value, /* field_user_address_value (the preformatted address) */
               null                          as field_user_address_format /* field_user_address_format */
          from export_user_addresses2
          join users on address_uid = uid
                    and address_vid = vid
         where uid = xuid;

        select 'field_revision_field_user_address' as `Inserting`;

        select 'COPY',
               field_data_field_user_address.*
          from field_data_field_user_address
         where ENTITY_ID = xiid
         limit 9;

        insert into field_revision_field_user_address
        select *
          from field_data_field_user_address
         where entity_id = xiid;

        select 'field_data_field_use_as_postal_address' as `Inserting`;

        select would_insert as `Action`,
               'field_collection_item'       as entity_type,
               'field_addresses'             as bundle,
               false                         as deleted,
               xiid                          as entity_id,              /* == field_addresses_value */
               xrid                          as revision_id,            /* == field_addresses_revision_id */
               'und'                         as language,
               0                             as delta,                  /* == 0 (single-valued) */
               address_use_as_postal         as field_use_as_postal_address_value /* (always true) */
          from export_user_addresses2
          join users on address_uid = uid
                    and address_vid = vid
           and address_use_as_postal
         where uid = xuid
         limit 9;

        insert into field_data_field_use_as_postal_address (
                                                entity_type,
                                                bundle,
                                                deleted,
                                                entity_id,
                                                revision_id,
                                                language,
                                                delta,
                                                field_use_as_postal_address_value )
        select 'field_collection_item'       as entity_type,
               'field_addresses'             as bundle,
               false                         as deleted,
               xiid                          as entity_id,              /* == field_addresses_value */
               xrid                          as revision_id,            /* == field_addresses_revision_id */
               'und'                         as language,
               0                             as delta,                  /* == 0 (single-valued) */
               address_use_as_postal         as field_use_as_postal_address_value /* (always true) */
          from export_user_addresses2
          join users on address_uid = uid
                    and address_vid = vid
           and address_use_as_postal
         where uid = xuid;

        select 'field_revision_field_use_as_postal_address' as `Inserting`;

        select 'COPY',
               field_data_field_use_as_postal_address.*
          from field_data_field_use_as_postal_address
         where entity_id = xiid
         limit 9;

        insert into field_revision_field_use_as_postal_address
        select *
          from field_data_field_use_as_postal_address
         where entity_id = xiid;

    end loop get_address;
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
