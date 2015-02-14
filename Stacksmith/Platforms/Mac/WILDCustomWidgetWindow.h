//
//  WILDCustomWidgetWindow.h
//  Stacksmith
//
//  Created by Uli Kusterer on 2014-02-08.
//  Copyright (c) 2014 Uli Kusterer. All rights reserved.
//

/*
	A window with an "Edit" button in the upper right corner, next to the 'fullscreen' button.
*/

#import <Cocoa/Cocoa.h>

@interface WILDCustomWidgetWindow : NSWindow

@property (retain,nonatomic) NSButton * customWidget;

@end


@interface WILDCustomWidgetPanel : NSPanel

@property (retain,nonatomic) NSButton * customWidget;

@end


@protocol WILDCustomWidgetWindowDelegate <NSWindowDelegate>

@required
-(void)	customWidgetWindowEditButtonClicked: (NSButton*)sender;	// Message sent to window delegate when edit button is clicked. Look at sender.state to see whether you're editing (NSOnState) or browsing (NSOffState).

@end