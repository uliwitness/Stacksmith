//
//  WILDGroupInfoViewController.m
//  Stacksmith
//
//  Created by Uli Kusterer on 31.07.11.
//  Copyright 2011 Uli Kusterer. All rights reserved.
//

#import "WILDGroupInfoViewController.h"
#import "WILDNotifications.h"
#import "WILDIconPickerViewController.h"
#import "WILDPart.h"
#import "UKHelperMacros.h"


static 	NSArray*	sStylesInMenuOrder = nil;


@implementation WILDGroupInfoViewController

@synthesize stylePopUp = mStylePopUp;
@synthesize showNameSwitch = mShowNameSwitch;
@synthesize horizontalScrollerSwitch = mHorizontalScrollerSwitch;
@synthesize verticalScrollerSwitch = mVerticalScrollerSwitch;
@synthesize contentWidthField = mContentWidthField;
@synthesize contentHeightField = mContentHeightField;

-(void)	dealloc
{
	DESTROY_DEALLOC(mStylePopUp);
	DESTROY_DEALLOC(mShowNameSwitch);
	DESTROY_DEALLOC(mHorizontalScrollerSwitch);
	DESTROY_DEALLOC(mVerticalScrollerSwitch);
	DESTROY_DEALLOC(mContentWidthField);
	DESTROY_DEALLOC(mContentHeightField);
	
	[super dealloc];
}


-(void)	loadView
{
	[super loadView];
	
	if( !sStylesInMenuOrder )
		sStylesInMenuOrder = [[NSArray alloc] initWithObjects:
													@"rectangle",
													@"standard",
													nil];
	
	
	[mStylePopUp selectItemAtIndex: [sStylesInMenuOrder indexOfObject: [part partStyle]]];

	[mShowNameSwitch setState: [part showName]];
	[mHorizontalScrollerSwitch setState: [part hasHorizontalScroller]];
	[mVerticalScrollerSwitch setState: [part hasVerticalScroller]];
	NSSize	contentSize = part.contentSize;
	[mContentWidthField setIntegerValue: contentSize.width];
	[mContentHeightField setIntegerValue: contentSize.height];
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
										PROPERTY(partStyle), WILDAffectedPropertyKey,
										nil];
	[[NSNotificationCenter defaultCenter] postNotificationName: WILDPartWillChangeNotification object: part userInfo: infoDict];

	[part setPartStyle: [sStylesInMenuOrder objectAtIndex: [mStylePopUp indexOfSelectedItem]]];
	
	[[NSNotificationCenter defaultCenter] postNotificationName: WILDPartDidChangeNotification object: part userInfo: infoDict];
	[part updateChangeCount: NSChangeDone];
}


-(void)	controlTextDidChange: (NSNotification *)notif
{
	if( notif.object == mContentWidthField || notif.object == mContentHeightField )
	{
		NSDictionary	*	infoDict = [NSDictionary dictionaryWithObjectsAndKeys:
											PROPERTY(contentSize), WILDAffectedPropertyKey,
											nil];
		[[NSNotificationCenter defaultCenter] postNotificationName: WILDPartWillChangeNotification object: part userInfo: infoDict];

		NSSize		contentSize = {};
		contentSize.width = [mContentWidthField integerValue];
		contentSize.height = [mContentHeightField integerValue];
		part.contentSize = contentSize;
		
		[[NSNotificationCenter defaultCenter] postNotificationName: WILDPartDidChangeNotification object: part userInfo: infoDict];
		[part updateChangeCount: NSChangeDone];
	}
}

@end
