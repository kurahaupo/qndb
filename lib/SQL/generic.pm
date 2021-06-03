#!/module/for/perl

# NOTE:
# This is a SQL *reader* module. It provides a structured mechanism for taking
# CLI args and using them to establish a connection to a database, and to fetch
# thence all the user data.
#
# It returns rows that are blessed into some subclass of SQL::Common; in the
# initial version that will be SQL::Drupal7::users.

use 5.010;
use strict;
use warnings;

use utf8;

package SQL::generic;

use SQL::Drupal7;

use DBI;
use Data::Dumper;
use Time::HiRes 'time';
use Carp qw( carp cluck croak confess );

use verbose;

use classref;

sub ParseDSN;

# Call this for each --sql-FOO=BAR option, and for each $QDB_FOO variable, or
# with a collection of such as key-value pairs.
# Early values take precedence over later values.
sub ParseOpts {
    my $this = $_[0] && UNIVERSAL::isa($_[0], __PACKAGE__) ? shift : __PACKAGE__;

    v && warn sprintf "BEGIN: ParseOpts with %u args %s\n", scalar(@_), Dumper(\@_);

    my $opts = shift;
    UNIVERSAL::isa($opts, 'HASH') or croak "First arg must be opts hash";

    while (@_) {
        my $arg = shift;

        v && warn sprintf "ParseOpts checking arg '%s'\n", $arg // '(undef)';

        if (ref $arg) {
            UNIVERSAL::isa($arg, 'HASH') or croak "Invalid reference parameter";
            %$opts = (%$arg, %$opts);
            next;
        }

        $arg = lc $arg;

        my $val = shift;

        if ($arg eq ';dsn') {
            carp "DEPRECATION WARNING: avoid ';dsn='\n";
            ParseDSN \%$opts, $val if $val;
            next;
        }

        if ($arg eq 'dbi') {
            $opts->{driver} //= $val;
            next;
        }

        if ($arg eq 'db' || $arg eq 'database') {
            $arg = 'dbname';
        }

        $opts->{lc $arg} //= $val;
        next;
    }

    v && warn sprintf "FINISH: ParseOpts\n";
    return ();
}

# Takes a single DSN string and splits it into parts, which are then handed to
# ParseOpts.  Do nothing if the DSN string is undef or empty, so that cascading
# rules work properly.
sub ParseDSN {

    v && warn sprintf "BEGIN: ParseDSN with %u args %s\n", scalar(@_), Dumper(\@_);

    my ($opts, $dsn) = @_;
    if ( $dsn ) {
        my ($dbi_, $driver, $args) = split /:/, $dsn, 3;
        $dbi_ eq 'dbi' or croak "Invalid DSN $dsn";
        $opts->{driver} //= $driver if $driver;
        $opts->{dsn} //= $1 if $args =~ s/;dsn=(.*)//;   # for "proxy"
        if ($args) {
            if ($args !~ /[;=]/) {
                $opts->{dbname} //= $args;
            } else {
                # This apparent mutual recursion bottoms out because ';dsn'
                # cannot be present after splitting on ';'.
                ParseOpts $opts, map { my ($x,$y) = split '=', $_, 2 } split ';', $args;
            }
        }
    }
    v && warn sprintf "FINISH: ParseDSN\n";
}

# Connect
sub Connect($\%) {
    my $class = $_[0] && UNIVERSAL::isa($_[0], __PACKAGE__)
                    ? shift
                    : __PACKAGE__;

    $class = classname $class;

    @_ == 2 or croak "Exactly 2 args required";
    my ($dsn, $opts) = @_;

    my %opts = %$opts;
    if (! $dsn || $dsn eq '-') {
        my $driver = delete $opts->{driver} // die "Missing driver";
        my $dbname = delete $opts->{dbname} // die "Missing dbname";

        $dsn  = join ':', 'dbi', $driver, $dbname;
    }

    $opts{RaiseError}  = 1;
    $opts{mysql_enable_utf8} = 1;   # doesn't seem to work
    my $user = delete $opts{user};
    my $pass = delete $opts{pass};

    my $t0 = time;

    my $dbh = eval { DBI->connect( $dsn, $user, $pass, \%opts ) }
         || do {
            my $host = $opts{host} // '(missing)' || '(empty)';
            my $port = $opts{port} // '(missing)' || '(empty or zero)';
            $pass =~ s/./X/g;
            warn "Failed to connect to $dsn on host $host port $port as $user pw $pass\n";
            warn "Opts:".Dumper(\%opts);
            confess $@;
         };

    my $t1 = time;

    my $cmd = 'SET NAMES utf8';
    my $sth = $dbh->prepare($cmd) or die "Could not prepare '$cmd':" . $dbh->errstr . "\n";

    my $t2 = time;

    $sth->execute                 or die "Could not execute '$cmd':" . $sth->errstr . "\n";

    my $t3 = time;

    warn sprintf "Connecting to [%s] took %.3fs\n"
                ."   then PREPARE took %.3fs\n"
                ."   then EXECUTE took %.3fs\n",
                $dsn,
                $t1-$t0,
                $t2-$t1,
                $t3-$t2,
            if $debug;

    return bless { dbh => $dbh }, $class;
}

sub Disconnect($) {
    my $dbx = shift;
    my $dbh = delete $dbx->{dbh};
    $dbh->disconnect if $dbh;
}

