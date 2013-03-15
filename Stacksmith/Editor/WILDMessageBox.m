//
//  WILDMessageBox.m
//  Stacksmith
//
//  Created by Uli Kusterer on 14.04.11.
//  Copyright 2011 Uli Kusterer. All rights reserved.
//

#import "WILDMessageBox.h"
#import "WILDDocument.h"
#import "Forge.h"
#import "ForgeWILDObjectValue.h"
#import "UKHelperMacros.h"


static WILDMessageBox*	sSharedMessageBox = nil;

@interface WILDMessageBox ()
{
	LEOObjectID				mIDForScripts;
	LEOObjectSeed			mSeedForScripts;
	struct LEOValueObject	mValueForScripts;		// A LEOValue so scripts can reference us (see mIDForScripts).
}

@property (retain) id<WILDObject>					parentObject;

@end


@implementation WILDMessageBox

@synthesize messageField;
@synthesize parentObject;

+(WILDMessageBox*)	sharedMessageBox
{
	if( !sSharedMessageBox )
		sSharedMessageBox = [[WILDMessageBox alloc] init];
	
	return sSharedMessageBox;
}

-(void)	dealloc
{
	DESTROY_DEALLOC(parentObject);
	DESTROY_DEALLOC(messageField);
	
    [super dealloc];
}


-(NSString*)	windowNibName
{
	return NSStringFromClass( [self class] );
}


-(void)	windowDidLoad
{
    [super windowDidLoad];
    
	NSSize	maxSize = [[self window] minSize];
	maxSize.width = FLT_MAX;
	[[self window] setMaxSize: maxSize];
}


-(IBAction)	runMessageWithHighlight: (id)sender
{
	[runButton performClick: sender];
}


-(WILDDocument*)	frontDoc
{
	WILDDocument*	frontDoc = nil;
	NSArray*		docs = [NSApp orderedDocuments];
	for( WILDDocument* currDoc in docs )
	{
		if( [currDoc isKindOfClass: [WILDDocument class]] )
		{
			frontDoc = currDoc;
			break;
		}
	}
	
	return frontDoc;
}


-(IBAction)	runMessage: (id)sender
{
	/*
		This is the main script execution bottleneck for the message box.
		The text you enter in the field gets executed in the context of the
		current card.
	*/
	
	WILDDocument*	frontDoc = [self frontDoc];
	NSString	*	currCmd = [messageField stringValue];
	const char	*	scriptStr = [currCmd UTF8String];
	LEOScript	*	theScript = NULL;
	uint16_t		fileID = LEOFileIDForFileName( [[[self window] title] UTF8String] );
	LEOParseTree*	parseTree = LEOParseTreeCreateForCommandOrExpressionFromUTF8Characters( scriptStr, strlen(scriptStr), fileID );
	if( LEOParserGetLastErrorMessage() == NULL )
	{
		WILDCard	*	targetCard = [frontDoc currentCard];
		self.parentObject = targetCard;
		LEOObjectID		objectIDForScripts = kLEOObjectIDINVALID;
		LEOObjectSeed	seedForScripts = 0;
		[self getID: &objectIDForScripts seedForScripts: &seedForScripts];
		
		theScript = LEOScriptCreateForOwner( objectIDForScripts, seedForScripts, LEOForgeScriptGetParentScript );
		LEOScriptCompileAndAddParseTree( theScript, [frontDoc contextGroup], parseTree, fileID );
	}
	
	if( LEOParserGetLastErrorMessage() )
	{
		NSRunAlertPanel( @"Script Error", @"%@", @"OK", @"", @"", [NSString stringWithCString: LEOParserGetLastErrorMessage() encoding: NSUTF8StringEncoding] );
	}
	else
	{
		NSString*	resultString = nil;
		LEOContext	ctx;
		
		LEOInitContext( &ctx, [frontDoc contextGroup] );
		#if REMOTE_DEBUGGER
		ctx.preInstructionProc = LEORemoteDebuggerPreInstructionProc;
		ctx.promptProc = LEORemoteDebuggerPrompt;
		#endif
		
		LEOPushEmptyValueOnStack( &ctx );	// Reserve space for return value.
		LEOPushIntegerOnStack( &ctx, 0 );
		
		// Send message:
		LEOHandlerID	handlerID = LEOContextGroupHandlerIDForHandlerName( [frontDoc contextGroup], ":run" );
		LEOHandler*		theHandler = LEOScriptFindCommandHandlerWithID( theScript, handlerID );

		#if REMOTE_DEBUGGER
		LEORemoteDebuggerAddFile( scriptStr, fileID, theScript );
		LEORemoteDebuggerAddBreakpoint( theHandler->instructions );
		#endif
		
		LEOContextPushHandlerScriptReturnAddressAndBasePtr( &ctx, theHandler, theScript, NULL, NULL );	// NULL return address is same as exit to top. basePtr is set to NULL as well on exit.
		LEORunInContext( theHandler->instructions, &ctx );
		if( ctx.errMsg[0] != 0 )
		{
			NSRunAlertPanel( @"Script Error", @"%@", @"OK", @"", @"", [NSString stringWithCString: ctx.errMsg encoding: NSUTF8StringEncoding] );
		}
		else
		{
			char	returnValue[1024] = { 0 };
			LEOGetValueAsString( ctx.stack, returnValue, sizeof(returnValue), &ctx );
			resultString = [[[NSString alloc] initWithBytes: returnValue length: strlen(returnValue) encoding: NSUTF8StringEncoding] autorelease];
		}
		
		if( mIDForScripts )
		{
			mIDForScripts = kLEOObjectIDINVALID;
			LEOCleanUpValue( &mValueForScripts, kLEOInvalidateReferences, &ctx );
		}
		
		LEOCleanUpContext( &ctx );
	}
	
	if( theScript )
	{
		LEOScriptRelease( theScript );
		theScript = NULL;
	}
}
	
-(void)	getID: (LEOObjectID*)outID seedForScripts: (LEOObjectSeed*)outSeed
{
	if( mIDForScripts == kLEOObjectIDINVALID )
	{
		WILDDocument	*	frontDoc = [self frontDoc];
		LEOInitWILDObjectValue( &mValueForScripts, self, kLEOInvalidateReferences, NULL );
		mIDForScripts = LEOContextGroupCreateNewObjectIDForPointer( [frontDoc contextGroup], &mValueForScripts );
		mSeedForScripts = LEOContextGroupGetSeedForObjectID( [frontDoc contextGroup], mIDForScripts );
	}
	
	if( mIDForScripts )
	{
		if( outID )
			*outID = mIDForScripts;
		if( outSeed )
			*outSeed = mSeedForScripts;
	}
}


-(void)		setStringValue: (NSString*)messageString
{
	NSWindow	*	theWindow = [self window];	// Load the window.
	[messageField setStringValue: messageString];
	
	if( ![[self window] isVisible] )
		[self showWindow: self];
	[messageField displayIfNeeded];
	[messageField.window displayIfNeeded];
}


-(IBAction)	orderFrontMessageBox: (id)sender
{
	if( [[self window] isVisible] )
		[[self window] orderOut: sender];
	else
		[self showWindow: self];
}

@end
