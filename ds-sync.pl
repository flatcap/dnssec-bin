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

	my %ds_list;

	while (<$info>) {
		chomp;
		my ($zone, $class, $rr, $key, $algo, $dtype, $digest) = split ("[ \t]+", $_, 7);
		$digest =~ s/ //g;
		$ds_list{$digest} = { keyTag => $key, algorithm => $algo, digestType => $dtype, digest => $digest };
	}

	close $info;

	return %ds_list;
}

sub get_gkg
{
	my ($domain) = @_;
	my $host     = 'https://www.gkg.net';
	my $url      = "/ws/domain/$domain/ds";
	my $headers  = { Accept => 'application/json', Authorization => 'Basic ' . encode_base64 ($username . ':' . $password) };

	my $client = REST::Client->new();
	$client->setHost ($host);

	$client->GET ($url, $headers);

	my $code = $client->responseCode();
	if ($code != '200') {
		print STDERR "Can't get info from gkg: $code\n";
		return;
	}

	my %gkg_list;

	foreach (@{from_json ($client->responseContent())}) {
		my $digest = $_->{'digest'};
		$gkg_list{$digest} = $_;
	}

	return %gkg_list;
}

sub create_ds
{
	my ($domain, $key, $algo, $dtype, $digest) = @_;

	my $host = "https://www.gkg.net";
	my $url  = "/ws/domain/$domain/ds";

	my $headers = { Accept => 'application/json', Authorization => 'Basic ' . encode_base64 ($username . ':' . $password) };
	my $client = REST::Client->new();
	$client->setHost ($host);

	my $body = "{ \"digest\":\"$digest\", \"digestType\":\"$dtype\", \"algorithm\":\"$algo\", \"keyTag\":\"$key\", \"maxSigLife\":\"3456000\" }";
	# print "host = $host\n";
	# print "url  = $url\n";
	# print "body = $body\n";

	$client->POST($url, $body, $headers);
	# Responses:
	#	201 Created
	#	401 Unauthorized
	#	403 Forbidden
	#	404 Not Found
	#	415 Unsupported Media Type

	my $code = $client->responseCode();
	if ($code != '201') {
		print STDERR "Create failed: $code\n";
		return;
	}

	print "create succeeded: $digest\n";
	return 1;
}

sub delete_ds
{
	my ($domain, $digest) = @_;

	my $host = "https://www.gkg.net";
	my $url  = "/ws/domain/$domain/ds";

	my $headers = { Accept => 'application/json', Authorization => 'Basic ' . encode_base64 ($username . ':' . $password) };
	my $client = REST::Client->new();
	$client->setHost ($host);

	$url .= "/$digest";
	$client->DELETE ($url, $headers);
	# Responses:
	#	204 No Content
	#	401 Unauthorized
	#	403 Forbidden
	#	404 Not Found

	my $code = $client->responseCode();
	if ($code != '204') {
		print STDERR "Delete failed: $code\n";
		return;
	}

	return 1;
}


sub synchronise
{
	my ($domain) = @_;
	print "$domain:\n";

	my %ds_list = get_files ($domain);
	if (!%ds_list) {
		return 1
	}
	# print Dumper (%ds_list);

	my %gkg_list = get_gkg ($domain);
	if (!%gkg_list) {
		return 1;
	}
	# print Dumper (%gkg_list);

	foreach (keys %ds_list) {
		if (exists $gkg_list{$_}) {
			printf "\tSERVER: $_\n";
		} else {
			my $ds = $ds_list{$_};
			printf "Uploading $domain: $ds->{'digest'}\n";
			create_ds ($domain, $ds->{'keyTag'}, $ds->{'algorithm'}, $ds->{'digestType'}, $ds->{'digest'});
		}
	}

	foreach (keys %gkg_list) {
		if (exists $ds_list{$_}) {
			printf "\tLOCAL:  $_\n";
		} else {
			printf "\tDELETE: $_\n";
			my $gkg = $gkg_list{$_};
			printf "Deleting $domain: $gkg->{'digest'}\n";
			delete_ds ($domain, $gkg->{'digest'});
		}
	}

	return 0;
}

synchronise('flatcap.org');
synchronise('russon.org');

