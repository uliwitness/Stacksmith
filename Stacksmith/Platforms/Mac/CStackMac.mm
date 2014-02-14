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
#include "CDocument.h"
#include "CAlert.h"
#import "WILDStackWindowController.h"
#import <QuartzCore/QuartzCore.h>
#import "WILDScriptEditorWindowController.h"
#import "WILDPartInfoViewController.h"


using namespace Carlson;



CStackMac::CStackMac( const std::string& inURL, ObjectID inID, const std::string& inName, const std::string& inFileName, CDocument * inDocument )
	: CStack( inURL, inID, inName, inFileName, inDocument )
{
	mMacWindowController = nil;
	mPopover = nil;
}


CStackMac::~CStackMac()
{
	[mPopover release];
	mPopover = nil;
	[mMacWindowController release];
	mMacWindowController = nil;
}


bool	CStackMac::GoThereInNewWindow( TOpenInMode inOpenInMode, CStack* oldStack, CPart* overPart )
{
	Load([this,oldStack,inOpenInMode,overPart](CStack *inStack)
	{
		if( GetCurrentCard() == NULL )
		{
			CCard	*	theCard = inStack->GetCard(0);
			theCard->Load([inOpenInMode,oldStack,overPart]( CLayer *inCard )
			{
				inCard->GoThereInNewWindow( inOpenInMode, oldStack, overPart );
			});
		}
		else
		{
			if( !mMacWindowController )
				mMacWindowController = [[WILDStackWindowController alloc] initWithCppStack: this];
		
			[mMacWindowController showWindowOverPart: overPart];
		}
	});
	
	return true;
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


void	CStackMac::SetEditingBackground( bool inState )
{
	CStack::SetEditingBackground(inState);
	
	SetCurrentCard( GetCurrentCard() );
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
	[mMacWindowController updateToolbarVisibility];
}


void	CStackMac::SetStyle( TStackStyle inStyle )
{
	CStack::SetStyle(inStyle);
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
		
		sAlreadyDidThis = true;
	}
}
