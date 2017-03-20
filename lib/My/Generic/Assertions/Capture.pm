use 5.006;    # our
use strict;
use warnings;

package My::Generic::Assertions::Capture;

our $VERSION = '0.001000';

# ABSTRACT: A closed over proxy for assertions

# AUTHORITY

sub new {
    my ( $self, $assertion, $item ) = @_;
    bless [ $assertion, $item ], $self;
}

sub should {
    my ( $self, $action, @slurpy ) = @_;
    $self->[0]->should( $action, $self->[1], @slurpy );
}

sub test {
    my ( $self, $action, @slurpy ) = @_;
    $self->[0]->test( $action, $self->[1], @slurpy );
}

sub get {
    my ( $self, $action, @slurpy ) = @_;
    $self->[0]->get( $action, $self->[1], @slurpy );
}

1;

