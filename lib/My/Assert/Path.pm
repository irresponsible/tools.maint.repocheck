use 5.006;    # our
use strict;
use warnings;

package My::Assert::Path;

our $VERSION = '0.001000';

# ABSTRACT: Do asserty checks on paths

# AUTHORITY

use My::Generic::Assertions;
use Path::Tiny;

our $ASSERT_PATH = My::Generic::Assertions->new(
    '-input_transformer' => \&transform_input,
    -tests               => {
        exist              => \&test_exist,
        have_line_matching => \&test_have_line_matching,
    },
    '-get_handler' => \&handle_get,
);
sub assert { $ASSERT_PATH }

our %linecache;

sub _getlines {
    @{
        exists $linecache{ $_[0] }
        ? $linecache{ $_[0] }
        : $linecache{ $_[0] } = [ $_[0]->lines_raw( { chomp => 1 } ) ]
    };
}

sub transform_input {
    my ( $name, $path, @rest ) = @_;
    return ( Path::Tiny::path($path), @rest );
}

sub test_exist {
    return ( 0, "$_[0] does not exist" ) unless $_[0]->exists;
    return ( 1, "$_[0] exists" );
}

sub test_have_line_matching {
    my $re = $_[1];
    my $smessage = !$_[2] ? "" : " ( $_[2] )";
    return ( 0, "$_[0] does not have line matching ${re}${smessage}" )
      unless grep { $_ =~ $re } _getlines( $_[0] );
    return ( 1, "$_[0] has line matching ${re}${smessage}" );
}

sub handle_get {
    my ( $name, @args ) = @_;
    my $coderef = __PACKAGE__->can( 'get_' . $name );
    die "No such getter get_$name" unless $coderef;
    $coderef->(@args);
}

sub get_lines {
    _getlines( $_[0] );
}

sub get_utf8 {
    $_[0]->slurp_utf8;
}

1;

