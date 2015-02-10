#!/module/for/bash

# Usage:
#   . $HOME/Quakers/lib/qlib.bash

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

set -x

shopt -s extglob
true=1 false=0

printf >&2 "DEBUG-source: %s\n" "${BASH_SOURCE[@]}"

# find path to directory containing *this* file
libdir=${BASH_SOURCE%%+([^/])}
qdir=${libdir%%+([^/])/}
dbdir=${qdir}db/

printf >&2 "DEBUG: libdir = '%s'\n" "$libdir"
printf >&2 "DEBUG: qdir = '%s'\n" "$qdir"
printf >&2 "DEBUG: dbdir = '%s'\n" "$dbdir"

# templates for the filenames for archived downloads
pT="${dbdir}profile-%(%Y%m%d)T.csv" # for gmail.com distrodude downloads
gT="${dbdir}google-%(%Y%m%d)T.csv"  # for quaker.org.nz all_members downloads

dldirs=( $HOME/Downloads/ )

printf -v baseline_snapshot  "$pT" 1393541773   # baseline comparison file (first snapshot)
printf -v greenbook_snapshot "$pT" 1402216718   # snapshot on which the Green Book was based

set_current_vars() {
    # update time-related vars to reflect "now" or "today"
    printf -v now '%(%s)T' -1
    printf -v current_gmail "$gT" $now      # today's gmail.com distrodude download
    printf -v current_profile "$pT" $now    # today's quaker.org.nz profile download
}
set_current_vars

# make sure any new downloads are filed in proper locations
file_downloads() {
    local delay=false f t tt fmt
    while IFS=$'\t' read -d '' t f
    do
        case /$f in
        (*"${dbdir:-//SKIP//}"*)    # don't move any files which are already under $dbdir
                                    continue ;;
        (*/google*.csv)             fmt=$gT ;;  # gmail download
        (*/all_members*.csv)        fmt=$pT ;;  # profile download
        (*/profile*.csv)            fmt=$pT ;;  # profile download
        (*)                         printf "Skipping '%s'\n" "$f"
                                    continue ;;
        esac
        printf -v tt "$fmt" "$t" &&
        [[ -s "$f" ]] && {
            delay=true
            mv -vb "$f" "$tt"
        }
    done < <(
        find "${dldirs[@]}" -maxdepth 1 \( -name google\*.csv -o -name all_members\*.csv \) -mtime -30 -printf '%Ts\t%p\0'
    )
    ((delay)) && sleep 1.25

    return 0
}

set +x
