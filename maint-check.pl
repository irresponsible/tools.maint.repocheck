#!perl
use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/lib";

use My::Assert::Path qw/path/;
use My::Assert::YAML qw/yaml/;
use My::Assert::Git qw/git/;

use constant BOOT_VERSION    => '2.7.1';
use constant CLOJURE_VERSION => '1.9.0-alpha15';

check_boot_properties(
    'boot.properties' => {
        boot_version    => BOOT_VERSION,
        clojure_version => CLOJURE_VERSION,
    },
);
check_build_boot('build.boot');
check_changelog('CHANGELOG');
check_readme('README.md');
check_travis_yml(
    '.travis.yml' => {
        boot_version => BOOT_VERSION,
    },
);
check_gitignore('.gitignore');
check_jitpack_yml(
    'jitpack.yml' => {
        boot_version => BOOT_VERSION,
    },
);
check_mailmap('.mailmap');
check_resources('resources');

exit;

sub check_boot_properties {
    my ( $file, $opts ) = @_;
    my $boot_version = $opts->{boot_version};
    my $clj_version  = $opts->{clojure_version};

    path->should( 'exist' => $file );
    return unless path->test( 'exist' => $file );
    path->should(
        have_line_matching => $file,
        qr/\ABOOT_CLOJURE_VERSION=\Q$clj_version\E\z/
    );
    path->should(
        have_line_matching => $file,
        qr/\ABOOT_VERSION=\Q$boot_version\E\z/
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
    my ( $file, $opts ) = @_;

    path->should( exist => $file );
    return unless path->test( exist => $file );

    my $boot_version = $opts->{boot_version};
    my $jdk8_rule =
      '//matrix/include/*/*[ key eq q[env] && value =~ qr[JDK=zulu8] ]';

    yaml->should( have_dpath => $file, $jdk8_rule );
    yaml->should( have_dpath => $file, '//cache' );
    yaml->should( have_dpath => $file, '//language[ value eq q{generic} ]' );
    yaml->should_not(
        have_dpath => $file,
        '//cache/directories/*[ value =~ qr{$HOME/zulu} ]'
    );
    yaml->should( have_dpath => $file, '//matrix/allow_failures' );
    yaml->should( have_dpath => $file, '//sudo' );
    yaml->should( have_dpath => $file, '//script' );
    yaml->should( have_dpath => $file, '//install' );
    yaml->should(
        have_dpath => $file,
        '//before_install/*[ value =~ qr{curl.*init.sh} ]'
    );
    yaml->should(
        have_dpath => $file,
        '//before_install/*[ value =~ qr{source init.sh} ]'
    );
    yaml->should(
        have_dpath => $file,
        '//before_install/*[ value =~ qr{install_jdk} ]'
    );
    yaml->should(
        have_dpath => $file,
        '//before_install/*[ value =~ qr{install_boot} ]'
    );
    yaml->should(
        have_dpath => $file,
        '//before_install/*[ value =~ qr{setup_boot_env} ]'
    );
    yaml->should_not(
        have_dpath => $file,
        '//install/*[ value =~ qr{curl.*boot.sh} ]'
    );
    yaml->should_not(
        have_dpath => $file,
        '//install/*[ value =~ qr{chmod.*boot} ]'
    );
    yaml->should_not(
        have_dpath => $file,
        '//install/*[ value =~ qr{export BOOT_JVM_OPTIONS=} ]'
    );
}

sub check_gitignore {
    my ($file) = @_;
    path->should( exist => $file );
    return unless path->test( exist => $file );
    path->should( have_line_matching => $file, qr{\A/target} );
    path->should( have_line_matching => $file, qr{\A\.nrepl-\*\z} );
    path->should( have_line_matching => $file, qr{\A\*~\z} );
}

sub check_jitpack_yml {
    my ( $file, $opts ) = @_;
    path->should( exist => $file );
    return unless path->test( exist => $file );

    my $boot_version = $opts->{boot_version};
    my $dpath_rule =
      '//env/*[ key eq "BOOT_VERSION" && value eq "' . $boot_version . '" ]';
    yaml->should_not( have_dpath => $file, '//jdk' );
    yaml->should_not( have_dpath => $file, '//env' );
    yaml->should_not( have_dpath => $file, $dpath_rule );
    yaml->should(
        have_dpath => $file,
        '//before_install/*[ value =~ qr{curl.*init.sh} ]'
    );
    yaml->should(
        have_dpath => $file,
        '//before_install/*[ value =~ qr{source init.sh} ]'
    );
    yaml->should(
        have_dpath => $file,
        '//before_install/*[ value =~ qr{install_jdk} ]'
    );
    yaml->should(
        have_dpath => $file,
        '//before_install/*[ value =~ qr{install_boot} ]'
    );
    yaml->should(
        have_dpath => $file,
        '//before_install/*[ value =~ qr{setup_boot_env} ]'
    );
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
