#!/module/for/perl

use 5.018;
use strict;

package classref;

sub classname {
    my ($class) = @_;
    ref $class or return $class;
    return *$class{NAME};
}

sub classref {
    my ($class) = @_;
    ref $class and return $class;
    no strict 'refs';
    $class =~ s/:*$/::/;
    return \%$class;
}

use export 'classname', 'classref';

1;
