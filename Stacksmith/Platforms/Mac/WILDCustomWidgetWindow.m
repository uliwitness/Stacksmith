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
	// We really should do this in init, but of course the subviews of the NSWindow
	//	haven't been loaded at this point, including window buttons and content view.
	//	You could probably do a generic addWindowButtonView: method and just call
	//	that after creating the window. But I'll just do it here since I'll need a
	//	target for the window button anyway.
	[super setDelegate: anObject];
	if( !self.customWidget )
	{
		NSButton*	rightmostButton = [self standardWindowButton: NSWindowCloseButton];	// If this was generic code, I'd fall back on other window buttons here if the window doesn't support fullscreen, and maybe the toolbar button on older OSes.
		NSRect		box = rightmostButton.frame;
		box.origin.x = rightmostButton.superview.frame.size.width - 58;
		box.origin.y -= 2;
		box.size.width = 48;
		NSView*		superView = rightmostButton.superview;	// Use same superview as another widget, as DTS recommended.
		self.customWidget = [[[NSButton alloc] initWithFrame: box] autorelease];
		[self.customWidget sizeToFit];
		[self.customWidget setBezelStyle: NSRoundRectBezelStyle];
		[self.customWidget.cell setControlSize: NSMiniControlSize];
		[self.customWidget setTitle: @"Edit"];
		[self.customWidget setTranslatesAutoresizingMaskIntoConstraints: YES];
		[self.customWidget setAutoresizingMask: NSViewMinXMargin | NSViewMinYMargin];	// Remember, AppKit specifies the *flexible* parts, not the fixed-distance ones.
		[self.customWidget setButtonType: NSPushOnPushOffButton];
		[superView addSubview: self.customWidget];
	}
	
	self.customWidget.target = anObject;
	self.customWidget.action = @selector(customWidgetWindowEditButtonClicked:);
}

@end
