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
#include <map>
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
	
	virtual LEOScript*	GetScriptObject( std::function<void(const char*,size_t,size_t,CScriptableObject*)> errorHandler );	// Calls errorHandler with NULL message on success, calls error handler with error message and returns NULL on failure.
	virtual CDocument*	GetDocument()		{ return mDocument; };
	
	virtual std::string	GetName()			{ return mName; };
    virtual void        SetName( const std::string& inStr ) { mName = inStr; };
		
	virtual LEOContextGroup*	GetScriptContextGroupObject();

protected:
	virtual void		LoadUserPropertiesFromElement( tinyxml2::XMLElement * elem );
	
	virtual void		DumpUserProperties( size_t inIndent );

// ivars:
	std::string							mName;			// Name of this object for referring to it from scripts.
	std::string							mScript;		// Uncompiled text of this object's script.
	std::map<std::string,std::string>	mUserProperties;
	
	struct LEOScript *					mScriptObject;		// Compiled script, lazily created/recreated on changes.
	LEOObjectID							mIDForScripts;		// The ID Leonie uses to refer to this object.
	LEOObjectSeed						mSeedForScripts;	// The seed value to go with mIDForScripts.
	struct LEOValueObject				mValueForScripts;	// A LEOValue so scripts can reference us (see mIDForScripts).
	CDocument *							mDocument;			// Document that contains us.
};

typedef CRefCountedObjectRef<CConcreteObject>	CConcreteObjectRef;

}

#endif /* defined(__Stacksmith__CConcreteObject__) */
