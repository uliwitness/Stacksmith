//
//  CStack.h
//  Stacksmith
//
//  Created by Uli Kusterer on 2013-12-29.
//  Copyright (c) 2013 Uli Kusterer. All rights reserved.
//

#ifndef __Stacksmith__CStack__
#define __Stacksmith__CStack__

#include <vector>
#include <string>
#include "CConcreteObject.h"
#include "WILDObjectID.h"


class CCard;
class CBackground;
class CStack;


// Mix-in class that gets notified of stuff happening in our stack:
class CStackDelegate
{
public:
	virtual ~CStackDelegate() {};
	
	virtual void	StackDidFinishLoading( CStack* inSender )	{};
};


class CStack : public CConcreteObject
{
public:
	CStack() : mDelegate(NULL), mStackID(0)	{};
	
	void		LoadFromURL( const std::string inURL );
	
	void		AddCard( CCard* inCard );
	void		RemoveCard( CCard* inCard );
	
	void				SetDelegate( CStackDelegate* inDelegate )	{ mDelegate = inDelegate; };
	CStackDelegate	*	GetDelegate()								{ return mDelegate; };
	
protected:
	~CStack()	{};

protected:
	WILDObjectID				mStackID;
	std::vector<CCard*>			mCards;
	std::vector<CBackground*>	mBackgrounds;
	CStackDelegate*				mDelegate;
};

typedef CRefCountedObjectRef<CStack>	CStackRef;

#endif /* defined(__Stacksmith__CStack__) */
