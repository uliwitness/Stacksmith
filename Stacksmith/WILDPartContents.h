//
//  WILDPartContents.h
//  Propaganda
//
//  Created by Uli Kusterer on 28.02.10.
//  Copyright 2010 The Void Software. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "WILDObjectID.h"


@class WILDStack;
@class WILDPart;


@interface WILDPartContents : NSObject
{
	NSString*					mText;			// Plain-text version of the contents text.
	NSMutableAttributedString*	mStyledText;	// Version of mText with styles applied, if we have styles.
	NSString*					mLayer;			// @"card" or @"background".
	WILDObjectID				mID;			// ID of the part this object provides contents for.
	NSArray*					mListItems;		// The contents of this part re-interpreted as a list (ATM, each line as a separate item).
	NSMutableArray*				mStyles;		// Style data for this text.
	BOOL						mHighlighted;	// Buttons can have sharedHighlight == FALSE, in which case their highlight is stored here.
}

@property (assign,nonatomic) WILDObjectID	partID;

-(id)	initWithWILDObjectID: (WILDObjectID)inID layer: (NSString*)inLayer;
-(id)	initWithXMLElement: (NSXMLElement*)theElem forStack: (WILDStack*)theStack;

-(NSString*)			text;
-(void)					setText: (NSString*)inString;	// Nukes any styles and list item caches that may be there.
-(NSAttributedString*)	styledTextForPart: (WILDPart*)currPart;	// May return NIL.
-(void)	setStyledText: (NSAttributedString*)inString;

-(NSString*)			partLayer;
-(BOOL)					highlighted;
-(void)					setHighlighted: (BOOL)inState;

-(NSArray*)				listItems;

-(NSString*)			xmlString;

@end
