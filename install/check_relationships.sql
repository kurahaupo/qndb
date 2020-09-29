/* Create export_user_kin view */

/*create view export_user_kin as
        select ukin.entity_id                          as kin_uid,
               ukin.revision_id                        as kin_rev,
               ukin.language                           as kin_language,
               ukin.delta                              as kin_delta,
               ukint.field_user_kin_relationship_value as kin_rel_type,
               ukinr.field_user_kin_user_ref_target_id as kin_uid2
          from field_data_field_user_kin               as ukin
          join field_data_field_user_kin_user_ref      as ukinr  on ukinr.bundle = 'field_user_kin'
                                                                and ukinr.entity_type = 'field_collection_item'
                                                                and ukinr.deleted = 0
                                                                and ukinr.revision_id = ukin.field_user_kin_revision_id
                                                                and ukinr.entity_id = ukin.field_user_kin_value)
          join field_data_field_user_kin_relationship  as ukint  on ukint.entity_type = 'field_collection_item'
                                                                and ukint.bundle = 'field_user_kin'
                                                                and ukint.deleted = 0
                                                                and ukint.entity_id = ukin.field_user_kin_value
                                                                and ukint.revision_id = ukin.field_user_kin_revision_id
         where ukin.entity_type = 'user'
           and ukin.bundle = 'user'
           and not ukin.deleted
  union select uspo.entity_id                   as kin_uid,
               uspo.revision_id                 as kin_rev,
               uspo.language                    as kin_language,
               uspo.delta                       as kin_delta,
               'spouse'                         as kin_rel_type,
               uspo.field_user_spouse_target_id as kin_uid2
          from field_data_field_user_spouse as uspo
         where uspo.entity_type = 'user'
           and uspo.bundle      = 'user'
           and not uspo.deleted
*/

/* Reporting */
     select k1.kin_uid      as uid1,
            u1.name         as name1,
            k1.kin_rel_type as fwd_rel,
            k1.kin_uid2     as uid2,
            u2.name         as name2,
            k2.kin_rel_type as rev_rel,
            k2.kin_uid2     as rev_uid1,
            u3.name         as rev_name1,
            rr.symmetric
       from export_user_kin as k1
       join expmap_reverse_relations as rr  on k1.kin_rel_type = rr.fwd_rel
  left join export_user_kin          as k2  on rr.rev_rel  = k2.kin_rel_type
                                           and k1.kin_uid2 = k2.kin_uid
  left join users                    as u1  on rr.rev_rel  = k1.kin_rel_type
                                           and k1.kin_uid  = u1.uid
  left join users                    as u2  on k1.kin_uid2 = u2.uid
  left join users                    as u3  on k2.kin_uid2 = u3.uid
     having rev_uid1 is null
         or symmetric and uid1 != rev_uid1
         or u1.uid is null
         or u2.uid is null
         or u3.uid is null
;
