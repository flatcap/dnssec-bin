#!/usr/bin/perl

use strict;
use warnings;

use JSON;
use Data::Dumper;
use REST::Client;
use MIME::Base64;

my $dirname = "/var/named/keys";
opendir my($dh), $dirname or die "Couldn't open dir '$dirname': $!";

# my @files = readdir $dh;
# my @files = grep { !/^\.\.?$/ } readdir $dh;
my @files = grep { /^dsset-.*\.$/ } readdir $dh;

closedir $dh;

print Dumper (@files);
