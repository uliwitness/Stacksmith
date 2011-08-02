//
//  WILDFieldInfoViewController.m
//  Stacksmith
//
//  Created by Uli Kusterer on 31.07.11.
//  Copyright 2011 Uli Kusterer. All rights reserved.
//

#import "WILDFieldInfoViewController.h"
#import "WILDNotifications.h"
#import "WILDIconPickerViewController.h"


static 	NSArray*	sStylesInMenuOrder = nil;


@implementation WILDFieldInfoViewController

@synthesize stylePopUp = mStylePopUp;
@synthesize lockTextSwitch = mLockTextSwitch;
@synthesize autoSelectSwitch = mAutoSelectSwitch;
@synthesize multipleLinesSwitch = mMultipleLinesSwitch;
@synthesize sharedTextSwitch = mSharedTextSwitch;
@synthesize dontWrapSwitch = mDontWrapSwitch;
@synthesize dontSearchSwitch = mDontSearchSwitch;
@synthesize horizontalScrollerSwitch = mHorizontalScrollerSwitch;
@synthesize verticalScrollerSwitch = mVerticalScrollerSwitch;

-(void)	dealloc
{
	DESTROY(mStylePopUp);
	DESTROY(mLockTextSwitch);
	DESTROY(mAutoSelectSwitch);
	DESTROY(mMultipleLinesSwitch);
	DESTROY(mSharedTextSwitch);
	DESTROY(mDontWrapSwitch);
	DESTROY(mDontSearchSwitch);
	DESTROY(mHorizontalScrollerSwitch);
	DESTROY(mVerticalScrollerSwitch);
	
	[super dealloc];
}


-(void)	loadView
{
	[super loadView];
	
	if( !sStylesInMenuOrder )
		sStylesInMenuOrder = [[NSArray alloc] initWithObjects:
													@"rectangle",
													@"standard",
													@"popup",
													nil];
	
	
	[mStylePopUp selectItemAtIndex: [sStylesInMenuOrder indexOfObject: [part style]]];

	[mLockTextSwitch setState: [part lockText]];
	[mAutoSelectSwitch setState: [part autoSelect]];
	[mMultipleLinesSwitch setState: [part canSelectMultipleLines]];
	[mSharedTextSwitch setState: [part sharedText]];
	[mDontWrapSwitch setState: [part dontWrap]];
	[mDontSearchSwitch setState: [part dontSearch]];
	[mHorizontalScrollerSwitch setState: [part hasHorizontalScroller]];
	[mVerticalScrollerSwitch setState: [part hasVerticalScroller]];
}


-(IBAction)	doAutoSelectSwitchToggled: (id)sender
{
	[[NSNotificationCenter defaultCenter] postNotificationName: WILDPartWillChangeNotification object: part];

	[part setAutoSelect: [mAutoSelectSwitch state] == NSOnState];
	
	[[NSNotificationCenter defaultCenter] postNotificationName: WILDPartDidChangeNotification object: part];
	[part updateChangeCount: NSChangeDone];
}


-(IBAction)	doMultipleLinesSwitchToggled: (id)sender
{
	[[NSNotificationCenter defaultCenter] postNotificationName: WILDPartWillChangeNotification object: part];

	[part setCanSelectMultipleLines: [mMultipleLinesSwitch state] == NSOnState];
	
	[[NSNotificationCenter defaultCenter] postNotificationName: WILDPartDidChangeNotification object: part];
	[part updateChangeCount: NSChangeDone];
}


-(IBAction)	doSharedTextSwitchToggled: (id)sender
{
	[[NSNotificationCenter defaultCenter] postNotificationName: WILDPartWillChangeNotification object: part];

	[part setSharedText: [mSharedTextSwitch state] == NSOnState];
	
	[[NSNotificationCenter defaultCenter] postNotificationName: WILDPartDidChangeNotification object: part];
	[part updateChangeCount: NSChangeDone];
}


-(IBAction)	doLockTextSwitchToggled: (id)sender
{
	[[NSNotificationCenter defaultCenter] postNotificationName: WILDPartWillChangeNotification object: part];

	[part setLockText: [mLockTextSwitch state] == NSOnState];
	
	[[NSNotificationCenter defaultCenter] postNotificationName: WILDPartDidChangeNotification object: part];
	[part updateChangeCount: NSChangeDone];
}


-(IBAction)	doDontWrapSwitchToggled: (id)sender
{
	[[NSNotificationCenter defaultCenter] postNotificationName: WILDPartWillChangeNotification object: part];

	[part setDontWrap: [mDontWrapSwitch state] == NSOnState];
	
	[[NSNotificationCenter defaultCenter] postNotificationName: WILDPartDidChangeNotification object: part];
	[part updateChangeCount: NSChangeDone];
}


-(IBAction) doDontSearchSwitchToggled: (id)sender
{
	[[NSNotificationCenter defaultCenter] postNotificationName: WILDPartWillChangeNotification object: part];

	[part setDontSearch: [mDontSearchSwitch state] == NSOnState];
	
	[[NSNotificationCenter defaultCenter] postNotificationName: WILDPartDidChangeNotification object: part];
	[part updateChangeCount: NSChangeDone];
}


-(IBAction)	doHorizontalScrollerSwitchToggled: (id)sender
{
	[[NSNotificationCenter defaultCenter] postNotificationName: WILDPartWillChangeNotification object: part];

	[part setHasHorizontalScroller: [mHorizontalScrollerSwitch state] == NSOnState];
	
	[[NSNotificationCenter defaultCenter] postNotificationName: WILDPartDidChangeNotification object: part];
	[part updateChangeCount: NSChangeDone];
}


-(IBAction)	doVerticalScrollerSwitchToggled: (id)sender
{
	[[NSNotificationCenter defaultCenter] postNotificationName: WILDPartWillChangeNotification object: part];

	[part setHasVerticalScroller: [mVerticalScrollerSwitch state] == NSOnState];
	
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

@end
