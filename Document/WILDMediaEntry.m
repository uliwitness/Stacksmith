//
//  WILDMediaEntry.m
//  Stacksmith
//
//  Created by Uli Kusterer on 25.04.10.
//  Copyright 2010 The Void Software All rights reserved.
//

#import "WILDMediaEntry.h"
#import "WILDXMLUtils.h"


@implementation WILDMediaEntry

@synthesize isBuiltIn = mIsBuiltIn;

-(id)	initWithFilename: (NSString*)fileName withType: (NSString*)type
			name: (NSString*)iconName andID: (WILDObjectID)iconID hotSpot: (NSPoint)pos
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


-(WILDObjectID)	pictureID
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


-(BOOL)	writeToFolderURLIfNeeded:(NSURL *)absoluteURL withOriginalFolderURL: (NSURL*)absoluteOriginalContentsURL forSaveOperation: (NSSaveOperationType)saveOperation
{
	BOOL			success = NO;
	NSString	*	fileExtension = @"tiff";
	if( mFilename == nil )	// New, never been saved?
	{
		NSData		*	fileData = [mImage TIFFRepresentation];	// TODO: Handle movies, sounds etc.
		NSString	*	sanitizedName = [[mName stringByReplacingOccurrencesOfString: @"/" withString: @"-"] stringByAppendingPathExtension:fileExtension];
		NSString	*	filePath = [[absoluteURL path] stringByAppendingPathComponent: sanitizedName];
		filePath = [[NSFileManager defaultManager] uniqueFileName: filePath];
		ASSIGN(mFilename, sanitizedName);
		success = [fileData writeToFile: filePath atomically: YES];
	}
	else	// Must be a "save" or "save as" ... ?
	{
		NSString	*	fileBaseName = [mFilename lastPathComponent];
		NSString	*	filePath = [[absoluteURL path] stringByAppendingPathComponent: fileBaseName];
		NSString	*	originalFilePath = [[absoluteOriginalContentsURL path] stringByAppendingPathComponent: fileBaseName];
		BOOL			fileAlreadyThere = [[NSFileManager defaultManager] fileExistsAtPath: filePath];
		NSError		*	theError = nil;
		
		if( !fileAlreadyThere && (saveOperation == NSSaveOperation || saveOperation == NSAutosaveOperation) )
		{
			success = [[NSFileManager defaultManager] linkItemAtPath: originalFilePath toPath: filePath error: &theError];
		}
		if( !success && !fileAlreadyThere )
		{
			success = [[NSFileManager defaultManager] copyItemAtPath: originalFilePath toPath: filePath error: &theError];
		}
	}
	
	return success;
}


-(NSString*)	xmlString
{
	NSString	*	hotSpotXml = @"";
	if( [mType isEqualToString: @"cursor"] )
	{
		hotSpotXml = [NSString stringWithFormat: @"\n\t\t<hotspot>\n\t\t\t<left>%d</left>\n\t\t\t<top>%d<\top>\n\t\t</hotspot>", (int)mHotSpot.x, (int)mHotSpot.y];
	}
	return [NSString stringWithFormat: @"\t<media>\n\t\t<id>%lld</id>\n\t\t<type>%@</type>\n\t\t<name>%@</name>\n\t\t<file>%@</file>%@\n\t</media>\n", mID, mType, WILDStringEscapedForXML(mName), WILDStringEscapedForXML([mFilename lastPathComponent]),hotSpotXml];
}


-(NSString*)	description
{
	return [NSString stringWithFormat: @"%@ { name = %@ type = %@ id = %lld filename = %@ hotSpot = %@ }",
						[self class], mName, mType, mID, mFilename, NSStringFromPoint(mHotSpot)];
}

@end
