//
//  memory_clearing_operator_new.cpp
//  Stacksmith
//
//  Created by Uli Kusterer on 2014-12-31.
//  Copyright (c) 2014 Uli Kusterer. All rights reserved.
//

#include <new>
#include <stdexcept>
#include <stdlib.h>


void* operator new( size_t size )
{
	void	*	p = calloc( 1, size );
	if( p == NULL ) // did malloc succeed?
		throw std::bad_alloc(); // ANSI/ISO compliant behavior
	return p;
}


void operator delete( void *p ) throw()
{
	free( p );
}