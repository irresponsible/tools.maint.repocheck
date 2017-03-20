#!perl
use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/lib";

use My::Assert::Path qw/path/;
use My::Assert::YAML qw/yaml/;
use My::Assert::Git qw/git/;

our $BOOT_VERSION    = '2.7.1';
our $CLOJURE_VERSION = '1.9.0-alpha15';

check_boot_properties('boot.properties');
check_build_boot('build.boot');
check_changelog('CHANGELOG');
check_readme('README.md');
check_travis_yml('.travis.yml');
check_gitignore('.gitignore');
check_jitpack_yml('jitpack.yml');
check_mailmap('.mailmap');
check_resources('resources');

sub check_boot_properties {
    my ($file) = @_;
    path->should( 'exist' => $file );
    next unless path->test( 'exist' => $file );
    path->should(
        have_line_matching => $file,
        qr/\ABOOT_CLOJURE_VERSION=\Q$CLOJURE_VERSION\E\z/
    );
    path->should(
        have_line_matching => $file,
        qr/\ABOOT_VERSION=\Q$BOOT_VERSION\E\z/
    );

}

sub check_build_boot {
    my ($file) = @_;
    path->should( exist => $file );
}

sub check_changelog {
    my ($file) = @_;

    path->should( exist => $file );
    return unless path->test( exist => $file );

    git()->should('be_in_git');
    return unless git()->test('be_in_git');

    check_changelog_has_tags($file);
    check_tags_for_changelog($file);
}

sub check_changelog_has_tags {
    my ($file) = @_;
    git()->must('be_in_git');
    for my $tag ( git()->get('tags') ) {
        next unless $tag =~ /\Av?(\d.*)\z/;
        my $version = $1;
        path->should(
            'have_line_matching', $file,
            qr/\Av?\Q$version\E($|\s+-\s+\S)/,
            "Version = $version"
        );
    }
}

sub check_tags_for_changelog {
    my ($file) = @_;
    git()->must('be_in_git');

    for my $line ( path->get( 'lines', $file ) ) {
        next unless $line =~ /\Av?(\d[^\s]*)(?:$|\s+-\s+\S)/;
        my $version = $1;
        git()
          ->should( 'have_tag_matching', qr/\Av?\Q$version\E\z/,
            "Version = $version" );
    }
}

sub check_readme {
    my ($file) = @_;
    path->should( exist => $file );
}

sub check_travis_yml {
    my ($file) = @_;
    path->should( exist => $file );
    next unless path->test( exist => $file );

    my $jdk8_rule =
      '//matrix/include/*/*[ key eq q[jdk] && value eq q[oraclejdk8] ]';

    my $boot_rule =
        '//matrix/include/*/*[ key eq "env" && value =~ /BOOT_VERSION=\Q'
      . $BOOT_VERSION
      . '\E/  ]';

    yaml->should( have_dpath => $file, $jdk8_rule );
    yaml->should( have_dpath => $file, '//cache' );
    yaml->should( have_dpath => $file, '//sudo' );
    yaml->should( have_dpath => $file, '//script' );
    yaml->should( have_dpath => $file, '//install' );
    yaml->should( have_dpath => $file, $boot_rule );
}

sub check_gitignore {
    my ($file) = @_;
    path->should( exist => $file );
    next unless path->test( exist => $file );
    path->should( have_line_matching => $file, qr{\A/target} );
    path->should( have_line_matching => $file, qr{\A\.nrepl-\*\z} );
    path->should( have_line_matching => $file, qr{\A\*~\z} );
}

sub check_jitpack_yml {
    my ($file) = @_;
    path->should( exist => $file );
    return unless path->test( exist => $file );

    my $dpath_rule =
      '//env/*[ key eq "BOOT_VERSION" && value eq "' . $BOOT_VERSION . '" ]';
    yaml->should( have_dpath => $file, '//jdk' );
    yaml->should( have_dpath => $file, $dpath_rule );
}

sub check_mailmap {
    my ($file) = @_;
    path->should( exist => $file );
    return unless path->test( 'exist', $file );
}

sub check_resources {
    my ($dir) = @_;
    path->should( 'exist' => $dir );
    return unless path->test( 'exist' => $dir );
    path->should( 'exist' => $dir . '/README.md' );
}
