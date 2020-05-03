#!/module/for/perl

package verbose;

use Carp 'croak';

my $debug = $^C;
my $why_not = 0;

my %vx;
sub import {
    my $self = shift;
    my $cpkg = caller;
    my $vtag = shift || $cpkg;
    $vx{$vtag} ||= 0;
    my $vr = \$vx{$vtag};
    my $vf = sub(;$) {
        my $l = @_ ? $_[0] : 1;
        $l <= $vx{$vtag};
    };
  { no strict 'refs';
    *{"${cpkg}::debug"} = \$debug;
    *{"${cpkg}::set_verbose"} = \&set_verbose if $cpkg eq 'main';
    *{"${cpkg}::v"} = $vf;
    *{"${cpkg}::verbose"} = $vr;
    *{"${cpkg}::why_not"} = \$why_not;
  }
}

sub set_verbose {
    my $l = pop @_;
    for my $ll ( split /[\s,:]+/, $l // '' ) {
        my ($vtag,$q) = split /=/, $ll, 2;
        if (! defined $q && $vtag =~ m<^\d+$>) {
            $q = $vtag;
            $vtag = '';
        }
        $vtag !~ /\W/ or croak "Invalid verbosity setting '$l'";
        # L-value for-list
        for my $vv ( $vtag eq 'debug' ? $debug :
                     $vtag eq 'why'   ? $why_not :
                     $vtag eq ''      ? values %vx :
                                        $vx{$vtag} ) {
            if (! defined $q) {
                ++$vv;
            } else {
                $vv = $q;
            }
        }
    }
}

1;
