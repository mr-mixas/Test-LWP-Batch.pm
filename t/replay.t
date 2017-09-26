#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More tests => 5;
use LWP::UserAgent;

BEGIN {
    no warnings 'redefine';

    *LWP::UserAgent::request = sub {
        BAIL_OUT("LWP::UserAgent::request shudn't be called at replay mode");
    };

    $ENV{PERL_TEST_LWP_CAPTURE} = 0;
};

use Test::LWP::Capture file => __FILE__ . '.cap';

my $response = LWP::UserAgent->new()->get('http://www.example.com/');
is($response->as_string, "200 All goes well\nMocked: yes\n\n", 'example.com response');

$response = LWP::UserAgent->new()->get('http://www.example.org/');
is($response->as_string, "200 All goes well\nMocked: yes\n\n", 'example.org response');

$response = LWP::UserAgent->new()->get('http://www.example.com/');
is($response->as_string, "200 All goes well\nMocked: yes\n\n", 'example.org response');

$response = eval { LWP::UserAgent->new()->get('http://www.example.com/uncaptured') };
like($@, qr/No such request has been captured \(storage exhausted\)/);

Test::LWP::Capture->import(file => __FILE__ . '.cap'); # reload storage

$response = eval { LWP::UserAgent->new()->get('http://www.example.com/uncaptured') };
like($@, qr#Request mismatch, expected:\nGET http://www.example.com/uncaptured\n\n\ngot in storage:\nGET http://www.example.com/\n\n#);
