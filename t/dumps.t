#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More tests => 2;

require Test::LWP::Capture;

eval { Test::LWP::Capture::_load_dump('/no/such/file/ever/existed') };
like($@, qr#Failed to open file '/no/such/file/ever/existed' \(No such file or directory\) #, "Open: file not exists");

eval { Test::LWP::Capture::_save_dump([], '/no/such/path/to/file/ever/existed') };
like($@, qr#Failed to open file '/no/such/path/to/file/ever/existed' \(No such file or directory\) #, "Open: file not exists");

