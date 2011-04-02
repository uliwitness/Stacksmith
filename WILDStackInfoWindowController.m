//
//  WILDStackInfoWindowController.m
//  Stacksmith
//
//  Created by Uli Kusterer on 18.03.11.
//  Copyright 2011 Uli Kusterer. All rights reserved.
//

#import "WILDStackInfoWindowController.h"
#import "WILDScriptEditorWindowController.h"
#import "WILDCardView.h"
#import "WILDStack.h"


@implementation WILDStackInfoWindowController

@synthesize cardView = mCardView;
@synthesize stack = mStack;

@synthesize nameField = mNameField;
@synthesize IDField = mIDField;
@synthesize cardCountField = mCardCountField;
@synthesize backgroundCountField = mBackgroundCountField;
@synthesize editScriptButton = mEditScriptButton;
@synthesize widthField = mWidthField;
@synthesize heightField = mHeightField;

-(id)	initWithStack: (WILDStack*)inStack ofCardView: (WILDCardView*)owningView
{
	if(( self = [super initWithWindowNibName: NSStringFromClass([self class])] ))
	{
		mStack = [inStack retain];
		mCardView = [owningView retain];
		
		[self setShouldCascadeWindows: NO];
	}
	
	return self;
}

-(void)	dealloc
{
	DESTROY( mCardView );
	DESTROY( mStack );
	
	DESTROY( mEditScriptButton );
	DESTROY( mNameField );
	DESTROY( mIDField );
	DESTROY( mCardCountField );
	DESTROY( mBackgroundCountField );
	DESTROY( mWidthField );
	DESTROY( mHeightField );
	
	[super dealloc];
}


-(void)	windowDidLoad
{
	[super windowDidLoad];
	
	[mNameField setStringValue: [mStack name]];
	if( [[mStack document] fileName] == nil )
		[mNameField setEnabled: NO];
	
	unsigned long	numCards = [[mStack cards] count];
	[mCardCountField setStringValue: [NSString stringWithFormat: @"Contains %ld cards.", numCards]];

	unsigned long	numBackgrounds = [[mStack backgrounds] count];
	[mBackgroundCountField setStringValue: [NSString stringWithFormat: @"Contains %ld backgrounds.", numBackgrounds]];
	
	[mWidthField setIntValue: [mStack cardSize].width];
	[mHeightField setIntValue: [mStack cardSize].height];
}


-(IBAction)	showWindow: (id)sender
{
	NSRect	sourceRect = [[mCardView visibleObjectForWILDObject: mStack] frameInScreenCoordinates];
	
	[[self window] makeKeyAndOrderFrontWithZoomEffectFromRect: sourceRect];
}


-(IBAction)	doOKButton: (id)sender
{
	if( [[mStack document] fileName] == nil )
		[mStack setName: [mNameField stringValue]];
	
	NSSize	newSize = NSMakeSize( [mWidthField intValue], [mHeightField intValue] );
	[mStack setCardSize: newSize];
	
	[self updateChangeCount: NSChangeDone];

	NSRect	destRect = [[mCardView visibleObjectForWILDObject: mStack] frameInScreenCoordinates];
	[[self window] orderOutWithZoomEffectToRect: destRect];
	[self close];
}


-(IBAction)	doCancelButton: (id)sender
{
	NSRect	destRect = [[mCardView visibleObjectForWILDObject: mStack] frameInScreenCoordinates];
	[[self window] orderOutWithZoomEffectToRect: destRect];
	[self close];
}


-(IBAction)	doEditScriptButton: (id)sender
{
	NSRect		box = [mEditScriptButton convertRect: [mEditScriptButton bounds] toView: nil];
	NSRect		wFrame = [[self window] frame];
	box = NSOffsetRect(box, wFrame.origin.x, wFrame.origin.y );
	WILDScriptEditorWindowController*	se = [[[WILDScriptEditorWindowController alloc] initWithScriptContainer: mStack] autorelease];
	[se setGlobalStartRect: box];
	[[[[self window] windowController] document] addWindowController: se];
	[se showWindow: self];
}


-(NSString *)	windowTitleForDocumentDisplayName: (NSString *)displayName
{
	return [NSString stringWithFormat: @"%@ Info", [mStack displayName]];
}


-(BOOL)	window: (NSWindow *)window shouldPopUpDocumentPathMenu: (NSMenu *)menu
{
	// Make sure the former top item (pointing to the file) selects the main doc window:
	NSMenuItem*		fileItem = [menu itemAtIndex: 0];
	[fileItem setTarget: [[[[self document] windowControllers] objectAtIndex: 0] window]];
	[fileItem setAction: @selector(makeKeyAndOrderFront:)];
	
	// Now add a new item above that for this window, the script:
	NSMenuItem*		newItem = [menu insertItemWithTitle: [NSString stringWithFormat: @"%1$@ Info", [mStack displayName]]
											action: nil keyEquivalent: @"" atIndex: 0];
	[newItem setImage: [mStack displayIcon]];
	
	return YES;
}


-(void) setDocument: (NSDocument *)document
{
	[super setDocument: document];
	
	NSButton*	btn = [[self window] standardWindowButton: NSWindowDocumentIconButton];
	[btn setImage: [mStack displayIcon]];
}

@end
