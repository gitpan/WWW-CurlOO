/* vim: ts=4:sw=4:ft=xs:fdm=marker: */
/*
 * Copyright 2011 (C) Przemyslaw Iskra <sparky at pld-linux.org>
 *
 * Loosely based on code by Cris Bailiff <c.bailiff+curl at devsecure.com>,
 * and subsequent fixes by other contributors.
 */


typedef enum {
	CB_SHARE_LOCK = 0,
	CB_SHARE_UNLOCK,
	CB_SHARE_LAST,
} perl_curl_share_callback_code_t;

struct perl_curl_share_s {
	/* last seen version of this object */
	SV *perl_self;

	/* curl share handle */
	CURLSH *handle;

	/* list of callbacks */
	callback_t cb[ CB_SHARE_LAST ];
};


/* make a new share */
static perl_curl_share_t *
perl_curl_share_new( void )
{
	perl_curl_share_t *share;
	Newxz( share, 1, perl_curl_share_t );
	share->handle = curl_share_init();
	return share;
}

/* delete the share */
static void
perl_curl_share_delete( pTHX_ perl_curl_share_t *share )
{
	perl_curl_share_callback_code_t i;
	if ( share->handle )
		curl_share_cleanup( share->handle );

	for ( i = 0; i < CB_SHARE_LAST; i++ ) {
		sv_2mortal( share->cb[i].func );
		sv_2mortal( share->cb[i].data );
	}
	Safefree( share );
}


static void
cb_share_lock( CURL *easy_handle, curl_lock_data data, curl_lock_access locktype,
		void *userptr )
{
	dTHX;

	perl_curl_share_t *share;
	perl_curl_easy_t *easy;

	share = (perl_curl_share_t *) userptr;
	(void) curl_easy_getinfo( easy_handle, CURLINFO_PRIVATE, (void *) &easy );

	/* $easy, $data, $locktype, [$userdata] */
	SV *args[] = {
		newSVsv( easy->perl_self ),
		newSViv( data ),
		newSViv( locktype )
	};

	PERL_CURL_CALL( &share->cb[ CB_SHARE_LOCK ], args );
	return;
}

static void
cb_share_unlock( CURL *easy_handle, curl_lock_data data, void *userptr )
{
	dTHX;

	perl_curl_share_t *share;
	perl_curl_easy_t *easy;
	callback_t *cb;

	share = (perl_curl_share_t *) userptr;
	(void) curl_easy_getinfo( easy_handle, CURLINFO_PRIVATE, (void *) &easy );
	cb = &share->cb[ CB_SHARE_UNLOCK ];

	/* $easy, $data, [$userdata] */
	SV *args[] = {
		newSVsv( easy->perl_self ),
		newSViv( data )
	};

	PERL_CURL_CALL( &share->cb[ CB_SHARE_UNLOCK ], args );
	return;
}



MODULE = WWW::CurlOO	PACKAGE = WWW::CurlOO::Share	PREFIX = curl_share_

INCLUDE: const-share-xs.inc

PROTOTYPES: ENABLE

void
curl_share_new( sclass="WWW::CurlOO::Share", base=HASHREF_BY_DEFAULT )
	const char *sclass
	SV *base
	PREINIT:
		perl_curl_share_t *share;
		HV *stash;
	PPCODE:
		if ( ! SvOK( base ) || ! SvROK( base ) )
			croak( "object base must be a valid reference\n" );

		share = perl_curl_share_new();
		perl_curl_setptr( aTHX_ base, share );

		stash = gv_stashpv( sclass, 0 );
		ST(0) = sv_bless( base, stash );

		XSRETURN(1);


void
curl_share_DESTROY( share )
	WWW::CurlOO::Share share
	CODE:
		perl_curl_share_delete( aTHX_ share );


void
curl_share_setopt( share, option, value )
	WWW::CurlOO::Share share
	int option
	SV * value
	PREINIT:
		CURLSHcode ret1 = CURLSHE_OK, ret2 = CURLSHE_OK;
	CODE:
		switch ( option ) {
			case CURLSHOPT_LOCKFUNC:
				ret1 = curl_share_setopt( share->handle,
					CURLSHOPT_LOCKFUNC, SvOK( value ) ? cb_share_lock : NULL );
				ret2 = curl_share_setopt( share->handle,
					CURLSHOPT_USERDATA, share );
				SvREPLACE( share->cb[ CB_SHARE_LOCK ].func, value );
				break;
			case CURLSHOPT_UNLOCKFUNC:
				ret1 = curl_share_setopt( share->handle,
					CURLSHOPT_UNLOCKFUNC, SvOK( value ) ? cb_share_unlock : NULL );
				ret2 = curl_share_setopt( share->handle,
					CURLSHOPT_USERDATA, share );
				SvREPLACE( share->cb[ CB_SHARE_UNLOCK ].func, value );
				break;
			case CURLSHOPT_USERDATA:
				SvREPLACE( share->cb[ CB_SHARE_LOCK ].data, value );
				SvREPLACE( share->cb[ CB_SHARE_UNLOCK ].data, value );
				break;
			case CURLSHOPT_SHARE:
			case CURLSHOPT_UNSHARE:
				ret1 = curl_share_setopt( share->handle, option, (long) SvIV( value ) );
				break;
			default:
				ret1 = CURLSHE_BAD_OPTION;
				break;
		};
		if ( ret1 != CURLSHE_OK || ( ret1 = ret2 ) != CURLSHE_OK )
			die_code( "Share", ret1 );


SV *
curl_share_strerror( ... )
	PROTOTYPE: $;$
	PREINIT:
		const char *errstr;
	CODE:
		if ( items < 1 || items > 2 )
#ifdef croak_xs_usage
			croak_xs_usage(cv, "[share], errnum");
#else
			croak( "Usage: WWW::CurlOO::Share::strerror( [share], errnum )" );
#endif
		errstr = curl_share_strerror( SvIV( ST( items - 1 ) ) );
		RETVAL = newSVpv( errstr, 0 );
	OUTPUT:
		RETVAL
