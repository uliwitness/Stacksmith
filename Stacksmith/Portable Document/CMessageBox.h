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
	
	CMessageBox() : mScriptObject(NULL), mIDForScripts(kLEOObjectIDINVALID), mSeedForScripts(0), mLastContextGroup(NULL) {};
	
	virtual void		Show()	{};
	virtual void		Run();
	virtual void		SetVisible( bool n )	{};
	virtual bool		IsVisible()				{ return false; };
	
	virtual bool		GetTextContents( std::string& outString ) override;
	virtual bool		SetTextContents( const std::string& inString) override;
	virtual std::string	GetResultText()									{ return mResultText; };
	virtual void		SetResultText( const std::string& inString)		{ mResultText = inString; };
	// We don't provide InitValue here because the message box can be used to run scripts in many context groups.

	virtual std::string	GetObjectDescriptorString() override { return "message box"; }
	
    virtual void        ContextCompleted( LEOContext* ctx ) override;

	virtual LEOScript*	GetScriptObject( std::function<void(const char*,size_t,size_t,CScriptableObject*)> errorHandler ) override;
	virtual LEOContextGroup*	GetScriptContextGroupObject() override;
	virtual CScriptableObject*	GetParentObject( CScriptableObject* previousParent, LEOContext * ctx ) override;
	
protected:
	std::string				mScript;			// The actual text in the message box.
	LEOScript*				mScriptObject;		// A compiled script version of the message box text, lazily compiled when the user hits return in the message box.
	LEOObjectID				mIDForScripts;		// The ID Leonie uses to refer to this object.
	LEOObjectSeed			mSeedForScripts;	// The seed value to go with mIDForScripts.
	struct LEOValueObject	mValueForScripts;	// A LEOValue so scripts can reference us (see mIDForScripts).
	LEOContextGroup*		mLastContextGroup;	//!< The context group relative to which mSeedForScripts/mIDForScripts are.
	std::string				mResultText;		// If you type an expression into the message box, its result will go here.
};


}

#endif /* defined(__Stacksmith__CMessageBox__) */
