//
//  CScriptableObjectValue.h
//  Stacksmith
//
//  Created by Uli Kusterer on 16.04.11.
//  Copyright 2011 Uli Kusterer. All rights reserved.
//

/*!
	@header CScriptableObjectValue
	This file contains everything that is needed to interface Stacksmith's
	CConcreteObject-based object hierarchy (buttons, fields, cards) with the
	Leonie bytecode interpreter. This allows performing common operations on
	them (like retrieve property values, change their value, call handlers
	in their scripts, add user properties etc.
	
	So that the Leonie bytecode interpreter can deal with objects of this type,
	it also defines kLeoValueTypeScriptableObject, which is like a native object,
	but guarantees that the object conforms to the CScriptableObject protocol.
	
	You can create such a value using the <tt>CInitScriptableObjectValue</tt> function,
	just like any other values.
*/

#ifndef __Stacksmith__CScriptableObjectValue__
#define __Stacksmith__CScriptableObjectValue__

#include "LEOValue.h"
#include "CRefCountedObject.h"
#include <string>
#include <functional>
#include "LEOScript.h"
#include "LEOInterpreter.h"



namespace Carlson
{

extern struct LEOValueType	kLeoValueTypeScriptableObject;
extern struct LEOValueType	kLeoValueTypeObjectDescriptor;


class CStack;
class CDocument;
class CPart;


enum
{
	EOpenInSameWindow,
	EOpenInNewWindow
};
typedef uint16_t	TOpenInMode;


typedef enum
{
    EVisualEffectSpeedVerySlow,
    EVisualEffectSpeedSlow,
    EVisualEffectSpeedNormal,
    EVisualEffectSpeedFast,
    EVisualEffectSpeedVeryFast,
    EVisualEffectSpeed_Last
} TVisualEffectSpeed;


/*!
	@class CScriptableObject
	Base class for all objects that can be referenced from a script.
	This defines an interface for the basics, like using them as containers,
	querying and modifying properties, adding/removing user properties,
	deleting the object, Getting a context to run scripts in,
	sending messages and passing them up the hierarchy, opening a script editor etc.
	
	The bool returns on these methods indicate whether the given object can do
	what was asked (as in, ever). So if a property doesn't exist, they'd return
	FALSE. If an object has no contents, the same. Some other calls may return NULL
	instead of an object for the same reason.
*/

class CScriptableObject : public CRefCountedObject
{
public:
	virtual ~CScriptableObject() {};
	
	virtual bool				GetTextContents( std::string& outString )		{ return false; };
	virtual bool				SetTextContents( const std::string& inString)	{ return false; };

	virtual bool				GoThereInNewWindow( TOpenInMode inOpenInMode, CStack* oldStack, CPart* overPart, std::function<void()> completionHandler, const std::string& inEffectType, TVisualEffectSpeed inSpeed )			{ return false; };

	virtual bool				GetPropertyNamed( const char* inPropertyName, size_t byteRangeStart, size_t byteRangeEnd, LEOContext* inContext, LEOValuePtr outValue )						{ return false; };
	virtual bool				SetValueForPropertyNamed( LEOValuePtr inValue, LEOContext* inContext, const char* inPropertyName, size_t byteRangeStart, size_t byteRangeEnd )	{ return false; };

	virtual bool				DeleteObject()		{ return false; };

	virtual void				OpenScriptEditorAndShowOffset( size_t byteOffset )	{};
	virtual void				OpenScriptEditorAndShowLine( size_t lineIndex )		{};
	virtual void				OpenContentsEditor()								{};

	virtual bool				AddUserPropertyNamed( const char* userPropName )	{ return false; };
	virtual bool				DeleteUserPropertyNamed( const char* userPropName )	{ return false; };
	virtual size_t				GetNumUserProperties()								{ return 0; };
	virtual std::string			GetUserPropertyNameAtIndex( size_t inIndex )		{ return std::string(); };
	virtual bool				SetUserPropertyNameAtIndex( const char* inNewName, size_t inIndex )	{ return false; };
	virtual bool				GetUserPropertyValueForName( const char* inPropName, std::string& outValue )	{ return false; };
	virtual bool				SetUserPropertyValueForName( const std::string& inValue, const char* inPropName )	{ return false; };
	virtual std::string			GetObjectDescriptorString()	{ return "OBJECT DESCRIPTOR"; };
	
