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
#include "CMacScriptableObjectBase.h"


#if __OBJC__
@class WILDScriptEditorWindowController;
typedef WILDScriptEditorWindowController*			WILDScriptEditorWindowControllerPtr;
@class NSimage;
typedef NSImage*									WILDNSImagePtr;
#else
typedef struct WILDScriptEditorWindowController*	WILDScriptEditorWindowControllerPtr;
typedef struct NSImage*								WILDNSImagePtr;
#endif


namespace Carlson
{

/*!
	@class CPlatformLayer
	Mac-specific subclass of CLayer that contains code that we want both
	kinds of layer, cards and backgrounds, to have.
*/

class CPlatformLayer : public CLayer, public CMacScriptableObjectBase
{
public:
	CPlatformLayer( std::string inURL, ObjectID inID, const std::string& inName, const std::string& inFileName, CStack* inStack ) : CLayer( inURL, inID, inName, inFileName, inStack ) {};
	~CPlatformLayer();

	virtual WILDNSImagePtr		GetDisplayIcon();
	
	virtual void				OpenScriptEditorAndShowOffset( size_t byteOffset );
	virtual void				OpenScriptEditorAndShowLine( size_t lineIndex );
	
protected:
	WILDScriptEditorWindowControllerPtr	mScriptEditor;
};

}

#endif
