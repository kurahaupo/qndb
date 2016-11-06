#!/module/for/perl

use 5.010;
use strict;
use warnings;
use utf8;

package export;

use Carp qw( croak carp );

# Local debug; not controlled by -x command line option
my $debug = $ENV{PERL_debug_export} || $^C;

my %typemap = (
    # These are the elements of a glob, taken in this order from "man perlref"
    '$'  => 'SCALAR',
    '@'  => 'ARRAY',
    '%'  => 'HASH',
    '&'  => 'CODE',
    '*'  => 'IO',       # by perlref, '*' refers to the glob, but the IO handle
                        # is usually what's really wanted
    '**' => 'GLOB',     # made up prefix to disambiguate from the IO handle
    '^'  => 'FORMAT',   # made up prefix

    # These parts are defined in "man perlref", but cannot be imported into the
    # receiving package where they are read-only.
    '='  => 'NAME',     # read-only
    '==' => 'PACKAGE',  # read-only

    # This is made up, to search the @ISA graph
    '->' => 'METHOD',   # made up prefix, not part of "man perlref"
                        # Note that for this to work, you need to set up @ISA
                        # BEFORE 'use export' takes effect at compile time.
);

sub import {
    my $meta = shift;
    my $not_faking = @_ && $_[0] eq '-' && shift;
    my $exportable = \@_;
    my ($epkg, $efile) = caller;

    my $symtab = do { no strict 'refs'; \%{"${epkg}::"}; }
        or die "Can't connect to calling package $epkg";

    my %exportable;
    for my $e (@$exportable) {
        my $n = $e;
        my $m = '';
        $n =~ s/^\W*//;
        my $t = $& || '&';
        $n or croak "Can't export '$e' - invalid name";
        my $tt = $typemap{$t} || croak "Can't export '$e' - unknown type '$t'";
        my $o;
        if ($tt eq 'METHOD') {
            $o = $epkg->can($n) || croak "Can't export uninherited METHOD $e from $epkg";
        } else {
            my $eg = $symtab->{$n}
                || croak "Can't export undefined $t$n from $epkg (no symbol+glob)";
            my $r = ref $eg;
            if ( $r eq 'SCALAR' ) {
                # Only reach here for "use constant" and Perl > v5.9.2, when
                # the symbol-table entry that would normally hold a glob
                # instead holds the scalar which is the optimized constant.
                # (See &constant::_CAN_PCS)
                # Sorry, this de-optimization will make things slow!!!
                $m = " (downgraded constant)";
                my $const = $$eg;
                $o = sub () { $const };
            } else {
                $o = *$eg{$tt}
                    || croak "Can't export undefined $t$n from $epkg (no $tt within glob $eg)";
            }
        }
        $exportable{"$t$n"} = $o;
        warn "... $t$n exported (as $tt)$m\n" if $debug;
    }
    if ($debug) {
        warn sprintf "... exported from %-22s  %s\n", "$epkg:", join ", ", sort keys %exportable;
    }

    # Create an import method for the target package
    my $im = sub {
        my $self = shift;
        my $pkg = caller;
        $epkg eq $self or croak "${epkg}::import seems to be linked to ${self}::import, which won't work";
        $epkg ne $pkg or croak "$pkg can't import from itself";
        warn "Importing from $epkg into $pkg\n" if $debug;
        for my $i (@_ ? @_ : @$exportable) {
            if ($i =~ /^#/) { carp "Ignoring $i"; next }

            my $n = $i;
            $n =~ s/^\W+//;
            my $t = $& || '&';
            $n =~ s/>(.*)//;
            my $ni = $1 || $n;

            my $o = $exportable{"$t$n"} or do {
                my $as = $n eq $ni ? '' : " as $t$ni";
                croak "Can't import $t$n$as into $pkg (not exported by $epkg)";
            };

            {
              no strict 'refs';
              *{"${pkg}::$ni"} = $o;
            }
            warn "... $t${epkg}::$n imported as $t${pkg}::$ni\n" if $debug;
        }
    };
    warn "Creating ${epkg}::import\n" if $debug;
    { no strict 'refs'; *{"${epkg}::import"} = $im; };
    # Fake things so that when "use" does "require FILE", it thinks it's already loaded
    $INC{$epkg} ||= $efile;
}

1;
