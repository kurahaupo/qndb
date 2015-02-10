#!/module/for/perl

use 5.010;

use strict;
use warnings;
use utf8;

package export;

use Carp 'croak';

# Fake things so that when "use" does "require FILE", it thinks it's already loaded
sub fake_require($) {
    my $cpkg = shift;
    $cpkg =~ s#::#/#g;
    $cpkg .= '.pm';
    $INC{$cpkg} = __FILE__;
}

#BEGIN { fake_require __PACKAGE__ } # not needed unless you're inlining here

sub import {
    my $meta = shift;
    my $not_faking = @_ && $_[0] eq '-' && shift;
    my $exportable = \@_;
    my $cpkg = caller;

    # Create an import method for the target package
    my $im = sub {
        my $self = shift;
        my $pkg = caller;
        $cpkg eq $self or croak "'${cpkg}::import' seems to be linked to '${self}::import', which won't work";
        $cpkg ne $pkg or croak "'$pkg' can't import from itself";
        for my $nn (@_ ? @_ : @$exportable) {
            no strict 'refs';
            (my $n = $nn) =~ s/^\W//;
            my $t = $& || '&';
            if ($t eq '&') {
                *{"${pkg}::$n"} = UNIVERSAL::can($self,$n)
                                || die "'$pkg' can't import function '$n' from '$self', which neither defines nor inherits it\n";
            } elsif ($t eq '$') {
                *{"${pkg}::$n"} = *{"${self}::$n"}{SCALAR};
            } elsif ($t eq '@') {
                *{"${pkg}::$n"} = *{"${self}::$n"}{ARRAY};
            } elsif ($t eq '%') {
                *{"${pkg}::$n"} = *{"${self}::$n"}{HASH};
            } elsif ($t eq '*') {
                *{"${pkg}::$n"} = *{"${self}::$n"}{IO};
            } else {
                croak "Can't export '$n' - unknown type '$t'";
            }
        }
    };
    { no strict 'refs'; *{"${cpkg}::import"} = $im; };
    # Fake things so that when "use" does "require FILE", it thinks it's already loaded
    fake_require $cpkg if ! $not_faking;
}

1;
