//
//  WILDContentsEditorWindowController.m
//  Propaganda
//
//  Created by Uli Kusterer on 13.03.10.
//  Copyright 2010 The Void Software. All rights reserved.
//

#import "WILDContentsEditorWindowController.h"
#import "WILDPart.h"
#import "WILDCardView.h"
#import "WILDNotifications.h"
#import "NSWindow+ULIZoomEffect.h"
#import "UKHelperMacros.h"
#import "WILDCard.h"
#import "WILDBackground.h"
#import "WILDBackground.h"
#import "WILDPartContents.h"


@implementation WILDContentsEditorWindowController

-(id)	initWithPart: (WILDPart*)inContainer
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
	DESTROY(mCardView);
	
	[super dealloc];
}


-(void)	awakeFromNib
{
	[super awakeFromNib];
	
	WILDPartContents*	theContents = nil;
	if( [mContainer sharedText] )
		theContents = [[[mCardView card] owningBackground] contentsForPart: mContainer];
	else
		theContents = [[mCardView card] contentsForPart: mContainer];
	NSString*					contentsStr = [theContents text];
	[mTextView setString: contentsStr ? contentsStr : @""];
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
	NSDictionary	*	infoDict = [NSDictionary dictionaryWithObjectsAndKeys:
										@"contents", WILDAffectedPropertyKey,
										nil];
	[[NSNotificationCenter defaultCenter] postNotificationName: WILDPartWillChangeNotification object: mContainer userInfo: infoDict];

	WILDPartContents*	theContents = nil;
	if( [mContainer sharedText] )
		theContents = [[[mCardView card] owningBackground] contentsForPart: mContainer create: YES];
	else
		theContents = [[mCardView card] contentsForPart: mContainer create: YES];
	[theContents setStyledText: [mTextView textStorage]];
	
	[[NSNotificationCenter defaultCenter] postNotificationName: WILDPartDidChangeNotification object: mContainer userInfo: infoDict];
	
	[mContainer updateChangeCount: NSChangeDone];
}


-(void) setDocument: (NSDocument *)document
{
	[super setDocument: document];
	
	NSButton*	btn = [[self window] standardWindowButton: NSWindowDocumentIconButton];
	[btn setImage: [mContainer displayIcon]];
}


-(NSString *)	windowTitleForDocumentDisplayName: (NSString *)displayName
{
	return [NSString stringWithFormat: @"%1$@’s Contents", [mContainer displayName]];
}


-(BOOL)	window: (NSWindow *)window shouldPopUpDocumentPathMenu: (NSMenu *)menu
{
	// Make sure the former top item (pointing to the file) selects the main doc window:
	NSMenuItem*		fileItem = [menu itemAtIndex: 0];
	[fileItem setTarget: [[[[self document] windowControllers] objectAtIndex: 0] window]];
	[fileItem setAction: @selector(makeKeyAndOrderFront:)];
	
	// Now add a new item above that for this window, the script:
	NSMenuItem*		newItem = [menu insertItemWithTitle: [NSString stringWithFormat: @"%1$@’s Contents", [mContainer displayName]]
											action: nil keyEquivalent: @"" atIndex: 0];
	[newItem setImage: [mContainer displayIcon]];
	
	return YES;
}


-(void)		setGlobalStartRect: (NSRect)theBox
{
	mGlobalStartRect = theBox;
}


-(void)		setCardView: (WILDCardView*)inView
{
	ASSIGN(mCardView,inView);
}

@end
