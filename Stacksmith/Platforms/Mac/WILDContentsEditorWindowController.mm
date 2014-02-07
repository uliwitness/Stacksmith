//
//  WILDContentsEditorWindowController.m
//  Propaganda
//
//  Created by Uli Kusterer on 13.03.10.
//  Copyright 2010 The Void Software. All rights reserved.
//

#import "WILDContentsEditorWindowController.h"
#import "CPart.h"
#import "NSWindow+ULIZoomEffect.h"
#import "UKHelperMacros.h"
#import "CMacPartBase.h"



using namespace Carlson;


@implementation WILDContentsEditorWindowController

-(id)	initWithPart: (CPart*)inContainer
{
	if(( self = [super initWithWindowNibName: NSStringFromClass( [self class] )] ))
	{
		mContainer = inContainer;
	}
	
	return self;
}


-(void)	dealloc
{
	mContainer = nil;
	
	[super dealloc];
}


-(void)	awakeFromNib
{
	[super awakeFromNib];
	
	std::string		contentsStr;
	mContainer->GetTextContents( contentsStr );
	[mTextView setString: [[[NSString alloc] initWithBytes: contentsStr.c_str() length: contentsStr.length() encoding: NSUTF8StringEncoding] autorelease]];
}


-(void)	showWindow:(id)sender
{
	NSWindow	*	theWindow = [self window];
	
	[theWindow makeKeyAndOrderFrontWithZoomEffectFromRect: mGlobalStartRect];
}


-(BOOL)	windowShouldClose: (id)sender
{
	NSWindow	*	theWindow = [self window];
	
	[theWindow orderOutWithZoomEffectToRect: mGlobalStartRect];
	
	return YES;
}


-(void)	windowWillClose: (NSNotification*)notification
{
	NSString	*	contentsStr = mTextView.textStorage.string;
	
	mContainer->SetTextContents( std::string( contentsStr.UTF8String, [contentsStr lengthOfBytesUsingEncoding: NSUTF8StringEncoding] ) );
}


-(void) setDocument: (NSDocument *)document
{
	[super setDocument: document];
	
	CMacPartBase*	macPart = dynamic_cast<CMacPartBase*>(mContainer);
	if( macPart )
	{
		NSButton*		btn = [[self window] standardWindowButton: NSWindowDocumentIconButton];
		[btn setImage: macPart->GetDisplayIcon()];
	}
}


-(NSString *)	windowTitleForDocumentDisplayName: (NSString *)displayName
{
	return [NSString stringWithFormat: @"%1$@’s Contents", [NSString stringWithUTF8String: mContainer->GetDisplayName().c_str()]];
}


-(BOOL)	window: (NSWindow *)window shouldPopUpDocumentPathMenu: (NSMenu *)menu
{
	// Make sure the former top item (pointing to the file) selects the main doc window:
	NSMenuItem*		fileItem = [menu itemAtIndex: 0];
	[fileItem setTarget: [[[[self document] windowControllers] objectAtIndex: 0] window]];
	[fileItem setAction: @selector(makeKeyAndOrderFront:)];
	
	// Now add a new item above that for this window, the script:
	NSMenuItem*		newItem = [menu insertItemWithTitle: [NSString stringWithFormat: @"%1$@’s Contents", [NSString stringWithUTF8String: mContainer->GetDisplayName().c_str()]]
											action: nil keyEquivalent: @"" atIndex: 0];
	CMacPartBase*	macPart = dynamic_cast<CMacPartBase*>(mContainer);
	if( macPart )
		[newItem setImage: macPart->GetDisplayIcon()];
	
	return YES;
}


-(void)		setGlobalStartRect: (NSRect)theBox
{
	mGlobalStartRect = theBox;
}

@end
