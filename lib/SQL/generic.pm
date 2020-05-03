#!/module/for/perl

use 5.010;
use strict;
use warnings;

package SQL::generic;

use DBI;
use Data::Dumper;
use Time::HiRes 'time';

use verbose;

my $dbh;

my %def_opts = (
    dsn     => $ENV{QDB_DSN}    // 'dbi:mysql:database=quakers;host=ip6-localhost;port=33060',
  # dbtype  => $ENV{QDB_DBTYPE} // 'mysql',
  # dbname  => $ENV{QDB_DBNAME} // 'quakers',
  # host    => $ENV{QDB_HOST}   // 'ip6-localhost', # ::1
  # port    => $ENV{QDB_PORT}   // 33060,
    user    => $ENV{QDB_USER}   // 'quakers_user',
    pass    => $ENV{QDB_PASS},
);

sub Connect {
    $dbh and return $dbh;

    my $arg = pop @_;
    my %opts = ref $arg ? %$arg : %def_opts;
    my $dsn  = delete $opts{dsn} //
                join ':', 'dbi',
                          delete $opts{dbtype} // 'mysql',
                          delete $opts{dbname} // 'quakers',
                          ;
    my $user = delete $opts{user};
    my $pass = delete $opts{pass};
    $opts{RaiseError} = 1;

    my $t0 = time;

    $dbh ||= DBI->connect( $dsn, $user, $pass, \%opts )
         || do {
            my $host = delete $opts{host} // '(missing)' || '(empty)';
            my $port = delete $opts{port} // '(missing)' || '(empty or zero)';
            die "Failed to connect to $dsn on $host port $port as $user; $!"
         };

    my $t1 = time;

    warn sprintf "Connecting to [%s] took %.3fs\n",
                $dsn, $t1-$t0
            if $debug;

    return $dbh;
}

sub Disconnect() {
    $dbh->disconnect if $dbh;
    $dbh = undef;
}

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

sub _fetch_rows($$) {
    my $class = ref $_[0] || UNIVERSAL::isa($_[0], __PACKAGE__) ? shift : __PACKAGE__;
    my ($view, $class) = @_;

    Connect();
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

sub fetch_mms() {
    Connect();
    return _fetch_rows(<<'EoQ', 'SQL::generic::mm')
        select field_short_name_value as tag, entity_id as id
          from field_data_field_short_name
         where bundle = 'meeting_group'
EoQ
}

sub fetch_distrib() {
    Connect();
    return _fetch_rows("select * from export_all_subs", 'SQL::generic::all_subs');
}

sub fetch_users() {
    Connect();
    my %RZ;
    my %RZM;
    for my $tk (qw( full_users/uid user_addresses/address_uid
                    user_phones/phone_uid user_kin/kin_uid
                    user_wgroup/wgroup_uid user_notes/notes_uid all_subs/uid
                )) {
        my ($t, $k) = split '/', $tk;
        my $rr = _fetch_rows("select * from export_$t", "SQL::generic::${t}");
        $RZ{$t} = $rr;
        $RZM{$t} = _map_of_rows $k, @$rr if $k;
    }
    my @users = @{ $RZ{full_users} };
    my $RM_uid = _map_of_rows 'uid', @users;
    #print Dumper($RM_uid);
    return \@users;
}

END { Disconnect(); }

1;
