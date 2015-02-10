#!/module/for/perl

use 5.010;
use strict;
use warnings;
use utf8;

package export;

use Carp 'croak';

sub import {
    my $meta = shift;
    my $not_faking = @_ && $_[0] eq '-' && shift;
    my $exportable = \@_;
    my ($epkg, $efile) = caller;

        for my $nn (@$exportable) {
            no strict 'refs';
            (my $n = $nn) =~ s/^\W+//;
            my $t = $& || '&';
            if    ($t eq '&')  { *{"${epkg}::$n"}{CODE}   || croak "Can't export undefined function '$n'\n"                 }
            elsif ($t eq '$')  { *{"${epkg}::$n"}{SCALAR} || croak "Can't export undefined scalar '\$$n'\n"                 }
            elsif ($t eq '@')  { *{"${epkg}::$n"}{ARRAY}  || croak "Can't export undefined array '\@$n'\n"                  }
            elsif ($t eq '%')  { *{"${epkg}::$n"}{HASH}   || croak "Can't export undefined hash '\%$n'\n"                   }
            elsif ($t eq '*')  { *{"${epkg}::$n"}{IO}     || croak "Can't export undefined io-handle '\*$n'\n"              }
            elsif ($t eq '->') { UNIVERSAL::can($epkg,$n) || croak "Can't export undefined (and uninherited) method '$n'\n" }
            else               {                             croak "Can't export '$n' - unknown type '$t'"                  }
        }

    # Create an import method for the target package
    my $im = sub {
        my $self = shift;
        my $pkg = caller;
        $epkg eq $self or croak "'${epkg}::import' seems to be linked to '${self}::import', which won't work";
        $epkg ne $pkg or croak "'$pkg' can't import from itself";
        for my $nn (@_ ? @_ : @$exportable) {
            no strict 'refs';
            (my $n = $nn) =~ s/^\W+//;
            my $t = $& || '&';
            if    ($t eq '&')  { *{"${pkg}::$n"} = *{"${epkg}::$n"}{CODE}   || croak "'$epkg' does not define function '$n'\n"          }
            elsif ($t eq '$')  { *{"${pkg}::$n"} = *{"${epkg}::$n"}{SCALAR} || croak "'$epkg' does not define scalar '\$$n'\n"          }
            elsif ($t eq '@')  { *{"${pkg}::$n"} = *{"${epkg}::$n"}{ARRAY}  || croak "'$epkg' does not define array '\@$n'\n"           }
            elsif ($t eq '%')  { *{"${pkg}::$n"} = *{"${epkg}::$n"}{HASH}   || croak "'$epkg' does not define hash '\%$n'\n"            }
            elsif ($t eq '*')  { *{"${pkg}::$n"} = *{"${epkg}::$n"}{IO}     || croak "'$epkg' does not define io-handle '\*$n'\n"       }
            elsif ($t eq '->') { *{"${pkg}::$n"} = UNIVERSAL::can($epkg,$n) || croak "'$epkg' does not define or inherit method '$n'\n" }
            else               {                                               croak "Can't import '$n' - unknown type '$t'" }
        }
    };
    { no strict 'refs'; *{"${epkg}::import"} = $im; };
    # Fake things so that when "use" does "require FILE", it thinks it's already loaded
    $INC{$epkg} ||= $efile;
}

1;
