//
//  UKPropStyleEntry.m
//  Stacksmith
//
//  Created by Uli Kusterer on 25.04.10.
//  Copyright 2010 The Void Software. All rights reserved.
//

#import "UKPropStyleEntry.h"



@implementation UKPropStyleEntry

-(id)	initWithFontID: (NSInteger)theID fontSize: (NSInteger)theSize
			styles: (NSArray*)theStyles
{
	if(( self = [super init] ))
	{
		mFontID = theID;
		mFontSize = theSize;
		mFontStyles = [theStyles retain];
	}
	
	return self;
}

-(void)	dealloc
{
	DESTROY(mFontName);
	DESTROY(mFontStyles);
	
	[super dealloc];
}

-(NSInteger)	fontID
{
	return mFontID;
}


-(NSString*)	fontName
{
	return mFontName;
}


-(void)			setFontName: (NSString*)fName
{
	ASSIGN(mFontName,fName);
}


-(NSInteger)	fontSize
{
	return mFontSize;
}


-(NSArray*)		styles
{
	return mFontStyles;
}

-(NSString*)	description
{
	return [NSString stringWithFormat: @"%@ { font = %@ (%ld), size = %d, style = %@ }",
						[self class], mFontName, mFontID, mFontSize, [mFontStyles componentsJoinedByString: @", "]];
}

@end



