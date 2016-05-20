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


#if __OBJC__
@class WILDStackCanvasWindowController;
typedef WILDStackCanvasWindowController*			WILDStackCanvasWindowControllerPtr;
#else
typedef struct WILDStackCanvasWindowController*		WILDStackCanvasWindowControllerPtr;
#endif


namespace Carlson
{

class CDocumentManagerMac : public CDocumentManager
{
public:
	virtual ~CDocumentManagerMac()	{};
	
	virtual void	OpenDocumentFromURL( const std::string& inURL, std::function<void(CDocument*)> inCompletionBlock, const std::string& inEffectType, TVisualEffectSpeed inSpeed, LEOContextGroup* inGroup ) override;
	
	virtual void	Quit() override;
};


class CDocumentMac : public CDocument
{
public:
	CDocumentMac( LEOContextGroup* inGroup ) : CDocument(inGroup), mCanvasWindowController(NULL) {};
	
	virtual CStack*		NewStackWithURLIDNameForDocument( const std::string& inURL, ObjectID inID, const std::string& inName, const std::string& inFileName, CDocument * inDocument ) override;
	
	virtual void		ShowStackCanvasWindow() override;
	
	virtual void		IncrementChangeCount() override;
	virtual void		StackIncrementedChangeCount( CStack* inStack ) override;
	virtual void		LayerIncrementedChangeCount( CLayer* inLayer ) override;
	
protected:
	WILDStackCanvasWindowController*	mCanvasWindowController;
};

}

#endif /* defined(__Stacksmith__CDocumentMac__) */
