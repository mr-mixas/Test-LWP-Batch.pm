#!perl -T

use 5.006;
use strict;
use warnings FATAL => 'all';

use Test::File::Contents;
use Test::More tests => 4;
use LWP::UserAgent;

BEGIN {
    no warnings 'redefine';

    *LWP::UserAgent::request = sub {
        shift->prepare_request(shift); # populate request with default headers
        return HTTP::Response->new(200, "Ok", ["Header","here"], "Body here");
    };

    $ENV{PERL_TEST_LWP_CAPTURE} = 1;
}

use Test::LWP::Capture file => __FILE__ . '.got';

my $ua = LWP::UserAgent->new(agent => 'Test::LWP::Capture');

my $response = $ua->get('http://www.example.com/');
is($response->as_string, "200 Ok\nHeader: here\n\nBody here\n", 'example.com response');

$response = $ua->get('http://www.example.org/');
is($response->as_string, "200 Ok\nHeader: here\n\nBody here\n", 'example.org response');

$response = $ua->get('http://www.example.com/');
is($response->as_string, "200 Ok\nHeader: here\n\nBody here\n", 'example.org response');

Test::LWP::Capture::_flush;
delete $ENV{PERL_TEST_LWP_CAPTURE}; # don't overwrite .got file on END
files_eq_or_diff(__FILE__ . '.exp', __FILE__ . '.got', "File contents");

