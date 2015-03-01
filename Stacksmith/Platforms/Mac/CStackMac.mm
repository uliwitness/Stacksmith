//
//  CStackMac.mm
//  Stacksmith
//
//  Created by Uli Kusterer on 2014-01-06.
//  Copyright (c) 2014 Uli Kusterer. All rights reserved.
//

#include "CStackMac.h"
#include "CButtonPartMac.h"
#include "CFieldPartMac.h"
#include "CMoviePlayerPartMac.h"
#include "CWebBrowserPartMac.h"
#include "CTimerPartMac.h"
#include "CRectanglePart.h"
#include "CPicturePart.h"
#include "CGraphicPartMac.h"
#include "CDocument.h"
#include "CAlert.h"
#import "WILDStackWindowController.h"
#import <QuartzCore/QuartzCore.h>
#import "WILDScriptEditorWindowController.h"
#import "WILDPartInfoViewController.h"
#include <sstream>


using namespace Carlson;



NSString*	WILDToolDidChangeNotification = @"WILDToolDidChangeNotification";
NSString*	WILDBackgroundEditingDidChangeNotification = @"WILDBackgroundEditingDidChangeNotification";


CStackMac::CStackMac( const std::string& inURL, ObjectID inID, const std::string& inName, const std::string& inFileName, CDocument * inDocument )
	: CStack( inURL, inID, inName, inFileName, inDocument )
{
	mMacWindowController = nil;
	mPopover = nil;
}


CStackMac::~CStackMac()
{
	[mScriptEditor close];
	[mScriptEditor release];
	mScriptEditor = nil;
	[mPopover release];
	mPopover = nil;
	[mMacWindowController release];
	mMacWindowController = nil;
}


std::string		CStackMac::GetDisplayName()
{
	std::stringstream		strs;
	if( mName.length() > 0 )
		strs << "Stack \"" << mName << "\"";
	else
		strs << "Stack ID " << GetID();
	return strs.str();
}


bool	CStackMac::GoThereInNewWindow( TOpenInMode inOpenInMode, CStack* oldStack, CPart* overPart, std::function<void()> completionHandler )
{
	Load([this,oldStack,inOpenInMode,overPart,completionHandler](CStack *inStack)
	{
		if( GetCurrentCard() == NULL )
		{
			CCard	*	theCard = inStack->GetCard(0);
			theCard->Load([inOpenInMode,oldStack,overPart,completionHandler]( CLayer *inCard )
			{
				inCard->GoThereInNewWindow( inOpenInMode, oldStack, overPart, completionHandler );
			});
		}
		else
		{
			if( !mMacWindowController )
				mMacWindowController = [[WILDStackWindowController alloc] initWithCppStack: this];
		
			[mMacWindowController showWindowOverPart: overPart];
			
			completionHandler();
		}
	});
	
	return true;
}


void	CStackMac::Show( TEvenIfVisible inEvenIfVisible )
{
	if( !mVisible )
	{
		[mMacWindowController showWindow: nil];
	}
	else if( inEvenIfVisible == EEvenIfVisible )
	{
		[mMacWindowController.window makeKeyAndOrderFront: nil];
	}
}



void	CStackMac::SetName( const std::string& inName )
{
	CStack::SetName(inName);
	[[mMacWindowController window] setTitle: [NSString stringWithUTF8String: inName.c_str()]];
}


void	CStackMac::SetPeeking( bool inState )
{
	CStack::SetPeeking( inState );
	[mMacWindowController drawBoundingBoxes];
}


void	CStackMac::SelectedPartChanged()
{
	[mMacWindowController reflectFontOfSelectedParts];
}


void	CStackMac::SetEditingBackground( bool inState )
{
	if( mEditingBackground != inState )
	{
		CStack::SetEditingBackground(inState);
		
		SetCurrentCard( GetCurrentCard() );
		
		[[NSNotificationCenter defaultCenter] postNotificationName: WILDBackgroundEditingDidChangeNotification object: nil];
	}
}


