#!/usr/bin/perl

use strict;
use warnings;

our $VERSION = 0.2;

use JSON;
use Data::Dumper;
use REST::Client;
use MIME::Base64;
use English '-no_match_vars';
use Readonly;
use DateTime::Format::ISO8601;
use POSIX qw(strftime);

$Data::Dumper::Indent    = 2;
$Data::Dumper::Useqq     = 1;
$Data::Dumper::Quotekeys = 0;
$Data::Dumper::Sortkeys  = 1;

Readonly my $HOST         => 'https://www.gkg.net';
Readonly my $MAX_SIG_LIFE => (60 * 60 * 24 * 7);

my $USERNAME;
my $PASSWORD;
my $KEY_DIR;

sub get_files
{
	my ($domain) = @_;

	Readonly my $FIELDS => 7;

	my $file   = "$KEY_DIR/dsset-$domain.";
	my $now    = strftime '%Y%m%d', localtime;
	my %ds_list;

	my $FH;
	if (!open $FH, '<', $file) {
		printf {*STDERR} "Can't open $file: $ERRNO\n";
		return;
	}

	while (<$FH>) {
		chomp;
		my ($zone, $class, $rr, $key, $algo, $dtype, $digest) = split /\s+/msx, $_, $FIELDS;
		$digest =~ s/\s//msxg;

		$ds_list{$digest} = {
			keyTag     => $key,
			algorithm  => $algo,
			digestType => $dtype,
			digest     => $digest,
			maxSigLife => $MAX_SIG_LIFE
		};
	}

	if (!close $FH) {
		printf "Close failed for: %s\n", $file;
	}

	return %ds_list;
}

sub get_gkg
{
	my ($domain) = @_;
	my $url      = "/ws/domain/$domain/ds";
	my $headers  = {
		Accept => 'application/json',
		Authorization => 'Basic ' . encode_base64 ($USERNAME . q{:} . $PASSWORD)
	};

	my $client = REST::Client->new ();
	$client->setHost ($HOST);

	$client->GET ($url, $headers);

	my $code = $client->responseCode ();
	if ($code ne '200') {
		printf {*STDERR} "Can't get info from gkg: $code\n";
		return;
	}

	my %gkg_list;

	foreach (@{from_json ($client->responseContent ())}) {
		my $digest = $_->{'digest'};
		$gkg_list{$digest} = $_;
	}

	return %gkg_list;
}


sub create_ds
{
	my ($domain, $ds) = @_;

	my $url = "/ws/domain/$domain/ds";

	my $headers = {
		Accept => 'application/json',
		Authorization => 'Basic ' . encode_base64 ($USERNAME . q{:} . $PASSWORD)
	};
	my $client = REST::Client->new ();
	$client->setHost ($HOST);

	my $body = "{ \"digest\":\"$ds->{'digest'}\", \"digestType\":\"$ds->{'digestType'}\", \"algorithm\":\"$ds->{'algorithm'}\", \"keyTag\":\"$ds->{'keyTag'}\", \"maxSigLife\":\"$ds->{'maxSigLife'}\" }";
	# print "host = $HOST\n";
	# print "url  = $url\n";
	# print "body = $body\n";

	$client->POST ($url, $body, $headers);
	# Responses:
	#	201 Created
	#	401 Unauthorized
	#	403 Forbidden
	#	404 Not Found
	#	415 Unsupported Media Type

	my $code = $client->responseCode ();
	if ($code ne '201') {
		printf {*STDERR} "Create failed: $code\n";
		return;
	}

	printf "create succeeded: $ds->{'digest'}\n";
	return 1;
}

sub delete_ds
{
	my ($domain, $digest) = @_;

	my $headers = {
		Accept => 'application/json',
		Authorization => 'Basic ' . encode_base64 ($USERNAME . q{:} . $PASSWORD)
	};
	my $client = REST::Client->new ();
	$client->setHost ($HOST);

	my $url = "/ws/domain/$domain/ds/$digest";

	$client->DELETE ($url, $headers);
	# Responses:
	#	204 No Content
	#	401 Unauthorized
	#	403 Forbidden
	#	404 Not Found

	my $code = $client->responseCode ();
	if ($code ne '204') {
		printf {*STDERR} "Delete failed: $code\n";
		return;
	}

	return 1;
}


sub synchronise
{
	my ($domain) = @_;
	printf "$domain:\n";

	my %ds_list = get_files ($domain);
	# printf {*STDOUT} Dumper (\%ds_list);
	if (!%ds_list) {
		return 1
	}

	my %gkg_list = get_gkg ($domain);
	# printf {*STDOUT} Dumper (\%gkg_list);
	if (!%gkg_list) {
		# return 1;
	}

	foreach (keys %ds_list) {
		if (exists $gkg_list{$_}) {
			printf "\tSERVER: $_\n";
		} else {
			my $ds = $ds_list{$_};
			printf "Uploading $domain: $ds->{'digest'}\n";
			create_ds ($domain, $ds);
		}
	}

	foreach (keys %gkg_list) {
		if (exists $ds_list{$_}) {
			printf "\tLOCAL:  $_\n";
		} else {
			my $gkg = $gkg_list{$_};
			printf "Deleting $domain: $gkg->{'digest'}\n";
			delete_ds ($domain, $gkg->{'digest'});
		}
	}

	return 0;
}

sub main
{
	$USERNAME   = $ENV{'DNSSEC_GKG_USERNAME'};
	$PASSWORD   = $ENV{'DNSSEC_GKG_PASSWORD'};
	$KEY_DIR    = $ENV{'DNSSEC_KEY_DIR'};
	my $domains = $ENV{'DNSSEC_DOMAINS'};
	my $fail    = 0;

	if (!$USERNAME || !$PASSWORD || !$KEY_DIR || !$domains) {
		$fail = 1;
		printf "You need to set some environment variables:\n";
	}

	if (!$USERNAME) { printf "\tDNSSEC_GKG_USERNAME\n"; }
	if (!$PASSWORD) { printf "\tDNSSEC_GKG_PASSWORD\n"; }
	if (!$KEY_DIR)  { printf "\tDNSSEC_KEY_DIR\n";      }
	if (!$domains)  { printf "\tDNSSEC_DOMAINS\n";      }

	if ($fail) {
		return 1;
	}

	my @d = split /\s/msx, $domains;
	foreach (@d) {
		synchronise ($_);
	}

	return 0;
}


exit main();

