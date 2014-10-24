package WWW::CurlOO::Multi;
use strict;
use warnings;

use WWW::CurlOO ();
use Exporter 'import';

*VERSION = \*WWW::CurlOO::VERSION;

our @EXPORT_OK = grep /^CURL/, keys %{WWW::CurlOO::Multi::};
our %EXPORT_TAGS = ( constants => \@EXPORT_OK );

# workaround for "magical destroy too late" bug
sub DESTROY
{
	my $self = shift;
	foreach my $easy ( $self->handles() ) {
		$self->remove_handle( $easy );
	}
}

package WWW::CurlOO::Multi::Code;

use overload
	'0+' => sub {
		return ${(shift)};
	},
	'""' => sub {
		return WWW::CurlOO::Multi::strerror( ${(shift)} );
	},
	fallback => 1;

1;

__END__

=head1 NAME

WWW::CurlOO::Multi - Perl interface for curl_multi_* functions

=head1 SYNOPSIS

 use WWW::CurlOO::Multi qw(:constants);

 my $multi = WWW::CurlOO::Multi->new();
 $multi->add_handle( $easy );

 my $running = 0;
 do {
     my ($r, $w, $e) = $multi->fdset();
     my $timeout = $multi->timeout();
     select $r, $w, $e, $timeout / 1000
         if $timeout > 0;

     $running = $multi->perform();
     while ( my ( $msg, $easy, $result ) = $multi->info_read() ) {
         $multi->remove_handle( $easy );

         # process $easy
     }
 } while ( $running );

=head1 DESCRIPTION

This module wraps multi handle from libcurl and all related functions and
constants. It does not export by default anything, but constants can be
exported upon request.

 use WWW::CurlOO::Multi qw(:constants);

=head2 CONSTRUCTOR

=over

=item new( [BASE] )

Creates new WWW::CurlOO::Multi object. If BASE is specified it will be used
as object base, otherwise an empty hash will be used. BASE must be a valid
reference which has not been blessed already. It will not be used by the
object.

 my $multi = WWW::CurlOO::Multi->new( [qw(my very private data)] );

Calls L<curl_multi_init(3)> and presets some defaults.

=back

=head2 METHODS

=over

=item add_handle( EASY )

Add WWW::CurlOO::Easy to this WWW::CurlOO::Multi object.

 $multi->add_handle( $easy );

Calls L<curl_multi_add_handle(3)>.
Throws L</WWW::CurlOO::Multi::Code> on error.

=item remove_handle( EASY )

Remove WWW::CurlOO::Easy from this WWW::CurlOO::Multi object.

 $multi->remove_handle( $easy );

Calls L<curl_multi_remove_handle(3)>.
Rethrows exceptions from callbacks.
Throws L</WWW::CurlOO::Multi::Code> on error.

=item info_read( )

Read last message from this Multi.

 my ( $msg, $easy, $result ) = $multi->info_read();

$msg contains one of CURLMSG_* values, currently only CURLMSG_DONE is returned.
$easy is the L<WWW::CurlOO::Easy> object. Result is a
L<WWW::CurlOO::Easy::Code> dualvar object.

Calls L<curl_multi_info_read(3)>.

=item fdset( )

Returns read, write and exception vectors suitable for
L<select()|perlfunc/select> and L<vec()|perlfunc/vec> perl builtins.

 my ( $rvec, $wvec, $evec ) = $multi->fdset();

Calls L<curl_multi_fdset(3)>.
Throws L</WWW::CurlOO::Multi::Code> on error.

=item timeout( )

Returns timeout value in miliseconds.

 my $timeout_ms = $multi->timeout();

Calls L<curl_multi_timeout(3)>.
Throws L</WWW::CurlOO::Multi::Code> on error.

=item setopt( OPTION, VALUE )

Set an option. OPTION is a numeric value, use one of CURLMOPT_* constants.
VALUE depends on whatever that option expects.

 $multi->setopt( CURLMOPT_MAXCONNECTS, 10 );

Calls L<curl_multi_setopt(3)>.
Throws L</WWW::CurlOO::Multi::Code> on error.

=item perform( )

