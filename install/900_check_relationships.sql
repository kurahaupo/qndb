/* Create experl_user_kin view */

select 'expmap_reverse_relations' as `Creating Table`;

create or replace table expmap_reverse_relations (
    fwd_rel     varchar(32) primary key,
    rev_rel     varchar(32) unique key,
    symmetric   boolean,
    many_to     boolean,
    to_many     boolean
) default character set=utf8
;
insert into expmap_reverse_relations ( fwd_rel, rev_rel, many_to, to_many )
     values ( 'child',      'parent',      true,  true  ),
            ( 'grandchild', 'grandparent', true,  true  ),
            ( 'sibling',    'sibling',     true,  true  ),
            ( 'relative',   'relative',    true,  true  ),
            ( 'whānau',     'whānau',      true,  true  ),
            ( 'spouse',     'spouse',      false, false ),
            ( 'ex-spouse',  'ex-spouse',   true,  true  )
;
update expmap_reverse_relations set symmetric = fwd_rel = rev_rel;
insert into expmap_reverse_relations
            ( fwd_rel, rev_rel, many_to, to_many, symmetric )
       select rev_rel, fwd_rel, to_many, many_to, symmetric
         from expmap_reverse_relations
        where not symmetric
;

select 'check_half_relationships' as `Creating Procedure`;

delimiter ';;'

create or replace procedure check_half_relationships()
        sql security invoker
begin
    select 'Half-linked relationships' as `Testing for`;

    select      k1.kin_uid      as uid1,
                u1.name         as name1,
                k1.kin_rel_type as fwd_rel,
                k1.kin_uid2     as uid2,
                u2.name         as name2,
                k2.kin_rel_type as rev_rel,
                k2.kin_uid2     as rev_uid1,
                u3.name         as rev_name1,
                rr.symmetric,
                if(isnull(k2.kin_uid2), 'MISSING', if(k1.kin_uid = k2.kin_uid2, 'MISMATCHED', 'OK')) as `test result`
           from experl_user_kin as k1
           join expmap_reverse_relations as rr  on k1.kin_rel_type = rr.fwd_rel
      left join experl_user_kin          as k2  on rr.rev_rel  = k2.kin_rel_type
                                               and k1.kin_uid2 = k2.kin_uid
      left join users                    as u1  on rr.rev_rel  = k1.kin_rel_type
                                               and k1.kin_uid  = u1.uid
      left join users                    as u2  on k1.kin_uid2 = u2.uid
      left join users                    as u3  on k2.kin_uid2 = u3.uid
          where k2.kin_uid2 is null
             or symmetric and k1.kin_uid != k2.kin_uid2
             or u1.uid is null
             or u2.uid is null
             or u3.uid is null
    ;

    select 'Kinds of relationships' as `Testing for`;

    select kin_rel_type,count(*) from experl_user_kin group by kin_rel_type ;
    select fwd_rel from expmap_reverse_relations ;

    select 'New kinds of relationships' as `Testing for`;

    select      k1.kin_uid      as uid,
                u1.name,
                k1.kin_rel_type as relationship,
                k1.kin_uid2     as other_uid,
                u2.name         as other_name
           from experl_user_kin as k1
           join expmap_reverse_relations as rr  on k1.kin_rel_type = rr.fwd_rel
      left join users                    as u1  on rr.rev_rel  = k1.kin_rel_type
                                               and k1.kin_uid  = u1.uid
      left join users                    as u2  on k1.kin_uid2 = u2.uid
          where kin_rel_type not in ( select fwd_rel from expmap_reverse_relations )
    ;

end
;;

delimiter ';'
