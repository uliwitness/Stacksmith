//
//  WILDLayerInfoViewController.m
//  Stacksmith
//
//  Created by Uli Kusterer on 18.03.11.
//  Copyright 2011 Uli Kusterer. All rights reserved.
//

#import "WILDLayerInfoViewController.h"
#import "WILDScriptEditorWindowController.h"
#import "WILDCardView.h"
#import "WILDLayer.h"
#import "UKHelperMacros.h"
#import "NSWindow+ULIZoomEffect.h"


@implementation WILDLayerInfoViewController

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
	if(( self = [super initWithNibName: NSStringFromClass([self class]) bundle: nil] ))
	{
		mLayer = [inCard retain];
		mCardView = [owningView retain];
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


-(void)	awakeFromNib
{
	[super awakeFromNib];
	
	[mNameField setStringValue: [mLayer name]];
	[mCantDeleteSwitch setState: [mLayer cantDelete] ? NSOnState : NSOffState];
	[mDontSearchSwitch setState: [mLayer dontSearch] ? NSOnState : NSOffState];
		
	unsigned long	numFields = [mLayer numberOfPartsOfType: @"field"];
	[mFieldCountField setStringValue: [NSString stringWithFormat: @"Contains %ld card fields", numFields]];

	unsigned long	numButtons = [mLayer numberOfPartsOfType: @"button"];
	[mButtonCountField setStringValue: [NSString stringWithFormat: @"Contains %ld card buttons", numButtons]];
}


//-(IBAction)	doOKButton: (id)sender
//{
//	[mLayer setName: [mNameField stringValue]];
//	[mLayer setCantDelete: [mCantDeleteSwitch state] == NSOnState];
//	[mLayer setDontSearch: [mDontSearchSwitch state] == NSOnState];
//	
//	NSRect	destRect = [[mCardView visibleObjectForWILDObject: mLayer] frameInScreenCoordinates];
//	[[self window] orderOutWithZoomEffectToRect: destRect];
//	[self close];
//}
//
//
//-(IBAction)	doCancelButton: (id)sender
//{
//	NSRect	destRect = [[mCardView visibleObjectForWILDObject: mLayer] frameInScreenCoordinates];
//	[[self window] orderOutWithZoomEffectToRect: destRect];
//	[self close];
//}


-(IBAction)	doEditScriptButton: (id)sender
{
	NSRect		box = [mEditScriptButton convertRect: [mEditScriptButton bounds] toView: nil];
	NSRect		wFrame = [[self.view window] frame];
	box = NSOffsetRect(box, wFrame.origin.x, wFrame.origin.y );
	WILDScriptEditorWindowController*	se = [[[WILDScriptEditorWindowController alloc] initWithScriptContainer: mLayer] autorelease];
	[se setGlobalStartRect: box];
	[[mLayer.stack document] addWindowController: se];
	[se showWindow: self];
}

@end
