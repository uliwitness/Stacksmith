//
//  WILDPartPresenter.m
//  Stacksmith
//
//  Created by Uli Kusterer on 21.08.11.
//  Copyright 2011 Uli Kusterer. All rights reserved.
//

#import "WILDPartPresenter.h"
#import "WILDNotifications.h"
#import "WILDPartView.h"
#import "WILDPart.h"
#import "UKHelperMacros.h"
#import "WILDCardView.h"


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


-(void)	setupCursorRectInPartViewWithDefaultCursor: (NSCursor*)currentCursor
{
	[mPartView addCursorRect: [mPartView visibleRect] cursor: currentCursor];
	//UKLog(@"cursor rect for part %@", mPartView.part);
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
	WILDGuidelineView	*	gv = [mPartView enclosingCardView].guidelineView;
	NSRect	theBox = [gv convertRect: [mPartView bounds] fromView: mPartView];
	return [self partRectForPartViewFrame: theBox];
}


-(NSEdgeInsets)	partToViewInsets
{
	return NSEdgeInsetsMake(0, 0, 0, 0);
}


-(NSRect)	partRectForPartViewFrame: (NSRect)inRect
{
	NSEdgeInsets	partToViewInsets = [self partToViewInsets];
	inRect.origin.x -= partToViewInsets.left;
	inRect.origin.y -= partToViewInsets.bottom;
	inRect.size.width += partToViewInsets.left +partToViewInsets.right;
	inRect.size.height += partToViewInsets.top +partToViewInsets.bottom;
	return inRect;
}


-(NSRect)	partViewFrameForPartRect: (NSRect)inLayoutRect
{
	NSEdgeInsets	partToViewInsets = [self partToViewInsets];
	inLayoutRect.origin.x += partToViewInsets.left;
	inLayoutRect.origin.y += partToViewInsets.bottom;
	inLayoutRect.size.width -= partToViewInsets.left +partToViewInsets.right;
	inLayoutRect.size.height -= partToViewInsets.top +partToViewInsets.bottom;
	return inLayoutRect;
}


-(void)		removeSubPartView: (WILDPartView*)inView
{
	[inView removeFromSuperview];
}


-(void)		addSubPartView: (WILDPartView*)inView
{
	[self.contentView addSubview: inView];
}


-(BOOL)	isViewContainer
{
	return NO;
}


-(BOOL)	needsViewContainer
{
	return YES;
}


-(NSView*)	contentView
{
	return mPartView;
}

@end
