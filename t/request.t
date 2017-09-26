#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';

use Carp qw(croak);
use Test::More tests => 2;
use LWP::UserAgent;

BEGIN {
    no warnings 'redefine';

    *LWP::UserAgent::request = sub {
        croak 'oops';
    };

    $ENV{PERL_TEST_LWP_CAPTURE} = 1;
}

use Test::LWP::Capture file => __FILE__ . '.got';

my $response = eval { LWP::UserAgent->new()->get('http://www.example.com/') };
like($@, qr/^oops/, 'Request should fail');

Test::LWP::Capture::_flush;
ok(!-e __FILE__ . '.got', 'Interrupted session should never be wtitten');
