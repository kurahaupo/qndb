#!/module/for/perl

package string_with_components;

#
# An object that mostly just looks like a string, but you can attach attributes to it.
# Useful for "full name" while still being able to look at the surname/firstname etc
#

sub new {
    my $class = shift;
    my $formatted = shift;
    bless ref $formatted && !@_ ? $formatted : { @_, formatted => $formatted }, $class;
}

use overload '""' => sub {
    my $r = shift;
    $r->{formatted} //= $r->formatted;
};

use overload 'eq' => sub {
    my ($r1, $r2) = @_;
    defined $r1 && defined $r2 || return 0;
    !ref $r1   && return $r1              eq $r2->{formatted};
    !ref   $r2 && return $r1->{formatted} eq $r2;
                  return $r1->{formatted} eq $r2->{formatted}
};

use overload 'ne' => sub {
    my ($r1, $r2) = @_;
    defined $r1 && defined $r2 || return 1;
    !ref $r1   && return $r1              ne $r2->{formatted};
    !ref   $r2 && return $r1->{formatted} ne $r2;
                  return $r1->{formatted} ne $r2->{formatted}
};

1;