void	CStackMac::SetCurrentCard( CCard* inCard )
{
	if( inCard && !mMacWindowController )
		mMacWindowController = [[WILDStackWindowController alloc] initWithCppStack: this];
	
	if( mMacWindowController )
	{
		[CATransaction begin];
		[CATransaction setAnimationDuration: 0.0];
		
		[mMacWindowController removeAllViews];
	}
	
	CStack::SetCurrentCard(inCard);
	
	if( mMacWindowController )
	{
		[mMacWindowController createAllViews];

		[CATransaction commit];
	}
	
	if( inCard )
		[mMacWindowController showWindow: nil];
	else
	{
		[mMacWindowController close];
		[mMacWindowController release];
		mMacWindowController = nil;
	}
}


void	CStackMac::SetTool( TTool inTool )
{
	CStack::SetTool(inTool);
	
	[mMacWindowController refreshExistenceAndOrderOfAllViews];
	[mMacWindowController drawBoundingBoxes];
	[[NSNotificationCenter defaultCenter] postNotificationName: WILDToolDidChangeNotification object: nil];
}


void	CStackMac::SetStyle( TStackStyle inStyle )
{
	CStack::SetStyle(inStyle);
	[mMacWindowController updateStyle];
}


void	CStackMac::SetResizable( bool n )
{
	CStack::SetResizable( n );
	[mMacWindowController updateStyle];
}


WILDNSWindowPtr	CStackMac::GetMacWindow()
{
	return mMacWindowController.window;
}


bool	CStackMac::ShowScriptEditorForObject( CConcreteObject* inObject )
{
	inObject->OpenScriptEditorAndShowLine( SIZE_T_MAX );
	return true;
}


bool	CStackMac::ShowPropertyEditorForObject( CConcreteObject* inObject )
{
	CPart	*	thePart = dynamic_cast<CPart*>(inObject);
	if( !thePart )
		return false;
	CMacPartBase	*	macPart = dynamic_cast<CMacPartBase*>(inObject);
	WILDPartInfoViewController	*	piv = [[[macPart->GetPropertyEditorClass() alloc] initWithPart: thePart] autorelease];
	[mPopover release];
	mPopover = [[NSPopover alloc] init];
	//mPopover.delegate = self;
	mPopover.contentSize = piv.view.frame.size;
	mPopover.contentViewController = piv;
	[mPopover setBehavior: NSPopoverBehaviorTransient];
	[mPopover showRelativeToRect: macPart->GetView().bounds ofView: macPart->GetView() preferredEdge: NSMaxYEdge];
	return true;
}


void	CStackMac::OpenScriptEditorAndShowOffset( size_t byteOffset )
{
	if( !mScriptEditor )
		mScriptEditor = [[WILDScriptEditorWindowController alloc] initWithScriptContainer: this];
	
	[mScriptEditor showWindow: nil];
	if( byteOffset != SIZE_T_MAX )
		[mScriptEditor goToCharacter: byteOffset];
}


void	CStackMac::OpenScriptEditorAndShowLine( size_t lineIndex )
{
	if( !mScriptEditor )
		mScriptEditor = [[WILDScriptEditorWindowController alloc] initWithScriptContainer: this];
	
	[mScriptEditor showWindow: nil];
	if( lineIndex != SIZE_T_MAX )
		[mScriptEditor goToLine: lineIndex];
}


void	CStackMac::GetMousePosition( LEONumber *x, LEONumber *y )
{
	NSPoint	mousePos = [NSEvent mouseLocation];
	NSRect	wBox = [mMacWindowController.window contentRectForFrameRect: mMacWindowController.window.frame];
	
	mousePos.x -= wBox.origin.x;
	mousePos.y -= wBox.origin.y;
	
	*x = mousePos.x;
	*y = wBox.size.height -mousePos.y;
}


