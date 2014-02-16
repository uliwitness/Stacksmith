//
//  CPlatformLayer.h
//  Stacksmith
//
//  Created by Uli Kusterer on 2014-02-16.
//  Copyright (c) 2014 Uli Kusterer. All rights reserved.
//

#ifndef Stacksmith_CPlatformLayer_h
#define Stacksmith_CPlatformLayer_h

#include "CLayer.h"


#if __OBJC__
@class WILDScriptEditorWindowController;
typedef WILDScriptEditorWindowController*			WILDScriptEditorWindowControllerPtr;
#else
typedef struct WILDScriptEditorWindowController*	WILDScriptEditorWindowControllerPtr;
#endif


namespace Carlson
{

class CPlatformLayer : public CLayer
{
public:
	CPlatformLayer( std::string inURL, ObjectID inID, const std::string& inName, const std::string& inFileName, CStack* inStack ) : CLayer( inURL, inID, inName, inFileName, inStack ) {};
	~CPlatformLayer();
	
	virtual void				OpenScriptEditorAndShowOffset( size_t byteOffset );
	virtual void				OpenScriptEditorAndShowLine( size_t lineIndex );
	
protected:
	WILDScriptEditorWindowControllerPtr	mScriptEditor;
};

}

#endif
