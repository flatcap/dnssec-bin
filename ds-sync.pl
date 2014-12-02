#!/usr/bin/perl

use strict;
use warnings;

use JSON;
use Data::Dumper;
use REST::Client;
use MIME::Base64;

my $username = 'flatcap';
my $password = 'ha2meiChu8';

sub get_files
{
	my ($domain) = @_;
	my $keydir = 'keys';
	my $file = "$keydir/dsset-$domain.";

	my $info;
	unless (open $info, $file) {
		 print STDERR "Can't open $file: $!\n";
		 return;
	}

	my @ds_list;

	while (<$info>) {
		chomp;
		my ($zone, $class, $rr, $key, $algo, $dtype, $digest) = split ("[ \t]+", $_, 7);
		$digest =~ s/ //g;
		push (@ds_list, { keyTag => $key, algorithm => $algo, digestType => $dtype, digest => $digest });
	}

	close $info;

	return @ds_list;
}

sub get_gkg
{
	my ($domain) = @_;
	my $host     = 'https://www.gkg.net';
	my $url      = "/ws/domain/$domain/ds";
	my $headers  = { Accept => 'application/json', Authorization => 'Basic ' . encode_base64($username . ':' . $password) };

	my $client = REST::Client->new();
	$client->setHost($host);

	$client->GET($url, $headers);

	my $code = $client->responseCode();
	if ($code != '200') {
		print STDERR "Can't get info from gkg: $code\n";
		return;
	}

	return @{from_json($client->responseContent())};
}

sub main
{
	my $domain   = 'russon.org';

	my @ds_list  = get_files ($domain);
	if (@ds_list == 0) {
		return 1;
	}
	# print Dumper (@ds_list);
	my %ds_digest;
	foreach (keys @ds_list) {
		my $digest = $ds_list[$_]{'digest'};
		$ds_digest{$digest} = ();
	}
	# print Dumper (%ds_digest);

	my @gkg_list = get_gkg ($domain);
	if (@gkg_list == 0) {
		return 1;
	}
	# print Dumper (@gkg_list);

	my %gkg_digest;
	foreach (keys @gkg_list) {
		my $digest = $gkg_list[$_]{'digest'};
		$gkg_digest{$digest} = ();
	}
	# print Dumper (%gkg_digest);

	foreach (keys %ds_digest) {
		if (exists $gkg_digest{$_}) {
			printf "exists on server\n";
		} else {
			printf "need to upload: $_\n";
		}
	}

	foreach (keys %gkg_digest) {
		if (exists $ds_digest{$_}) {
			printf "matches local file\n";
		} else {
			printf "need to delete: $_\n";
		}
	}

	return 0;
}


exit main();

