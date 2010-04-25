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
	NSInteger	mFontID;
	NSString*	mFontName;
	NSInteger	mFontSize;
	NSArray*	mFontStyles;
}

-(id)	initWithFontID: (NSInteger)theID fontSize: (NSInteger)theSize
			styles: (NSArray*)theStyles;

-(NSInteger)	fontID;
-(NSString*)	fontName;
-(void)			setFontName: (NSString*)fName;
-(NSInteger)	fontSize;
-(NSArray*)		styles;

@end
