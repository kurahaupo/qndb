#!/module/for/perl

package export;

# Fake things so that when "use" does "require FILE", it thinks it's already loaded
sub fake_require($) {
    my $cpkg = shift;
    $cpkg =~ s#::#/#g;
    $cpkg .= '.pm';
    $INC{$cpkg} = __FILE__;
}

#BEGIN { fake_require __PACKAGE__ } # not needed unless you're inlining here

sub import {
    my $self = shift;
    my $exportable = \@_;
    my $cpkg = caller;
    # Create an import method for the target package
    my $im = sub {
        my $self = shift;
        my $pkg = caller;
        for my $n (@_ ? @_ : @$exportable) {
            no strict 'refs';
            my $f = UNIVERSAL::can($self,$n)
                or die "'$pkg' cannot import function '$n' from '$self', which neither defines nor inherits it\n";
            *{"${pkg}::$n"} = $f;
        }
    };
    { no strict 'refs'; *{"${cpkg}::import"} = $im; };
    # Fake things so that when "use" does "require FILE", it thinks it's already loaded
    fake_require $cpkg;
}

1;
