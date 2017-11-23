#!perl -T

use 5.006;
use strict;
use warnings FATAL => 'all';

use Test::File::Contents;
use Test::More tests => 6;
use LWP::UserAgent;

BEGIN {
    no warnings 'redefine';

    *LWP::UserAgent::request = sub {
        shift->prepare_request(shift); # populate request with default headers
        return HTTP::Response->new(
            200, 'Ok',
            [
                'Hdr-Should-Be-Removed', 'yes',
                'Hdr-Should-Remain', 'yes'
            ],
            'Body here'
        );
    };

    $ENV{PERL_TEST_LWP_CAPTURE} = 1;
}


use constant STORAGE =>  __FILE__ . '.got';
use Test::LWP::Capture file => STORAGE;
unlink STORAGE;

my $ua = LWP::UserAgent->new(agent => 'Test::LWP::Capture');

$Test::LWP::Capture::HOOK_POST_REQUEST = sub {
    isa_ok($_[0], 'HTTP::Request');
    $_[0]->remove_header('Hdr-Should-Be-Removed');
};

$Test::LWP::Capture::HOOK_RESPONSE = sub {
    isa_ok($_[0], 'HTTP::Response');
    $_[0]->remove_header('Hdr-Should-Be-Removed');
};

my $response = $ua->get(
    'http://www.example.com/',
    'Hdr-Should-Be-Removed' => 'yes',
    'Hdr-Should-Remain' => 'yes'
);
is(
    $response->as_string,
    "200 Ok\nHdr-Should-Remain: yes\n\nBody here\n",
    "request and response procesed by hooks"
);

$Test::LWP::Capture::HOOK_POST_REQUEST = sub { undef };
eval { $ua->get('http://www.example.org/') };
like(
    $@, qr|^Request hook failed for GET http://www\.example\.org/|,
    'Request hook failed'
);
$ENV{PERL_TEST_LWP_CAPTURE} = 1; # re-enable .got file writing

$Test::LWP::Capture::HOOK_POST_REQUEST = undef; # disabled
$Test::LWP::Capture::HOOK_RESPONSE = sub { undef };
eval { $ua->get('http://www.example.org/') };
like(
    $@, qr|^Response hook failed for GET http://www\.example\.org/|,
    'Response hook failed'
);
$ENV{PERL_TEST_LWP_CAPTURE} = 1; # re-enable .got file writing

Test::LWP::Capture::_flush;
delete $ENV{PERL_TEST_LWP_CAPTURE}; # don't overwrite .got file on END
files_eq_or_diff(__FILE__ . '.exp', __FILE__ . '.got', "File contents");
unlink STORAGE;

