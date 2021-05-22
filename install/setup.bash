#!/bin/bash

declare -ri true=1 false=0

die() {
    # mostly copied from sysexits.h
    EX_STATUS=$? EX_USAGE=64 EX_NOINPUT=66 EX_OSFILE=72 EX_INTERNAL=96
    exit_code=$1 ; shift
    if [[ $* ]] ; then
        [[ $1 != *[%\\]* ]] && { IFS=' ' ; set -- '%s\n' "$*" ; } ||
        [[ $1 = *'\n' || $1 = *$'\n' ]] || set -- "$1\\n" "${@:2}"
        printf >&2 "$@"
    fi
    exit $((exit_code))
}

argv0=$( readlink -e "$0" ) || die EX_OSFILE "Cannot locate $0"
dir=${argv0%"${argv0##*/}"}
[[ $dir = /*/ ]] || die EX_INTERNAL "$argv0 is not absolute, from $0"

dry_run=false
gen_drop=false
gen_summary=false
one_by_one=false

for ((;$#;)) do
    case $1 in
        -1|--one-by-one)    one_by_one=true ;;
        -d|--gen-drop)      gen_drop=true ;;
        -s|--gen-summary)   gen_summary=true ;;
        -n|--dry_run)       dry_run=true ;;
        -*) die EX_USAGE "Invalid option '%1'" ;;
        *)  break ;;
    esac
    shift
done

(($#)) && die EX_USAGE "Non-option args not allowed"

cd "$dir" || die EX_NOINPUT "Can't cd $dir"

if (( gen_drop )) ; then

    f=000_dropall.sql
    {
    printf "show tables like '%s%%';\n" exp exd qdb |
    mysql quakers |
    sort -u |
    sed -e "
        /^Tables_in/d ;
        /^exdata_/bt ;
        /^expmap_/bt ;
        /^qdbt_/bt ;
        /^exp[0-9]*_/bv ;
        /^export_/bv ;
        /^qdbv_/bv ;
        d;
        s@.*@/* & */@ ; p ; d ;

    :t; s/.*/ select '&' as \`dropping table\`; drop table \`&\`;/ ; p ; d ;
    :v; s/.*/ select '&' as \`dropping view\`;  drop view \`&\`;/  ; p ; d ;
    "
    } > "$f"
fi

[[ -s 000_dropall.sql ]] || rm -v 000_dropall.sql

(( dry_run )) ||
if (( one_by_one )) ; then
    for f in *.sql
    do
        printf 'RUNNING %s\n' "$f"
        mysql quakers < "$f" || exit
    done
else
    printf 'RUNNING %s\n' "*.sql"
    mysql quakers < <( cat *.sql )
fi

if (( gen_summary )) ; then

    t='$summary'
    f=999_summary.sql
    {
    printf "select '%s' as \`creating\`;\n" "$t"

    echo "create or replace view \`$t\` as"
    mysql 2>/dev/null quakers <<< 'show tables;' |
    tee >( n=$( wc -l ) ; sleep 5 ; printf "       select %-50sas table_name, %8u as num_rows\n" "'$t'" "$n" >&3 ) |
     sed -e "/^Tables_in_/d;
             /${t//'$'}/d;
             s#.*# union select '&'\tas table_name, count(*) as num_rows from &#" |
      sort | expand -t 64
    echo ";"
    } >"$f" 3>&1

    (( dry_run )) ||
        mysql quakers < "$f" || exit
fi
