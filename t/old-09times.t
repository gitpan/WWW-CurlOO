#!perl

use strict;
use warnings;
use Test::More tests => 19;
use File::Temp qw/tempfile/;

BEGIN { use_ok( 'WWW::CurlOO::Easy' ); }
use WWW::CurlOO::Easy qw(:constants);

my $url = $ENV{CURL_TEST_URL} || "http://rsget.pl";

# Init the curl session
my $curl = WWW::CurlOO::Easy->new();
ok($curl, 'Curl session initialize returns something');
ok(ref($curl) eq 'WWW::CurlOO::Easy', 'Curl session looks like an object from the WWW::CurlOO::Easy module');

ok(! $curl->setopt(CURLOPT_NOPROGRESS, 1), "Setting CURLOPT_NOPROGRESS");
ok(! $curl->setopt(CURLOPT_FOLLOWLOCATION, 1), "Setting CURLOPT_FOLLOWLOCATION");
ok(! $curl->setopt(CURLOPT_TIMEOUT, 30), "Setting CURLOPT_TIMEOUT");

my $head = tempfile();
ok(! $curl->setopt(CURLOPT_WRITEHEADER, $head), "Setting CURLOPT_WRITEHEADER");

my $body = tempfile();
ok(! $curl->setopt(CURLOPT_FILE, $body), "Setting CURLOPT_FILE");

ok(! $curl->setopt(CURLOPT_URL, $url), "Setting CURLOPT_URL");

my @myheaders;
$myheaders[0] = "Server: www";
$myheaders[1] = "User-Agent: Perl interface for libcURL";
ok(! $curl->setopt(CURLOPT_HTTPHEADER, \@myheaders), "Setting CURLOPT_HTTPHEADER");

eval { $curl->perform(); };
ok( !$@,"Checking perform return code");

if ( not $@ ) {
    my $bytes = $curl->getinfo(CURLINFO_SIZE_DOWNLOAD);
    ok($bytes, "Non-zero bytesize check");
    my $realurl = $curl->getinfo(CURLINFO_EFFECTIVE_URL);
    ok($realurl, "URL definedness check");
    my $httpcode = $curl->getinfo(CURLINFO_HTTP_CODE);
    ok($httpcode, "HTTP status code check");
}

my $start = $curl->getinfo(CURLINFO_STARTTRANSFER_TIME);
ok ($start, "Valid transfer start time");
my $total = $curl->getinfo(CURLINFO_TOTAL_TIME);
ok ($total, "defined total transfer time");
my $dns = $curl->getinfo(CURLINFO_NAMELOOKUP_TIME);
ok ($dns || $^O eq "cygwin" || $^O eq "MSWin32",
	"NSLOOKUP time is defined: $dns @ $^O");
my $conn = $curl->getinfo(CURLINFO_CONNECT_TIME);
ok ($conn, "Connect time defined");
my $pre = $curl->getinfo(CURLINFO_PRETRANSFER_TIME);
ok ($pre, "Pre-transfer time nonzero, defined");

exit;
