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
	DESTROY(mIconPopover);
	DESTROY(mStylePopUp);
	DESTROY(mFamilyPopUp);
	DESTROY(mShowNameSwitch);
	DESTROY(mAutoHighlightSwitch);
	DESTROY(mHighlightedSwitch);
	DESTROY(mSharedHighlightSwitch);
	DESTROY(mIconButton);
	
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
	
	
	[mStylePopUp selectItemAtIndex: [sStylesInMenuOrder indexOfObject: [part style]]];
	[mFamilyPopUp selectItemAtIndex: [part family]];

	[mShowNameSwitch setState: [part showName]];
	[mAutoHighlightSwitch setState: [part autoHighlight]];
	[mHighlightedSwitch setState: [part highlighted]];
	[mSharedHighlightSwitch setState: [part sharedHighlight]];
}


-(IBAction)	doShowNameSwitchToggled:(id)sender
{
	[[NSNotificationCenter defaultCenter] postNotificationName: WILDPartWillChangeNotification object: part];

	[part setShowName: [mShowNameSwitch state] == NSOnState];
	
	[[NSNotificationCenter defaultCenter] postNotificationName: WILDPartDidChangeNotification object: part];
	[part updateChangeCount: NSChangeDone];
}


-(IBAction)	doSharedHighlightSwitchToggled: (id)sender
{
	[[NSNotificationCenter defaultCenter] postNotificationName: WILDPartWillChangeNotification object: part];

	[part setSharedHighlight: [mSharedHighlightSwitch state] == NSOnState];
	
	[[NSNotificationCenter defaultCenter] postNotificationName: WILDPartDidChangeNotification object: part];
	[part updateChangeCount: NSChangeDone];
}


-(IBAction)	doHighlightedSwitchToggled:(id)sender
{
	[[NSNotificationCenter defaultCenter] postNotificationName: WILDPartWillChangeNotification object: part];

	[part setHighlighted: [mHighlightedSwitch state] == NSOnState];
	
	[[NSNotificationCenter defaultCenter] postNotificationName: WILDPartDidChangeNotification object: part];
	[part updateChangeCount: NSChangeDone];
}


-(IBAction)	doAutoHighlightSwitchToggled:(id)sender
{
	[[NSNotificationCenter defaultCenter] postNotificationName: WILDPartWillChangeNotification object: part];

	[part setAutoHighlight: [mAutoHighlightSwitch state] == NSOnState];
	
	[[NSNotificationCenter defaultCenter] postNotificationName: WILDPartDidChangeNotification object: part];
	[part updateChangeCount: NSChangeDone];
}


-(IBAction) doFamilyPopUpChanged:(id)sender
{
	[[NSNotificationCenter defaultCenter] postNotificationName: WILDPartWillChangeNotification object: part];

	[part setFamily: [mFamilyPopUp indexOfSelectedItem]];
	
	[[NSNotificationCenter defaultCenter] postNotificationName: WILDPartDidChangeNotification object: part];
	[part updateChangeCount: NSChangeDone];
}


-(IBAction) doStylePopUpChanged:(id)sender
{
	[[NSNotificationCenter defaultCenter] postNotificationName: WILDPartWillChangeNotification object: part];

	[part setStyle: [sStylesInMenuOrder objectAtIndex: [mStylePopUp indexOfSelectedItem]]];
	
	[[NSNotificationCenter defaultCenter] postNotificationName: WILDPartDidChangeNotification object: part];
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


-(void)	popoverDidClose: (NSNotification *)notification
{
	DESTROY(mIconPopover);
}

@end
