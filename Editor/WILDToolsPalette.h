//
//  WILDToolsPalette.h
//  Stacksmith
//
//  Created by Uli Kusterer on 11.05.11.
//  Copyright 2011 Uli Kusterer. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "ULIPaintView.h"


@interface WILDToolsPalette : NSWindowController
{
@private
    NSColorWell		*	mLineColorWell;
	NSColorWell		*	mFillColorWell;
}

@property (retain) IBOutlet NSColorWell		*		lineColorWell;
@property (retain) IBOutlet NSColorWell		*		fillColorWell;

+(WILDToolsPalette*)	sharedToolsPalette;

-(void)	orderFrontToolsPalette: (id)sender;

-(NSColor*)	lineColor;
-(NSColor*)	fillColor;

-(IBAction)	takeLineColorFrom: (NSColorWell*)sender;
-(IBAction)	takeFillColorFrom: (NSColorWell*)sender;

@end
