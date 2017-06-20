//
//  CStackIOS.mm
//  Stacksmith
//
//  Created by Uli Kusterer on 2017-06-20.
//  Copyright (c) 2017 Uli Kusterer. All rights reserved.
//

#include "CStackIOS.h"
#include "CIOSPartBase.h"
#include "CDocument.h"
#include "CAlert.h"
#include <sstream>
#include "CUndoStack.h"
#import "WILDIOSMainViewController.h"


using namespace Carlson;



CStackIOS::CStackIOS( const std::string& inURL, ObjectID inID, const std::string& inName, const std::string& inFileName, CDocument * inDocument )
	: CStack( inURL, inID, inName, inFileName, inDocument )
{
}


CStackIOS::~CStackIOS()
{
}


bool	CStackIOS::GoThereInNewWindow( TOpenInMode inOpenInMode, CStack* oldStack, CPart* overPart, std::function<void()> completionHandler, const std::string& inEffectType, TVisualEffectSpeed inSpeed )
{
	Load([this,oldStack,inOpenInMode,overPart,completionHandler,inEffectType,inSpeed](CStack *inStack)
	{
		if( GetCurrentCard() == NULL )
		{
			CCard	*	theCard = inStack->GetCard(0);
			theCard->Load([inOpenInMode,oldStack,overPart,completionHandler,inEffectType,inSpeed]( CLayer *inCard )
			{
				inCard->GoThereInNewWindow( inOpenInMode, oldStack, overPart, completionHandler, inEffectType, inSpeed);
			});
		}
		else
		{
			completionHandler();
		}
	});
	
	return true;
}


void	CStackIOS::Show( TEvenIfVisible inEvenIfVisible )
{
	if( !mVisible )
	{
		// TODO: Implement for iOS to update all views.
	}
	else if( inEvenIfVisible == EEvenIfVisible )
	{
		// TODO: Implement for iOS to update all views.
	}
}


void	CStackIOS::Hide()
{
	if( mVisible )
	{
		// TODO: Implement for iOS to update all views.
	}
}


void	CStackIOS::NumberOrOrderOfPartsChanged()
{
	// TODO: Implement for iOS to update all views.
}


void	CStackIOS::SetPeeking( bool inState )
{
	CStack::SetPeeking( inState );
	
	// TODO: Implement for iOS to update any peek rectangles or selection handles.
}


void	CStackIOS::SelectedPartChanged()
{
	// TODO: Implement for iOS to update any peek rectangles, font pickers or selection handles.
}


void	CStackIOS::SetEditingBackground( bool inState )
{
	if( mEditingBackground != inState )
	{
		CStack::SetEditingBackground(inState);
		
		SetCurrentCard( GetCurrentCard() );
	}
}


CUndoStack*	CStackIOS::GetUndoStack()
{
	if( !mUndoStack )
		mUndoStack = new CUndoStack( [WILDIOSMainViewController sharedMainViewController].undoManager );
	return mUndoStack;
}


void	CStackIOS::SetCurrentCard( CCard* inCard, const std::string& inEffectType, TVisualEffectSpeed inSpeed )
{
	UIView * targetView = [WILDIOSMainViewController sharedMainViewController].view;
	
	CCard * cd = GetCurrentCard();
	if( cd )
	{
		for( size_t x = 0; x < cd->GetNumParts(); ++x )
		{
			CIOSPartBase * currentPart = dynamic_cast<CIOSPartBase*>( cd->GetPart( x ) );
			currentPart->DestroyView();
		}
		CBackground * bg = GetCurrentCard()->GetBackground();
		for( size_t x = 0; x < bg->GetNumParts(); ++x )
		{
			CIOSPartBase * currentPart = dynamic_cast<CIOSPartBase*>( bg->GetPart( x ) );
			currentPart->DestroyView();
		}
	}
	
	CStack::SetCurrentCard(inCard, inEffectType, inSpeed);
	
	if( inCard )
	{
		CGSize cardSize = targetView.frame.size;
		mCardWidth = cardSize.width;
		mCardHeight = cardSize.height;
		
		CBackground * newBg = inCard->GetBackground();
		for( size_t x = 0; x < newBg->GetNumParts(); ++x )
		{
			CIOSPartBase * currentPart = dynamic_cast<CIOSPartBase*>( newBg->GetPart( x ) );
			if( currentPart )
			{
				currentPart->CreateViewIn( targetView );
			}
		}
		for( size_t x = 0; x < inCard->GetNumParts(); ++x )
		{
			CIOSPartBase * currentPart = dynamic_cast<CIOSPartBase*>( inCard->GetPart( x ) );
			if( currentPart )
			{
				currentPart->CreateViewIn( targetView );
			}
		}
	}
}


void	CStackIOS::SetTool( TTool inTool )
{
	CStack::SetTool(inTool);
	
	// TODO: Implement for iOS to update any peek rectangles or selection handles.
}


void	CStackIOS::RectChangedOfPart( CPart* inChangedPart )
{
	// TODO: Implement for iOS to update any peek rectangles or selection handles.
}


void	CStackIOS::SetCardWidth( LEOInteger n )
{
	CStack::SetCardWidth(n);
	
	// TODO: Update card rectangle and show border around it or make it scroll.
}


void	CStackIOS::SetCardHeight( LEOInteger n )
{
	CStack::SetCardHeight(n);
	
	// TODO: Update card rectangle and show border around it or make it scroll.
}


LEOInteger	CStackIOS::GetLeft()
{
	return mCardLeft;
}


LEOInteger	CStackIOS::GetTop()
{
	return mCardTop;
}


LEOInteger	CStackIOS::GetRight()
{
	return mCardLeft +mCardWidth;
}


LEOInteger	CStackIOS::GetBottom()
{
	return mCardTop +mCardHeight;
}


void	CStackIOS::SetRect( LEOInteger l, LEOInteger t, LEOInteger r, LEOInteger b )
{
	mCardLeft = l;
	mCardTop = t;
	mCardWidth = r- l;
	mCardHeight = b - t;
	
	// TODO: Update card rectangle and show border around it or make it scroll.
}
