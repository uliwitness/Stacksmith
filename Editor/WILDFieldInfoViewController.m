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
	NSDictionary	*	infoDict = [NSDictionary dictionaryWithObjectsAndKeys:
										@"autoSelect", WILDAffectedPropertyKey,
										nil];
	[[NSNotificationCenter defaultCenter] postNotificationName: WILDPartWillChangeNotification object: part userInfo: infoDict];

	[part setAutoSelect: [mAutoSelectSwitch state] == NSOnState];
	
	[[NSNotificationCenter defaultCenter] postNotificationName: WILDPartDidChangeNotification object: part];
	[part updateChangeCount: NSChangeDone];
}


-(IBAction)	doMultipleLinesSwitchToggled: (id)sender
{
	NSDictionary	*	infoDict = [NSDictionary dictionaryWithObjectsAndKeys:
										@"multipleLines", WILDAffectedPropertyKey,
										nil];
	[[NSNotificationCenter defaultCenter] postNotificationName: WILDPartWillChangeNotification object: part userInfo: infoDict];

	[part setCanSelectMultipleLines: [mMultipleLinesSwitch state] == NSOnState];
	
	[[NSNotificationCenter defaultCenter] postNotificationName: WILDPartDidChangeNotification object: part userInfo: infoDict];
	[part updateChangeCount: NSChangeDone];
}


-(IBAction)	doSharedTextSwitchToggled: (id)sender
{
	NSDictionary	*	infoDict = [NSDictionary dictionaryWithObjectsAndKeys:
										@"sharedText", WILDAffectedPropertyKey,
										nil];
	[[NSNotificationCenter defaultCenter] postNotificationName: WILDPartWillChangeNotification object: part userInfo: infoDict];

	[part setSharedText: [mSharedTextSwitch state] == NSOnState];
	
	[[NSNotificationCenter defaultCenter] postNotificationName: WILDPartDidChangeNotification object: part userInfo: infoDict];
	[part updateChangeCount: NSChangeDone];
}


-(IBAction)	doLockTextSwitchToggled: (id)sender
{
	NSDictionary	*	infoDict = [NSDictionary dictionaryWithObjectsAndKeys:
										@"lockText", WILDAffectedPropertyKey,
										nil];
	[[NSNotificationCenter defaultCenter] postNotificationName: WILDPartWillChangeNotification object: part userInfo: infoDict];

	[part setLockText: [mLockTextSwitch state] == NSOnState];
	
	[[NSNotificationCenter defaultCenter] postNotificationName: WILDPartDidChangeNotification object: part userInfo: infoDict];
	[part updateChangeCount: NSChangeDone];
}


-(IBAction)	doDontWrapSwitchToggled: (id)sender
{
	NSDictionary	*	infoDict = [NSDictionary dictionaryWithObjectsAndKeys:
										@"dontWrap", WILDAffectedPropertyKey,
										nil];
	[[NSNotificationCenter defaultCenter] postNotificationName: WILDPartWillChangeNotification object: part userInfo: infoDict];

	[part setDontWrap: [mDontWrapSwitch state] == NSOnState];
	
	[[NSNotificationCenter defaultCenter] postNotificationName: WILDPartDidChangeNotification object: part userInfo: infoDict];
	[part updateChangeCount: NSChangeDone];
}


-(IBAction) doDontSearchSwitchToggled: (id)sender
{
	NSDictionary	*	infoDict = [NSDictionary dictionaryWithObjectsAndKeys:
										@"dontSearch", WILDAffectedPropertyKey,
										nil];
	[[NSNotificationCenter defaultCenter] postNotificationName: WILDPartWillChangeNotification object: part userInfo: infoDict];

	[part setDontSearch: [mDontSearchSwitch state] == NSOnState];
	
	[[NSNotificationCenter defaultCenter] postNotificationName: WILDPartDidChangeNotification object: part userInfo: infoDict];
	[part updateChangeCount: NSChangeDone];
}


-(IBAction)	doHorizontalScrollerSwitchToggled: (id)sender
{
	NSDictionary	*	infoDict = [NSDictionary dictionaryWithObjectsAndKeys:
										@"horizontalScroller", WILDAffectedPropertyKey,
										nil];
	[[NSNotificationCenter defaultCenter] postNotificationName: WILDPartWillChangeNotification object: part userInfo: infoDict];

	[part setHasHorizontalScroller: [mHorizontalScrollerSwitch state] == NSOnState];
	
	[[NSNotificationCenter defaultCenter] postNotificationName: WILDPartDidChangeNotification object: part userInfo: infoDict];
	[part updateChangeCount: NSChangeDone];
}


-(IBAction)	doVerticalScrollerSwitchToggled: (id)sender
{
	NSDictionary	*	infoDict = [NSDictionary dictionaryWithObjectsAndKeys:
										@"verticalScroller", WILDAffectedPropertyKey,
										nil];
	[[NSNotificationCenter defaultCenter] postNotificationName: WILDPartWillChangeNotification object: part userInfo: infoDict];

	[part setHasVerticalScroller: [mVerticalScrollerSwitch state] == NSOnState];
	
	[[NSNotificationCenter defaultCenter] postNotificationName: WILDPartDidChangeNotification object: part userInfo: infoDict];
	[part updateChangeCount: NSChangeDone];
}


-(IBAction) doStylePopUpChanged:(id)sender
{
	NSDictionary	*	infoDict = [NSDictionary dictionaryWithObjectsAndKeys:
										@"style", WILDAffectedPropertyKey,
										nil];
	[[NSNotificationCenter defaultCenter] postNotificationName: WILDPartWillChangeNotification object: part userInfo: infoDict];

	[part setStyle: [sStylesInMenuOrder objectAtIndex: [mStylePopUp indexOfSelectedItem]]];
	
	[[NSNotificationCenter defaultCenter] postNotificationName: WILDPartDidChangeNotification object: part userInfo: infoDict];
	[part updateChangeCount: NSChangeDone];
}

@end
