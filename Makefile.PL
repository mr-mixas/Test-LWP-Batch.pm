use 5.006;
use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Test::LWP::Capture',
    AUTHOR           => 'Michael Samoglyadov <mixas@cpan.org>',
    VERSION_FROM     => 'lib/Test/LWP/Capture.pm',
    ABSTRACT_FROM    => 'lib/Test/LWP/Capture.pm',
    LICENSE          => 'Perl_5',
    PL_FILES         => {},
    MIN_PERL_VERSION => 5.006,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES => {
        'Test::File::Contents'  => 0,
        'Test::More'            => 0,
    },
    META_MERGE => {
        resources => {
            repository  => 'https://github.com/mr-mixas/Test-LWP-Capture.pm',
        },
    },
    PREREQ_PM => {
        'HTTP::Request'       => 0,
        'HTTP::Response'      => 0,
        'LWP::UserAgent'      => 0,
    },
    dist  => {
        COMPRESS => 'gzip -9f',
        SUFFIX => 'gz',
    },
    clean => {
        FILES => 'Test-LWP-Capture-* t/*.got',
    },
);
