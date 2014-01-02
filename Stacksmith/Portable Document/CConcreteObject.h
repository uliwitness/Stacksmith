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
#include <string>
#include <map>
#include "tinyxml2.h"
extern "C" {
#include "LEOInterpreter.h"
#include "LEOScript.h"
#include "Forge.h"
#include "LEOValue.h"
}


namespace Calhoun {

class CDocument;

class CConcreteObject : public CRefCountedObject
{
public:
	CConcreteObject();
	~CConcreteObject();
	
	void				SetScript( std::string inScript );
	std::string			GetScript()							{ return mScript; };
	
	struct LEOScript*	GetScriptObject( std::function<void(const char*,size_t,size_t,CConcreteObject*)> errorHandler );	// Calls errorHandler with NULL message on success, calls error handler with error message and returns NULL on failure.

protected:
	void				LoadUserPropertiesFromElement( tinyxml2::XMLElement * elem );
	
	void				DumpUserProperties( size_t inIndent );
		
	LEOContextGroup*	GetScriptContextGroupObject();

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