void	CStackMac::RectChangedOfPart( CPart* inChangedPart )
{
	[mMacWindowController drawBoundingBoxes];
}


void	CStackMac::RegisterPartCreators()
{
	static bool	sAlreadyDidThis = false;
	if( !sAlreadyDidThis )
	{
		CPart::RegisterPartCreator( new CPartCreator<CButtonPartMac>( "button" ) );
		CPart::RegisterPartCreator( new CPartCreator<CFieldPartMac>( "field" ) );
		CPart::RegisterPartCreator( new CPartCreator<CWebBrowserPartMac>( "browser" ) );
		CPart::RegisterPartCreator( new CPartCreator<CMoviePlayerPartMac>( "moviePlayer" ) );
		CPart::RegisterPartCreator( new CPartCreator<CTimerPartMac>( "timer" ) );
		CPart::RegisterPartCreator( new CPartCreator<CRectanglePart>( "rectangle" ) );
		CPart::RegisterPartCreator( new CPartCreator<CPicturePart>( "picture" ) );
		CPart::RegisterPartCreator( new CPartCreator<CGraphicPartMac>( "graphic" ) );
		
		sAlreadyDidThis = true;
	}
}


NSImage*	CStackMac::GetDisplayIcon()
{
	static NSImage*	sStackIcon = nil;
	if( !sStackIcon )
	{
		sStackIcon = [[NSImage imageNamed: @"Stack"] copy];
		[sStackIcon setSize: NSMakeSize(16,16)];
	}
	return sStackIcon;
}

void	CStackMac::SetCardWidth( int n )
{
	CStack::SetCardWidth(n);
	
	NSWindow	*	wd = mMacWindowController.window;
	NSRect	box = [wd contentRectForFrameRect: wd.frame];
	box.size.width = n;
	box = [wd frameRectForContentRect: box];
	[wd setFrame: box display: YES];
}


void	CStackMac::SetCardHeight( int n )
{
	CStack::SetCardHeight(n);
	
	NSWindow	*	wd = mMacWindowController.window;
	NSRect	box = [wd contentRectForFrameRect: wd.frame];
	box.origin.y -= n -box.size.height;
	box.size.height = n;
	box = [wd frameRectForContentRect: box];
	[wd setFrame: box display: YES];
}


void	CStackMac::ClearAllGuidelines( bool inTrackingDone )
{
	CStack::ClearAllGuidelines( inTrackingDone );
	
	if( inTrackingDone )
		[mMacWindowController drawBoundingBoxes];
}


void	CStackMac::SaveThumbnailIfFirstCardOpen()
{
	if( mCurrentCard && mCurrentCard->GetNeedsToBeSaved() && mCurrentCard == GetCard(0) )
		SaveThumbnail();	// Make sure snapshot of first card is current.
}


void	CStackMac::SaveThumbnail()
{
	NSURL	*	theURL = [NSURL URLWithString: [NSString stringWithUTF8String: mURL.c_str()]];
	if( mThumbnailName.length() == 0 )
	{
		theURL = [theURL.URLByDeletingPathExtension URLByAppendingPathExtension: @"jpg"];
		mThumbnailName = theURL.lastPathComponent.UTF8String;
		GetDocument()->IncrementChangeCount();	// Make sure stack TOC gets written again with the file name in it.
	}
	else
		theURL = [theURL.URLByDeletingLastPathComponent URLByAppendingPathComponent: [NSString stringWithUTF8String:mThumbnailName.c_str()]];
	[[mMacWindowController currentCardSnapshotData] writeToFile: theURL.path atomically: YES];
	
	CStack::SaveThumbnail();
}


bool	CStackMac::ShowContextualMenuForObject( CConcreteObject* inObject )
{
	[mMacWindowController performSelector: @selector(showContextualMenuForSelection) withObject: nil afterDelay: 0.0];
	
	return true;
}

