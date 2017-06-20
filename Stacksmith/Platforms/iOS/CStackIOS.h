//
//  CStackIOS.h
//  Stacksmith
//
//  Created by Uli Kusterer on 2017-06-20.
//  Copyright (c) 2017 Uli Kusterer. All rights reserved.
//

#ifndef __Stacksmith__CStackIOS__
#define __Stacksmith__CStackIOS__

#include "CStack.h"


namespace Carlson {

class CStackIOS : public CStack
{
public:
	CStackIOS( const std::string& inURL, ObjectID inID, const std::string& inName, const std::string& inFileName, CDocument * inDocument );
	virtual ~CStackIOS();

	virtual bool				GoThereInNewWindow( TOpenInMode inOpenInMode, CStack* oldStack, CPart* overPart, std::function<void()> completionHandler, const std::string& inEffectType, TVisualEffectSpeed inSpeed );
	virtual void				SetPeeking( bool inState );

	virtual void				SetCurrentCard( CCard* inCard, const std::string& inEffectType = "", TVisualEffectSpeed inSpeed = EVisualEffectSpeedNormal );
	virtual void				SetEditingBackground( bool inState );
	virtual void				SetTool( TTool inTool );
	
	virtual void				RectChangedOfPart( CPart* inChangedPart );
	virtual void				SelectedPartChanged();
	virtual void				SetCardWidth( LEOInteger n );
	virtual void				SetCardHeight( LEOInteger n );
	virtual LEOInteger			GetLeft();
	virtual LEOInteger			GetTop();
	virtual LEOInteger			GetRight();
	virtual LEOInteger			GetBottom();
	virtual void				SetRect( LEOInteger l, LEOInteger t, LEOInteger r, LEOInteger b );
	
	virtual CUndoStack*			GetUndoStack();

	virtual void				Show( TEvenIfVisible inEvenIfVisible );
	virtual void				Hide();
	
	virtual void				NumberOrOrderOfPartsChanged();
};

}

#endif /* defined(__Stacksmith__CStackIOS__) */