	virtual void				SendMessage( LEOContext** outContext, std::function<void(const char*,size_t,size_t,CScriptableObject*,bool)> errorHandler, TMayGoUnhandledFlag inMayGoUnhandled, const char* fmt, ... );	//!< Error handler takes errMsg, line, offset, object, wasHandled.
    virtual void                ContextCompleted( LEOContext* ctx )                 {};
	virtual bool				HasOrInheritsMessageHandler( const char* inMsgName, CScriptableObject* previousParent );	//!< To find whether this object implements the given message, or someone up the hierarchy does that this object will forward it to (e.g. to not ask the OS for mouseMoved events unless actually implemented).
	virtual bool				HasMessageHandler( const char* inMsgName );	//!< To find whether this object implements the given message.

	virtual CStack*				GetStack()												{ return NULL; };
	virtual CScriptableObject*	GetParentObject( CScriptableObject* previousParent )	{ return NULL; };
	virtual LEOScript*			GetScriptObject( std::function<void(const char*,size_t,size_t,CScriptableObject*)> errorHandler )										{ return NULL; };
	virtual LEOContextGroup*	GetScriptContextGroupObject()					{ return NULL; };
	virtual void				InitValue( LEOValuePtr outObject, LEOKeepReferencesFlag keepReferences, LEOContext* inContext );
	virtual void				InitObjectDescriptorValue( LEOValuePtr outObject, LEOKeepReferencesFlag keepReferences, LEOContext* inContext );
	
	void 						RunHandlerForObjectInScriptAndContext( LEOHandlerID inID, CScriptableObject ** ioHandlingObject, LEOScript **ioScript, LEOContext *ctx, std::function<void(const char*,size_t,size_t,CScriptableObject*,bool)> errorHandler, TMayGoUnhandledFlag mayGoUnhandled, LEOHandler ** outHandler );

// statics:
	static void			InitScriptableObjectValue( LEOValueObject* inStorage, CScriptableObject* wildObject, LEOKeepReferencesFlag keepReferences, LEOContext* inContext );
	static void			InitObjectDescriptorValue( LEOValueObject* inStorage, CScriptableObject* wildObject, LEOKeepReferencesFlag keepReferences, LEOContext* inContext );
	static LEOScript*	GetParentScript( LEOScript* inScript, LEOContext* inContext, void* inParam );

	static CScriptableObject*	GetOwnerScriptableObjectFromContext( LEOContext * inContext );
	static void					PreInstructionProc( LEOContext* inContext );
	static void					ContextCompletedProc( LEOContext* inContext );
};

typedef CRefCountedObjectRef<CScriptableObject>	CScriptableObjectRef;


/*!
	@class CScriptContextUserData
	An instance of these class should be passed as the userData into every
	LEOCreateContext(). We use it to associate some Stacksmith-specific
	state with each execution thread (not actually an OS thread, at least yet,
	but sort of, due to our continuation-like approach to e.g. the "go" command).
*/
class CScriptContextUserData
{
public:
	CScriptContextUserData( CStack* currStack, CScriptableObject* target, CScriptableObject* owner );
	~CScriptContextUserData();
	
	void				SetStack( CStack* currStack );
	CStack*				GetStack()						{ return mCurrentStack; };
    void				SetTarget( CScriptableObject* target );
    CScriptableObject*	GetTarget()						{ return mTarget; };
    void				SetOwner( CScriptableObject* owner );
    CScriptableObject*	GetOwner()						{ return mOwner; };
	CDocument*			GetDocument();
	void				SetVisualEffectTypeAndSpeed( const std::string& inType, TVisualEffectSpeed inSpeed ) { mVisualEffectType = inType; mVisualEffectSpeed = inSpeed; };
	const std::string&	GetVisualEffectType()	{ return mVisualEffectType; };
	TVisualEffectSpeed	GetVisualEffectSpeed()	{ return mVisualEffectSpeed; };
	
	static void			CleanUp( void* inData );
	
protected:
	CStack				*	mCurrentStack;
    CScriptableObject	*	mTarget;
    CScriptableObject	*	mOwner;
	std::string				mVisualEffectType;
	TVisualEffectSpeed		mVisualEffectSpeed;
};


class CScriptContextGroupUserData
{
public:
	std::vector<CScriptableObjectRef>	mFrontScripts;
	
	static void			CleanUp( void* inData );
};


}

#endif /* defined(__Stacksmith__CScriptableObjectValue__) */

