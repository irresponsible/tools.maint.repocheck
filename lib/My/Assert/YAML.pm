use 5.006;    # our
use strict;
use warnings;

package My::Assert::YAML;

our $VERSION = '0.001000';

# ABSTRACT: Do assertions on yaml files

# AUTHORITY

use My::Generic::Assertions;
use My::Assert::Path;

use YAML::XS qw();
use Data::DPath qw();

our $ASSERT_YAML = My::Generic::Assertions->new(
    '-input_transformer' => \&transform_input,
    '-tests'             => { have_dpath => \&test_have_dpath },
    '-get_handler'       => \&handle_get,
);

sub assert { $ASSERT_YAML }

sub transform_input {
    My::Assert::Path::assert->must( exist => $_[1] );
    return (
        {
            yaml =>
              YAML::XS::Load( My::Assert::Path::assert->get( 'utf8', $_[1] ) ),
            file => $_[1]
        },
        @_[ 2 .. $#_ ]
    );
}

sub handle_get {
    my ( $name, @args ) = @_;
    my $coderef = __PACKAGE__->can( 'get_' . $name );
    die "No such getter get_$name" unless $coderef;
    $coderef->(@args);
}

sub handle_should {
    my ( $status, $message, $name, @slurpy ) = @_;
    my $cname    = colored( ['yellow'], $name );
    my $cmessage = colored( ['yellow'], $message );
    warn "should $cname > $cmessage\n" unless $status;
    return $status;
}

sub test_have_dpath {
    my ( $data, $path ) = @_;
    my (@results) = get_dpath( $data, $path );
    return ( 0, "$data->{file} does not have dpath $path" ) unless @results;
    return ( 1, "$data->{file} has dpath $path" );
}

sub get_dpath {
    my ( $data, $path ) = @_;
    Data::DPath->match( $data->{yaml}, $path );
}

1;

