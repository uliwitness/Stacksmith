//
//  WILDButtonInfoViewController.m
//  Stacksmith
//
//  Created by Uli Kusterer on 31.07.11.
//  Copyright 2011 Uli Kusterer. All rights reserved.
//

#import "WILDButtonInfoViewController.h"
#import "WILDNotifications.h"
#import "WILDIconPickerViewController.h"
#import "WILDPart.h"
#import "UKHelperMacros.h"


static 	NSArray*	sStylesInMenuOrder = nil;


@implementation WILDButtonInfoViewController

@synthesize iconButton = mIconButton;
@synthesize stylePopUp = mStylePopUp;
@synthesize familyPopUp = mFamilyPopUp;
@synthesize showNameSwitch = mShowNameSwitch;
@synthesize autoHighlightSwitch = mAutoHighlightSwitch;
@synthesize highlightedSwitch = mHighlightedSwitch;
@synthesize sharedHighlightSwitch = mSharedHighlightSwitch;

-(void)	dealloc
{
	[mIconPopover close];
	DESTROY_DEALLOC(mIconPopover);
	DESTROY_DEALLOC(mStylePopUp);
	DESTROY_DEALLOC(mFamilyPopUp);
	DESTROY_DEALLOC(mShowNameSwitch);
	DESTROY_DEALLOC(mAutoHighlightSwitch);
	DESTROY_DEALLOC(mHighlightedSwitch);
	DESTROY_DEALLOC(mSharedHighlightSwitch);
	DESTROY_DEALLOC(mIconButton);
	
	[super dealloc];
}


-(void)	loadView
{
	[super loadView];
	
	if( !sStylesInMenuOrder )
		sStylesInMenuOrder = [[NSArray alloc] initWithObjects:
													@"rectangle",
													@"roundrect",
													@"oval",
													@"standard",
													@"default",
													@"checkbox",
													@"radiobutton",
													@"popup",
													nil];
	
	
	[mStylePopUp selectItemAtIndex: [sStylesInMenuOrder indexOfObject: [part partStyle]]];
	[mFamilyPopUp selectItemAtIndex: [part family]];

	[mShowNameSwitch setState: [part showName]];
	[mAutoHighlightSwitch setState: [part autoHighlight]];
	[mHighlightedSwitch setState: [part highlighted]];
	[mSharedHighlightSwitch setState: [part sharedHighlight]];
	[self.bevelSlider setDoubleValue: [part bevel]];
	[self.bevelAngleSlider setDoubleValue: [part bevelAngle]];
}


-(IBAction)	doShowNameSwitchToggled:(id)sender
{
	NSDictionary	*	infoDict = [NSDictionary dictionaryWithObjectsAndKeys:
										@"showName", WILDAffectedPropertyKey,
										nil];
	[[NSNotificationCenter defaultCenter] postNotificationName: WILDPartWillChangeNotification object: part userInfo: infoDict];

	[part setShowName: [mShowNameSwitch state] == NSOnState];
	
	[[NSNotificationCenter defaultCenter] postNotificationName: WILDPartDidChangeNotification object: part userInfo: infoDict];
	[part updateChangeCount: NSChangeDone];
}


-(IBAction)	doSharedHighlightSwitchToggled: (id)sender
{
	NSDictionary	*	infoDict = [NSDictionary dictionaryWithObjectsAndKeys:
										@"sharedHighlight", WILDAffectedPropertyKey,
										nil];
	[[NSNotificationCenter defaultCenter] postNotificationName: WILDPartWillChangeNotification object: part userInfo: infoDict];

	[part setSharedHighlight: [mSharedHighlightSwitch state] == NSOnState];
	
	[[NSNotificationCenter defaultCenter] postNotificationName: WILDPartDidChangeNotification object: part userInfo: infoDict];
	[part updateChangeCount: NSChangeDone];
}


-(IBAction)	doHighlightedSwitchToggled:(id)sender
{
	NSDictionary	*	infoDict = [NSDictionary dictionaryWithObjectsAndKeys:
										@"highlighted", WILDAffectedPropertyKey,
										nil];
	[[NSNotificationCenter defaultCenter] postNotificationName: WILDPartWillChangeNotification object: part userInfo: infoDict];

	[part setHighlighted: [mHighlightedSwitch state] == NSOnState];
	
	[[NSNotificationCenter defaultCenter] postNotificationName: WILDPartDidChangeNotification object: part userInfo: infoDict];
	[part updateChangeCount: NSChangeDone];
}


