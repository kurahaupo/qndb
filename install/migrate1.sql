/*SET autocommit=0;   /* don't actually make changes until COMMIT is used */

set @deflang = 'und';

/*
 *  Turns out we need ADMIN access to create a function,
 *  but not to create a stored procedure; go figure...
 */

delimiter ';;'

create or replace procedure add_collection_item( out o_iid integer unsigned,
                                                 out o_rid integer unsigned,
                                                 out o_uuid varchar(36) )
        modifies sql data
        sql security invoker
begin
    /* why is this so messy? */
    select uuid() into o_uuid ;
    insert into field_collection_item
            (item_id, revision_id, field_name,        archived, uuid)
     values (null,    0,           'field_addresses', false,    o_uuid) ;
    select last_insert_id() into o_iid ;
    /* select o_iid as `new IID` ; /**/
    /* select 'FIRST' as `Seq`, field_collection_item.* from field_collection_item where item_id = o_iid ; /**/
    insert into field_collection_item_revision
            (revision_id, item_id)
     values (null,        o_iid) ;
    select last_insert_id() into o_rid ;
    /* select o_rid as `new RID` ; /**/
    update field_collection_item set revision_id = o_rid where item_id = o_iid ; /**/
    /* select 'SECOND' as `Seq`, field_collection_item.* from field_collection_item where item_id = o_iid ; /**/
end
;;

create or replace procedure test_add_collection_item()
        modifies sql data
        sql security invoker
begin
    declare xiid integer unsigned ;
    declare xrid integer unsigned ;
    declare xuuid varchar(40) ;
    call add_collection_item(xiid, xrid, xuuid) ;
    select xiid  as `new item_id`,
           xrid  as `new revision_id`,
           xuuid as `new uuid` ;
end
;;

create or replace procedure purge_test_data( in dry_run boolean,
                                             in do_commit boolean )
        modifies sql data
        sql security invoker
