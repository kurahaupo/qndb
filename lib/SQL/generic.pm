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

sub fetch_users($) {
    my $dbx = shift;
    my $dbh = $dbx->{dbh};

    my $core_class = $dbx->_core_user_class;
    my $core_table = $core_class->fetch_from;
    my $core_key = $core_class->fetch_key;

    my @aux_classes = $dbx->_joined_user_classes;

    my $ru = _fetch_rows $dbh, 'select * from '.$core_table, $core_class;

    my %mu; @mu{ map { $_->{$core_key} } @$ru } = @$ru;
    warn sprintf "Mapped %s rows to %s keys\n", scalar @$ru, scalar keys %mu;

    for my $aux_class (@aux_classes) {
        my $aux_table = $aux_class->fetch_from;
        my $aux_key = $aux_class->fetch_key;
        my $t = $aux_table =~ s/^.*user_|^exp.*?_//r;
        my $rr = _fetch_rows $dbh, "select * from $aux_table", $aux_class;
        my %rz;
        my $missing_users = 0;
        for my $r (@$rr) {
            my $uid = $r->{$aux_key} //= do { warn sprintf "Missing UID key %s of %s\n", $aux_key, $aux_table; next };
            # We filter out users who are blocked, deleted, or deceased, but we
            # will still get their anciliary records, so avoid complaining
            # about them.
            my $u = $mu{$uid} // do { ++$missing_users; next; };
            # $u // do { warn sprintf "No user with UID value %s from key %s of %s\n", $uid, $aux_key, $aux_table; +{ uid => $uid } };
            push @{$u->{"__$t"}}, $r;
            $rz{$uid}++;
        }
        warn sprintf "Read %s, got %u rows mapped as %u uids in field %s\n\tuser field «%s» type %s\n\tMissing users: %s\n",
                    $aux_table,
                    scalar @$rr,
                    scalar keys %rz,
                    $aux_key,
                    "__$t",
                    $missing_users || "(none)",
                if $debug;
    }

    if ( my $fix = UNIVERSAL::can($core_class, 'fix_one') ) {
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
