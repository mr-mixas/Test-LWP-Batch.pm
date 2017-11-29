package Test::LWP::Capture;

use 5.006;
use strict;
use warnings FATAL => 'all';

use HTTP::Request;
use HTTP::Response;
use LWP::UserAgent;

=head1 NAME

Test::LWP::Capture - Mock LWP requests using captured data

=begin html

<a href="https://travis-ci.org/mr-mixas/Test-LWP-Capture.pm"><img src="https://travis-ci.org/mr-mixas/Test-LWP-Capture.pm.svg?branch=master" alt="CI"></a>
<a href='https://coveralls.io/github/mr-mixas/Test-LWP-Capture.pm?branch=master'><img src='https://coveralls.io/repos/github/mr-mixas/Test-LWP-Capture.pm/badge.svg?branch=master' alt='Coverage Status' /></a>
<a href="https://badge.fury.io/pl/Test-LWP-Capture"><img src="https://badge.fury.io/pl/Test-LWP-Capture.svg" alt="CPAN version"></a>

=end html

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

In test file:

    use Test::More;
    use Test::LWP::Capture file => '/path/to/file';

    # arbitrary code with LWP usage

or in command line:

    perl -MTest::LWP::Capture=file,captured.txt ./app.pl

=head1 EXPORT

Nothing is exported.

=head1 DESCRIPTION

Distinct feautures:

=over 4

=item * Mock LWP requests for standalone perl programs out of the box

=item * VCS friendly request/response dumps

=back

=cut

my %OPTS;
my $DATA;

our $HOOK_POST_REQUEST;
our $HOOK_RESPONSE;

our $ACCEPT_REQ_HDR;
our $DISCARD_REQ_HDR;
our $ACCEPT_RESP_HDR;
our $DISCARD_RESP_HDR;

BEGIN {
    my $orig_method = \&LWP::UserAgent::request;
    no warnings 'redefine';

    *LWP::UserAgent::request = sub {
        local *LWP::UserAgent::request = $orig_method;
        _wrapper(@_);
    };

    $ACCEPT_REQ_HDR = qr/$ENV{TEST_LWP_CAPTURE_ACCEPT_REQ_HDR}/
        if (defined $ENV{TEST_LWP_CAPTURE_ACCEPT_REQ_HDR});
    $DISCARD_REQ_HDR = qr/$ENV{TEST_LWP_CAPTURE_DISCARD_REQ_HDR}/
        if (defined $ENV{TEST_LWP_CAPTURE_DISCARD_REQ_HDR});
    $ACCEPT_RESP_HDR = qr/$ENV{TEST_LWP_CAPTURE_ACCEPT_RESP_HDR}/
        if (defined $ENV{TEST_LWP_CAPTURE_ACCEPT_RESP_HDR});
    $DISCARD_RESP_HDR = qr/$ENV{TEST_LWP_CAPTURE_DISCARD_RESP_HDR}/
        if (defined $ENV{TEST_LWP_CAPTURE_DISCARD_RESP_HDR});
}

sub _croak {
    $ENV{PERL_TEST_LWP_CAPTURE} = 0; # don't dump garbage

    require Carp;
    Carp::croak @_;
}

sub _decode {
    my $data = shift;
    $data =~ s/^\t//gm;
    return $data;
}

sub _encode {
    my $data = shift;
    $data =~ s/^/\t/gm;
    return $data;
}

sub _flush {
    _save_dump($DATA, $OPTS{file}) if ($ENV{PERL_TEST_LWP_CAPTURE});
}

sub _load_dump {
    my $file = shift;
    my $out;

    open(my $fh, '<', $file) or _croak "Failed to open file '$file' ($!)";
    my $data = do { local $/; <$fh> }; # load whole file
    close($fh);

    $data = [ split /REQUEST:\n/, $data ];
    shift @{$data}; # throw away unexisted field

    for (@{$data}) {
        my ($request, $response) = split(/RESPONSE:\n/, $_);
        chomp $response;
        push @{$out}, _decode($request), _decode($response);
    }

    return $out;
}

