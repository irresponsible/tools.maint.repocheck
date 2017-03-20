use 5.006;    # our
use strict;
use warnings;

package My::Assert::Git;

our $VERSION = '0.001000';

# ABSTRACT: Assert things against git

# AUTHORITY

use Git::Wrapper qw();

our $WRAPPER;

our $ASSERT_GIT = My::Generic::Assertions->new(
    '-input_transformer' => \&transform_input,
    -tests               => {
        be_in_git         => \&test_be_in_git,
        have_tag_matching => \&test_have_tag_matching,
    },
    '-get_handler' => \&handle_get,
);

sub import {
  if ( grep /\Agit\z/, @_[1..$#_] ) {
    no strict;
    *{ caller . '::git'} = \&assert
  }
}

sub assert { $ASSERT_GIT }

sub transform_input {
    $WRAPPER ||= Git::Wrapper->new('.');
    return @_;
}

sub test_be_in_git {
    return ( 0, "Not in a valid git repo" )
      unless eval { $WRAPPER->status; 1 };
    return ( 1, "In a valid git repo" );
}

sub handle_get {
    my ( $name, @args ) = @_;
    my $coderef = __PACKAGE__->can( 'get_' . $name );
    die "No such getter get_$name" unless $coderef;
    $coderef->(@args);
}

sub get_tags {
    $WRAPPER->tag();
}

sub test_have_tag_matching {
    my ( $name, $regex ) = @_;
    my $smessage = !$_[2] ? "" : " ( $_[2] )";
    return ( 0, "No such tag matching ${regex}${smessage}" )
      unless grep { $_ =~ $regex } $WRAPPER->tag;
    return ( 1, "Has tag matching ${regex}${smessage}" );
}

1;

