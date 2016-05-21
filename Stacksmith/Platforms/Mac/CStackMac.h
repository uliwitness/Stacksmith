//
//  CStackMac.h
//  Stacksmith
//
//  Created by Uli Kusterer on 2014-01-06.
//  Copyright (c) 2014 Uli Kusterer. All rights reserved.
//

#ifndef __Stacksmith__CStackMac__
#define __Stacksmith__CStackMac__

#include "CStack.h"
#include "CMacScriptableObjectBase.h"


#if __OBJC__
@class WILDStackWindowController;
typedef WILDStackWindowController*					WILDStackWindowControllerPtr;
@class NSWindow;
@class NSPopover;
@class WILDScriptEditorWindowController;
@class NSImage;
typedef NSWindow*									WILDNSWindowPtr;
typedef NSPopover*									WILDNSPopoverPtr;
typedef WILDScriptEditorWindowController*			WILDScriptEditorWindowControllerPtr;
typedef NSImage*									WILDNSImagePtr;
@class NSString;
#else
typedef struct WILDStackWindowController*			WILDStackWindowControllerPtr;
typedef struct NSWindow*							WILDNSWindowPtr;
typedef struct NSPopover*							WILDNSPopoverPtr;
typedef struct WILDScriptEditorWindowController*	WILDScriptEditorWindowControllerPtr;
typedef struct NSImage*								WILDNSImagePtr;
typedef struct NSString								NSString;
#endif


namespace Carlson {

class CStackMac : public CStack, public CMacScriptableObjectBase
{
public:
	CStackMac( const std::string& inURL, ObjectID inID, const std::string& inName, const std::string& inFileName, CDocument * inDocument );
	virtual ~CStackMac();

	virtual bool				GoThereInNewWindow( TOpenInMode inOpenInMode, CStack* oldStack, CPart* overPart, std::function<void()> completionHandler, const std::string& inEffectType, TVisualEffectSpeed inSpeed );
	virtual void				SetPeeking( bool inState );
	virtual void				SetStyle( TStackStyle inStyle );
	virtual void				SetResizable( bool n );

	virtual void				SetCurrentCard( CCard* inCard, const std::string& inEffectType = "", TVisualEffectSpeed inSpeed = EVisualEffectSpeedNormal );
	virtual void				SetEditingBackground( bool inState );
	virtual void				SetTool( TTool inTool );
	virtual void				SetName( const std::string& inName );

	virtual std::string			GetDisplayName();
	virtual WILDNSImagePtr		GetDisplayIcon();
	
	virtual void				SaveThumbnail();
	virtual void				SaveThumbnailIfFirstCardOpen();
	virtual WILDNSWindowPtr		GetMacWindow();
	virtual WILDStackWindowControllerPtr	GetMacWindowController() { return mMacWindowController; }
	
	virtual bool				ShowScriptEditorForObject( CConcreteObject* inObject );
	virtual bool				ShowPropertyEditorForObject( CConcreteObject* inObject );
	virtual void				OpenScriptEditorAndShowOffset( size_t byteOffset );
	virtual void				OpenScriptEditorAndShowLine( size_t lineIndex );
	virtual bool				ShowContextualMenuForObject( CConcreteObject* inObject );
	
	virtual void				GetMousePosition( LEONumber *x, LEONumber *y );
	virtual void				RectChangedOfPart( CPart* inChangedPart );
	virtual void				SelectedPartChanged();
	virtual void				SetCardWidth( int n );
	virtual void				SetCardHeight( int n );
	virtual LEOInteger			GetLeft();
	virtual LEOInteger			GetTop();
	virtual LEOInteger			GetRight();
	virtual LEOInteger			GetBottom();
	virtual void				SetRect( LEOInteger l, LEOInteger t, LEOInteger r, LEOInteger b );
	
	virtual CUndoStack*			GetUndoStack();

	virtual void				ClearAllGuidelines( bool inTrackingDone = false );

	virtual void				Show( TEvenIfVisible inEvenIfVisible );
	
	virtual void				NumberOrOrderOfPartsChanged();
	
	static void					RegisterPartCreators();

protected:
	WILDStackWindowControllerPtr		mMacWindowController;
	WILDNSPopoverPtr					mPopover;
	WILDScriptEditorWindowControllerPtr	mScriptEditor;
};

}


#if __OBJC__
extern NSString*	WILDToolDidChangeNotification;
extern NSString*	WILDBackgroundEditingDidChangeNotification;
#endif

#endif /* defined(__Stacksmith__CStackMac__) */