begin
    declare would_delete varchar(16) default 'Delete' ;

    start transaction ;

    select 'Purge test data' as `Run Stored Procedure`,
           dry_run           as `Dry Run?` ;

    if dry_run then
        select 'Propose deletion' into would_delete ;
    end if ;

    select would_delete as `Action`,
                   'field_data_field_label'     as `Table`, count(*) as `Rows`
               from field_data_field_label     where bundle = 'field_addresses'
    union
    select would_delete as `Action`,
                   'field_revision_field_label' as `Table`, count(*) as `Rows`
               from field_revision_field_label where bundle = 'field_addresses' ;
    if dry_run then
        select 'DELETE' as `Action`, field_data_field_label.*     from field_data_field_label     where bundle = 'field_addresses' limit 9 ;
        select 'DELETE' as `Action`, field_revision_field_label.* from field_revision_field_label where bundle = 'field_addresses' limit 9 ;
    else
        delete from field_data_field_label     where bundle = 'field_addresses' ;
        delete from field_revision_field_label where bundle = 'field_addresses' ;
    end if ;

    select would_delete as `Action`,
                   'field_data_field_user_address'     as `Table`, count(*) as `Rows`
               from field_data_field_user_address     where bundle = 'field_addresses'
    union
    select would_delete as `Action`,
                   'field_revision_field_user_address' as `Table`, count(*) as `Rows`
               from field_revision_field_user_address where bundle = 'field_addresses' ;
    if dry_run then
        select 'DELETE' as `Action`, field_data_field_user_address.*     from field_data_field_user_address     where bundle = 'field_addresses' limit 9 ;
        select 'DELETE' as `Action`, field_revision_field_user_address.* from field_revision_field_user_address where bundle = 'field_addresses' limit 9 ;
    else
        delete from field_data_field_user_address     where bundle = 'field_addresses' ;
        delete from field_revision_field_user_address where bundle = 'field_addresses' ;
    end if ;

    select would_delete as `Action`,
                   'field_data_field_use_as_postal_address'     as `Table`, count(*) as `Rows`
               from field_data_field_use_as_postal_address     where bundle = 'field_addresses'
    union
    select would_delete as `Action`,
                   'field_revision_field_use_as_postal_address' as `Table`, count(*) as `Rows`
               from field_revision_field_use_as_postal_address where bundle = 'field_addresses' ;
    if dry_run then
        select 'DELETE' as `Action`, field_data_field_use_as_postal_address.*     from field_data_field_use_as_postal_address     where bundle = 'field_addresses' limit 9 ;
        select 'DELETE' as `Action`, field_revision_field_use_as_postal_address.* from field_revision_field_use_as_postal_address where bundle = 'field_addresses' limit 9 ;
    else
        delete from field_data_field_use_as_postal_address     where bundle = 'field_addresses' ;
        delete from field_revision_field_use_as_postal_address where bundle = 'field_addresses' ;
    end if ;

    select would_delete as `Action`,
                   'field_data_field_addresses'     as `Table`, count(*) as `Rows`
               from field_data_field_addresses     where bundle = 'field_addresses'
    union
    select would_delete as `Action`,
                   'field_revision_field_addresses' as `Table`, count(*) as `Rows`
               from field_revision_field_addresses where bundle = 'field_addresses' ;
    if dry_run then
        select 'DELETE' as `Action`, field_data_field_addresses.*     from field_data_field_addresses     where bundle = 'field_addresses' limit 9 ;
        select 'DELETE' as `Action`, field_revision_field_addresses.* from field_revision_field_addresses where bundle = 'field_addresses' limit 9 ;
    else
        delete from field_data_field_addresses     where bundle = 'field_addresses' ;
        delete from field_revision_field_addresses where bundle = 'field_addresses' ;
    end if ;

    select would_delete as `Action`,
                   'field_data_field_print_in_book'     as `Table`, count(*) as `Rows`
               from field_data_field_print_in_book     where bundle = 'field_addresses'
    union
    select would_delete as `Action`,
                   'field_revision_field_print_in_book' as `Table`, count(*) as `Rows`
               from field_revision_field_print_in_book where bundle = 'field_addresses' ;
    if dry_run then
        select 'DELETE' as `Action`, field_data_field_print_in_book.*     from field_data_field_print_in_book     where bundle = 'field_addresses' limit 9 ;
        select 'DELETE' as `Action`, field_revision_field_print_in_book.* from field_revision_field_print_in_book where bundle = 'field_addresses' limit 9 ;
    else
        delete from field_data_field_print_in_book     where bundle = 'field_addresses' ;
        delete from field_revision_field_print_in_book where bundle = 'field_addresses' ;
    end if ;

    select would_delete as `Action`,
                   'field_collection_item'          as `Table`, count(*) as `Rows`
               from field_collection_item where field_name = 'field_addresses'
               union
    select would_delete as `Action`,
                   'field_collection_item_revision' as `Table`, count(*) as `Rows` from field_collection_item_revision where item_id in ( select item_id
               from field_collection_item where field_name = 'field_addresses' ) ;
    if dry_run then
        select 'DELETE' as `Action`, field_collection_item_revision.* from field_collection_item_revision where item_id in ( select item_id
                                                                      from field_collection_item where field_name = 'field_addresses' ) limit 9 ;
        select 'DELETE' as `Action`, field_collection_item.*          from field_collection_item where field_name = 'field_addresses' limit 9 ;
    else
        delete from field_collection_item_revision where item_id in ( select item_id
               from field_collection_item where field_name = 'field_addresses' ) ;
        delete from field_collection_item where field_name = 'field_addresses' ;
    end if ;

    if do_commit
    then
        commit ;
    else
        rollback ;
    end if ;

end
;;

create or replace procedure purge_user_addresses( in muid integer unsigned,
                                                  in dry_run boolean,
                                                  in do_commit boolean,
                                                  in as_transaction boolean )
        modifies sql data
        sql security invoker
