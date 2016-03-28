#!/module/for/perl

#
# run_options
#
# Enable multiple modules to add options to be parsed by GetOptions from main.
#
# Usage:
#
#   use run_options ( ... parameters as for GetOptions ... );
#
# Additionally, options may be prefaced with:
#
#   '!'     The assigned value should be the logical inverse of the argument.
#           Note: this surplants the "N" function previously applied to
#           parameters, and works properly with function callbacks.
#
#   '%'     The option takes a length, so the argument will be scaled so that
#           the assigned value is in "points".
#
#   ','     The option takes a comma-separated list of values; if the target is
#           an array, the separate values will be pushed onto the array; if it
#           is a function, it will be called once with each value.
#           (Currently only strings are supported, so it must end with '=s'.)
#
#   '+'     The command-line option is permitted multiple times; if given on
#           the command line, all the assignments will be performed (with the
#           same value).
#
#   '#'     Some non-option control follows
#
#   '#help' The target is a description string to be used as "help" text when
#           requested
#   '#check' or '='
#           The target is a CODE that is invoked after all command-line options
#           have been processed, but before the rest of main. A number may be
#           given (like '#check=4' or '=4') to control the order in which such
#           checks are run.
#   '#import'
#           Export the RunOptions function; normally this is exported
#           automatically into main, but if you wish to invoke it from a
#           different namespace then this will be needed.
#   '#exclude'
#           The target is an array of references to variables representing
#           mutually exclusive command-line options; it is an error for more
#           than one of a group to be given on the command-line.
#           Additionally, the number of options permitted can be controlled by
#           including '>min', '<max'.
#           Or for complete flexibility, a CODE ref can be included in the
#           list, which will be invoked with the values of all the variables.
#

use 5.010;
use strict;
use warnings;
use utf8;

package run_options;

use Carp qw( croak carp );
use Getopt::Long qw( :config auto_abbrev bundling );

use PDF::scale_factors;

use verbose;

sub as_points($) {
    my $v = $_[-1];
    if ($v =~ s/[a-z]+$//) {
        state $units = {
            cm => 0.1*mm,
            in => in,
            m  => 1000*mm,
            mm => mm,
            pt => pt,
            px => px,
            μm => 0.001*mm,
        };
        $v *= $units->{$&} || die "Unknown unit-of-measure $&\n";
    }
    $v;
}

my %sharding;
my %get_opt_args;
my %exclusion_group;
my @run_queue;

sub _assign($;$$) {
    my ($v, $f, $x) = @_;
    my $r = ref $v;
    return $v if ! $r;
    if ($f) {
        return sub {      $$v =         $f->($_[1]) } if $r eq 'SCALAR';
        return sub { push @$v,          $f->($_[1]) } if $r eq 'ARRAY';
        return sub {       $v->($_) for $f->($_[1]) } if $r eq 'CODE';
    } else {
        return sub {      $$v =              $_[1]  } if $r eq 'SCALAR';
        return sub { push @$v,               $_[1]  } if $r eq 'ARRAY';
        return $v if $r eq 'CODE' or $x;
    }
    croak "Unsupported target type $r";
}

#$verbose = 99;

sub import {
    my $from = shift;
    my $to = caller;
    my $do_export = $to eq 'main';

    my $auto_shard = 0;

    while (@_) {
        my $ko = my $k = shift;
        my $vo = my $v = shift;

        $k =~ s/^=(\d*)$/#check$&/;    # compatibility fix-up

        if ($k =~ s/^#//) {
            if ($k =~ m/^check[-=]?(\d*)$/) {
                my $l = $1 eq '' ? 1 : $1;
                push @{$run_queue[$l]}, $v;
                carp "Adding to run-queue (level $l) from $ko" if $verbose > 2;
            }
            elsif ($k =~ s/^exclude[-=]*//) {
                push @{ $exclusion_group{$k} }, $v;
                carp "Adding to exclusion group $k from $ko" if $verbose > 2;
            }
            elsif ($k =~ m/^help/) {
                $get_opt_args{$k} = do {
                            my $vv = $v;
                            sub { print STDERR $vv; exit 0; }
                        };
                carp "Adding help text for $k from $ko" if $verbose > 2;
            }
            elsif ($k eq 'import') {
                $do_export = 1;
                carp "Requesting import from $ko" if $verbose > 2;
            }
            elsif ($k eq 'shard') {
                $auto_shard = 1;
                carp "Requesting auto-sharding from $ko" if $verbose > 2;
            }
            else {
                croak "Undefined extension element $ko";
            }
            next
        }

        my $f = undef;
        my $vv = $v;
        my $r = ref $v;

        if ($k =~ s/^,//) {
            $r eq 'SCALAR' and croak "Can't auto-split into a SCALAR for option '$ko'";
            $k !~ /=s$/    and croak "Can't auto-split non-string for option '$ko'";
            carp "Split option $k from $ko" if $verbose > 2;
            $f = sub { split /\s*\,\s*/, $_[-1] };
        }
        elsif ($k =~ s/^!//) {
            carp "Negated option $k from $ko" if $verbose > 2;
            $f = sub { ! $_[1] };
        }
        elsif ($k =~ s/^%//) {
            carp "Distance option $k from $ko" if $verbose > 2;
            $f = \&as_points;
        }

        if ($k =~ s/^\+// || $auto_shard && (exists $get_opt_args{$k} || exists $sharding{$k})) {
            carp "Sharded option $k from $ko" if $verbose > 2;
            push @{$sharding{$k}}, _assign( delete $get_opt_args{$k} ) if exists $get_opt_args{$k};
            push @{$sharding{$k}}, _assign( $v, $f );
        } else {
            carp "Plain option $k from $ko" if $verbose > 2;
            exists $get_opt_args{$k} || exists $sharding{$k} and croak "Duplicate unsharded option '$ko'";
            $get_opt_args{$k} = _assign( $v, $f, 1 );
        }
    }

    $do_export or return;

    my $ff = sub() {
        #%get_opt_args += @_;
        for my $k (keys %sharding) {
            my $shards = $sharding{$k};
#           carp "Gathering shards for $k";
            $get_opt_args{$k} = sub { for my $x (@$shards) { $x->(@_) }; 1 };
        }

        GetOptions %get_opt_args or exit 64;
        for my $x (keys %exclusion_group) {
            my $e = $exclusion_group{$x};
            my $n = "Too many conflicting options for $x";
            my @g;
            my $f;
            my $min = 0;
            my $max = 1;
            for my $x (@$e) {
                if (ref $x eq 'CODE') {
                    $f = $x;
                } elsif (ref $x) {
                    push @g, $$x;
                } elsif ($x =~ s/^\<//) {
                    $max = $x-1;
                } elsif ($x =~ s/^\>//) {
                    $min = $x+1;
                } else {
                    $n = $x
                }
            }
            $f ||= sub { my @c = grep {$_} @_; @c >= $min && @c <= $max };
            $f->(@g) or die $n;
        }
        for my $a (map {@$_} grep {$_} @run_queue) {
            $a->() or die "RunOptions failed";
        }
        1;
    };
    no strict 'refs';
    carp "Exporting RunOptions into $to" if $verbose > 2;
    *{"${to}::RunOptions"} = $ff;
}

1;
