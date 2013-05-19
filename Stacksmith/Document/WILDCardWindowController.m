//
//  WILDCardWindowController.m
//  Stacksmith
//
//  Created by Uli Kusterer on 18.04.10.
//  Copyright 2010 The Void Software. All rights reserved.
//

#import "WILDCardWindowController.h"
#import "WILDDocument.h"
#import "WILDStack.h"
#import "WILDCard.h"
#import "WILDXMLUtils.h"
#import "WILDCardViewController.h"
#import "WILDCardView.h"
#import "NSFileHandle+UKReadLinewise.h"
#import "UKProgressPanelController.h"
#import "NSView+SizeWindowForViewSize.h"
#import "NSWindow+centerHorizontallyAndVertically.h"
#import <Quartz/Quartz.h>


@implementation WILDCardWindowController

- (id)initWithStack: (WILDStack*)inStack
{
    self = [super initWithWindowNibName: NSStringFromClass([self class])];
    if( self )
	{
		[self setShouldCascadeWindows: NO];
		
		mStack = inStack;
    }
    return self;
}


-(void)	dealloc
{
	mCardViewController = nil;	// It's an outlet now.
	mStack = nil;
	
	[super dealloc];
}


-(void)	awakeFromNib
{
	// Make sure window fits the cards:
	NSSize		cardSize = [mStack cardSize];
	if( cardSize.width == 0 || cardSize.height == 0 )
		cardSize = NSMakeSize( 512, 342 );
	[mView sizeWindowForViewSize: cardSize];
	[self.window centerHorizontallyAndVertically];
	
	[mCardViewController setView: mView];
	if( [[mStack cards] count] > 0 )
		[mCardViewController loadCard: [[mStack cards] objectAtIndex: 0]];
		
//	if( [self fileURL] )
//	{
//		NSString*	iconPath = [[[self fileURL] path] stringByAppendingPathComponent: @"Icon\r"];
//		if( ![[NSFileManager defaultManager] fileExistsAtPath: iconPath] )
//			[self performSelector: @selector(generatePreview) withObject: nil afterDelay: 0.0];
//	}
	
	NSButton	*	fsButton = [self.window standardWindowButton: NSWindowFullScreenButton];
	NSRect			theBox;
	NSView		*	windowWidgetSuperview = [fsButton superview];
	if( !fsButton )
		windowWidgetSuperview = [[self.window standardWindowButton: NSWindowCloseButton] superview];
	theBox = [windowWidgetSuperview bounds];
	theBox.origin.y = NSMaxY(theBox) -22;
	theBox.size.height = 22;
	if( fsButton )
		theBox.size.width = fsButton.frame.origin.x -4;
	NSButton	*	editButton = [[NSButton alloc] initWithFrame: theBox];
	[[editButton cell] setControlSize: NSMiniControlSize];
	[editButton setTitle: @"Edit"];
	[editButton setBezelStyle: NSRoundRectBezelStyle];
	[editButton setButtonType: NSPushOnPushOffButton];
	[editButton setImagePosition: NSNoImage];
	[editButton sizeToFit];
	[editButton setKeyEquivalentModifierMask: NSCommandKeyMask | NSControlKeyMask];
	[editButton setKeyEquivalent: @"\t"];
	[editButton setAction: @selector(toggleEditBrowseTool:)];
	theBox.origin.x = NSMaxX(theBox) - editButton.frame.size.width -6;
	theBox.size.width = editButton.frame.size.width +8;
	theBox.origin.x -= 8;
	[editButton setFrame: theBox];
	[windowWidgetSuperview addSubview: editButton];
	[editButton setAutoresizingMask: NSViewMinYMargin | NSViewMaxXMargin];
	[windowWidgetSuperview setNeedsLayout: YES];
}


-(WILDStack*)	stack
{
	return mStack;
}


-(id<WILDVisibleObject>)	visibleObjectForWILDObject: (id)inObjectToFind
{
	if( inObjectToFind == [mCardViewController currentCard]
		|| inObjectToFind == [[mCardViewController currentCard] owningBackground] )
		return self;	// Window is also visible object for card & bg.
	
	return [mCardViewController visibleObjectForWILDObject: inObjectToFind];
}


-(NSRect)	frameInScreenCoordinates
{
	return [[self window] frame];
}


-(void)	goToCard: (WILDCard*)inCard
{
	[mCardViewController loadCard: inCard];
}


-(WILDCard*)	currentCard
{
	return [mCardViewController currentCard];
}


-(void)	windowWillClose: (NSNotification*)notification
{
	[mCardViewController loadCard: nil];
}


-(void)	windowDidResize: (NSNotification*)notification
{
	NSWindow	*	wd = self.window;
	[mStack setCardSize: [wd contentRectForFrameRect: wd.frame].size];
}


-(void)	setTransitionType: (NSString*)inType subtype: (NSString*)inSubtype
{
	[mCardViewController setTransitionType: inType subtype: inSubtype];
}

@end
