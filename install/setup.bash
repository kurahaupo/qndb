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

declare -ri yes=true no=false

declare -i dry_run=false
declare -i gen_drop=false
declare -i gen_summary=false
declare -i one_by_one=false

declare -i val=true
for ((;$#;)) do
    case $1 in
        -1|--one-by-one)    one_by_one=$val ;;
        -m|--no-one-by-one) one_by_one=!$val ;;
        -d|--gen-drop)      gen_drop=$val ;;
        -s|--gen-summary)   gen_summary=$val ;;
        -n|--dry-run)       dry_run=$val ;;

        --) shift ; break ;;
        --no-*) val=!val ; set -- "--${1:5}" "${@:2}" ; continue ;;
        -[A-Z]) val=!val ; set --   "${1,,}" "${@:2}" ; continue ;;
        -[!-]?*) set -- "${1:0:2}" "-${1:2}" "${@:2}" ; continue ;;
        -?*) die EX_USAGE "Invalid option '%1'" ;;
        *)  break ;;
    esac
    shift
    val=true
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

    :t; s/.*/ select '&' as \`Dropping Table\`; drop table if exists \`&\`;/ ; p ; d ;
    :v; s/.*/ select '&' as \`Dropping View\`;  drop view if exists \`&\`;/  ; p ; d ;
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
    printf "select '%s' as \`Creating Summary View\`;\n" "$t"

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
