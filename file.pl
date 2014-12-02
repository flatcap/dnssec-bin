#!/usr/bin/perl

use strict;
use warnings;

use JSON;
use Data::Dumper;
use REST::Client;
use MIME::Base64;

my $file = 'keys/dsset-russon.org.';
open my $info, $file or die "Could not open $file: $!";

my @ds_list;

while (<$info>) {
	chomp;
	my ($zone, $class, $rr, $key, $algo, $dtype, $digest) = split ("[ \t]+", $_, 7);
	$digest =~ s/ //g;
	# printf ("%s\t%s\t%s\t%d\t%d\t%d\t%s\n", $zone, $class, $rr, $key, $algo, $dtype, $digest);

	push (@ds_list, { keyTag => $key, algorithm => $algo, digestType => $dtype, digest => $digest });
}

close $info;

print Dumper (@ds_list);

