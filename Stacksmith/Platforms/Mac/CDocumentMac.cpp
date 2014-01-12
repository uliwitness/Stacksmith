//
//  CDocumentMac.cpp
//  Stacksmith
//
//  Created by Uli Kusterer on 2014-01-06.
//  Copyright (c) 2014 Uli Kusterer. All rights reserved.
//

#include "CDocumentMac.h"
#include "CStackMac.h"


using namespace Carlson;


CStack*		CDocumentMac::NewStackWithURLIDNameForDocument( const std::string& inURL, ObjectID inID, const std::string& inName, CDocument * inDocument )
{
	return new CStackMac( inURL, inID, inName, inDocument );
}
