#!perl
use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/lib";

use My::Assert::Path;

use Git::Wrapper ();

our $BOOT_VERSION    = '2.7.1';
our $CLOJURE_VERSION = '1.9.0-alpha15';

BEGIN {
    *path = \&My::Assert::Path::assert;
    *yaml = \&My::Assert::YAML::assert;
    *git  = \&My::Assert::Git::assert;
}

for ( path->with('boot.properties') ) {
    $_->should('exist');
    next unless $_->test('exist');
    $_->should( have_line_matching =>
          qr/\ABOOT_CLOJURE_VERSION=\Q$CLOJURE_VERSION\E\z/ );
    $_->should( have_line_matching => qr/\ABOOT_VERSION=\Q$BOOT_VERSION\E\z/ );
}

for ( path->with('build.boot') ) {
    $_->should('exist');
}
for ( path->with('CHANGELOG') ) {
    $_->should('exist');
    next unless $_->test('exist');

    git()->should('be_in_git');
    next unless git()->test('be_in_git');

    my (@tags) = git()->get('tags');
    for my $tag (@tags) {
        next unless $tag =~ /\Av?(\d.*)\z/;
        my $version = $1;
        $_->should(
            'have_line_matching',
            qr/\Av?\Q$version\E($|\s+-\s+\S)/,
            "Version = $version"
        );
    }
    for my $line ( $_->get('lines') ) {
        next unless $line =~ /\Av?(\d[^\s]*)(?:$|\s+-\s+\S)/;
        my $version = $1;
        git()
          ->should( 'have_tag_matching', qr/\Av?\Q$version\E\z/,
            "Version = $version" );
    }
}
for ( path->with('README.md') ) {
    $_->should('exist');
}

for ( path->with('.travis.yml') ) {
    $_->should('exist');
    next unless $_->test('exist');
    my $yaml = yaml->with('.travis.yml');
    $yaml->should( have_dpath =>
          '//matrix/include/*/*[ key eq q[jdk] && value eq q[oraclejdk8] ]' );
    $yaml->should( have_dpath => '//cache' );
    $yaml->should( have_dpath => '//sudo' );
    $yaml->should( have_dpath => '//script' );
    $yaml->should( have_dpath => '//install' );
    $yaml->should( have_dpath =>
            '//matrix/include/*/*[ key eq "env" && value =~ /BOOT_VERSION=\Q'
          . $BOOT_VERSION
          . '\E/  ]' );

}

for ( path->with('.gitignore') ) {
    $_->should('exist');
    next unless $_->test('exist');
    $_->should( have_line_matching => qr{\A/target} );
    $_->should( have_line_matching => qr{\A\.nrepl-\*\z} );
    $_->should( have_line_matching => qr{\A\*~\z} );
}
for ( path->with('jitpack.yml') ) {
    $_->should('exist');
    next unless $_->test('exist');
    my $yaml = yaml->with('jitpack.yml');
    $yaml->should( have_dpath => '//jdk' );
    $yaml->should( have_dpath => '//env/*[ key eq "BOOT_VERSION" && value eq "'
          . $BOOT_VERSION
          . '" ]' );

}

for ( path->with('.mailmap') ) {
    $_->should('exist');
    next unless $_->test('exist');

}
for ( path->with('resources') ) {
    $_->should('exist');
    next unless $_->test('exist');
    path->should( exist => 'resources/README.md' );
}

use My::Generic::Assertions;

BEGIN {

    package My::Assert::YAML;
    use YAML::XS qw();
    use Data::DPath qw( dpath );
    use Term::ANSIColor qw( colored );

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
                yaml => YAML::XS::Load(
                    My::Assert::Path::assert->get( 'utf8', $_[1] )
                ),
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
    use Data::Dump qw(pp);

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

}

BEGIN {

    package My::Assert::Git;

    our $WRAPPER;

    use YAML::XS qw();

    our $ASSERT_GIT = My::Generic::Assertions->new(
        '-input_transformer' => \&transform_input,
        -tests               => {
            be_in_git         => \&test_be_in_git,
            have_tag_matching => \&test_have_tag_matching,
        },
        '-get_handler' => \&handle_get,
    );

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
}

