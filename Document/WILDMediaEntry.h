//
//  WILDMediaEntry.h
//  Stacksmith
//
//  Created by Uli Kusterer on 25.04.10.
//  Copyright 2010 The Void Software. All rights reserved.
//

/*
	A WILDMediaEntry groups information about a piece of media that is contained
	in a particular stack file, so we can case-sensitively look it up by name,
	or by ID like the resources of old they used to be.
*/

#import <Cocoa/Cocoa.h>
#import "WILDObjectID.h"


@interface WILDMediaEntry : NSObject
{
	NSString*		mFilename;
	NSString*		mType;
	NSString*		mName;
	WILDObjectID	mID;
	NSPoint			mHotSpot;
	id				mImage;		// NSImage, NSMovie or NSCursor we've already loaded for this.
	BOOL			mIsBuiltIn;
}

@property (assign) BOOL	isBuiltIn;

-(id)	initWithFilename: (NSString*)fileName withType: (NSString*)type
			name: (NSString*)iconName andID: (WILDObjectID)iconID hotSpot: (NSPoint)pos;

-(NSString*)	filename;
-(NSString*)	pictureType;
-(NSString*)	name;
-(WILDObjectID)	pictureID;
-(NSPoint)		hotSpot;
-(id)			imageMovieOrCursor;
-(void)			setImageMovieOrCursor: (id)theImage;

-(void)			writeToFolderURLIfNeeded: (NSURL*)absoluteURL;

-(NSString*)	xmlString;

@end