BEGIN { *DESTROY = \&Disconnect; }

sub _flatten($) { @{$_[0]} }

sub _hashify(\@$) {
    my ($F, $R) = @_;
    return map { my %r; @r{@$F} = @$_; \%r } @$R;
}

sub _fetch_rows($$$) {
    my ($dbh, $view, $class) = @_;

    $class = classname $class;

    my $t0 = time;

    my $sth = $dbh->prepare($view) or die "Could not prepare '$view':" . $dbh->errstr . "\n";
    $sth->execute                  or die "Could not execute '$view':" . $sth->errstr . "\n";

    my $fields = $sth->{NAME} or die;
    @$fields or die;

    my @rows ;#= ((undef) x 2048);

    my $t1 = time;

    my $ri = 0;
    while (my $row = $sth->fetchrow_arrayref) {

        $row = bless do {
            my %r;
            @r{ @$fields } = @$row;
            \%r
        }, $class;

        # Make sure array is large enough
        $ri < @rows or push @rows, (undef) x (@rows);

        $rows[$ri++] = $row;
    }

    my $t2 = time;

    $sth->finish or die;

    my $t3 = time;

    # Trim array
    splice @rows, $ri;

    my $t4 = time;

    warn sprintf "Fetched %u rows from «%s», as class «%s» took %.0fms (prep=%.1fms retr=%.2fms finn=%.2fµs trim=%.2fµs)\n",
                scalar @rows,
                $view,
                $class,
                ($t4-$t0)*1000,
                                ($t1-$t0)*1000, ($t2-$t1)*1000,
                                ($t3-$t2)*1e6, ($t4-$t3)*1e6
            if $debug;
    return \@rows;
}

sub fetch_mms($) {
    my $dbx = shift;
    my $dbh = $dbx->{dbh};
    return _fetch_rows $dbh, <<'EoQ', SQL::Drupal7::user_mm_member::
        select field_short_name_value as tag, entity_id as id
          from field_data_field_short_name
         where bundle = 'meeting_group'
EoQ
}

#TODO: pull apart user_all_subs into user_email_subs and user_print_subs
#   sub fetch_distrib($$) {
#       my $dbx = shift;
#       my $type = shift;
#       $type eq 'print' || $type eq 'email' || croak "parameter 2 (type) must be 'print' or 'email'";
#       my $dbh = $dbx->{dbh};
#       return _fetch_rows $dbh, "select * from experl_user_all_subs where method='$type'", 'SQL::Drupal7::{$type}_sub';
#   }

sub fetch_users($) {
    my $dbx = shift;
    my $dbh = $dbx->{dbh};
    my $ru = _fetch_rows $dbh, 'select * from experl_full_users', SQL::Drupal7::users::;
    $_->{user_name} //= delete $_->{name} for @$ru;   # WTF?!? whyyyy, Drupal?

    my %mu; @mu{ map { $_->{uid} } @$ru } = @$ru;
    warn sprintf "Mapped %s rows to %s keys\n", scalar @$ru, scalar keys %mu;

    for my $tk (qw(

                    experl_user_access_needs.access_needs_uid
                    experl_user_med_needs.med_needs_uid
                    experl_user_addresses.address_uid
                    experl_user_addresses2.address_uid
                    experl_user_all_subs.subs_uid
                    experl_user_kin.kin_uid
                    experl_user_mm_member.mmm_uid
                    experl_user_notes.notes_uid
                    experl_user_phones.phone_uid
                    experl_user_visible_emails.visible_email_uid
                    experl_user_websites.website_uid
                    experl_user_wgroup.wgroup_uid

                )) {
        my ($tt, $k) = split /\./, $tk;
        my $t = $tt =~ s/^.*user_|^exp.*?_//r;
        my $rr = _fetch_rows $dbh, "select * from $tt", "SQL::Drupal7::user_$t";
        my %rz;
        my $missing_users = 0;
        for my $r (@$rr) {
            my $uid = $r->{$k} //= do { warn sprintf "Missing UID key %s of %s\n", $k, $tt; next };
            # We filter out users who are blocked, deleted, or deceased, but we
            # will still get their anciliary records, so avoid complaining
            # about them.
            my $u = $mu{$uid} //= do { ++$missing_users; next; };
            # $u // do { warn sprintf "No user with UID value %s from key %s of %s\n", $uid, $k, $tt; +{ uid => $uid } };
            push @{$u->{"__$t"}}, $r;
            $rz{$uid}++;
        }
        warn sprintf "Read %s, got %u rows mapped as %u uids in field %s (user field «%s»)\n\tMissing users: %s\n",
                    $tt,
                    scalar @$rr,
                    scalar keys %rz,
                    $k,
                    "__$t",
                    $missing_users || "(none)",
                if $debug;
    }

    if ( my $fix = UNIVERSAL::can(SQL::Drupal7::users::, 'fix_one') ) {
        warn sprintf "Trying fix_one using %s; starting with %d records", $fix, scalar @$ru if $debug;
        for my $u ( @$ru ) { $fix->($u) }
        warn "Completed fix_one" if $debug;
    }
    else {
        cluck "Can't fix_one for SQL::Drupal7::users";
    }

    v && warn sprintf "fetch_users returning %s", Dumper($ru);
    return $ru;
}

1;