begin

    declare would_delete varchar(16) default 'Delete' ;

    if dry_run then
        select 'Propose deletion' into would_delete ;
    end if ;

    if as_transaction then
        start transaction ;
    end if ;

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
                                  and entity_id   = muid
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
                                  and entity_id   = muid
                             ) ;

    if dry_run then

        select 'DELETE' as `Action`,
               field_revision_field_user_address.*
          from field_revision_field_user_address
         where entity_type = 'field_collection_item'
           and bundle      = 'field_addresses'
           and entity_id  in (
                               select field_addresses_value
                                 from field_revision_field_addresses
                                where entity_type = 'user'
                                  and bundle      = 'user'
                                  and entity_id   = muid
                             )
         limit 9 ;
            /* or entity_id > 0x20000000 */

        select 'DELETE' as `Action`,
               field_data_field_user_address.*
          from field_data_field_user_address
         where entity_type = 'field_collection_item'
           and bundle      = 'field_addresses'
           and entity_id  in (
                               select field_addresses_value
                                 from field_data_field_addresses
                                where entity_type = 'user'
                                  and bundle      = 'user'
                                  and entity_id   = muid
                             )
         limit 9 ;
             /* or entity_id > 0x20000000 */

    else

        delete
          from field_revision_field_user_address
         where entity_type = 'field_collection_item'
           and bundle      = 'field_addresses'
           and entity_id  in (
                                    select field_addresses_value
                                      from field_revision_field_addresses
                                     where entity_type = 'user'
                                       and bundle      = 'user'
                                       and entity_id   = muid
                                  ) ;
            /* or entity_id > 0x20000000 */

        delete
          from field_data_field_user_address
         where entity_type = 'field_collection_item'
           and bundle      = 'field_addresses'
           and entity_id  in (
                               select field_addresses_value
                                 from field_data_field_addresses
                                where entity_type = 'user'
                                  and bundle      = 'user'
                                  and entity_id   = muid
                             ) ;
            /* or entity_id > 0x20000000 */

    end if ;

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
                                  and entity_id   = muid
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
                                  and entity_id   = muid
                             ) ;

    if dry_run then

        select 'DELETE',
               field_data_field_use_as_postal_address.*
          from field_data_field_use_as_postal_address
         where entity_type = 'field_collection_item'
           and bundle      = 'field_addresses'
           and entity_id  in (
                               select field_addresses_value
                                 from field_data_field_addresses
                                where entity_type = 'user'
                                  and bundle      = 'user'
                                  and entity_id   = muid
                             )
         limit 9 ;
             /* or entity_id > 0x20000000 */

        select 'DELETE',
               field_revision_field_use_as_postal_address.*
          from field_revision_field_use_as_postal_address
         where entity_type = 'field_collection_item'
           and bundle      = 'field_addresses'
           and entity_id  in (
                               select field_addresses_value
                                 from field_revision_field_addresses
                                where entity_type = 'user'
                                  and bundle      = 'user'
                                  and entity_id   = muid
                             )
         limit 9 ;
            /* or entity_id > 0x20000000 */

    else

        delete
          from field_data_field_use_as_postal_address
         where entity_type = 'field_collection_item'
           and bundle      = 'field_addresses'
           and entity_id  in (
                               select field_addresses_value
                                 from field_data_field_addresses
                                where entity_type = 'user'
                                  and bundle      = 'user'
                                  and entity_id   = muid
                             ) ;
             /* or entity_id > 0x20000000 */

        delete
          from field_revision_field_use_as_postal_address
         where entity_type = 'field_collection_item'
           and bundle      = 'field_addresses'
           and entity_id  in (
                               select field_addresses_value
                                 from field_revision_field_addresses
                                where entity_type = 'user'
                                  and bundle      = 'user'
                                  and entity_id   = muid
                             ) ;
             /* or entity_id > 0x20000000 */

    end if ;

    /**************/

    select would_delete as `Action`,
              'field_collection_item_revision' as `Table`, count(*) as `Rows`
          from field_collection_item_revision
         where item_id in (
                           select field_addresses_value
                             from field_data_field_addresses
                            where entity_type = 'user'
                              and bundle      = 'user'
                              and entity_id   = muid
                          ) ;

    if dry_run then

        select 'DELETE',
               field_collection_item_revision.*
          from field_collection_item_revision
         where item_id in (
                           select field_addresses_value
                             from field_data_field_addresses
                            where entity_type = 'user'
                              and bundle      = 'user'
                              and entity_id   = muid
                          )
         limit 9 ;

    else

        delete
          from field_collection_item_revision
         where item_id in (
                           select field_addresses_value
                             from field_data_field_addresses
                            where entity_type = 'user'
                              and bundle      = 'user'
                              and entity_id   = muid
                          ) ;

    end if ;

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
                                  and entity_id   = muid
                            ) ;

    if dry_run then

        select 'DELETE',
               field_collection_item.*
          from field_collection_item
         where field_name = 'field_addresses'
           and item_id   in (
                               select field_address_value
                                 from field_data_field_addresses
                                where entity_type = 'user'
                                  and bundle      = 'user'
                                  and entity_id   = muid
                            )
         limit 9 ;

    else

        delete
          from field_collection_item
         where field_name = 'field_addresses'
           and item_id in (
                           select field_addresses_value
                             from field_data_field_addresses
                            where entity_type = 'user'
                              and bundle      = 'user'
                              and entity_id   = muid
                          ) ;
            /* or item_id >= 0x20000000 */

    end if ;

    /**************/

    select would_delete as `Action`,
              'field_revision_field_addresses' as `Table`, count(*) as `Rows`
          from field_revision_field_addresses
         where entity_type = 'user'
           and bundle      = 'user'
           and entity_id   = muid
    union
    select would_delete as `Action`,
              'field_data_field_addresses' as `Table`, count(*) as `Rows`
          from field_data_field_addresses
         where entity_type = 'user'
           and bundle      = 'user'
           and entity_id   = muid
    ;

    if dry_run then

        select 'DELETE',
               field_revision_field_addresses.*
          from field_revision_field_addresses
         where entity_type = 'user'
           and bundle      = 'user'
           and entity_id   = muid
         limit 9 ;

        select 'DELETE' as `Action`,
               field_data_field_addresses.*
          from field_data_field_addresses
         where entity_type = 'user'
           and bundle      = 'user'
           and entity_id   = muid
          limit 9 ;

    else

        delete
          from field_revision_field_addresses
         where entity_type = 'user'
           and bundle      = 'user'
           and entity_id   = muid ;

        delete
          from field_data_field_addresses
         where entity_type = 'user'
           and bundle      = 'user'
           and entity_id   = muid ;

    end if ;

    /**************/

    if as_transaction then
        if do_commit then
            commit ;
        else
            rollback ;
        end if ;
    end if ;

