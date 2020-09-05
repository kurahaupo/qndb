#!/module/for/perl

use 5.010;
use strict;
use warnings;

package SQL::generic;

use DBI;
use Data::Dumper;
use Time::HiRes 'time';
use Carp 'croak';

use verbose;

sub ParseDSN(\%$);

# Call this for each --sql-FOO=BAR option, and for each $QDB_FOO variable, or
# with a collection of such as key-value pairs.
# Early values take precedence over later values.
sub ParseOpts {
    my $this = $_[0] && UNIVERSAL::isa($_[0], __PACKAGE__) ? shift : __PACKAGE__;

    v && printf "BEGIN: ParseOpts with %u args %s\n", scalar(@_), Dumper(\@_);

    my $opts = shift;
    UNIVERSAL::isa($opts, 'HASH') or croak "First arg must be opts hash";

    while (@_) {
        my $arg = shift;

        v && printf "ParseOpts checking arg '%s'\n", $arg // '(undef)';

        if (ref $arg) {
            UNIVERSAL::isa($arg, 'HASH') or croak "Invalid reference parameter";
            %$opts = (%$arg, %$opts);
            next;
        }

        $arg = lc $arg;

        my $val = shift;

        if ($arg eq ';dsn') {
            ParseDSN(%$opts, $val) if $val;
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

    v && printf "FINISH: ParseOpts\n";
    return ();
}

# Takes a single DSN string and splits it into parts, which are then handed to
# ParseOpts.  Do nothing if the DSN string is undef or empty, so that cascading
# rules work properly.
sub ParseDSN(\%$) {

    v && printf "BEGIN: ParseDSN with %u args %s\n", scalar(@_), Dumper(\@_);

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
    v && printf "FINISH: ParseDSN\n";
}

# Connect
sub Connect($\%) {
    my $class = $_[0] && UNIVERSAL::isa($_[0], __PACKAGE__)
                    ? shift
                    : __PACKAGE__;
    @_ == 2 or croak "Exactly 2 args required";
    my ($dsn, $opts) = @_;

    my %opts = %$opts;
    if (! $dsn || $dsn eq '-') {
        my $driver = delete $opts->{driver} // die "Missing driver";
        my $dbname = delete $opts->{dbname} // die "Missing dbname";

        $dsn  = join ':', 'dbi', $driver, $dbname;
    }

    $opts{RaiseError}  = 1;
    my $user = delete $opts{user};
    my $pass = delete $opts{pass};

    my $t0 = time;

    my $dbh = DBI->connect( $dsn, $user, $pass, \%opts )
         || do {
            my $host = $opts{host} // '(missing)' || '(empty)';
            my $port = $opts{port} // '(missing)' || '(empty or zero)';
            $pass =~ s/./X/g;
            die "Failed to connect to $dsn on $host port $port as $user pw $pass; $!"
         };

    my $t1 = time;

    warn sprintf "Connecting to [%s] took %.3fs\n",
                $dsn, $t1-$t0
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

{
    package SQL::generic::Common;
    use parent 'CSV::Common';
    use export; # also patches up %INC so that use « parent 'SQL::generic::Common' » later works

    sub uid { $_[0]->{uid}; }

    sub foooooooooo {1}
}

{ package SQL::generic::mm;             use parent 'SQL::generic::Common'; }
{ package SQL::generic::full_users;     use parent 'SQL::generic::Common'; }
{ package SQL::generic::user_addresses; use parent 'SQL::generic::Common'; }
{ package SQL::generic::user_phones;    use parent 'SQL::generic::Common'; }
{ package SQL::generic::user_kin;       use parent 'SQL::generic::Common'; }
{ package SQL::generic::user_wgroup;    use parent 'SQL::generic::Common'; }
{ package SQL::generic::user_notes;     use parent 'SQL::generic::Common'; }
{ package SQL::generic::all_subs;       use parent 'SQL::generic::Common'; }

sub _fetch_rows($$$) {
    my ($dbh, $view, $class) = @_;

    my $t0 = time;

    my $sth = $dbh->prepare($view) or die "Could not prepare '$view':" . $dbh->errstr . "\n";
    $sth->execute                  or die "Could not execute '$view':" . $sth->errstr . "\n";

    my $fields = $sth->{NAME} or die;
    @$fields or die;

    my @rows ;#= ((undef) x 2048);

    my $t1 = time;

    my $ri = 0;
    while (my $row = $sth->fetchrow_arrayref) {
        $ri < @rows or push @rows, (undef) x (@rows);
        $rows[$ri++] = $row;
    }

    my $t2 = time;

    $sth->finish or die;

    my $t3 = time;

    splice @rows, $ri;

    for my $row (@rows) {
        my %r;
        @r{ @$fields } = @$row;
        $row = bless \%r, $class;
    }

    my $t4 = time;

    warn sprintf "Fetching %u rows from %s took %.0fms (prep=%.1fms retr=%.2fms finn=%.4fms hash=%.2fms)\n",
                scalar @rows,
                $view,
                ($t4-$t0)*1000,
                                ($t1-$t0)*1000, ($t2-$t1)*1000,
                                ($t3-$t2)*1000, ($t4-$t3)*1000
            if $debug;
    return \@rows;
}

sub _map_of_rows($\@) {
    my $K = $_[-2];
    my $R = $_[-1];
    my %M;
    for my $r (@$R) {
        $M{ $r->{$K} } = $r;
    }
    return \%M;
}

sub fetch_mms($) {
    my $dbx = shift;
    my $dbh = $dbx->{dbh};
    return _fetch_rows($dbh, <<'EoQ', 'SQL::generic::mm')
        select field_short_name_value as tag, entity_id as id
          from field_data_field_short_name
         where bundle = 'meeting_group'
EoQ
}

sub fetch_distrib($) {
    my $dbx = shift;
    my $dbh = $dbx->{dbh};
    return _fetch_rows($dbh, "select * from export_all_subs", 'SQL::generic::all_subs');
}

sub fetch_users($) {
    my $dbx = shift;
    my $dbh = $dbx->{dbh};

    my %RZ;
    my %RZM;
    for my $tk (qw( full_users/uid user_addresses/address_uid
                    user_phones/phone_uid user_kin/kin_uid
                    user_wgroup/wgroup_uid user_notes/notes_uid all_subs/uid
                )) {
        my ($t, $k) = split '/', $tk;
        my $rr = _fetch_rows($dbh, "select * from export_$t", "SQL::generic::${t}");
        $RZ{$t} = $rr;
        $RZM{$t} = _map_of_rows $k, @$rr if $k;
    }
    my @users = @{ $RZ{full_users} };
    my $RM_uid = _map_of_rows 'uid', @users;
    #print Dumper($RM_uid);
    return \@users;
}

1;

__END__

y{ AEI OUY BCDFGHJLMS WPQTVKXRNZ aei ouy bcdfghjlms wpqtvkxrnz }
 { OUY AEI PQTVKXWRNZ JBCDFGHLMS ouy aei pqtvkxwrnz jbcdfghlms };

