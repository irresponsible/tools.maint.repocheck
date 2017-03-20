use 5.006;    # our
use strict;
use warnings;

package My::Generic::Assertions;

our $VERSION = '0.001000';

# ABSTRACT: Subclass of Generic::Assertions to provide nonstandard features

# AUTHORITY

use My::Generic::Assertions::Capture;
use Term::ANSIColor qw( colored );
use Generic::Assertions;
use parent "Generic::Assertions";

sub with {
    my ( $self, $item ) = @_;
    return My::Generic::Assertions::Capture->new( $self, $item );
}

sub get {
    my ( $self, $name, @slurpy ) = @_;
    my (@input) = $self->_transform_input( $name, @slurpy );
    $self->_get_handler->( $name, @input );
}

sub _get_handler {
    my ($self) = @_;
    return $self->{get_handler} if exists $self->{get_handler};
    if ( not exists $self->_args->{'-get_handler'} ) {
        die "No 'get_handler'";
    }
    return ( $self->{get_handler} = $self->_args->{'-get_handler'} );
}

sub _handler_defaults {
    my $defaults = $_[0]->Generic::Assertions::_handler_defaults();
    $defaults->{should} = \&handle_should;
    $defaults->{test}   = \&handle_test;
    return $defaults;
}

sub handle_should {
    my ( $status, $message, $name, @slurpy ) = @_;
    my $cname    = colored( ['yellow'], $name );
    my $cmessage = colored( ['yellow'], $message );
    my $cbang = colored( [ 'bold', 'yellow' ], '!' );
    warn "   should $name: $message\n" if $status and $ENV{DEBUG};
    warn " ${cbang} should $cname > $cmessage\n" unless $status;
    return $status;
}

sub handle_test {
    my ( $status, $message, $name, @slurpy ) = @_;
    warn "   test   $name: $message\n" if $ENV{DEBUG};
    return $status;
}

1;

