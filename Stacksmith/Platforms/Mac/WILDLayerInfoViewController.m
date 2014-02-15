//
//  WILDLayerInfoViewController.m
//  Stacksmith
//
//  Created by Uli Kusterer on 18.03.11.
//  Copyright 2011 Uli Kusterer. All rights reserved.
//

#import "WILDLayerInfoViewController.h"
#import "WILDScriptEditorWindowController.h"
#import "CLayer.h"
#import "UKHelperMacros.h"
#import "WILDUserPropertyEditorController.h"


using namespace Carlson;


@interface WILDLayerInfoViewController () <NSTextFieldDelegate>

@end


@implementation WILDLayerInfoViewController

@synthesize layer = mLayer;

@synthesize nameField = mNameField;
@synthesize numberField = mNumberField;
@synthesize IDField = mIDField;
@synthesize fieldCountField = mFieldCountField;
@synthesize buttonCountField = mButtonCountField;
@synthesize editScriptButton = mEditScriptButton;
@synthesize dontSearchSwitch = mDontSearchSwitch;
@synthesize cantDeleteSwitch = mCantDeleteSwitch;
@synthesize userPropertyEditButton = mUserPropertyEditButton;


-(id)	initWithLayer: (CLayer*)inCard
{
	if(( self = [super initWithNibName: NSStringFromClass([self class]) bundle: nil] ))
	{
		mLayer = inCard->Retain();
	}
	
	return self;
}

-(void)	dealloc
{
	mLayer->Release();
	
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
	
	[mNameField setStringValue: [NSString stringWithUTF8String: mLayer->GetName().c_str()]];
	[mCantDeleteSwitch setState: mLayer->GetCantDelete() ? NSOnState : NSOffState];
	[mDontSearchSwitch setState: mLayer->GetDontSearch() ? NSOnState : NSOffState];
		
	unsigned long	numFields = mLayer->GetPartCountOfType( CPart::GetPartCreatorForType("field") );
	[mFieldCountField setStringValue: [NSString stringWithFormat: @"Contains %ld card fields", numFields]];

	unsigned long	numButtons = mLayer->GetPartCountOfType( CPart::GetPartCreatorForType("button") );
	[mButtonCountField setStringValue: [NSString stringWithFormat: @"Contains %ld card buttons", numButtons]];
}


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


-(IBAction)	doUserPropertyEditButton: (id)sender
{
	NSRect		box = [mUserPropertyEditButton convertRect: [mUserPropertyEditButton bounds] toView: nil];
	NSRect		wFrame = [[self.view window] frame];
	box = NSOffsetRect(box, wFrame.origin.x, wFrame.origin.y );
	WILDUserPropertyEditorWindowController*	se = [[[WILDUserPropertyEditorWindowController alloc] initWithPropertyContainer: mLayer] autorelease];
	[se setGlobalStartRect: box];
	[[mLayer.stack document] addWindowController: se];
	[se showWindow: self];
}


-(IBAction)	doCantDeleteSwitchChanged: (id)sender
{
	[[NSNotificationCenter defaultCenter] postNotificationName: WILDLayerWillChangeNotification object: mLayer userInfo: [NSDictionary dictionaryWithObjectsAndKeys:
									PROPERTY(cantDelete), WILDAffectedPropertyKey,
									nil]];

	[mLayer setCantDelete: [mDontSearchSwitch state] == NSOnState];
	
	[[NSNotificationCenter defaultCenter] postNotificationName: WILDLayerWillChangeNotification object: mLayer userInfo: [NSDictionary dictionaryWithObjectsAndKeys:
									PROPERTY(cantDelete), WILDAffectedPropertyKey,
									nil]];
	[mLayer updateChangeCount: NSChangeDone];
}


-(IBAction)	doDontSearchSwitchChanged: (id)sender
{
	[[NSNotificationCenter defaultCenter] postNotificationName: WILDLayerWillChangeNotification object: mLayer userInfo: [NSDictionary dictionaryWithObjectsAndKeys:
									PROPERTY(dontSearch), WILDAffectedPropertyKey,
									nil]];

	[mLayer setDontSearch: [mDontSearchSwitch state] == NSOnState];
	
	[[NSNotificationCenter defaultCenter] postNotificationName: WILDLayerWillChangeNotification object: mLayer userInfo: [NSDictionary dictionaryWithObjectsAndKeys:
									PROPERTY(dontSearch), WILDAffectedPropertyKey,
									nil]];
	[mLayer updateChangeCount: NSChangeDone];
}


-(void)	controlTextDidChange: (NSNotification *)notif
{
	if( [notif object] == mNameField )
	{
		[[NSNotificationCenter defaultCenter] postNotificationName: WILDLayerWillChangeNotification object: mLayer userInfo: [NSDictionary dictionaryWithObjectsAndKeys:
										PROPERTY(name), WILDAffectedPropertyKey,
										nil]];

		[mLayer setName: [mNameField stringValue]];
			
		[[NSNotificationCenter defaultCenter] postNotificationName: WILDLayerWillChangeNotification object: mLayer userInfo: [NSDictionary dictionaryWithObjectsAndKeys:
										PROPERTY(name), WILDAffectedPropertyKey,
										nil]];
		[mLayer updateChangeCount: NSChangeDone];
	}
}

@end
