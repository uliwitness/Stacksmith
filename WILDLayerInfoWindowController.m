//
//  WILDLayerInfoWindowController.m
//  Stacksmith
//
//  Created by Uli Kusterer on 18.03.11.
//  Copyright 2011 Uli Kusterer. All rights reserved.
//

#import "WILDLayerInfoWindowController.h"
#import "WILDScriptEditorWindowController.h"
#import "WILDCardView.h"


@implementation WILDLayerInfoWindowController

@synthesize cardView = mCardView;
@synthesize layer = mLayer;

@synthesize nameField = mNameField;
@synthesize numberField = mNumberField;
@synthesize IDField = mIDField;
@synthesize fieldCountField = mFieldCountField;
@synthesize buttonCountField = mButtonCountField;
@synthesize editScriptButton = mEditScriptButton;
@synthesize dontSearchSwitch = mDontSearchSwitch;
@synthesize cantDeleteSwitch = mCantDeleteSwitch;

-(id)	initWithLayer: (WILDLayer*)inCard ofCardView: (WILDCardView*)owningView
{
	if(( self = [super initWithWindowNibName: NSStringFromClass([self class])] ))
	{
		mLayer = [inCard retain];
		mCardView = [owningView retain];
		
		[self setShouldCascadeWindows: NO];
	}
	
	return self;
}

-(void)	dealloc
{
	DESTROY_DEALLOC( mCardView );
	DESTROY_DEALLOC( mLayer );
	
	DESTROY_DEALLOC( mEditScriptButton );
	DESTROY_DEALLOC( mDontSearchSwitch );
	DESTROY_DEALLOC( mCantDeleteSwitch );
	DESTROY_DEALLOC( mNameField );
	DESTROY_DEALLOC( mNumberField );
	DESTROY_DEALLOC( mIDField );
	DESTROY_DEALLOC( mFieldCountField );
	DESTROY_DEALLOC( mButtonCountField );
	
	[super dealloc];
}


-(void)	windowDidLoad
{
	[super windowDidLoad];
	
	[mNameField setStringValue: [mLayer name]];
	[mCantDeleteSwitch setState: [mLayer cantDelete] ? NSOnState : NSOffState];
	[mDontSearchSwitch setState: [mLayer dontSearch] ? NSOnState : NSOffState];
		
	unsigned long	numFields = [mLayer numberOfPartsOfType: @"field"];
	[mFieldCountField setStringValue: [NSString stringWithFormat: @"Contains %ld card fields", numFields]];

	unsigned long	numButtons = [mLayer numberOfPartsOfType: @"button"];
	[mButtonCountField setStringValue: [NSString stringWithFormat: @"Contains %ld card buttons", numButtons]];
}


-(IBAction)	showWindow: (id)sender
{
	NSRect	sourceRect = [[mCardView visibleObjectForWILDObject: mLayer] frameInScreenCoordinates];
	
	[[self window] makeKeyAndOrderFrontWithZoomEffectFromRect: sourceRect];
}


-(IBAction)	doOKButton: (id)sender
{
	[mLayer setName: [mNameField stringValue]];
	[mLayer setCantDelete: [mCantDeleteSwitch state] == NSOnState];
	[mLayer setDontSearch: [mDontSearchSwitch state] == NSOnState];
	
	NSRect	destRect = [[mCardView visibleObjectForWILDObject: mLayer] frameInScreenCoordinates];
	[[self window] orderOutWithZoomEffectToRect: destRect];
	[self close];
}


-(IBAction)	doCancelButton: (id)sender
{
	NSRect	destRect = [[mCardView visibleObjectForWILDObject: mLayer] frameInScreenCoordinates];
	[[self window] orderOutWithZoomEffectToRect: destRect];
	[self close];
}


-(IBAction)	doEditScriptButton: (id)sender
{
	NSRect		box = [mEditScriptButton convertRect: [mEditScriptButton bounds] toView: nil];
	NSRect		wFrame = [[self window] frame];
	box = NSOffsetRect(box, wFrame.origin.x, wFrame.origin.y );
	WILDScriptEditorWindowController*	se = [[[WILDScriptEditorWindowController alloc] initWithScriptContainer: mLayer] autorelease];
	[se setGlobalStartRect: box];
	[[[[self window] windowController] document] addWindowController: se];
	[se showWindow: self];
}


-(NSString *)	windowTitleForDocumentDisplayName: (NSString *)displayName
{
	return [NSString stringWithFormat: @"%@ Info", [mLayer displayName]];
}


-(BOOL)	window: (NSWindow *)window shouldPopUpDocumentPathMenu: (NSMenu *)menu
{
	// Make sure the former top item (pointing to the file) selects the main doc window:
	NSMenuItem*		fileItem = [menu itemAtIndex: 0];
	[fileItem setTarget: [[[[self document] windowControllers] objectAtIndex: 0] window]];
	[fileItem setAction: @selector(makeKeyAndOrderFront:)];
	
	// Now add a new item above that for this window, the script:
	NSMenuItem*		newItem = [menu insertItemWithTitle: [NSString stringWithFormat: @"%1$@ Info", [mLayer displayName]]
											action: nil keyEquivalent: @"" atIndex: 0];
	[newItem setImage: [mLayer displayIcon]];
	
	return YES;
}


-(void) setDocument: (NSDocument *)document
{
	[super setDocument: document];
	
	NSButton*	btn = [[self window] standardWindowButton: NSWindowDocumentIconButton];
	[btn setImage: [mLayer displayIcon]];
}

@end
