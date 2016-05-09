//
//  CSocket.cpp
//  Stacksmith
//
//  Created by Uli Kusterer on 08/05/16.
//  Copyright © 2016 Uli Kusterer. All rights reserved.
//

#include "CSocket.h"
#include <sys/socket.h>
#include <netinet/in.h>
#include <netinet/tcp.h>
#include <netdb.h>
#include <unistd.h>
#include <stdlib.h>
#include <iostream>


using namespace Carlson;


CSocket::~CSocket()
{
	if( mSocketFD >= 0 )
		close(mSocketFD);
}


bool	CSocket::ConnectToServerAtPort( const char* inHostName, short inPortNumber )
{
	struct sockaddr_in		serv_addr = { 0 };
	struct hostent		*	server = NULL;

	mSocketFD = socket( AF_INET, SOCK_STREAM, 0 );
	int v = 1; 
	if( setsockopt( mSocketFD, IPPROTO_TCP, TCP_NODELAY, &v, sizeof(v)) )
	{
		std::cerr << "Couldn't set options when connecting to " << inHostName << ": " << errno << std::endl;
		return false;
	}
	server = gethostbyname( inHostName );
	if( server == NULL )
	{
		fprintf( stderr, "Couldn't resolve %s\n", inHostName );
		return false;
	}
	
	serv_addr.sin_family = AF_INET;
	bcopy( (char *)server->h_addr, (char *)&serv_addr.sin_addr.s_addr, server->h_length );
	serv_addr.sin_port = htons( inPortNumber );
	if( connect( mSocketFD, (struct sockaddr*)&serv_addr, sizeof(serv_addr) ) < 0 )
	{
		std::cerr << "Couldn't connect to " << inHostName << ":" << inPortNumber << " error = " << errno << std::endl;
		return false;
	}
	
	return true;
}


void	CSocket::Close()
{
	if( mSocketFD >= 0 )
	{
		close(mSocketFD);
		mSocketFD = -1;
	}
}


size_t	CSocket::Write( void* inBytes, size_t numBytes )
{
	return write( mSocketFD, (const char*)inBytes, numBytes );
}


size_t	CSocket::Read( void* inBuffer, size_t bufSize )
{
	return read( mSocketFD, (char*)inBuffer, bufSize );
}


