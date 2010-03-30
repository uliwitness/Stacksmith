//
//  UKPropagandaPartContents.h
//  Propaganda
//
//  Created by Uli Kusterer on 28.02.10.
//  Copyright 2010 The Void Software. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@class UKPropagandaStack;
@class UKPropagandaPart;


@interface UKPropagandaPartContents : NSObject
{
	NSString*					mText;			// Plain-text version of the contents text.
	NSMutableAttributedString*	mStyledText;	// Version of mText with styles applied, if we have styles.
	NSString*					mLayer;			// @"card" or @"background".
	NSInteger					mID;			// ID of the part this object provides contents for.
	NSArray*					mListItems;		// The contents of this part re-interpreted as a list (ATM, each line as a separate item).
	NSMutableArray*				mStyles;		// Style data for this text.
}

-(id)	initWithXMLElement: (NSXMLElement*)theElem forStack: (UKPropagandaStack*)theStack;

-(NSString*)			text;
-(NSAttributedString*)	styledTextForPart: (UKPropagandaPart*)currPart;	// May return NIL.
-(NSString*)			partLayer;
-(NSInteger)			partID;

-(NSArray*)				listItems;

@end