Perform. Call it if there is some activity on any fd used by multi interface
or timeout has just reached zero.

 my $active = $multi->perform();

Calls L<curl_multi_perform(3)>.
Rethrows exceptions from callbacks.
Throws L</WWW::CurlOO::Multi::Code> on error.

=item socket_action( [SOCKET], [BITMASK] )

Signalize action on a socket.

 my $active = $multi->socket_action();

 # there is data to read on socket:
 my $active = $multi->socket_action( $socket, CURL_CSELECT_IN );

Calls L<curl_multi_socket_action(3)>.
Rethrows exceptions from callbacks.
Throws L</WWW::CurlOO::Multi::Code> on error.

=item assign( SOCKET, [VALUE] )

Assigns some value to a socket file descriptor. Removes it if value is not
specified. The value is used only in socket callback.

 my $socket = some_socket_open(...);

 # store socket object for socket callback
 $multi->assign( $socket->fileno(), $socket );

Calls L<curl_multi_assign(3)>.
Throws L</WWW::CurlOO::Multi::Code> on error.

=item handles( )

In list context returns easy handles attached to this multi.
In scalar context returns number of easy handles attached.

There is no libcurl equivalent.

=back

=head2 FUNCTIONS

None of those functions are exported, you must use fully qualified names.

=over

=item strerror( [WHATEVER], CODE )

Return a string for error code CODE.

 my $message = $multi->strerror( CURLM_BAD_EASY_HANDLE );

See L<curl_multi_strerror(3)> for more info.

=back

=head2 CONSTANTS

=over

=item CURLM_*

If any method fails, it will return one of those values.

=item CURLMSG_*

Message type from info_read().

=item CURLMOPT_*

Option values for setopt().

=item CURL_POLL_*

Poll action information for socket callback.

=item CURL_CSELECT_*

Select bits for socket_action() method.

=item CURL_SOCKET_TIMEOUT

Special socket value for socket_action() method.

=back

=head2 CALLBACKS

=over

=item CURLMOPT_SOCKETFUNCTION ( CURLMOPT_SOCKETDATA )

Socket callback will be called only if socket_action() method is being used.
It receives 6 arguments: multi handle, easy handle, socket file number, poll
action, socket data (see assign), and CURLMOPT_SOCKETDATA value. It must
return 0.
For more information refer to L<curl_multi_socket_action(3)>.

 sub cb_socket {
     my ( $multi, $easy, $socketfn, $action, $socketdata, $uservar ) = @_;
     # ... register or deregister socket actions ...
     return 0;
 }

=item CURLMOPT_TIMERFUNCTION ( CURLMOPT_TIMERDATA ) 7.16.0+

Timer callback receives 3 arguments: multi object, timeout in ms, and
CURLMOPT_TIMERDATA value. Should return 0.

 sub cb_timer {
     my ( $multi, $timeout_ms, $uservar ) = @_;
     # ... update timeout ...
     return 0;
 }

=back

=head2 WWW::CurlOO::Multi::Code

Most WWW::CurlOO::Multi methods on failure throw a WWW::CurlOO::Multi::Code error
object. It has both numeric value and, when used as string, it calls strerror()
function to display a nice message.

 eval {
     $multi->somemethod();
 };
 if ( ref $@ eq "WWW::CurlOO::Easy::Code" ) {
     if ( $@ == CURLM_SOME_ERROR_WE_EXPECTED ) {
         warn "Expected multi error, continuing\n";
     } else {
         die "Unexpected curl multi error: $@\n";
     }
 } else {
     # rethrow everyting else
     die $@;
 }


=head1 SEE ALSO

L<WWW::CurlOO>
L<WWW::CurlOO::Easy>
L<WWW::CurlOO::examples>
L<libcurl-multi(3)>
L<libcurl-errors(3)>

=head1 COPYRIGHT

Copyright (c) 2011 Przemyslaw Iskra <sparky at pld-linux.org>.

You may opt to use, copy, modify, merge, publish, distribute and/or sell
copies of the Software, and permit persons to whom the Software is furnished
to do so, under the terms of the MPL or the MIT/X-derivate licenses. You may
pick one of these licenses.
