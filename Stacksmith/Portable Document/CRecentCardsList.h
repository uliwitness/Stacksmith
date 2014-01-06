//
//  CRecentCardsList.h
//  Stacksmith
//
//  Created by Uli Kusterer on 2014-01-06.
//  Copyright (c) 2014 Uli Kusterer. All rights reserved.
//

/*
	This is the list of recently visited cards (i.e. the "browser history"
	of Stacksmith). In general, you'd subclass the list and entry classes,
	then call ListSubclass::Initialize<EntrySubclass>() to create the shared
	instance, e.g. to add a thumbnail image of the visited card to each entry.
	
	The "go" command and other spots update this history for you, no matter
	what subclass you prevent them with.
*/

#ifndef __Stacksmith__CRecentCardsList__
#define __Stacksmith__CRecentCardsList__

#include <vector>
#include <cstddef>
#include <string>
#include "WILDObjectID.h"
#include "CCard.h"
#include "CStack.h"


namespace Carlson {


class CRecentCardInfo
{
public:
	CRecentCardInfo() {};
	CRecentCardInfo( const std::string& inURL, WILDObjectID inID, CCard* inCard ) {};
	
	std::string		GetDocumentURL()	{ return mDocumentURL; };
	WILDObjectID	GetCardID()			{ return mCardID; };
	CCard*			GetCard()			{ return mCard; };

protected:
	std::string		mDocumentURL;	// To get back to a closed stack.
	WILDObjectID	mCardID;		// To get back to a closed stack's card.
	CCardRef		mCard;			// If still loaded, this is the card for quick access.
};


class CRecentCardsList
{
public:
	template<class RecentCardInfoSubclass>
	static void	Initialize();	// Create the shared instance & customize the class used for recents entries.
	static CRecentCardsList*	GetSharedInstance();	// Shared across all subclasses.
	
	virtual void	AddCard( CCard* inCard ) = 0;
	virtual void	RemoveCard( CCard* inCard ) = 0;
	
	virtual size_t	GetNumRecentCards() = 0;
	virtual CCard*	GetCard( size_t inIndex ) = 0;
	
	void	SetMaxRecentsToKeep( size_t inNumRecents )	{ mMaxRecentsToKeep = inNumRecents; };
	size_t	GetMaxRecentsToKeep()						{ return mMaxRecentsToKeep; };

protected:
	CRecentCardsList() : mMaxRecentsToKeep(16)	{};
	~CRecentCardsList() {};
	
	size_t		mMaxRecentsToKeep;		// Maximum number of items in list before we start purging some.
};


// Template class with default behaviour. Preferentially subclass this instead of CRecentCardsList.
//	E.g. to add an image subclass CRecentCardInfo, add the member, then in an AddCard override, call
//	SetImage on mRecentCardInfos.back() to fill that last field.
template<class RecentCardInfoSubclass>
class CRecentCardsListConcrete : public CRecentCardsList
{
public:
	virtual void	AddCard( CCard* inCard )
	{
		if( mRecentCardInfos.size() > mMaxRecentsToKeep )
			mRecentCardInfos.erase( mRecentCardInfos.begin() );
		mRecentCardInfos.push_back( RecentCardInfoSubclass(inCard->GetStack()->GetURL(), inCard->GetID(), inCard) );
	};
	virtual void	RemoveCard( CCard* inCard )
	{
		for( auto itty = mRecentCardInfos.begin(); itty != mRecentCardInfos.end(); itty++ )
		{
			if( (*itty).GetCard() == inCard )
			{
				mRecentCardInfos.erase( itty );
				return;
			}
		}
	};
	
	virtual size_t	GetNumRecentCards()			{ return mRecentCardInfos.size(); };
	virtual CCard*	GetCard( size_t inIndex )	{ return mRecentCardInfos[inIndex].GetCard(); };

protected:
	std::vector<RecentCardInfoSubclass>	mRecentCardInfos;
};


}

#endif /* defined(__Stacksmith__CRecentCardsList__) */
