//
//  WILDConcreteObject.m
//  Stacksmith
//
//  Created by Uli Kusterer on 01.05.13.
//  Copyright (c) 2013 Uli Kusterer. All rights reserved.
//

#import "WILDConcreteObject.h"
#import "UKHelperMacros.h"
#import "LEOInterpreter.h"
#import "LEOScript.h"
#import "Forge.h"
#import "WILDNotifications.h"


@implementation WILDConcreteObject

@synthesize script = mScript;
@synthesize name = mName;

-(id)	init
{
	if(( self = [super init] ))
	{
		mIDForScripts = kLEOObjectIDINVALID;
		
		[self getPropertyTypes: &mPropertyTypes names: &mPropertyNames];
	}
	
	return self;
}


-(void)	dealloc
{
	DESTROY_DEALLOC(mScript);
	DESTROY_DEALLOC(mName);
	if( mPropertyTypes )
		CFRelease(mPropertyTypes);
	mPropertyTypes = (CFMutableDictionaryRef) UKInvalidPointer;
	DESTROY_DEALLOC(mPropertyNames);
	
	if( mScriptObject )
	{
		LEOScriptRelease( mScriptObject );
		mScriptObject = NULL;
	}
	
	[super dealloc];
}


PROPERTY_MAP_START
PROPERTY_MAPPING(name,"name",kLeoValueTypeString)
PROPERTY_MAPPING(name,"short name",kLeoValueTypeString)
PROPERTY_MAPPING(script,"script",kLeoValueTypeString)
PROPERTY_MAP_END


-(void)	setScript: (NSString*)theScript
{
	ASSIGN(mScript,theScript);
	if( mScriptObject )
	{
		LEOScriptRelease( mScriptObject );
		mScriptObject = NULL;
	}
}


-(struct LEOScript*)	scriptObjectShowingErrorMessage: (BOOL)showError
{
	if( !mScriptObject )
	{
		const char*		scriptStr = [mScript UTF8String];
		uint16_t		fileID = LEOFileIDForFileName( [[self displayName] UTF8String] );
		LEOParseTree*	parseTree = LEOParseTreeCreateFromUTF8Characters( scriptStr, strlen(scriptStr), fileID );
		if( LEOParserGetLastErrorMessage() == NULL )
		{
			if( mIDForScripts == kLEOObjectIDINVALID )
			{
				WILDInitObjectValue( &mValueForScripts, self, kLEOInvalidateReferences, NULL );
				mIDForScripts = LEOContextGroupCreateNewObjectIDForPointer( [self scriptContextGroupObject], &mValueForScripts );
				mSeedForScripts = LEOContextGroupGetSeedForObjectID( [self scriptContextGroupObject], mIDForScripts );
			}
			mScriptObject = LEOScriptCreateForOwner( mIDForScripts, mSeedForScripts, WILDGetParentScript );
			LEOScriptCompileAndAddParseTree( mScriptObject, [self scriptContextGroupObject], parseTree, fileID );
			
#if REMOTE_DEBUGGER
			LEORemoteDebuggerAddFile( scriptStr, fileID, mScriptObject );
			
			// Set a breakpoint on the mouseUp handler:
			//			LEOHandlerID handlerName = LEOContextGroupHandlerIDForHandlerName( [self scriptContextGroupObject], "mouseup" );
			//			LEOHandler* theHandler = LEOScriptFindCommandHandlerWithID( mScriptObject, handlerName );
			//			if( theHandler )
			//				LEORemoteDebuggerAddBreakpoint( theHandler->instructions );
#endif
		}
		if( LEOParserGetLastErrorMessage() )
		{
			if( showError )
			{
				size_t	lineNum = LEOParserGetLastErrorLineNum();
				size_t	errorOffset = LEOParserGetLastErrorOffset();
				if( NSRunAlertPanel( @"Script Error", @"%@", @"OK", ((lineNum != SIZE_T_MAX || errorOffset != SIZE_T_MAX) ? @"Edit Script" : @""), @"", [NSString stringWithCString: LEOParserGetLastErrorMessage() encoding: NSUTF8StringEncoding] ) == NSAlertAlternateReturn )
				{
					if( errorOffset != SIZE_T_MAX )
						[self openScriptEditorAndShowOffset: errorOffset];
					else
						[self openScriptEditorAndShowLine: lineNum];
				}
			}
			if( mScriptObject )
			{
				LEOScriptRelease( mScriptObject );
				mScriptObject = NULL;
			}
		}
	}
	
	return mScriptObject;
}


-(void)	openScriptEditorAndShowOffset: (NSInteger)byteOffset
{
	
}


-(void)	openScriptEditorAndShowLine: (NSInteger)lineIndex
{
	
}


