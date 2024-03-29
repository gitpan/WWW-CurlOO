#!perl

use strict;
use warnings;
use Test::More tests => 7;
use File::Temp qw/tempfile/;

BEGIN { use_ok( 'WWW::CurlOO::Easy' ); }
use WWW::CurlOO::Easy qw(:constants);

my $url = $ENV{CURL_TEST_URL} || "http://rsget.pl";

# Init the curl session
my $curl = WWW::CurlOO::Easy->new();
ok($curl, 'Curl session initialize returns something');
ok(ref($curl) eq 'WWW::CurlOO::Easy', 'Curl session looks like an object from the WWW::CurlOO::Easy module');

$curl->setopt(CURLOPT_NOPROGRESS, 1);
$curl->setopt(CURLOPT_FOLLOWLOCATION, 1);
$curl->setopt(CURLOPT_TIMEOUT, 30);

my $head = tempfile();
$curl->setopt(CURLOPT_WRITEHEADER, $head);

my $body = tempfile();
$curl->setopt(CURLOPT_FILE,$body);

$curl->setopt(CURLOPT_URL, $url);

my $header_called = 0;
sub header_callback {
	$header_called = 1;
	$_[0]->{head} = 1;
	return length($_[1])
};
my $body_called = 0;
sub body_callback {
	$body_called++;
	$_[0]->{body}++;
	return length($_[1])
};



ok (! $curl->setopt(CURLOPT_HEADERFUNCTION, \&header_callback), "CURLOPT_HEADERFUNCTION set");
ok (! $curl->setopt(CURLOPT_WRITEFUNCTION, \&body_callback), "CURLOPT_WRITEFUNCTION set");

$curl->perform();
ok($curl->{head}, "CURLOPT_HEADERFUNCTION callback was used");
ok($curl->{body}, "CURLOPT_WRITEFUNCTION callback was used");
