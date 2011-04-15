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


static WILDMessageBox*	sSharedMessageBox = nil;

@implementation WILDMessageBox

@synthesize messageField;

+(WILDMessageBox*)	sharedMessageBox
{
	if( !sSharedMessageBox )
		sSharedMessageBox = [[WILDMessageBox alloc] init];
	
	return sSharedMessageBox;
}

-(void)	dealloc
{
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


-(IBAction)	runMessage: (id)sender
{
	WILDDocument*	frontDoc = nil;
	NSArray*		docs = [[NSDocumentController sharedDocumentController] documents];
	for( WILDDocument* currDoc in docs )
	{
		if( [currDoc isKindOfClass: [WILDDocument class]] )
		{
			frontDoc = currDoc;
			break;
		}
	}
	
	NSString	*	currCmd = [messageField stringValue];
	const char	*	scriptStr = [currCmd UTF8String];
	LEOScript	*	theScript = NULL;
	LEOParseTree*	parseTree = LEOParseTreeCreateForCommandOrExpressionFromUTF8Characters( scriptStr, strlen(scriptStr), [[self window] title] );
	if( LEOParserGetLastErrorMessage() == NULL )
	{
		theScript = LEOScriptCreateForOwner( 0, 0 );	// TODO: Store owner reference and use here!
		LEOScriptCompileAndAddParseTree( theScript, [frontDoc contextGroup], parseTree );
	}
	
	if( LEOParserGetLastErrorMessage() )
	{
		NSRunAlertPanel( @"Script Error", @"%s", @"OK", @"", @"", LEOParserGetLastErrorMessage() );
	}
	else
	{
		NSString*	resultString = nil;
		LEOContext	ctx;
		
		LEOInitContext( &ctx, [frontDoc contextGroup] );
		
		LEOPushEmptyValueOnStack( &ctx );	// Reserve space for return value.
		LEOPushIntegerOnStack( &ctx, 0 );
		
		// Send message:
		LEOHandlerID	handlerID = LEOContextGroupHandlerIDForHandlerName( [frontDoc contextGroup], ":run" );
		LEOHandler*		theHandler = LEOScriptFindCommandHandlerWithID( theScript, handlerID );
		
		LEOContextPushHandlerScriptReturnAddressAndBasePtr( &ctx, theHandler, theScript, NULL, NULL );	// NULL return address is same as exit to top. basePtr is set to NULL as well on exit.
		LEORunInContext( theHandler->instructions, &ctx );
		if( ctx.errMsg[0] != 0 )
		{
			NSRunAlertPanel( @"Script Error", @"%s", @"OK", @"", @"", ctx.errMsg );
		}
		
		char	returnValue[1024] = { 0 };
		LEOGetValueAsString( ctx.stack, returnValue, sizeof(returnValue), &ctx );
		resultString = [[[NSString alloc] initWithBytes: returnValue length: strlen(returnValue) encoding: NSUTF8StringEncoding] autorelease];
		
		LEOCleanUpContext( &ctx );
	}
	
	if( theScript )
	{
		LEOScriptRelease( theScript );
		theScript = NULL;
	}
}


-(void)		setStringValue: (NSString*)messageString
{
	NSWindow	*	theWindow = [self window];	// Load the window.
	[messageField setStringValue: messageString];
	
	if( ![[self window] isVisible] )
		[self showWindow: self];
}


-(IBAction)	orderFrontMessageBox: (id)sender
{
	if( [[self window] isVisible] )
		[[self window] orderOut: sender];
	else
		[self showWindow: self];
}

@end
