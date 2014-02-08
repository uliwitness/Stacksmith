//
//  WILDCustomWidgetWindow.h
//  Stacksmith
//
//  Created by Uli Kusterer on 2014-02-08.
//  Copyright (c) 2014 Uli Kusterer. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface WILDCustomWidgetWindow : NSWindow

@property (retain,nonatomic) NSButton * customWidget;

@end


@protocol WILDCustomWidgetWindowDelegate <NSWindowDelegate>

-(void)	customWidgetWindowEditButtonClicked: (NSButton*)sender;

@end