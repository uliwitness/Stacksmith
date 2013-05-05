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

-(void)	dealloc
{
	DESTROY_DEALLOC(mStylePopUp);
	DESTROY_DEALLOC(mShowNameSwitch);
	
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

@end
