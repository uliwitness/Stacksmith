//
//  WILDMediaEntry.m
//  Stacksmith
//
//  Created by Uli Kusterer on 25.04.10.
//  Copyright 2010 The Void Software All rights reserved.
//

#import "WILDMediaEntry.h"


@implementation WILDMediaEntry

-(id)	initWithFilename: (NSString*)fileName withType: (NSString*)type
			name: (NSString*)iconName andID: (NSInteger)iconID hotSpot: (NSPoint)pos
{
	if(( self = [super init] ))
	{
		mFilename = [fileName retain];
		mType = [type retain];
		mName = [[iconName lowercaseString] retain];
		mID = iconID;
		mHotSpot = pos;
	}
	
	return self;
}

-(NSString*)	filename
{
	return mFilename;
}


-(NSString*)	pictureType
{
	return mType;
}


-(NSString*)	name
{
	return mName;
}


-(NSInteger)	pictureID
{
	return mID;
}


-(NSPoint)		hotSpot
{
	return mHotSpot;
}


-(id)	imageMovieOrCursor
{
	return mImage;
}


-(void)	setImageMovieOrCursor: (id)theImage
{
	ASSIGN(mImage,theImage);
}


-(NSString*)	description
{
	return [NSString stringWithFormat: @"%@ { name = %@ type = %@ id = %ld filename = %@ hotSpot = %@ }",
						[self class], mName, mType, mID, mFilename, NSStringFromPoint(mHotSpot)];
}

@end