-(void)	getID: (LEOObjectID*)outID seedForScripts: (LEOObjectSeed*)outSeed
{
	if( mIDForScripts == kLEOObjectIDINVALID )
	{
		WILDInitObjectValue( &mValueForScripts, self, kLEOInvalidateReferences, NULL );
		mIDForScripts = LEOContextGroupCreateNewObjectIDForPointer( [self scriptContextGroupObject], &mValueForScripts );
		mSeedForScripts = LEOContextGroupGetSeedForObjectID( [self scriptContextGroupObject], mIDForScripts );
	}
	
	if( mIDForScripts )
	{
		if( outID )
			*outID = mIDForScripts;
		if( outSeed )
			*outSeed = mSeedForScripts;
	}
}


-(id<WILDObject>)	parentObject
{
	return nil;
}


-(WILDDocument*)	document
{
	return nil;
}


-(struct LEOContextGroup*)	scriptContextGroupObject
{
	return [self.document scriptContextGroupObject];
}


-(void)	updateChangeCount: (NSDocumentChangeType)inChange
{
	[self.document updateChangeCount: inChange];
}


-(NSString*)	textContents
{
	return nil;
}


-(BOOL)	setTextContents: (NSString*)inString
{
	return NO;
}

-(BOOL)	goThereInNewWindow: (BOOL)inNewWindow
{
	return NO;
}


-(NSString*)	displayName
{
	return @"";
}


-(NSImage*)	displayIcon
{
	return nil;
}


-(WILDStack*)	stack
{
	return [self.parentObject stack];
}


-(id)	valueForWILDPropertyNamed: (NSString*)inPropertyName ofRange: (NSRange)byteRange
{
	if( [inPropertyName isEqualToString: @"properties"] )
		return [mPropertyNames allKeys];
	else if( [inPropertyName isEqualToString: @"userproperties"] )
		return [mUserProperties allKeys];
	else
	{
		NSString*	propName = [mPropertyNames objectForKey: inPropertyName];
		if( propName )
			return [self valueForKey: propName];
		else
			return [mUserProperties objectForKey: inPropertyName];
	}
}


-(BOOL)		setValue: (id)inValue forWILDPropertyNamed: (NSString*)inPropertyName inRange: (NSRange)byteRange
{
	BOOL	propExists = YES;
	
	NSString*	propName = [mPropertyNames objectForKey: inPropertyName];
	if( propName )
	{
		[[NSNotificationCenter defaultCenter] postNotificationName: self.propertyWillChangeNotificationName
															object: self userInfo: [NSDictionary dictionaryWithObject: propName
																											   forKey: WILDAffectedPropertyKey]];
		[self setValue: inValue forKey: propName];
		[[NSNotificationCenter defaultCenter] postNotificationName: self.propertyDidChangeNotificationName
															object: self userInfo: [NSDictionary dictionaryWithObject: propName
																											   forKey: WILDAffectedPropertyKey]];
	}
	else
	{
		id		theValue = [mUserProperties objectForKey: inPropertyName];
		if( theValue )
			[mUserProperties setObject: inValue forKey: inPropertyName];
		else
			propExists = NO;
	}
	
	if( propExists )
		[self updateChangeCount: NSChangeDone];
	
	return propExists;
}


-(NSString*)	propertyWillChangeNotificationName
{
	return nil;
}


-(NSString*)	propertyDidChangeNotificationName
{
	return nil;
}


-(LEOValueTypePtr)	typeForWILDPropertyNamed: (NSString*)inPropertyName
{
	LEOValueTypePtr	propType = (LEOValueTypePtr) CFDictionaryGetValue( mPropertyTypes, (CFStringRef) inPropertyName );
	if( propType )
		return propType;
	else if( [inPropertyName isEqualToString: @"properties"] )
		return &kLeoValueTypeArray;
	else
		return &kLeoValueTypeString;
}


-(void)	addUserPropertyNamed: (NSString*)userPropName
{
	if( !mUserProperties )
		mUserProperties = [[NSMutableDictionary alloc] init];
	if( ![mUserProperties objectForKey: userPropName] )
	{
		[mUserProperties setObject: @"" forKey: userPropName];
		[self updateChangeCount: NSChangeDone];
	}
}


-(void)	deleteUserPropertyNamed: (NSString*)userPropName
{
	if( mUserProperties[userPropName] )
	{
		[mUserProperties removeObjectForKey: userPropName];
		[self updateChangeCount: NSChangeDone];
	}
}


-(NSMutableArray*)	allUserProperties
{
	NSMutableArray	*	allProps = [NSMutableArray arrayWithCapacity: mUserProperties.count];
	for( NSString * theKey in mUserProperties )
	{
		[allProps addObject: [NSMutableDictionary dictionaryWithObjectsAndKeys: theKey, WILDUserPropertyNameKey, mUserProperties[theKey], WILDUserPropertyValueKey, nil]];
	}
	return allProps;
}


-(void)	setValue: (NSString*)inValue forUserPropertyNamed: (NSString*)inName oldName: (NSString*)inOldName
{
	if( inOldName )
		[mUserProperties removeObjectForKey: inOldName];
	if( !mUserProperties )
		mUserProperties = [[NSMutableDictionary alloc] init];
	[mUserProperties setObject: inValue forKey: inName];
	[self updateChangeCount: NSChangeDone];
}

@end
