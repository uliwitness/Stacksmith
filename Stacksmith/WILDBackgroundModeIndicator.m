//
//  WILDBackgroundModeIndicator.m
//  Propaganda
//
//  Created by Uli Kusterer on 28.02.10.
//  Copyright 2010 The Void Software. All rights reserved.
//

#import "WILDBackgroundModeIndicator.h"
#import "UKHelperMacros.h"


@interface WILDBackgroundModeIndicatorView : NSView
{
	NSTimer*	mAnimationTimer;
	CGFloat		mLineWidth;
	CGFloat		mAnimationDirection;
}

@end


@implementation WILDBackgroundModeIndicatorView

-(void)	dealloc
{
	[mAnimationTimer invalidate];
	DESTROY_DEALLOC(mAnimationTimer);
	
	[super dealloc];
}


-(void)	drawRect: (NSRect)dirtyRect
{
	[[NSColor colorWithCalibratedRed: 0.2 green: 0.2 blue: 1.0 alpha: 0.8] set];
	[NSBezierPath setDefaultLineWidth: mLineWidth];
	[NSBezierPath strokeRect: [self bounds]];
	
	[[NSColor colorWithCalibratedWhite: 0.4 alpha: 0.4] set];
	[NSBezierPath setDefaultLineWidth: 7.0];
	[NSBezierPath strokeRect: [self bounds]];
	[NSBezierPath setDefaultLineWidth: 1.0];
}


-(void)	viewWillMoveToSuperview: (NSView*)theView
{
	[mAnimationTimer invalidate];
	DESTROY(mAnimationTimer);
	
	if( theView )
		mAnimationTimer = [[NSTimer scheduledTimerWithTimeInterval: 0.05 target: self selector: @selector(doAnimation:) userInfo: nil repeats: YES] retain];
	
	[super viewWillMoveToSuperview: theView];
}


-(void)	doAnimation: (NSTimer*)sender
{
	mLineWidth += mAnimationDirection;
	
	if( mLineWidth > 6.0 || mAnimationDirection == 0 )
	{
		mAnimationDirection = -0.5;
		mLineWidth = 6.0;
	}
	else if( mLineWidth < 0 )
	{
		mAnimationDirection = 0.5;
		mLineWidth = 0;
	}
	
	[self setNeedsDisplay: YES];
}

@end




static NSPanel*	sMenuBarOverlayWindow = nil;


@implementation WILDBackgroundModeIndicator

+(void)	showOnWindow: (NSWindow*)inWindow
{
	if( !sMenuBarOverlayWindow )
	{
		NSRect		mbarBox = [[[NSScreen screens] objectAtIndex: 0] frame];
		mbarBox.origin.y = NSMaxY(mbarBox) -[[NSApp mainMenu] menuBarHeight];
		mbarBox.size.height = [[NSApp mainMenu] menuBarHeight];
		if( inWindow )
			mbarBox = [inWindow contentRectForFrameRect: inWindow.frame];
		sMenuBarOverlayWindow = [[NSPanel alloc] initWithContentRect: mbarBox
									styleMask: NSBorderlessWindowMask
									backing: NSBackingStoreBuffered defer: YES];
		[sMenuBarOverlayWindow setLevel: NSMainMenuWindowLevel +1];
		[sMenuBarOverlayWindow setBackgroundColor: [NSColor clearColor]];
		[sMenuBarOverlayWindow setHasShadow: NO];
		[sMenuBarOverlayWindow setOpaque: NO];
		[sMenuBarOverlayWindow setHidesOnDeactivate: YES];
		[sMenuBarOverlayWindow setIgnoresMouseEvents: YES];
		
		WILDBackgroundModeIndicatorView*	vw = [[[WILDBackgroundModeIndicatorView alloc] initWithFrame: [[sMenuBarOverlayWindow contentView] bounds]] autorelease];
		[[sMenuBarOverlayWindow contentView] addSubview: vw];
		[inWindow addChildWindow: sMenuBarOverlayWindow ordered: NSWindowAbove];
	}
	else
	{
		NSRect		mbarBox = [[[NSScreen screens] objectAtIndex: 0] frame];
		mbarBox.origin.y = NSMaxY(mbarBox) -[[NSApp mainMenu] menuBarHeight];
		mbarBox.size.height = [[NSApp mainMenu] menuBarHeight];
		[sMenuBarOverlayWindow.parentWindow removeChildWindow: sMenuBarOverlayWindow];
		if( inWindow )
			mbarBox = [inWindow contentRectForFrameRect: inWindow.frame];
		[sMenuBarOverlayWindow setFrame: mbarBox display: YES];
		[inWindow addChildWindow: sMenuBarOverlayWindow ordered: NSWindowAbove];
	}
}


+(void)	hide
{
	[sMenuBarOverlayWindow.parentWindow removeChildWindow: sMenuBarOverlayWindow];
	[sMenuBarOverlayWindow close];
	[sMenuBarOverlayWindow release];
	sMenuBarOverlayWindow = nil;
}

@end
