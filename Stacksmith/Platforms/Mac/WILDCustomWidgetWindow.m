//
//  WILDCustomWidgetWindow.m
//  Stacksmith
//
//  Created by Uli Kusterer on 2014-02-08.
//  Copyright (c) 2014 Uli Kusterer. All rights reserved.
//

#import "WILDCustomWidgetWindow.h"

@implementation WILDCustomWidgetWindow

-(void)	dealloc
{
	self.customWidget = nil;
	
	[super dealloc];
}


-(void)	setDelegate: (id <NSWindowDelegate>)anObject
{
	[super setDelegate: anObject];
	if( !self.customWidget )
	{
		NSButton*	rightmostButton = [self standardWindowButton: NSWindowFullScreenButton];
		NSRect		box = rightmostButton.frame;
		box.origin.x -= 56;
		box.size.width = 48;
		NSView*		superView = rightmostButton.superview;
		self.customWidget = [[[NSButton alloc] initWithFrame: box] autorelease];
		[self.customWidget setBezelStyle: NSRoundRectBezelStyle];
		[self.customWidget.cell setControlSize: NSSmallControlSize];
		[self.customWidget setTitle: @"Edit"];
		[self.customWidget setTranslatesAutoresizingMaskIntoConstraints: YES];
		[self.customWidget setAutoresizingMask: NSViewMinXMargin | NSViewMinYMargin];
		[self.customWidget setButtonType: NSPushOnPushOffButton];
		[superView addSubview: self.customWidget];
	}
	
	self.customWidget.target = anObject;
	self.customWidget.action = @selector(customWidgetWindowEditButtonClicked:);
}

@end
