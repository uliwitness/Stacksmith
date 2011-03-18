//
//  WILDCardInfoWindowController.m
//  Stacksmith
//
//  Created by Uli Kusterer on 18.03.11.
//  Copyright 2011 Uli Kusterer. All rights reserved.
//

#import "WILDCardInfoWindowController.h"
#import "WILDScriptEditorWindowController.h"
#import "WILDCardView.h"


@implementation WILDCardInfoWindowController

@synthesize cardView = mCardView;
@synthesize card = mCard;

@synthesize nameField = mNameField;
@synthesize numberField = mNumberField;
@synthesize IDField = mIDField;
@synthesize fieldCountField = mFieldCountField;
@synthesize buttonCountField = mButtonCountField;
@synthesize editScriptButton = mEditScriptButton;
@synthesize markedSwitch = mMarkedSwitch;
@synthesize dontSearchSwitch = mDontSearchSwitch;
@synthesize cantDeleteSwitch = mCantDeleteSwitch;

-(id)	initWithCard: (WILDCard*)inCard ofCardView: (WILDCardView*)owningView
{
	if(( self = [super initWithWindowNibName: NSStringFromClass([self class])] ))
	{
		mCard = [inCard retain];
		mCardView = [owningView retain];
		
		[self setShouldCascadeWindows: NO];
	}
	
	return self;
}

-(void)	dealloc
{
	DESTROY( mCardView );
	DESTROY( mCard );
	
	DESTROY( mEditScriptButton );
	DESTROY( mMarkedSwitch );
	DESTROY( mDontSearchSwitch );
	DESTROY( mCantDeleteSwitch );
	DESTROY( mNameField );
	DESTROY( mNumberField );
	DESTROY( mIDField );
	DESTROY( mFieldCountField );
	DESTROY( mButtonCountField );
	
	[super dealloc];
}


-(void)	windowDidLoad
{
	[super windowDidLoad];
	
	[mNameField setStringValue: [mCard name]];
	[mCantDeleteSwitch setState: [mCard cantDelete] ? NSOnState : NSOffState];
	[mDontSearchSwitch setState: [mCard dontSearch] ? NSOnState : NSOffState];
	[mIDField setIntegerValue: [mCard cardID]];
}


-(IBAction)	showWindow: (id)sender
{
	NSRect	sourceRect = [[mCardView visibleObjectForWILDObject: mCard] frameInScreenCoordinates];
	
	[[self window] makeKeyAndOrderFrontWithZoomEffectFromRect: sourceRect];
}


-(IBAction)	doOKButton: (id)sender
{
	
	
	NSRect	destRect = [[mCardView visibleObjectForWILDObject: mCard] frameInScreenCoordinates];
	[[self window] orderOutWithZoomEffectToRect: destRect];
	[self close];
}


-(IBAction)	doCancelButton: (id)sender
{
	NSRect	destRect = [[mCardView visibleObjectForWILDObject: mCard] frameInScreenCoordinates];
	[[self window] orderOutWithZoomEffectToRect: destRect];
	[self close];
}


-(IBAction)	doEditScriptButton: (id)sender
{
	NSRect		box = [mEditScriptButton convertRect: [mEditScriptButton bounds] toView: nil];
	NSRect		wFrame = [[self window] frame];
	box = NSOffsetRect(box, wFrame.origin.x, wFrame.origin.y );
	WILDScriptEditorWindowController*	se = [[[WILDScriptEditorWindowController alloc] initWithScriptContainer: mCard] autorelease];
	[se setGlobalStartRect: box];
	[[[[self window] windowController] document] addWindowController: se];
	[se showWindow: self];
}


-(NSString *)	windowTitleForDocumentDisplayName: (NSString *)displayName
{
	return [NSString stringWithFormat: @"%@ Info", [mCard displayName]];
}


-(BOOL)	window: (NSWindow *)window shouldPopUpDocumentPathMenu: (NSMenu *)menu
{
	// Make sure the former top item (pointing to the file) selects the main doc window:
	NSMenuItem*		fileItem = [menu itemAtIndex: 0];
	[fileItem setTarget: [[[[self document] windowControllers] objectAtIndex: 0] window]];
	[fileItem setAction: @selector(makeKeyAndOrderFront:)];
	
	// Now add a new item above that for this window, the script:
	NSMenuItem*		newItem = [menu insertItemWithTitle: [NSString stringWithFormat: @"%1$@ Info", [mCard displayName]]
											action: nil keyEquivalent: @"" atIndex: 0];
	[newItem setImage: [mCard displayIcon]];
	
	return YES;
}


-(void) setDocument: (NSDocument *)document
{
	[super setDocument: document];
	
	NSButton*	btn = [[self window] standardWindowButton: NSWindowDocumentIconButton];
	[btn setImage: [mCard displayIcon]];
}

@end
