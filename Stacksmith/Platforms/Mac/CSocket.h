//
//  CSocket.h
//  Stacksmith
//
//  Created by Uli Kusterer on 08/05/16.
//  Copyright © 2016 Uli Kusterer. All rights reserved.
//

#ifndef CSocket_h
#define CSocket_h

#include <cstddef>

namespace Carlson
{

class CSocket
{
public:
	CSocket() : mSocketFD(-1) {}
	~CSocket();
	
	bool	ConnectToServerAtPort( const char* inHostName, short inPortNumber );
	void	Close();
	
	size_t	Write( void* inBytes, size_t numBytes );
	size_t	Read( void* inBuffer, size_t bufSize );

protected:
	int		mSocketFD;
};

} /* namespace Carlson */

#endif /* CSocket_h */
