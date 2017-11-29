# NAME

Test::LWP::Capture - Mock LWP requests using captured data

<a href="https://travis-ci.org/mr-mixas/Test-LWP-Capture.pm"><img src="https://travis-ci.org/mr-mixas/Test-LWP-Capture.pm.svg?branch=master" alt="CI"></a>
<a href='https://coveralls.io/github/mr-mixas/Test-LWP-Capture.pm?branch=master'><img src='https://coveralls.io/repos/github/mr-mixas/Test-LWP-Capture.pm/badge.svg?branch=master' alt='Coverage Status' /></a>
<a href="https://badge.fury.io/pl/Test-LWP-Capture"><img src="https://badge.fury.io/pl/Test-LWP-Capture.svg" alt="CPAN version"></a>

# VERSION

Version 0.01

# SYNOPSIS

In test file:

    use Test::More;
    use Test::LWP::Capture file => '/path/to/file';

    # arbitrary code with LWP usage

or in command line:

    perl -MTest::LWP::Capture=file,captured.txt ./app.pl

# EXPORT

Nothing is exported.

# DESCRIPTION

Distinct feautures:

- Mock LWP requests for standalone perl programs out of the box
- VCS friendly request/response dumps

# ENVIRONMENT

- __PERL\_TEST\_LWP\_CAPTURE__

    Request/response pairs will be recaptured if set to some true value.

- __TEST\_LWP\_CAPTURE\_ACCEPT\_REQ\_HDR__, __TEST\_LWP\_CAPTURE\_ACCEPT\_RESP\_HDR__

    All headers match provided regexp will be captured, for requests and responces
    respectively. Ignored if not defined.

- __TEST\_LWP\_CAPTURE\_DISCARD\_REQ\_HDR__, __TEST\_LWP\_CAPTURE\_DISCARD\_RESP\_HDR__

    All headers match provided regexp will be discarded (higher priority than
    according `ACCEPT` env var. For requests and responces respectively. Ignored
    if not defined.

# AUTHOR

Michael Samoglyadov, `<mixas at cpan.org>`

# BUGS

Please report any bugs or feature requests to `bug-test-lwp-cmd at rt.cpan.org`,
or through the web interface at
[http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Test-LWP-Capture](http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Test-LWP-Capture). I will be
notified, and then you'll automatically be notified of progress on your bug as
I make changes.

# SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Test::LWP::Capture

You can also look for information at:

- RT: CPAN's request tracker (report bugs here)

    [http://rt.cpan.org/NoAuth/Bugs.html?Dist=Test-LWP-Capture](http://rt.cpan.org/NoAuth/Bugs.html?Dist=Test-LWP-Capture)

- AnnoCPAN: Annotated CPAN documentation

    [http://annocpan.org/dist/Test-LWP-Capture](http://annocpan.org/dist/Test-LWP-Capture)

- CPAN Ratings

    [http://cpanratings.perl.org/d/Test-LWP-Capture](http://cpanratings.perl.org/d/Test-LWP-Capture)

- Search CPAN

    [http://search.cpan.org/dist/Test-LWP-Capture/](http://search.cpan.org/dist/Test-LWP-Capture/)

# LICENSE AND COPYRIGHT

Copyright 2017 Michael Samoglyadov.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See [http://dev.perl.org/licenses/](http://dev.perl.org/licenses/) for more information.

# SEE ALSO

[Test::LWP::Recorder](https://metacpan.org/pod/Test::LWP::Recorder), [Test::VCR::LWP](https://metacpan.org/pod/Test::VCR::LWP)
