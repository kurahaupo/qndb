#!/module/for/perl

use 5.010;
use strict;
use warnings;
use utf8;

# This "common" class is stuff used by or provided for all types of input records

package CSV::Common;

use Carp 'croak';
use string_with_components;
use verbose;

# The rule of thumb is to map towards the ambiguous abbreviations, rather than
# away from them, so that we don't get silly things like "1 Scenic Doctor" or
# "Drive Jones' Surgery" or "1 Street Mary's Road" or "1 Queen Saint".
my %address_designators = (
    Av        => 'Ave',
    Avenue    => 'Ave',
    Boulevard => 'Bvd',
    Blvd      => 'Bvd',
    Cr        => 'Cres',
    Crescent  => 'Cres',
    Doctor    => 'Dr',
    Dve       => 'Dr',
    Drive     => 'Dr',
    Grove     => 'Gr',
    Highway   => 'Hwy',
    Mount     => 'Mt',
    Place     => 'Pl',
    Point     => 'Pt',
    Road      => 'Rd',
    Saint     => 'St',
    Street    => 'St',
    Tc        => 'Tce',
    Terrace   => 'Tce',
);

# Generic spelling fixes to apply to all "English" fields
my %spelling_fixes = (
#       Wanganui => 'Whanganui',
    );

our $canon_address = 0;
our $use_care_of = 1;
our $only_explicitly_shared_email = 1;

# Create an individual record, using a "headers" row to assign field names.

sub new($\@\@$) {
    $#_ == 3 or croak "Wrong number of parameters to CSV::Common::new";
    my ($class, $headers, $ra, $fpos) = @_;
    $#$ra == $#$headers or die "Line $. has $#$ra fields, but headers had $#$headers\n[@$ra] vs [@$headers]\n";

    my %rh;
    $rh{__source_fpos} = $fpos;
    $rh{__source_line} = $. - 1;
    @rh{@$headers} = @$ra;
    my $r = bless \%rh, $class;
    $r->fix_one or return ();
    return $r;
}

# Individual post-processing.
#   (a) filter (return 0 to exclude a record, non-0 to include)
#   (b) patch up individual fields
#
# Always finish fix_one in any derived class with a call to the parent
# implementation, like this:
#   goto &{$_[0]->can("SUPER::fix_one")}
# or this:
#   return $_[0]->SUPER::fix_one;

sub fix_one {
    my ($r) = @_;
    make_name_sortable($r->name);
    return 1;
}

# Bulk post-processing step.
# This can split or join rows.

sub foldrows {
    my ($records) = @_;
    #warn sprintf "CSV::Common::foldrows; start with %u rows, keeping all\n", scalar @$records;
    for my $r (@$records) {
        make_name_sortable($r->name);
    }
}

sub _titlecase($$) {
    my ($r, $fixme) = @_;
    $fixme or return;
    my @fn = split /([- ]+)/, $fixme;
    for my $fn (@fn) {
        (my $xfn = $fn) =~ s#^Ma?c##;
        if ( $xfn !~ /[a-z]/ ) {
            $fn = lc $fn;
            $fn = ucfirst $fn unless $fn =~ /^d[eu]$|^d'/;
            $fn =~ s#^(Mc|[dO]')([a-z])#$1\U$2#;
            $fn = $spelling_fixes{$fn} || $fn;
        }
    }
    $fixme = join '', @fn;
    return $fixme;
}

sub make_name_sortable($) {
    my ($n) = @_;
    s#\s*\([^()]*\)\s*# #g,
    s#\s*\([^()]*\)\s*# #g,
    s#\s*\([^()]*\)\s*# #g,  # thrice, to clean double-nested brackets
    s#\s\s+# #g,
    s#^\s|\s$##g
        for $n->{formatted},
            $n->{sort_by_surname},
            $n->{sort_by_givenname};
    s#'##g,
    s#-# #g,
    s#\bmc(?=\w\w\w)#mac#g,
        for $n->{sort_by_surname},
            $n->{sort_by_givenname};
    s#\band[eiy]+\b#andrew#,
    s#\b(deb)(?:or+ah?|b[eyi]*)\b#$+#,
    s#\b[bw]ill[eiy]*\b#william#,
    s#\bdan+[eiy]+\b#daniel#,
    s#\bdav+[eiy]+\b#david#,
    s#\bdon+[eiy]*\b#donald#,
    s#\bjim+[eiy]*\b#james#,
    s#\bliz+[aeiy]*\b#elizabeth#,
    s#\bm[ei]gs?\b|\bmargo\b|\bma[rg]g[eiy]+\b#margaret#,
    s#\bma+rt[iey]+n?\b#martin#,
    s#\bmiki?e?y?\b#michael#,
    s#\bnicky?\b|\bnicolas\b#nicholas#,
    s#\bnik+[iy]\b|\bnic\b#nicole#,
    s#\bted(?:d[iey]*|)\b#edward#,
    s#\btony\b|\bantony\b#anthony#,
        for $n->{sort_by_givenname};
}

sub _map($$) {
    my ($r, $k) = @_;
    my $m = $r->{"MAP_$k"} ||= +{};
    return values %$m if wantarray;
    $m;
}

# List defaults to single-item
sub _list($$) {
    my ($r, $k) = @_;
    return [ $r->{$k} ] if !wantarray;
    return $r->{$k} // ();
}

#sub fix_addr($) { my $z = shift; $z =~ s#,\s*#\n#sgo; return $z; }

sub _canon_address($$$) {
    my ($r, $z, $c) = @_;
    for ($z) {
        s#,\s*#\n#sgo;
        s#\s*\r*\n#\n#g;
        s#^?:c/[-o]\s+##;
        s#^#c/- # if $use_care_of && $c;
        if ( $canon_address ) {
            state $ax = do {
                            my $r = join '|', map { quotemeta $_ } reverse sort keys %address_designators;
                            my $q = eval "qr/\\b(?:$r)\\b/";
                            warn "Initialized designators re=$q\n" if $verbose > 1;
                            $q;
                        };
            s#$ax#$address_designators{$&}#g;
            s#\nNZ\z##;
        }
        return $_;
    }
}

sub name {
    my $r = shift;
    $r->{composite_name} ||= state $x =
        new string_with_components::
            "(unknown-default $_[0])",
            sort_by_surname => '',
            sort_by_givenname => '';
}

sub uid($) {
    my $r = shift;
    return "GEN".(0+$r)."-default";
}

sub uid_of_children_under_16 { () }     # not supported by all record types
sub uid_of_spouse { () }                # not supported by all record types

sub label_priority { 0 }    # no specific priorities by default

sub debuginfo($) {
    my $r = shift;
    sprintf "%s uid=%s [%s]",
            $r->name || '(nameless)',
            $r->uid || '(unnumbered)',
            (join "; ", grep { $_ } '#'.$r->{__source_line}, '@'.$r->{__source_fpos}, $r->listed_email, $r->mobile_number || $r->phone_number),
            ;
}

sub DESTROY {}  # don't autoload!

#use Carp qw( croak confess );
#$SIG{__DIE__} = \&confess;
sub xAUTOLOAD {
    (my $f = our $AUTOLOAD ) =~ s#.*::##;
    my $fn = sub {
        my $r = shift;
        $r->{$f} ||= '';
    };
    warn sprintf "Autoloaded CSV::Common::$f on (@_) as $fn\n" if $verbose > 1;
    $f or return;
    no strict 'refs';
    *{"CSV::Common::$f"} = $fn;
    goto &$fn;
}

1;
