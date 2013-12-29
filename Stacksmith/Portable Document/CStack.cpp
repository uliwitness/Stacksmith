//
//  CStack.cpp
//  Stacksmith
//
//  Created by Uli Kusterer on 2013-12-29.
//  Copyright (c) 2013 Uli Kusterer. All rights reserved.
//

#include "CStack.h"
#include "CCard.h"
#include "CBackground.h"
#include "CURLConnection.h"
#include "tinyxml2.h"


void	CStack::LoadFromURL( const std::string inURL )
{
	Retain();
	
	CURLRequest		request( inURL );
	CURLConnection::SendRequestWithCompletionHandler( request, [this] (CURLResponse inResponse, const char* inData, size_t inDataLength) -> void
	{
		tinyxml2::XMLDocument		document;
		
		if( tinyxml2::XML_SUCCESS == document.Parse( inData, inDataLength ) )
		{
			document.Print();
		}
		
		Release();
	} );
}

void	CStack::AddCard( CCard* inCard )
{
	inCard->Retain();
	mCards.push_back( inCard );
}

void	CStack::RemoveCard( CCard* inCard )
{
	mCards.push_back( inCard );
	inCard->Release();
}
