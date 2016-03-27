#!/module/for/perl

use 5.010;
use strict;
use warnings;
use utf8;

package run_options;

use Carp 'croak';
use Getopt::Long qw( :config auto_abbrev bundling );
#use Data::Dumper;

use PDF::scale_factors;

#sub M($) { my $r = \$_[0]; sub { $$r = as_points $_[-1] } }
#sub N($) { my $r = \$_[0]; sub { $$r = ! $_[1] } }

sub as_points($) {
    my $v = $_[0];
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
my @get_opt_args;
my %exclusion_group;
my @run_queue;

sub import {
    my $from = shift;
    my $to = caller;
    my $do_export = $to eq 'main';
    while (@_) {
        my $k = shift;
        my $v = shift;
        if ($k =~ m/^=(\d*)$/) {
            my $l = $1 eq '' ? 1 : $1;
            push @{$run_queue[$l]}, $v;
        } elsif ($k =~ s/^\+//) {
            ref $v eq 'CODE' or croak "Can't shard an option unless it has a coderef";
            push @{$sharding{$k}}, $v;
        } elsif ($k eq '*') {
            $do_export = 1;
        } else {
            if ($k =~ s/^!//) {
                $v = do {
                            my $vv = $v;
                            ref $v eq 'CODE' ? sub {  $vv ->( ! $_[1] ) }
                                             : sub { $$vv =   ! $_[1]   }
                        };
            } elsif ($k =~ s/^%//) {
                $v = do {
                            my $vv = $v;
                            ref $v eq 'CODE' ? sub {  $vv ->( as_points $_[1] ) }
                                             : sub { $$vv =   as_points $_[1]   }
                        };
            } elsif ($k =~ s/^#*help/help/) {
                $v = do { my $vv = $v; sub { print $vv; exit 0; }};
            } elsif ($k =~ s/^#require-*//) {
            } elsif ($k =~ s/^#exclude-*//) {
                push @{ $exclusion_group{$k} }, $v;
            }
            push @get_opt_args, $k => $v;
        }
    }

    $do_export or return;

    my $ff = sub {
        for my $k (keys %sharding) {
            my $shards = $sharding{$k};
#           warn "Gathering shards for $k";
            unshift @get_opt_args, $k => sub { for my $x (@$shards) { $x->(@_) }; 1 };
        }
        push @get_opt_args, @_;

#       print Data::Dumper->Dump([\@get_opt_args,
#                                 \@run_queue,
#                                 \%exclusion_group],
#                             [qw( args
#                                  queue
#                                  exclude )]) if 0;

        GetOptions @get_opt_args or
            croak "BAD";
        #exit 64;
        for my $e (values %exclusion_group) {
            my $n = 'Too many conflicting options';
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
    warn "Exporting RunOptions into $to";
    *{"${to}::RunOptions"} = $ff;
}

1;
