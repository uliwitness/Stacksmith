//
//  UKPropPictureEntry.h
//  Stacksmith
//
//  Created by Uli Kusterer on 25.04.10.
//  Copyright 2010 The Void Software. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface UKPropPictureEntry : NSObject
{
	NSString*	mFilename;
	NSString*	mType;
	NSString*	mName;
	NSInteger	mID;
	NSPoint		mHotSpot;
	id			mImage;		// NSImage or NSCursor we've already loaded for this.
}

-(id)	initWithFilename: (NSString*)fileName withType: (NSString*)type
			name: (NSString*)iconName andID: (NSInteger)iconID hotSpot: (NSPoint)pos;

-(NSString*)	filename;
-(NSString*)	pictureType;
-(NSString*)	name;
-(NSInteger)	pictureID;
-(NSPoint)		hotSpot;
-(id)			imageOrCursor;
-(void)			setImageOrCursor: (id)theImage;

@end