end
;;

create or replace procedure test_user_addresses( in dry_run boolean,
                                                 in do_commit boolean,
                                                 in as_transaction boolean )
        modifies sql data
        sql security invoker
begin

    declare xuid integer unsigned default 849 ;
    declare xvid integer unsigned default null ;
    declare xiid integer unsigned default 0 ;
    declare xrid integer unsigned default 0 ;
    declare xseq integer unsigned default 0 ;
    declare xuuid varchar(36) default 'xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx';

    if as_transaction then
        select 'Begin Transaction' as `Action`;
        start transaction ;
    end if ;

    select vid from users where uid = xuid into xvid ;

    select max(delta)+1 from field_data_field_addresses where entity_id = 849 into xseq ;

    select 'Test address migration' as `Action`, xuid as `UID`, xvid as `VID`, xseq as `Delta` ;

    call add_collection_item(xiid, xrid, xuuid);

    select 'Collection item added' as `Action`, xiid as `ItemID`, xrid as `Item Revision` ;

    select 'Step 1' as `Action`, 'field_data_field_addresses' as `Table`,
             'user' as `entity_type`, 'user' as `bundle`, false as `deleted`,
             xuid as `entity_id`, xvid as `revision_id`, @deflang as
             `language`, xseq as `delta`, xiid as `field_addresses_value`, xrid
             as `field_addresses_revision_id` ;
    insert into field_data_field_addresses
           ( entity_type, bundle, deleted, entity_id, revision_id, language, delta, field_addresses_value, field_addresses_revision_id )
    values ( 'user',      'user', false,   xuid,      xvid,        @deflang, xseq,  xiid,                  xrid) ;
    insert into field_revision_field_addresses select * from field_data_field_addresses where entity_id = xuid and revision_id = xvid and delta = xseq ;

    select 'Step 2' as `Action`, 'field_data_field_label' as `Table`,
             'field_collection_item' as `entity_type`, 'field_addresses' as
             `bundle`, false as `deleted`,   xiid as `entity_id`,      xrid as
             `revision_id`,        @deflang as `language`, 0 as `delta`,
             'Wibble' as `field_label_value` ;
    insert into field_data_field_label
           ( entity_type,             bundle,            deleted, entity_id, revision_id, language, delta, field_label_value )
    values ( 'field_collection_item', 'field_addresses', false,   xiid,      xrid,        @deflang, 0,     'Wibble' ) ;
    insert into field_revision_field_label select * from field_data_field_label where entity_id = xiid and revision_id = xrid ;

    select 'Step 3' as `Action`, 'field_data_field_user_address' as `Table`,
             'field_collection_item' as `entity_type`, 'field_addresses' as
             `bundle`, false as `deleted`,    xiid as `entity_id`,      xrid as
             `revision_id`,        @deflang as `language`, 0 as `delta`,
             concat('test-address-migration:\nuid=',xuid,', vid=',xvid,', iid=',xiid,', rid=',xrid,'\nuuid=',xuuid,'\n',now()) as `field_user_address_value`, NULL as
             `field_user_address_format` ;
    insert into field_data_field_user_address
           ( entity_type,             bundle,            deleted,  entity_id, revision_id, language, delta, field_user_address_value, field_user_address_format )
    values ( 'field_collection_item', 'field_addresses', false,    xiid,      xrid,        @deflang, 0,     'test-address-migration', NULL ) ;
    insert into field_revision_field_user_address select * from field_data_field_user_address where entity_id = xiid and revision_id = xrid ;

    select 'Step 4' as `Action`, 'field_data_field_use_as_postal_address' as `Table`,
             'field_collection_item' as `entity_type`, 'field_addresses' as
             `bundle`, false as `deleted`, xiid as `entity_id`, xrid as
             `revision_id`, @deflang as `language`, 0 as `delta`, true as
             `field_use_as_postal_address_value` ;
    insert into field_data_field_use_as_postal_address
           ( entity_type,             bundle,            deleted, entity_id, revision_id, language, delta, field_use_as_postal_address_value )
    values ( 'field_collection_item', 'field_addresses', false,   xiid,      xrid,        @deflang, 0,     true ) ;
    insert into field_revision_field_use_as_postal_address select * from field_data_field_use_as_postal_address where entity_id = xiid and revision_id = xrid ;

    select 'Step 5' as `Action`, 'field_data_field_print_in_book' as `Table`,
             'field_collection_item' as `entity_type`, 'field_addresses' as
             `bundle`, false as `deleted`,   xiid as `entity_id`,      xrid as
             `revision_id`,        @deflang as `language`, 0 as `delta`,
             true as `field_print_in_book_value` ;
    insert into field_data_field_print_in_book
           ( entity_type,             bundle,            deleted, entity_id, revision_id, language, delta, field_print_in_book_value )
    values ( 'field_collection_item', 'field_addresses', false,   xiid,      xrid,        @deflang, 0,     true ) ;
    insert into field_revision_field_print_in_book select * from field_data_field_print_in_book where entity_id = xiid and revision_id = xrid ;

    select 'Finish' as `Action`;

    if as_transaction then
        if do_commit then
            select 'Commit' as `Action`;
            commit ;
        else
            select 'Rollback' as `Action`;
            rollback ;
        end if ;
    end if ;

