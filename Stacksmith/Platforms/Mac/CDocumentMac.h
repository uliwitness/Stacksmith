//
//  CDocumentMac.h
//  Stacksmith
//
//  Created by Uli Kusterer on 2014-01-06.
//  Copyright (c) 2014 Uli Kusterer. All rights reserved.
//

#ifndef __Stacksmith__CDocumentMac__
#define __Stacksmith__CDocumentMac__

#include "CDocument.h"

namespace Carlson
{

class CDocumentMac : public CDocument
{
public:
	virtual CStack*		NewStackWithURLIDNameForDocument( const std::string& inURL, WILDObjectID inID, const std::string& inName, CDocument * inDocument );

};

}

#endif /* defined(__Stacksmith__CDocumentMac__) */
