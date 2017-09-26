#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More tests => 2;

BEGIN {
    require_ok('Test::LWP::Capture') || print "Bail out!\n";
}

diag( "Testing Test::LWP::Capture $Test::LWP::Capture::VERSION, Perl $], $^X" );

eval { Test::LWP::Capture->import() };
like($@, qr/Option 'file' must be defined/);
