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

=item * Sessions correctly handled

=item * VCS aware

=back

=cut

my %OPTS;
my $DATA;

BEGIN {
    my $orig_method = \&LWP::UserAgent::request;
    no warnings 'redefine';

    *LWP::UserAgent::request = sub {
        local *LWP::UserAgent::request = $orig_method;
        _wrapper(@_);
    }
}

sub _croak {
    require Carp;
    Carp::croak @_;
    delete $OPTS{file}; # to prevent file corruption (END executed on die)
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

sub _wrapper {
    my ($obj, $req) = @_;

    my $request = $req->clone(); # 'canonize' it for correct serialize/parse roundtrip
    my $response;

    if ($ENV{PERL_TEST_LWP_CAPTURE}) {
        $response = LWP::UserAgent::request($obj, $req);
        push @{$DATA}, $request, $response;
    } else {
        my $key = $request->as_string;
        _croak "No such request found among captured"
            unless (exists $DATA->{$key}->[0]);
        $response = HTTP::Response->parse($DATA->{$key}->[0]);
    }

    return $response;
}

sub import {
    (undef, %OPTS) = @_;

    _croak "Option 'file' must be defined"
        unless (defined $OPTS{file});

    unless ($ENV{PERL_TEST_LWP_CAPTURE}) {
        open(my $fh, '<', $OPTS{file}) or
            _croak "Failed to open file '$OPTS{file}' ($!)";
        my $data = do { local $/; <$fh> }; # load whole file
        close($fh);

        for (split /REQUEST:\n/, $data) {
            next if ($_ eq ''); # skip first empty field;
            my ($request, $response) = split(/RESPONSE:\n/, $_);
            $request  = _decode($request);
            $response = _decode($response);
            push @{$DATA->{$request}}, $response;
        }
    }
}

END {
    if ($DATA and defined $OPTS{file} and $ENV{PERL_TEST_LWP_CAPTURE}) {
        open(my $fh, '>', $OPTS{file}) or
            _croak "Failed to open file '$OPTS{file}' ($!)";
        while (@{$DATA}) {
            my ($request, $response) = splice @{$DATA}, 0, 2;
            print $fh "REQUEST:\n",  _encode($request->as_string);
            print $fh "RESPONSE:\n", _encode($response->as_string);
        }
        close($fh);
    }
}

=head1 ENVIRONMENT

=over 4

=item B<PERL_TEST_LWP_CAPTURE>

Request/response pairs will be recaptured if set to some true value.

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
