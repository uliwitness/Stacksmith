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


enum EHandlerListEntryType { kHandlerEntryCommand, kHandlerEntryFunction, kHandlerEntryGroupHeader, kHandlerEntry_LAST };

/*! List entries for our "add handler" popup's entries.
	This only includes handlers that make sense for this
	object, and may e.g. include user-specified handlers
	like a timer's action. */
struct CAddHandlerListEntry
{
	enum EHandlerListEntryType	mType;				// Only mHandlerName is valid, containing the name of the new section.
	LEOHandlerID				mHandlerID;				// Handler ID corresponding to mHandlerName.
	std::string					mHandlerName;			// Name of the handler to be added.
	std::string					mHandlerDescription;	// Longer description for this handler, for presenting to user in addition to the actual name.
	std::string					mHandlerTemplate;		// A dummy example of this handler that can be appended to a script to create a new handler of this type.
	std::string					mTiedToType;			// Part type this handler/section should only be shown for.
};

/*!
	This is an object that can be addressed from a script (it's a CScriptableObject) but
	also contains the basic framework needed for an object that can be saved to a project
	and be read again. Objects of this type have a script and save it to XML, and support
	creating user-defined properties on them that also get saved.
*/
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
	
	virtual void		InitValue( LEOValuePtr outObject, LEOKeepReferencesFlag keepReferences, LEOContext* inContext );
	
	virtual LEOScript*	GetScriptObject( std::function<void(const char*,size_t,size_t,CScriptableObject*)> errorHandler );	// Calls errorHandler with NULL message on success, calls error handler with error message and returns NULL on failure.
	virtual CDocument*	GetDocument()		{ return mDocument; };
	
	virtual std::string	GetName()			{ return mName; };
    virtual void        SetName( const std::string& inStr ) { mName = inStr; IncrementChangeCount(); };
	virtual std::string	GetDisplayName()	{ return mName; };
		
	virtual LEOContextGroup*	GetScriptContextGroupObject();
	
	virtual void		SetBreakpointLines( const std::vector<size_t>& inBreakpointLines );
	virtual void		GetBreakpointLines( std::vector<size_t>& outBreakpointLines ) { outBreakpointLines = mBreakpointLines; };

	virtual void		IncrementChangeCount()	{};
	virtual bool		GetNeedsToBeSaved()		{ return false; };
	
	virtual std::string							GetTypeName()			{ return std::string(); };
	virtual std::vector<CAddHandlerListEntry>	GetAddHandlerList();	// List for an "add handler" popup in script editor.
	virtual bool		ShowHandlersForObjectType( std::string inTypeName )	{ return GetTypeName().compare(inTypeName) == 0; };
	
protected:
	virtual void		LoadUserPropertiesFromElement( tinyxml2::XMLElement * elem );
	virtual void		SaveUserPropertiesToElementOfDocument( tinyxml2::XMLElement * elem, tinyxml2::XMLDocument * document );
	
	virtual void		DumpUserProperties( size_t inIndent );

// ivars:
	std::string							mName;			// Name of this object for referring to it from scripts.
	std::string							mScript;		// Uncompiled text of this object's script.
	CMap<std::string>					mUserProperties;
	std::vector<size_t>					mBreakpointLines;	// Lines on which the user set breakpoints using the UI that should be applied to the script when compiled.
	
	struct LEOScript *					mScriptObject;		// Compiled script, lazily created/recreated on changes.
	LEOObjectID							mIDForScripts;		// The ID Leonie uses to refer to this object.
	LEOObjectSeed						mSeedForScripts;	// The seed value to go with mIDForScripts.
	struct LEOValueObject				mValueForScripts;	// A LEOValue so scripts can reference us (see mIDForScripts).
	CDocument *							mDocument;			// Document that contains us.
};

typedef CRefCountedObjectRef<CConcreteObject>	CConcreteObjectRef;

}

#endif /* defined(__Stacksmith__CConcreteObject__) */