end
;;

create or replace procedure migrate_user_addresses( in muid integer unsigned,
                                                    in dry_run boolean,
                                                    in do_commit boolean,
                                                    in as_transaction boolean )
        modifies sql data
        sql security invoker
begin

    declare xiid integer unsigned default 0 ;
    declare xrid integer unsigned default 0 ;
    declare xuuid varchar(36) default 'xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx';

    declare would_insert varchar(17) default 'Insert' ;

    if dry_run then
        select 'Propose insertion' into would_insert ;
    end if ;

    select 'Migrate addresses from fixed blocks to flexi block' as `Run Stored Procedure`,
           muid                                                 as `Target UID`,
           dry_run                                              as `Dry Run?` ;

    if as_transaction then
        start transaction ;
    end if ;

    call purge_user_addresses( muid, dry_run, false, false ) ;

    /******************************************************************************/

    select 'field_collection_item' as `Inserting` ;

    select 'INSERT',
           vid*4+address_slot+0x20000000 as item_id,                   /* == field_addresses_value       */
           vid*4+address_slot+0x21000000 as revision_id,               /* == field_addresses_revision_id */
           'field_addresses'             as field_name,
           false                         as archived,
           'as-yet-unknown random UUID'  as uuid
      from export_user_addresses2
      join users on address_uid = uid
     where uid = muid ;

    insert into field_collection_item (
                                            item_id,
                                            revision_id,
                                            field_name,
                                            archived,
                                            uuid )
    select vid*4+address_slot+0x20000000 as item_id,                   /* == field_addresses_value       */
           vid*4+address_slot+0x21000000 as revision_id,               /* == field_addresses_revision_id */
           'field_addresses'             as field_name,
           false                         as archived,
           uuid()                        as uuid
      from export_user_addresses2
      join users on address_uid = uid
     where uid = muid ;

    insert into field_collection_item_revision (
                                           revision_id,
                                           item_id )
    select revision_id,
           item_id
      from field_collection_item
     where field_name = 'field_addresses'
       AND ITEM_ID >= 0x20000000 ;

    select 'field_data_field_addresses' as `Inserting` ;

    select 'INSERT',
           'user'                        as entity_type,
           'user'                        as bundle,
           false                         as deleted,
           uid                           as entity_id,      /* == users.uid */
           vid                           as revision_id,    /* == users.vid */
           'und'                         as language,
           address_slot-1                as delta,
           vid*4+address_slot+0x20000000 as field_addresses_value,
           vid*4+address_slot+0x21000000 as field_addresses_revision_id
      from export_user_addresses2
      join users on address_uid = uid
     WHERE ADDRESS_UID IN ( @muid )
     limit 9 ;

    insert into field_data_field_addresses (
                                             entity_type,
                                             bundle,
                                             deleted,
                                             entity_id,
                                             revision_id,
                                             language,
                                             delta,
                                             field_addresses_value,
                                             field_addresses_revision_id )
    select 'user'                        as entity_type,
           'user'                        as bundle,
           false                         as deleted,
           uid                           as entity_id,      /* == users.uid */
           vid                           as revision_id,    /* == users.vid */
           'und'                         as language,
           address_slot-1                as delta,
           vid*4+address_slot+0x20000000 as field_addresses_value,
           vid*4+address_slot+0x21000000 as field_addresses_revision_id
      from export_user_addresses2
      join users on address_uid = uid
     WHERE ADDRESS_UID IN ( @muid ) ;

    select 'field_revision_field_addresses' as `Inserting` ;

    select 'COPY',
           field_data_field_addresses.*
      from field_data_field_addresses
     WHERE field_addresses_value >= 0x20000000
     limit 9 ;

    insert into field_revision_field_addresses
    select *
      from field_data_field_addresses
     WHERE field_addresses_value >= 0x20000000 ;

    select 'field_data_field_user_address' as `Inserting` ;

    select 'INSERT',
           'field_collection_item'       as entity_type,
           'field_addresses'             as bundle,
           false                         as deleted,
           vid*4+address_slot+0x20000000 as entity_id,                /* == field_addresses_value       */
           vid*4+address_slot+0x21000000 as revision_id,              /* == field_addresses_revision_id */
           'und'                         as language,
           0                             as delta,                    /* == 0 (single-valued) */
           address                       as field_user_address_value, /* field_user_address_value (the preformatted address) */
           null                          as field_user_address_format /* field_user_address_format */
      from export_user_addresses2
      join users on address_uid = uid
     where uid = muid ;

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
           vid*4+address_slot+0x20000000 as entity_id,                /* == field_addresses_value       */
           vid*4+address_slot+0x21000000 as revision_id,              /* == field_addresses_revision_id */
           'und'                         as language,
           0                             as delta,                    /* == 0 (single-valued) */
           address                       as field_user_address_value, /* field_user_address_value (the preformatted address) */
           null                          as field_user_address_format /* field_user_address_format */
      from export_user_addresses2
      join users on address_uid = uid
     where uid = muid ;

    select 'field_revision_field_user_address' as `Inserting` ;

    select 'COPY',
           field_data_field_user_address.*
      from field_data_field_user_address
     WHERE ENTITY_ID > 0x20000000
     limit 9 ;

    insert into field_revision_field_user_address
    select *
      from field_data_field_user_address
     WHERE ENTITY_ID > 0x20000000 ;

    select 'field_data_field_use_as_postal_address' as `Inserting` ;

    select 'INSERT',
           'field_collection_item'       as entity_type,
           'field_addresses'             as bundle,
           false                         as deleted,
           vid*4+address_slot+0x20000000 as entity_id,              /* == field_addresses_value */
           vid*4+address_slot+0x21000000 as revision_id,            /* == field_addresses_revision_id */
           'und'                         as language,
           0                             as delta,                  /* == 0 (single-valued) */
           address_use_as_postal         as field_use_as_postal_address_value /* (always true) */
      from export_user_addresses2
      join users on address_uid = uid
       and address_use_as_postal
     where uid = muid
     limit 9 ;

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
           vid*4+address_slot+0x20000000 as entity_id,              /* == field_addresses_value */
           vid*4+address_slot+0x21000000 as revision_id,            /* == field_addresses_revision_id */
           'und'                         as language,
           0                             as delta,                  /* == 0 (single-valued) */
           address_use_as_postal         as field_use_as_postal_address_value /* (always true) */
      from export_user_addresses2
      join users on address_uid = uid
       and address_use_as_postal
     where uid = muid ;

    select 'field_revision_field_use_as_postal_address' as `Inserting` ;

    select 'COPY',
           field_data_field_use_as_postal_address.*
      from field_data_field_use_as_postal_address
     WHERE ENTITY_ID > 0x20000000
     limit 9 ;

    insert into field_revision_field_use_as_postal_address
    select *
      from field_data_field_use_as_postal_address
     WHERE ENTITY_ID > 0x20000000 ;

    select 'Migrate addresses from fixed blocks to flexi block' as `Completed` ;

    if as_transaction then
        if do_commit
        then
            commit ;
        else
            rollback ;
        end if ;
    end if ;

end
;;

delimiter ';'
