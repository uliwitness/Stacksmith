//
//  CMessageBox.h
//  Stacksmith
//
//  Created by Uli Kusterer on 2014-01-05.
//  Copyright (c) 2014 Uli Kusterer. All rights reserved.
//

#ifndef __Stacksmith__CMessageBox__
#define __Stacksmith__CMessageBox__

#include "CScriptableObjectValue.h"


namespace Carlson {


class CMessageBox : public CScriptableObject
{
public:
	static void			SetSharedInstance( CMessageBox* inMsg );	// Call once at startup
	static CMessageBox*	GetSharedInstance();
	
	CMessageBox() : mScriptObject(NULL), mIDForScripts(kLEOObjectIDINVALID), mSeedForScripts(0) {};
	
	virtual void		Run();
	
	virtual bool		GetTextContents( std::string& outString );
	virtual bool		SetTextContents( std::string inString);

	virtual LEOScript*	GetScriptObject( std::function<void(const char*,size_t,size_t,CScriptableObject*)> errorHandler );
	virtual LEOContextGroup*	GetScriptContextGroupObject();
	virtual CScriptableObject*	GetParentObject();
	
protected:
	std::string				mScript;			// The actual text in the message box.
	LEOScript*				mScriptObject;		// A compiled script version of the message box text, lazily compiled when the user hits return in the message box.
	LEOObjectID				mIDForScripts;		// The ID Leonie uses to refer to this object.
	LEOObjectSeed			mSeedForScripts;	// The seed value to go with mIDForScripts.
	struct LEOValueObject	mValueForScripts;	// A LEOValue so scripts can reference us (see mIDForScripts).
};


}

#endif /* defined(__Stacksmith__CMessageBox__) */
