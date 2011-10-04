//
//  WILDPartPresenter.m
//  Stacksmith
//
//  Created by Uli Kusterer on 21.08.11.
//  Copyright 2011 Uli Kusterer. All rights reserved.
//

#import "WILDPartPresenter.h"
#import "WILDNotifications.h"


@implementation WILDPartPresenter


-(id)	initWithPartView: (WILDPartView*)inPartView
{
    self = [super init];
    if( self )
	{
		mPartView = inPartView;
    }
    
    return self;
}


-(void)	createSubviewsForPartView: (WILDPartView*)inPartView
{
	
}


-(void)	refreshProperties
{
	
}


-(void)	removeSubviewsFromPartView: (WILDPartView*)inPartView
{
	
}


-(void)	partWillChange: (NSNotification*)notif
{
	WILDPart	*	thePart = [notif object];
	NSString	*	propName = [[notif userInfo] objectForKey: WILDAffectedPropertyKey];
	SEL				theAction = NSSelectorFromString( [propName stringByAppendingString: @"PropertyWillChangeOfPart:"] );
	if( [self respondsToSelector: theAction] )
		[self performSelector: theAction withObject: thePart];
}


-(void)	partDidChange: (NSNotification*)notif
{
	WILDPart	*	thePart = [notif object];
	NSString	*	propName = [[notif userInfo] objectForKey: WILDAffectedPropertyKey];
	SEL				theAction = NSSelectorFromString( [propName stringByAppendingString: @"PropertyDidChangeOfPart:"] );
	if( [self respondsToSelector: theAction] )
		[self performSelector: theAction withObject: thePart];
	else
		[self refreshProperties];
}

@end
