delimiter ';;'

create or replace procedure migrate_addresses( in muid integer unsigned )
begin

start transaction;

 select 'Migrate addresses from fixed blocks to flexi block' as `Action`
;

/*
 # Don't use these because truncate doesn't honour transaction boundaries
 select 'field_data_field_user_address' as `Truncating` ;
 truncate table field_data_field_user_address ;

 select 'field_data_field_use_as_postal_address' as `Truncating` ;
 truncate table field_data_field_use_as_postal_address ;

 select 'field_data_field_addresses' as `Truncating` ;
 truncate table field_data_field_addresses ;
*/

 select 'field_revision_field_user_address' as `Deleting`
;
 select 'DELETE',
        field_revision_field_user_address.*
   from field_revision_field_user_address
       where entity_type = 'field_collection_item'
         and bundle      = 'field_addresses'
         and /* entity_id  in (
                             select field_addresses_value
                               from field_revision_field_addresses
                              where entity_type = 'user'
                                and bundle      = 'user'
                                AND ENTITY_ID  IN ( @muid )
                           )
         OR*/
             ENTITY_ID > 0x20000000
  LIMIT 99
;
 delete from field_revision_field_user_address
       where entity_type = 'field_collection_item'
         and bundle      = 'field_addresses'
         and /*entity_id  in (
                             select field_addresses_value
                               from field_revision_field_addresses
                              where entity_type = 'user'
                                and bundle      = 'user'
                                AND ENTITY_ID  IN ( @muid )
                           )
         OR*/
             ENTITY_ID > 0x20000000
;

 select 'field_data_field_user_address' as `Deleting`
;
 select 'DELETE',
        field_data_field_user_address.*
   from field_data_field_user_address
       where entity_type = 'field_collection_item'
         and bundle      = 'field_addresses'
         and (entity_id  in (
                             select field_addresses_value
                               from field_data_field_addresses
                              where entity_type = 'user'
                                and bundle      = 'user'
                                AND ENTITY_ID  IN ( @muid )
                           )
           OR ENTITY_ID > 0x20000000
          )
  LIMIT 99
;
 delete from field_data_field_user_address
       where entity_type = 'field_collection_item'
         and bundle      = 'field_addresses'
         and (entity_id  in (
                             select field_addresses_value
                               from field_data_field_addresses
                              where entity_type = 'user'
                                and bundle      = 'user'
                                AND ENTITY_ID  IN ( @muid )
                           )
           OR ENTITY_ID > 0x20000000
          )
;

 select 'field_revision_field_use_as_postal_address' as `Deleting`
;
 select 'DELETE',
        field_revision_field_use_as_postal_address.*
   from field_revision_field_use_as_postal_address
       where entity_type = 'field_collection_item'
         and bundle      = 'field_addresses'
         and /*entity_id  in (
                             select field_addresses_value
                               from field_revision_field_addresses
                              where entity_type = 'user'
                                and bundle      = 'user'
                                AND ENTITY_ID  IN ( @muid )
                           )
          OR*/
             ENTITY_ID > 0x20000000
  LIMIT 99
;
 delete from field_revision_field_use_as_postal_address
       where entity_type = 'field_collection_item'
         and bundle      = 'field_addresses'
         and /*entity_id  in (
                             select field_addresses_value
                               from field_revision_field_addresses
                              where entity_type = 'user'
                                and bundle      = 'user'
                                AND ENTITY_ID  IN ( @muid )
                           )
           OR*/
             ENTITY_ID > 0x20000000
;

 select 'field_data_field_use_as_postal_address' as `Deleting`
;
 select 'DELETE',
        field_data_field_use_as_postal_address.*
   from field_data_field_use_as_postal_address
       where entity_type = 'field_collection_item'
         and bundle      = 'field_addresses'
         and (entity_id  in (
                             select field_addresses_value
                               from field_data_field_addresses
                              where entity_type = 'user'
                                and bundle      = 'user'
                                AND ENTITY_ID  IN ( @muid )
                           )
           OR ENTITY_ID > 0x20000000
          )
  LIMIT 99
;
 delete from field_data_field_use_as_postal_address
       where entity_type = 'field_collection_item'
         and bundle      = 'field_addresses'
         and (entity_id  in (
                             select field_addresses_value
                               from field_data_field_addresses
                              where entity_type = 'user'
                                and bundle      = 'user'
                                AND ENTITY_ID  IN ( @muid )
                           )
           OR ENTITY_ID > 0x20000000
          )
;

 select 'field_revision_field_addresses' as `Deleting`
;
 select 'DELETE',
        field_revision_field_addresses.*
   from field_revision_field_addresses
      where entity_type = 'user'
        and bundle      = 'user'
        AND (ENTITY_ID  IN ( @muid )
          OR FIELD_ADDRESSES_VALUE >= 0x20000000
         )
  LIMIT 99
;
 delete from field_revision_field_addresses
      where entity_type = 'user'
        and bundle      = 'user'
        AND (ENTITY_ID  IN ( @muid )
          OR FIELD_ADDRESSES_VALUE >= 0x20000000
         )
;

 select 'field_data_field_addresses' as `Deleting`
;
 select 'DELETE',
        field_data_field_addresses.*
  from field_data_field_addresses
      where entity_type = 'user'
        and bundle      = 'user'
        AND (ENTITY_ID  IN ( @muid )
          OR FIELD_ADDRESSES_VALUE >= 0x20000000
         )
  LIMIT 99
;
 delete from field_data_field_addresses
      where entity_type = 'user'
        and bundle      = 'user'
        AND (ENTITY_ID  IN ( @muid )
          OR FIELD_ADDRESSES_VALUE >= 0x20000000
         )
;

 select 'field_data_field_addresses' as `Inserting`
;
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
  limit 99
;
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
   WHERE ADDRESS_UID IN ( @muid )
;

 select 'field_revision_field_addresses' as `Inserting`
;
 select 'COPY',
        field_data_field_addresses.*
   from field_data_field_addresses
  WHERE field_addresses_value >= 0x20000000
  LIMIT 99
;
 insert into field_revision_field_addresses
 select *
   from field_data_field_addresses
  WHERE field_addresses_value >= 0x20000000
;

 select 'field_data_field_user_address' as `Inserting`
;
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
  WHERE UID IN ( @muid )
;
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
  WHERE UID IN ( @muid )
;

 select 'field_revision_field_user_address' as `Inserting`
;
 select 'COPY',
        field_data_field_user_address.*
   from field_data_field_user_address
  WHERE ENTITY_ID > 0x20000000
  LIMIT 99
;
 insert into field_revision_field_user_address
 select *
   from field_data_field_user_address
  WHERE ENTITY_ID > 0x20000000
;

 select 'field_data_field_use_as_postal_address' as `Inserting`
;
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
  WHERE UID IN ( @muid )
  LIMIT 99
;
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
  WHERE UID IN ( @muid )
;

 select 'field_revision_field_use_as_postal_address' as `Inserting`
;
 select 'COPY',
        field_data_field_use_as_postal_address.*
   from field_data_field_use_as_postal_address
  WHERE ENTITY_ID > 0x20000000
  LIMIT 99
;
 insert into field_revision_field_use_as_postal_address
 select *
   from field_data_field_use_as_postal_address
  WHERE ENTITY_ID > 0x20000000
;

 select 'Migrate addresses from fixed blocks to flexi block' as `Completed`
;

commit;

end
;;

delimiter ';'
