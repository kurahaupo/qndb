#!/module/for/bash

# Usage:
#   . $HOME/Quakers/lib/qlib.bash

# shellcheck disable=SC2034
die() {
    STATUS=$?       EX_STATUS=STATUS
    OK=0            EX_OK=OK
    FAIL=1          EX_FAIL=FAIL
    USAGE=64        EX_USAGE=USAGE
    DATAERR=65      EX_DATAERR=DATAERR
    NOINPUT=66      EX_NOINPUT=NOINPUT
    NOUSER=67       EX_NOUSER=NOUSER
    NOHOST=68       EX_NOHOST=NOHOST
    UNAVAILABLE=69  EX_UNAVAILABLE=UNAVAILABLE
    SOFTWARE=70     EX_SOFTWARE=SOFTWARE
    OSERR=71        EX_OSERR=OSERR
    OSFILE=72       EX_OSFILE=OSFILE
    CANTCREAT=73    EX_CANTCREAT=CANTCREAT
    IOERR=74        EX_IOERR=IOERR
    TEMPFAIL=75     EX_TEMPFAIL=TEMPFAIL
    PROTOCOL=76     EX_PROTOCOL=PROTOCOL
    NOPERM=77       EX_NOPERM=NOPERM
    CONFIG=78       EX_CONFIG=CONFIG
    NOEXEC=127      EX_NOEXEC=NOEXEC
    SIGHUP=1+128    SIGFPE=8+128    SIGSTKFLT=16+128 SIGXCPU=24+128
    SIGINT=2+128    SIGKILL=9+128   SIGCHLD=17+128   SIGXFSZ=25+128
    SIGQUIT=3+128   SIGUSR1=10+128  SIGCONT=18+128   SIGVTALRM=26+128
    SIGILL=4+128    SIGSEGV=11+128  SIGSTOP=19+128   SIGPROF=27+128
    SIGTRAP=5+128   SIGUSR2=12+128  SIGTSTP=20+128   SIGWINCH=28+128
    SIGABRT=6+128   SIGPIPE=13+128  SIGTTIN=21+128   SIGIO=29+128
    SIGIOT=6+128    SIGALRM=14+128  SIGTTOU=22+128   SIGPWR=30+128
    SIGBUS=7+128    SIGTERM=15+128  SIGURG=23+128    SIGSYS=31+128
    (( _e = $1 ))
    shift
    (($#)) && echo >&2 "$@"
    exit $_e
}

shopt -s extglob
# shellcheck disable=SC2034
# (values used indirectly in numeric context)
true=1 false=0

sprintf() { printf -v "$@" ; }

printf >&2 "DEBUG-source: %s\n" "${BASH_SOURCE[@]}"

# find path to directory containing *calling* file
self=$(readlink -e "${BASH_SOURCE[1]}" 2>/dev/null) || self="${BASH_SOURCE[1]}"
bindir=${self%%+([^/])}
libdir=${bindir%bin/}lib/
# find path to directory containing data, hopefully
for dbdir in "$dbdir" \
             "${libdir%%+([^/])/}db/" \
             "${BASH_SOURCE[1]%%+([^/])/+([^/])}db/" \
             "${BASH_SOURCE[0]%%+([^/])/+([^/])}db/" \

do [[ -n $dbdir && -d $dbdir ]] && break ; false ; done || die EX_OSERR "Missing db dir"

printf >&2 "DEBUG: libdir = '%s'\n" "$libdir"
printf >&2 "DEBUG: dbdir = '%s'\n" "$dbdir"

# templates for the filenames for archived downloads
gT="${dbdir}google-%(%Y%m%d)T.csv"  # for gmail.com distrodude downloads
pT="${dbdir}profile-%(%Y%m%d)T.csv" # for quaker.org.nz all_members downloads
uT="${dbdir}users-%(%Y%m%d)T.csv"   # for quakers.nz users downloads

dldirs=( "$HOME/Downloads/" )

sprintf baseline_snapshot  "$pT" 1393541773   # baseline comparison file (first snapshot)
sprintf greenbook_snapshot "$pT" 1402216718   # snapshot on which the Green Book was based

set_current_vars() {
    # update time-related vars to reflect "now" or "today"
    sprintf now '%(%s)T' -1
    sprintf current_gmail "$gT" "$now"    # today's gmail.com distrodude download
    sprintf current_profile "$pT" "$now"  # today's quaker.org.nz profile download
}
set_current_vars

# make sure any new downloads are filed in proper locations
file_downloads() {
    local -a age_limit=( -mtime -30 )
    while (($#)) ; do
        case $1 in
            --help) printf >&2 'Usage: files_download [--max-age=DAYS]\n' ; return 0 ;;
            --no-max-age) age_limit=() ;;
            --max-age=*) age_limit=( -mtime "-${1#*=}" ) ;;
            -m?*) age_limit=( -mtime "-${1:2}" ) ;;
            -m) age_limit=( -mtime "-$2" ) ; shift ;;
            --) shift ; break ;;
            -?*) printf >&2 'files_download: invalid option "%s"\n' "$1" ; return 1 ;;
            *) break ;;
        esac
        shift
    done
    (($#)) && {
        printf >&2 'files_download: non-option args not allowed\n'
        return 1
    }
    local delay=false f t tt fmt
    while IFS=$'\t' read -d '' t f
    do
        case /$f in
        (*"${dbdir:-//SKIP//}"*)    # don't move any files which are already under $dbdir
                                    continue ;;
        (*/contacts*.csv)           fmt=$gT ;;  # gmail download (new from 2019)
        (*/google*.csv)             fmt=$gT ;;  # gmail download (old until 2018) or previously downloaded
        (*/all_members*.csv)        fmt=$pT ;;  # profile current download (old until 2019)
        (*/profile*.csv)            fmt=$pT ;;  # profile previously downloaded (old until 2019)
        (*/users*.csv)              fmt=$uT ;;  # users download (new from 2020)
        (*)                         printf "Skipping '%s'\n" "$f"
                                    continue ;;
        esac
        sprintf tt "$fmt" "$t" &&
        [[ -s "$f" ]] && {
            delay=true
            mv -vb "$f" "$tt"
        }
    done < <(
        find "${dldirs[@]}" -maxdepth 1 \( -name users\*.csv -o -name contacts\*.csv -o -name google\*.csv -o -name all_members\*.csv \) "${age_limit[@]}" -printf '%Ts\t%p\0'
    )
    ((delay)) && sleep 1.25

    return 0
}
