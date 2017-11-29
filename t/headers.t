#!perl -T

use 5.006;
use strict;
use warnings FATAL => 'all';

use Test::File::Contents;
use Test::More tests => 2;
use LWP::UserAgent;

BEGIN {
    no warnings 'redefine';

    *LWP::UserAgent::request = sub {
        shift->prepare_request(shift); # populate request with default headers
        return HTTP::Response->new(
            200, 'Ok',
            [
                'Hdr-Should-Be-Removed', 'yes',
                'Hdr-Should-Be-Removed-Also' => 'yes',
                'Hdr-Should-Remain', 'yes'
            ],
            'Body here'
        );
    };

    $ENV{PERL_TEST_LWP_CAPTURE} = 1;

    $ENV{TEST_LWP_CAPTURE_ACCEPT_REQ_HDR}   = '^Hdr-Should-Remain$';
    $ENV{TEST_LWP_CAPTURE_DISCARD_REQ_HDR}  = 'Hdr-Should-Be-Removed';

    $ENV{TEST_LWP_CAPTURE_ACCEPT_RESP_HDR}  = '^Hdr-Should-Remain$';
    $ENV{TEST_LWP_CAPTURE_DISCARD_RESP_HDR} = 'Hdr-Should-Be-Removed';
}

use constant STORAGE =>  __FILE__ . '.got';
use Test::LWP::Capture file => STORAGE;
unlink STORAGE;

my $ua = LWP::UserAgent->new(agent => 'Test::LWP::Capture');

my $response = $ua->get(
    'http://www.example.com/',
    'Hdr-Should-Be-Removed' => 'yes',
    'Hdr-Should-Be-Removed-Also' => 'yes',
    'Hdr-Should-Remain' => 'yes'
);
is(
    $response->as_string,
    "200 Ok\nHdr-Should-Remain: yes\n\nBody here\n",
    "request and response procesed by hooks"
);

Test::LWP::Capture::_flush;
delete $ENV{PERL_TEST_LWP_CAPTURE}; # don't overwrite .got file on END
files_eq_or_diff(__FILE__ . '.exp', __FILE__ . '.got', "File contents");
unlink STORAGE;

