/* Create experl_user_kin view */

select 'NEW VIEWS' as `CREATING `;

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
        where not symmetric
;

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
       from experl_user_kin as k1
       join expmap_reverse_relations as rr  on k1.kin_rel_type = rr.fwd_rel
  left join experl_user_kin          as k2  on rr.rev_rel  = k2.kin_rel_type
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
