#!/usr/bin/perl

use strict;
use warnings;

use JSON;
use Data::Dumper;
use REST::Client;
use MIME::Base64;

my $domain   = "russon.org";
my $host     = "https://www.gkg.net";
my $url      = "/ws/domain/$domain/ds";
my $username = "flatcap";
my $password = "ha2meiChu8";

my $headers = { Accept => 'application/json', Authorization => 'Basic ' . encode_base64($username . ':' . $password) };
my $client = REST::Client->new();
$client->setHost($host);

my $body = '{ "digest":"271DF793F41834C60F980EDA5FF8D5ABC0724222", "digestType":"1", "algorithm":"7", "keyTag":"978", "maxSigLife":"3456000" }';

$client->GET($url, $headers);
# $client->POST($url, $body, $headers);
# $url .= '/271DF793F41834C60F980EDA5FF8D5ABC0724222';
# $client->DELETE($url, $headers);

print Dumper ($client->responseCode());
# print Dumper ($client->responseContent());

my $response = from_json($client->responseContent());
print Dumper($response);

# my %rec_hash = ('a' => 1, 'b' => 2, 'c' => 3, 'd' => 4, 'e' => 5);
# my $json = encode_json \%rec_hash;
# print "$json\n";

# $json = '{"a":1,"b":2,"c":3,"d":4,"e":5}';

# my $text = decode_json($json);
# print Dumper($text);

