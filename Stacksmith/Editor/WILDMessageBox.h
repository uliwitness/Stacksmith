//
//  WILDMessageBox.h
//  Stacksmith
//
//  Created by Uli Kusterer on 14.04.11.
//  Copyright 2011 Uli Kusterer. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "WILDObjectValue.h"


@interface WILDMessageBox : NSWindowController <WILDObject>
{
    NSTextView		*		messageField;
	NSButton		*		runButton;
}

@property (retain) IBOutlet NSTextView		*		messageField;
@property (retain) IBOutlet NSButton		*		runButton;

+(WILDMessageBox*)	sharedMessageBox;

-(IBAction)	orderFrontMessageBox: (id)sender;
-(IBAction)	runMessageWithHighlight: (id)sender;
-(IBAction)	runMessage: (id)sender;

-(void)		setStringValue: (NSString*)messageString;

@end