sub _save_dump {
    my ($data, $file) = @_;

    open(my $fh, '>', $file) or _croak "Failed to open file '$file' ($!)";

    while (@{$data}) {
        print $fh "REQUEST:\n",  _encode(shift @{$data});
        print $fh "RESPONSE:\n", _encode(shift @{$data});
    }

    close($fh);
}

sub _remove_headers {
    my ($msg, $accept, $discard) = @_;

    for my $hdr ($msg->headers->header_field_names) {
        if (defined $discard and $hdr =~ $discard) {
            $msg->remove_header($hdr);
            next;
        }

        $msg->remove_header($hdr)
            if (defined $accept and $hdr !~ $accept);
    }
}

sub _wrapper {
    my ($self, $request) = @_;
    my $response;

    if ($ENV{PERL_TEST_LWP_CAPTURE}) {
        $response = eval { LWP::UserAgent::request($self, $request) };
        _croak $@ if ($@);

        if ($HOOK_POST_REQUEST) {
            $HOOK_POST_REQUEST->($request) or
                _croak "Request hook failed for " . $request->as_string;
        }
        _remove_headers($request, $ACCEPT_REQ_HDR, $DISCARD_REQ_HDR);

        if ($HOOK_RESPONSE) {
            $HOOK_RESPONSE->($response) or
                _croak "Response hook failed for " . $request->as_string;
        }
        _remove_headers($response, $ACCEPT_RESP_HDR, $DISCARD_RESP_HDR);

        push @{$DATA}, $request->as_string, $response->as_string;
    } else {
        $self->prepare_request($request); # populate request with default headers
        _remove_headers($request, $ACCEPT_REQ_HDR, $DISCARD_REQ_HDR);

        my ($key, $val) = splice @{$DATA}, 0, 2;
        _croak "No such request has been captured (storage exhausted):\n" .
            $request->as_string unless (defined $key);
        _croak "Request mismatch, expected:\n" . $request->as_string .
            "\ngot in storage:\n" . $key unless ($request->as_string eq $key);

        $response = HTTP::Response->parse($val);
    }

    return $response;
}

sub import {
    (undef, %OPTS) = @_;

    _croak "Option 'file' must be defined"
        unless (defined $OPTS{file});

    $DATA = _load_dump($OPTS{file})
        unless ($ENV{PERL_TEST_LWP_CAPTURE});
}

END {
    _flush
};

=head1 ENVIRONMENT

=over 4

=item B<PERL_TEST_LWP_CAPTURE>

Request/response pairs will be recaptured if set to some true value.

=item B<TEST_LWP_CAPTURE_ACCEPT_REQ_HDR>, B<TEST_LWP_CAPTURE_ACCEPT_RESP_HDR>

All headers match provided regexp will be captured, for requests and responces
respectively. Ignored if not defined.

=item B<TEST_LWP_CAPTURE_DISCARD_REQ_HDR>, B<TEST_LWP_CAPTURE_DISCARD_RESP_HDR>

All headers match provided regexp will be discarded (higher priority than
according C<ACCEPT> env var. For requests and responces respectively. Ignored
if not defined.

=back

=head1 AUTHOR

Michael Samoglyadov, C<< <mixas at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-test-lwp-cmd at rt.cpan.org>,
or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Test-LWP-Capture>. I will be
notified, and then you'll automatically be notified of progress on your bug as
I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Test::LWP::Capture

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Test-LWP-Capture>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Test-LWP-Capture>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Test-LWP-Capture>

=item * Search CPAN

L<http://search.cpan.org/dist/Test-LWP-Capture/>

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2017 Michael Samoglyadov.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See L<http://dev.perl.org/licenses/> for more information.

=head1 SEE ALSO

L<Test::LWP::Recorder>, L<Test::VCR::LWP>

=cut

1; # End of Test::LWP::Capture
