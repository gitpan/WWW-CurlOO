package WWW::CurlOO;

use strict;
use Exporter 'import';

our @ISA;
our $VERSION;
BEGIN {
	$VERSION = '0.12';

	my $loaded = 0;

	my $load_xs = sub {
		require XSLoader;
		XSLoader::load( __PACKAGE__, $VERSION );
		$loaded = 1;
	};
	my $load_dyna = sub {
		require DynaLoader;
		@ISA = qw(DynaLoader);
		DynaLoader::bootstrap( __PACKAGE__ );
		$loaded = 1;
	};
	eval { $load_xs->() } if $INC{ "XSLoader.pm" };
	eval { $load_dyna->() } if $INC{ "DynaLoader.pm" } and not $loaded;
	unless ( $loaded ) {
		eval { $load_xs->(); };
		$load_dyna->() if $@;
	}
}
END {
	_global_cleanup();
}

our @EXPORT_OK = grep /^(?:LIB)?CURL/, keys %{WWW::CurlOO::};
our %EXPORT_TAGS = ( constants => \@EXPORT_OK );

1;

__END__

=head1 NAME

WWW::CurlOO - Perl interface for libcurl

=head1 WARNING

B<THIS MODULE IS UNDER HEAVY DEVELOPEMENT AND SOME INTERFACE MAY CHANGE YET.>

=head1 SYNOPSIS

 use WWW::CurlOO;
 print $WWW::CurlOO::VERSION;

 print WWW::CurlOO::version();

=head1 DOCUMENTATION

WWW::CurlOO provides a Perl interface to libcurl created with object-oriented
implementations in mind. This documentation contains Perl-specific details
and quirks. For more information consult libcurl man pages and documentation
at L<http://curl.haxx.se>.

=head1 DESCRIPTION

This package contains some static functions and version-releated constants.
It does not export by default anything, but constants can be exported upon
request.

 use WWW::CurlOO qw(:constants);

To perform any request you want L<WWW::CurlOO::Easy>.

=head2 FUNCTIONS

None of those functions are exported, you must use fully qualified names.

=over

=item version

Returns libcurl version string.

 my $libcurl_verstr = WWW::CurlOO::version();
 # prints something like:
 # libcurl/7.21.4 GnuTLS/2.10.4 zlib/1.2.5 c-ares/1.7.4 libidn/1.20 libssh2/1.2.7 librtmp/2.3
 print $libcurl_verstr;

Calls L<curl_version(3)> function.

=item version_info

Returns a hashref with the same information as L<curl_version_info(3)>.

 my $libcurl_ver = WWW::CurlOO::version_info();
 print Dumper( $libcurl_ver );

Example for version_info with age CURLVERSION_FOURTH:

 age => 3,
 version => '7.21.4',
 version_num => 464132,
 host => 'x86_64-pld-linux-gnu',
 features => 18109,
 ssl_version => 'GnuTLS/2.10.4'
 ssl_version_num => 0,
 libz_version => '1.2.5',
 protocols => [ 'dict', 'file', 'ftp', 'ftps', 'gopher', 'http', 'https',
                'imap', 'imaps', 'ldap', 'ldaps', 'pop3', 'pop3s', 'rtmp', 'rtsp',
                'scp', 'sftp', 'smtp', 'smtps', 'telnet', 'tftp' ],
 ares => '1.7.4',
 ares_num => 67332,
 libidn => '1.20',
 iconv_ver_num => 0,
 libssh_version => 'libssh2/1.2.7',

You can import constants if you want to check libcurl features:

 use WWW::CurlOO qw(:constants);
 unless ( WWW::CurlOO::version_info()->{features} & CURL_VERSION_SSL ) {
     die "SSL support is required\n";
 }

=item getdate

Decodes date string returning its numerical value, in seconds.

 my $time = WWW::CurlOO::getdate( "GMT 08:49:37 06-Nov-94 Sunday" );
 my $timestr = gmtime $time;
 print "$timestr\n";
 # Sun Nov  6 08:49:37 1994

See L<curl_getdate(3)> for more info on supported input formats.

=back

=head2 CONSTANTS

=over

=item CURL_VERSION_* and CURLVERSION_*

Can be used for decoding version_info() values. L<curl_version_info(3)>

=item LIBCURL_*

Can be used for determining buildtime libcurl version. Some WWW::CurlOO
features will not be available if it was built with older libcurl, even if
runtime libcurl version has necessary features.

=back

=head1 AUTHORS

This package was mostly rewritten by Przemyslaw Iskra <sparky at pld-linux.org>.

It is based on WWW::Curl developed by Cris Bailiff <c.bailiff+curl at devsecure.com>
and Balint Szilakszi <szbalint at cpan.org>.

Original Author Georg Horn <horn@koblenz-net.de>, with additional callback,
pod and test work by Cris Bailiff <c.bailiff+curl@devsecure.com> and
Forrest Cahoon <forrest.cahoon@merrillcorp.com>. Sebastian Riedel added ::Multi
and Anton Fedorov (datacompboy <at> mail.ru) added ::Share. Balint Szilakszi
repackaged the module into a more modern form.

=head1 COPYRIGHT

Copyright (c) 2011 Przemyslaw Iskra.

Copyright (C) 2000-2005,2008-2010 Daniel Stenberg, Cris Bailiff,
Sebastian Riedel, Balint Szilakszi et al.

You may opt to use, copy, modify, merge, publish, distribute and/or sell
copies of the Software, and permit persons to whom the Software is furnished
to do so, under the terms of the MPL or the MIT/X-derivate licenses. You may
pick one of these licenses.

=head1 SEE ALSO

L<http://curl.haxx.se>

L<libcurl(3)>
