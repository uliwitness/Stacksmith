//
//  UKPropStyleEntry.h
//  Stacksmith
//
//  Created by Uli Kusterer on 25.04.10.
//  Copyright 2010 The Void Software. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface UKPropStyleEntry : NSObject
{
	NSString*	mFontName;
	NSInteger	mFontSize;
	NSArray*	mFontStyles;
}

-(id)	initWithFontName: (NSString*)theName fontSize: (NSInteger)theSize
			styles: (NSArray*)theStyles;

-(NSString*)	fontName;
-(void)			setFontName: (NSString*)fName;
-(NSInteger)	fontSize;
-(NSArray*)		styles;

@end
