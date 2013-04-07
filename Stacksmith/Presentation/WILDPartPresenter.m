//
//  WILDPartPresenter.m
//  Stacksmith
//
//  Created by Uli Kusterer on 21.08.11.
//  Copyright 2011 Uli Kusterer. All rights reserved.
//

#import "WILDPartPresenter.h"
#import "WILDNotifications.h"
#import "UKHelperMacros.h"


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


-(void)	dealloc
{
	mPartView = UKInvalidPointer;
	
	[super dealloc];
}


-(void)	createSubviews
{
	
}


-(void)	refreshProperties
{
	
}


-(void)	removeSubviews
{
	mPartView = UKInvalidPointer;
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


-(NSRect)	selectionFrame
{
	return [mPartView frame];	// Sensible fallback.
}


-(NSRect)	layoutRectForRect: (NSRect)inRect
{
	return NSInsetRect( inRect, 2, 2 );
}


-(NSRect)	rectForLayoutRect: (NSRect)inLayoutRect
{
	return NSInsetRect(inLayoutRect, -2, -2 );
}

@end