-(IBAction)	doAutoHighlightSwitchToggled:(id)sender
{
	NSDictionary	*	infoDict = [NSDictionary dictionaryWithObjectsAndKeys:
										@"autoHighlight", WILDAffectedPropertyKey,
										nil];
	[[NSNotificationCenter defaultCenter] postNotificationName: WILDPartWillChangeNotification object: part userInfo: infoDict];

	[part setAutoHighlight: [mAutoHighlightSwitch state] == NSOnState];
	
	[[NSNotificationCenter defaultCenter] postNotificationName: WILDPartDidChangeNotification object: part userInfo: infoDict];
	[part updateChangeCount: NSChangeDone];
}


-(IBAction) doFamilyPopUpChanged:(id)sender
{
	NSDictionary	*	infoDict = [NSDictionary dictionaryWithObjectsAndKeys:
										@"family", WILDAffectedPropertyKey,
										nil];
	[[NSNotificationCenter defaultCenter] postNotificationName: WILDPartWillChangeNotification object: part userInfo: infoDict];

	[part setFamily: [mFamilyPopUp indexOfSelectedItem]];
	
	[[NSNotificationCenter defaultCenter] postNotificationName: WILDPartDidChangeNotification object: part userInfo: infoDict];
	[part updateChangeCount: NSChangeDone];
}


-(IBAction) doStylePopUpChanged:(id)sender
{
	NSDictionary	*	infoDict = [NSDictionary dictionaryWithObjectsAndKeys:
										PROPERTY(partStyle), WILDAffectedPropertyKey,
										nil];
	[[NSNotificationCenter defaultCenter] postNotificationName: WILDPartWillChangeNotification object: part userInfo: infoDict];

	[part setPartStyle: [sStylesInMenuOrder objectAtIndex: [mStylePopUp indexOfSelectedItem]]];
	
	[[NSNotificationCenter defaultCenter] postNotificationName: WILDPartDidChangeNotification object: part userInfo: infoDict];
	[part updateChangeCount: NSChangeDone];
}


-(IBAction)	doShowIconPicker: (id)sender
{
	[mIconPopover close];
	DESTROY(mIconPopover);
	
	WILDIconPickerViewController	*	iconPickerViewController = [[[WILDIconPickerViewController alloc] initWithPart: part] autorelease];
	
	mIconPopover = [[NSPopover alloc] init];
	[mIconPopover setDelegate: self];
	[mIconPopover setBehavior: NSPopoverBehaviorTransient];
	[mIconPopover setContentViewController: iconPickerViewController];
	[mIconPopover showRelativeToRect: [mIconButton bounds] ofView: mIconButton preferredEdge: NSMaxXEdge];
}

-(IBAction)	doBevelSliderChanged: (id)sender
{
	NSDictionary	*	infoDict = [NSDictionary dictionaryWithObjectsAndKeys:
										PROPERTY(bevelWidth), WILDAffectedPropertyKey,
										nil];
	[[NSNotificationCenter defaultCenter] postNotificationName: WILDPartWillChangeNotification object: part userInfo: infoDict];

	[part setBevel: self.bevelSlider.doubleValue];
	
	[[NSNotificationCenter defaultCenter] postNotificationName: WILDPartDidChangeNotification object: part userInfo: infoDict];
	[part updateChangeCount: NSChangeDone];
}

-(IBAction)	doBevelAngleSliderChanged: (id)sender
{
	NSDictionary	*	infoDict = [NSDictionary dictionaryWithObjectsAndKeys:
										PROPERTY(bevelAngle), WILDAffectedPropertyKey,
										nil];
	[[NSNotificationCenter defaultCenter] postNotificationName: WILDPartWillChangeNotification object: part userInfo: infoDict];

	[part setBevelAngle: self.bevelAngleSlider.doubleValue];
	
	[[NSNotificationCenter defaultCenter] postNotificationName: WILDPartDidChangeNotification object: part userInfo: infoDict];
	[part updateChangeCount: NSChangeDone];
}


-(void)	popoverDidClose: (NSNotification *)notification
{
	DESTROY(mIconPopover);
}

@end
