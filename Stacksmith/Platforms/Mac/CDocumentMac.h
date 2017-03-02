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
typedef NSMutableArray*								WILDNSMutableArrayPtr;
typedef NSMenu*										WILDNSMenuPtr;
#else
typedef struct WILDStackCanvasWindowController*		WILDStackCanvasWindowControllerPtr;
typedef struct NSMutableArray*						WILDNSMutableArrayPtr;
typedef struct NSMenu*								WILDNSMenuPtr;
#endif


namespace Carlson
{

class CDocumentMac;


class CDocumentManagerMac : public CDocumentManager
{
public:
	virtual ~CDocumentManagerMac()	{}
	
	virtual void	OpenDocumentFromURL( const std::string& inURL, std::function<void(CDocument*)> inCompletionBlock, const std::string& inEffectType, TVisualEffectSpeed inSpeed, LEOContextGroup* inGroup, TOpenInvisibly openInvisibly ) override;
	
	virtual void	Quit() override;
	
	static CDocumentMac*	sCurrentMenuBarOwner;
};


class CDocumentMac : public CDocument, public CMacScriptableObjectBase
{
public:
	CDocumentMac( LEOContextGroup* inGroup ) : CDocument(inGroup), mCanvasWindowController(NULL), mMacMenus(nil) {};
	~CDocumentMac();
	
	virtual CStack*		NewStackWithURLIDNameForDocument( const std::string& inURL, ObjectID inID, const std::string& inName, const std::string& inFileName, CDocument * inDocument ) override;
	
	virtual CMenu*		NewMenuWithElement( tinyxml2::XMLElement* inMenuXML, TMenuMarkChangedFlag inMarkChanged = EMenuMarkChanged ) override;
	void				AddMacMenuForMenu( CMenu* currMenu );
	void				RemoveMacMenus();
	virtual void		SetIndexOfMenu( CMenu* inItem, LEOInteger inIndex ) override;


	virtual void		ShowStackCanvasWindow() override;
	
	virtual void		IncrementChangeCount() override;
	virtual void		MenuIncrementedChangeCount( CMenuItem* inItem, CMenu* inMenu, bool parentNeedsFullRebuild ) override;
	virtual void		StackIncrementedChangeCount( CStack* inStack ) override;
	virtual void		LayerIncrementedChangeCount( CLayer* inLayer ) override;
	
	virtual WILDNSImagePtr	GetDisplayIcon() override;
	virtual Class			GetPropertyEditorClass() override;
	virtual void			OpenScriptEditorAndShowOffset( size_t byteOffset ) override	{ CMacScriptableObjectBase::OpenScriptEditorAndShowOffset( byteOffset ); }
	virtual void			OpenScriptEditorAndShowLine( size_t lineIndex ) override	{ CMacScriptableObjectBase::OpenScriptEditorAndShowLine( lineIndex ); }
	
	WILDNSMutableArrayPtr	GetMacMenus();
	
protected:
	WILDNSMutableArrayPtr				mMacMenus;		// Menus currently installed.
	WILDStackCanvasWindowController*	mCanvasWindowController;
};

}

#endif /* defined(__Stacksmith__CDocumentMac__) */
