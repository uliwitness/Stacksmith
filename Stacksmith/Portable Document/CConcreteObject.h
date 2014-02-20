//
//  CConcreteObject.h
//  Stacksmith
//
//  Created by Uli Kusterer on 2013-12-29.
//  Copyright (c) 2013 Uli Kusterer. All rights reserved.
//

#ifndef __Stacksmith__CConcreteObject__
#define __Stacksmith__CConcreteObject__

#include "CRefCountedObject.h"
#include "CScriptableObjectValue.h"
#include <string>
#include "CMap.h"
#include "tinyxml2.h"
extern "C" {
#include "LEOInterpreter.h"
#include "LEOScript.h"
#include "Forge.h"
#include "LEOValue.h"
}


namespace Carlson {

class CDocument;

class CConcreteObject : public CScriptableObject
{
public:
	CConcreteObject();
	~CConcreteObject();
	
	virtual void		SetScript( std::string inScript );
	virtual std::string	GetScript()							{ return mScript; };
	virtual bool		GetPropertyNamed( const char* inPropertyName, size_t byteRangeStart, size_t byteRangeEnd, LEOContext* inContext, LEOValuePtr outValue );
	virtual bool		SetValueForPropertyNamed( LEOValuePtr inValue, LEOContext* inContext, const char* inPropertyName, size_t byteRangeStart, size_t byteRangeEnd );
	
	virtual bool		AddUserPropertyNamed( const char* userPropName );
	virtual bool		DeleteUserPropertyNamed( const char* userPropName );
	virtual size_t		GetNumUserProperties();
	virtual std::string	GetUserPropertyNameAtIndex( size_t inIndex );
	virtual bool		SetUserPropertyNameAtIndex( const char* inNewName, size_t inIndex );
	virtual bool		GetUserPropertyValueForName( const char* inPropName, std::string& outValue );
	virtual bool		SetUserPropertyValueForName( const std::string& inValue, const char* inPropName );
	
	virtual LEOScript*	GetScriptObject( std::function<void(const char*,size_t,size_t,CScriptableObject*)> errorHandler );	// Calls errorHandler with NULL message on success, calls error handler with error message and returns NULL on failure.
	virtual CDocument*	GetDocument()		{ return mDocument; };
	
	virtual std::string	GetName()			{ return mName; };
    virtual void        SetName( const std::string& inStr ) { mName = inStr; IncrementChangeCount(); };
	virtual std::string	GetDisplayName()	{ return mName; };
		
	virtual LEOContextGroup*	GetScriptContextGroupObject();

	virtual void		IncrementChangeCount()	{};
	virtual bool		GetNeedsToBeSaved()		{ return false; };
	
protected:
	virtual void		LoadUserPropertiesFromElement( tinyxml2::XMLElement * elem );
	virtual void		SaveUserPropertiesToElementOfDocument( tinyxml2::XMLElement * elem, tinyxml2::XMLDocument * document );
	
	virtual void		DumpUserProperties( size_t inIndent );

// ivars:
	std::string							mName;			// Name of this object for referring to it from scripts.
	std::string							mScript;		// Uncompiled text of this object's script.
	CMap<std::string>					mUserProperties;
	
	struct LEOScript *					mScriptObject;		// Compiled script, lazily created/recreated on changes.
	LEOObjectID							mIDForScripts;		// The ID Leonie uses to refer to this object.
	LEOObjectSeed						mSeedForScripts;	// The seed value to go with mIDForScripts.
	struct LEOValueObject				mValueForScripts;	// A LEOValue so scripts can reference us (see mIDForScripts).
	CDocument *							mDocument;			// Document that contains us.
};

typedef CRefCountedObjectRef<CConcreteObject>	CConcreteObjectRef;

}

#endif /* defined(__Stacksmith__CConcreteObject__) */
