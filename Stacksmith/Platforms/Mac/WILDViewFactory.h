//
//  WILDViewFactory.h
//  Stacksmith
//
//  Created by Uli Kusterer on 2014-01-13.
//  Copyright (c) 2014 Uli Kusterer. All rights reserved.
//

/*
	Helper class that loads certain parts that have bugs when
	created manually on 10.9.0-10.9.1 (latest release as of this
	writing) from a XIB file and then makes us a copy.
*/

#import <Cocoa/Cocoa.h>


@class WILDButtonView;
@class NSTextField;

@interface WILDViewFactory : NSViewController

+(WILDButtonView*)		systemButton;	// with NSButtonCell.
+(WILDButtonView*)		shapeButton;	// with WILDButtonCell.
+(NSTextField*)			textField;
+(NSPopUpButton*)		popUpButton;
+(NSTableView*)			tableViewInContainer;	// Scroll view containing a table view. Ask this view for its enclosingScrollView.

@end


