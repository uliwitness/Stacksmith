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
#include "CTimerPart.h"
#include "CRectanglePart.h"
#include "CPicturePart.h"
#include "CDocument.h"
#include "CAlert.h"
#include "WILDStackWindowController.h"
#include <QuartzCore/QuartzCore.h>


using namespace Carlson;



CStackMac::CStackMac( const std::string& inURL, ObjectID inID, const std::string& inName, const std::string& inFileName, CDocument * inDocument )
	: CStack( inURL, inID, inName, inFileName, inDocument )
{
	mMacWindowController = nil;
}


bool	CStackMac::GoThereInNewWindow( bool inNewWindow, CStack* oldStack )
{
	if( !mMacWindowController )
		mMacWindowController = [[WILDStackWindowController alloc] initWithCppStack: this];
	
	if( GetCurrentCard() == NULL )
	{
		GetCard(0)->GoThereInNewWindow( inNewWindow, oldStack );
	}
	else
		[mMacWindowController showWindow: nil];
	
	return true;
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
	if( !mMacWindowController )
		mMacWindowController = [[WILDStackWindowController alloc] initWithCppStack: this];

	[CATransaction begin];
	[CATransaction setAnimationDuration: 0.0];
	
	[mMacWindowController removeAllViews];
	
	CStack::SetCurrentCard(inCard);
	
	[mMacWindowController createAllViews];

	[CATransaction commit];
	
	[mMacWindowController showWindow: nil];
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
		CPart::RegisterPartCreator( new CPartCreator<CTimerPart>( "timer" ) );
		CPart::RegisterPartCreator( new CPartCreator<CRectanglePart>( "rectangle" ) );
		CPart::RegisterPartCreator( new CPartCreator<CPicturePart>( "picture" ) );
		
		sAlreadyDidThis = true;
	}
}
