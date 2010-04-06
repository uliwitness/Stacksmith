//
//  UKPropagandaStack.m
//  Propaganda
//
//  Created by Uli Kusterer on 27.02.10.
//  Copyright 2010 The Void Software. All rights reserved.
//

#import "UKPropagandaStack.h"
#import "UKPropagandaXMLUtils.h"
#import "UKPropagandaBackground.h"
#import "UKPropagandaCard.h"
#import <QTKit/QTKit.h>
#import "UKPropagandaStack.h"


NSInteger	UKRandomInteger()
{
	#if __LP64__
	return (((NSInteger)rand()) | ((NSInteger)rand()) >> 32);
	#else
	return rand();
	#endif
}



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

@implementation UKPropPictureEntry

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


-(id)	imageOrCursor
{
	return mImage;
}


-(void)	setImageOrCursor: (id)theImage
{
	if( mImage != theImage )
	{
		[mImage release];
		mImage = [theImage retain];
	}
}


-(NSString*)	description
{
	return [NSString stringWithFormat: @"%@ { name = %@ type = %@ id = %ld filename = %@ hotSpot = %@ }",
						[self class], mName, mType, mID, mFilename, NSStringFromPoint(mHotSpot)];
}

@end



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
	[mFontName release];
	mFontName = nil;
	[mFontStyles release];
	mFontStyles = nil;
	
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
	if( mFontName != fName )
	{
		[mFontName release];
		mFontName = [fName retain];
	}
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





@implementation UKPropagandaStack

-(id)	init
{
	if(( self = [super init] ))
	{
		mUserLevel = 5;
		
		mCantModify = NO;
		mCantDelete = NO;
		mPrivateAccess = NO;
		mCantAbort = NO;
		mCantPeek = NO;
		
		NSString*	appVersion = [[NSBundle mainBundle] objectForInfoDictionaryKey: @"CFBundleVersion"];
		mCreatedByVersion = [appVersion retain];
		mLastCompactedVersion = [appVersion retain];
		mFirstEditedVersion = [appVersion retain];
		mLastEditedVersion = [appVersion retain];
		
		mCardSize = NSMakeSize( 512, 342 );
		
		mPatterns = [[NSMutableArray alloc] initWithCapacity: 40];
		for( int x = 0; x < 40; x++ )
			[mPatterns addObject: [NSString stringWithFormat: @"PAT_%d.pbm", x+1]];
		
		mScript = [@"" retain];
		
		UKPropagandaBackground*		firstBg = [[[UKPropagandaBackground alloc] initForStack: self] autorelease];
		mBackgrounds = [[NSMutableArray alloc] initWithObjects: firstBg, nil];
		UKPropagandaCard*			firstCard = [[[UKPropagandaCard alloc] initForStack: self] autorelease];
		[firstCard setOwningBackground: firstBg];
		
		mCards = [[NSMutableArray alloc] initWithObjects: firstCard, nil];
		mFontIDTable = [[NSMutableDictionary alloc] init];
		mTextStyles = [[NSMutableDictionary alloc] init];
		mPictures = [[NSMutableArray alloc] init];
	}
	
	return self;
}


-(id)	initWithXMLElement: (NSXMLElement*)elem path: (NSString*)thePath
{
	if(( self = [super init] ))
	{
		mUserLevel = UKPropagandaIntegerFromSubElementInElement( @"userLevel", elem );
		
		mCantModify = UKPropagandaBoolFromSubElementInElement( @"cantModify", elem );
		mCantDelete = UKPropagandaBoolFromSubElementInElement( @"cantDelete", elem );
		mPrivateAccess = UKPropagandaBoolFromSubElementInElement( @"privateAccess", elem );
		mCantAbort = UKPropagandaBoolFromSubElementInElement( @"cantAbort", elem );
		mCantPeek = UKPropagandaBoolFromSubElementInElement( @"cantPeek", elem );
		
		mCreatedByVersion = [UKPropagandaStringFromSubElementInElement( @"createdByVersion", elem ) retain];
		mLastCompactedVersion = [UKPropagandaStringFromSubElementInElement( @"lastCompactedVersion", elem ) retain];
		mFirstEditedVersion = [UKPropagandaStringFromSubElementInElement( @"firstEditedVersion", elem ) retain];
		mLastEditedVersion = [UKPropagandaStringFromSubElementInElement( @"lastEditedVersion", elem ) retain];
		
		mCardSize = UKPropagandaSizeFromSubElementInElement( @"cardSize", elem );
		
		mPatterns = [UKPropagandaStringsFromSubElementInElement( @"pattern", elem ) mutableCopy];
		
		mScript = [UKPropagandaStringFromSubElementInElement( @"script", elem ) retain];
		
		mPath = [thePath retain];
		
		mCards = [[NSMutableArray alloc] init];
		mBackgrounds = [[NSMutableArray alloc] init];
		mFontIDTable = [[NSMutableDictionary alloc] init];
		mTextStyles = [[NSMutableDictionary alloc] init];
		mPictures = [[NSMutableArray alloc] init];
	}
	
	return self;
}


-(void)	dealloc
{
	[mBackgrounds release];
	mBackgrounds = nil;
	[mCards release];
	mCards = nil;
	[mCreatedByVersion release];
	mCreatedByVersion = nil;
	[mLastCompactedVersion release];
	mLastCompactedVersion = nil;
	[mFirstEditedVersion release];
	mFirstEditedVersion = nil;
	[mLastEditedVersion release];
	mLastEditedVersion = nil;
	[mPatterns release];
	mPatterns = nil;
	[mScript release];
	mScript = nil;
	[mPath release];
	mPath = nil;
	[mFontIDTable release];
	mFontIDTable = nil;
	[mTextStyles release];
	mTextStyles = nil;
	[mPictures release];
	mPictures = nil;
	
	[super dealloc];
}


-(void)	addCard: (UKPropagandaCard*)theCard
{
	[mCards addObject: theCard];
}


-(void)	addBackground: (UKPropagandaBackground*)theBg
{
	[mBackgrounds addObject: theBg];
}


-(void)		addFont: (NSString*)fontName withID: (NSInteger)fontID
{
	[mFontIDTable setObject: fontName forKey: [NSNumber numberWithInteger: fontID]];
}


-(NSString*)	fontNameForID: (NSInteger)fontID
{
	return [mFontIDTable objectForKey: [NSNumber numberWithInteger: fontID]];
}


-(void)		addStyleFormatWithID: (NSInteger)styleID forFontID: (NSInteger)fontID size: (NSInteger)fontSize styles: (NSArray*)fontStyles
{
	UKPropStyleEntry*	pse = [[[UKPropStyleEntry alloc] initWithFontID: fontID fontSize: fontSize
			styles: fontStyles] autorelease];
	NSString*	fontName = [self fontNameForID: fontID];	// Look up font by ID.
	[pse setFontName: fontName];	// Remember it for the future.
	
	[mTextStyles setObject: pse forKey: [NSNumber numberWithInteger: styleID]];
}


-(void)	provideStyleFormatWithID: (NSInteger)oneBasedIdx font: (NSString**)outFontName
			size: (NSInteger*)outFontSize styles: (NSArray**)outFontStyles
{
	UKPropStyleEntry*	pse = [mTextStyles objectForKey: [NSNumber numberWithInteger: oneBasedIdx]];
	if( pse )
	{
		*outFontName = [pse fontName];
		*outFontSize = [pse fontSize];
		*outFontStyles = [pse styles];
	}
}


-(NSArray*)	cards
{
	return mCards;
}


-(void)	setCards: (NSArray*)theCards
{
	if( mCards != theCards )
	{
		[mCards release];
		mCards = [theCards mutableCopy];
	}
}


-(UKPropagandaCard*)	cardWithID: (NSInteger)theID
{
	for( UKPropagandaCard* theCd in mCards )
	{
		if( [theCd cardID] == theID )
			return theCd;
	}
	
	return nil;
}


-(NSInteger)	uniqueIDForCardOrBackground
{
	NSInteger	cardID = UKRandomInteger();
	BOOL		notUnique = YES;
	
	while( notUnique )
	{
		notUnique = NO;
		
		for( UKPropagandaCard* currCard in mCards )
		{
			if( [currCard cardID] == cardID )
			{
				notUnique = YES;
				cardID = UKRandomInteger();
				break;
			}
		}

		if( !notUnique )
		{
			for( UKPropagandaBackground* currBkgd in mBackgrounds )
			{
				if( [currBkgd backgroundID] == cardID )
				{
					notUnique = YES;
					cardID = UKRandomInteger();
					break;
				}
			}
		}
	}
	
	return cardID;
}


-(void)	setBackgrounds: (NSArray*)theBkgds
{
	if( mBackgrounds != theBkgds )
	{
		[mBackgrounds release];
		mBackgrounds = [theBkgds mutableCopy];
	}
}


-(UKPropagandaBackground*)	backgroundWithID: (NSInteger)theID
{
	for( UKPropagandaBackground* theBg in mBackgrounds )
	{
		if( [theBg backgroundID] == theID )
			return theBg;
	}
	
	return nil;
}


-(NSImage*)	imageNamed: (NSString*)theName
{
	NSString*	imgPath = [mPath stringByAppendingPathComponent: theName];
	NSImage*	img = [[[NSImage alloc] initWithContentsOfFile: imgPath] autorelease];
	if( !img )
		img = [NSImage imageNamed: theName];
	else
		[img setName: theName];
	return img;
}


-(NSImage*)	imageForPatternAtIndex: (NSInteger)idx
{
	NSImage*	img = [mPatterns objectAtIndex: idx];
	if( [img isKindOfClass: [NSImage class]] )
		return img;	// Already cached.
	
	img = [self imageNamed: (NSString*)img];
	if( img )
		[mPatterns replaceObjectAtIndex: idx withObject: img];
	
	return img;
}


-(NSSize)	cardSize
{
	return mCardSize;
}


-(void)	addMediaFile: (NSString*)fileName withType: (NSString*)type
			name: (NSString*)iconName andID: (NSInteger)iconID hotSpot: (NSPoint)pos
{
	UKPropPictureEntry*	pentry = [[[UKPropPictureEntry alloc] initWithFilename: fileName withType: type name: iconName andID: iconID hotSpot: pos] autorelease];
	[mPictures addObject: pentry];
}


-(QTMovie*)		movieOfType: (NSString*)typ name: (NSString*)theName
{
	theName = [theName lowercaseString];
	for( UKPropPictureEntry* currPic in mPictures )
	{
		if( [[currPic pictureType] isEqualToString: typ]
			&& [[currPic name] isEqualToString: theName] )
		{
			if( ![currPic imageOrCursor] )
			{
				QTMovie*	img = [[[QTMovie alloc] initWithFile: [mPath stringByAppendingPathComponent: [currPic filename]] error: nil] autorelease];
				if( !img )
					img = [[[QTMovie alloc] initWithFile: [[NSBundle mainBundle] pathForResource: [currPic filename] ofType: @""] error: nil] autorelease];
				[currPic setImageOrCursor: img];
				return img;
			}
			else
				return [currPic imageOrCursor];
			break;
		}
	}
	
	return nil;
}


-(QTMovie*)		movieOfType: (NSString*)typ id: (NSInteger)theID
{
	for( UKPropPictureEntry* currPic in mPictures )
	{
		if( [currPic pictureID] == theID
			&& [[currPic pictureType] isEqualToString: typ] )
		{
			if( ![currPic imageOrCursor] )
			{
				QTMovie*	img = [[[QTMovie alloc] initWithFile: [mPath stringByAppendingPathComponent: [currPic filename]] error: nil] autorelease];
				if( !img )
					img = [[[QTMovie alloc] initWithFile: [[NSBundle mainBundle] pathForResource: [currPic filename] ofType: @""] error: nil] autorelease];
				[currPic setImageOrCursor: img];
				return img;
			}
			else
				return [currPic imageOrCursor];
			break;
		}
	}
	
	return nil;
}


-(NSImage*)		pictureOfType: (NSString*)typ name: (NSString*)theName
{
	assert(![typ isEqualToString: @"cursor"]);
	assert(![typ isEqualToString: @"sound"]);
	
	theName = [theName lowercaseString];
	for( UKPropPictureEntry* currPic in mPictures )
	{
		if( [[currPic pictureType] isEqualToString: typ]
			&& [[currPic name] isEqualToString: theName] )
		{
			if( ![currPic imageOrCursor] )
			{
				NSImage*	img = [self imageNamed: [currPic filename]];
				[currPic setImageOrCursor: img];
				return img;
			}
			else
				return [currPic imageOrCursor];
			break;
		}
	}
	
	return nil;
}


-(NSImage*)		pictureOfType: (NSString*)typ id: (NSInteger)theID
{
	assert(![typ isEqualToString: @"cursor"]);
	assert(![typ isEqualToString: @"sound"]);
	
	for( UKPropPictureEntry* currPic in mPictures )
	{
		if( [currPic pictureID] == theID
			&& [[currPic pictureType] isEqualToString: typ] )
		{
			if( ![currPic imageOrCursor] )
			{
				NSImage*	img = [self imageNamed: [currPic filename]];
				[currPic setImageOrCursor: img];
				return img;
			}
			else
				return [currPic imageOrCursor];
			break;
		}
	}
	
	return nil;
}


-(NSInteger)	numberOfPictures
{
	NSInteger		numPics = 0;
	for( UKPropPictureEntry* currPic in mPictures )
	{
		if( [[currPic pictureType] isEqualToString: @"icon"] )
			numPics++;
	}
	
	return numPics;
}


-(NSImage*)		pictureAtIndex: (NSInteger)idx
{
	NSInteger		numPics = 0;
	for( UKPropPictureEntry* currPic in mPictures )
	{
		if( [[currPic pictureType] isEqualToString: @"icon"] )
		{
			if( numPics == idx )
			{
				if( ![currPic imageOrCursor] )
				{
					NSImage*	img = [self imageNamed: [currPic filename]];
					[currPic setImageOrCursor: img];
					return img;
				}
				else
					return [currPic imageOrCursor];
			}
			numPics++;
		}
	}
	
	return nil;
}


-(void)	infoForPictureAtIndex: (NSInteger)idx name: (NSString**)outName id: (NSInteger*)outID
			image: (NSImage**)outImage fileName: (NSString**)outFileName
{
	NSInteger		numPics = 0;
	for( UKPropPictureEntry* currPic in mPictures )
	{
		if( [[currPic pictureType] isEqualToString: @"icon"] )
		{
			if( numPics == idx )
			{
				if( outImage )
				{
					if( ![currPic imageOrCursor] )
					{
						*outImage = [self imageNamed: [currPic filename]];
						[currPic setImageOrCursor: *outImage];
					}
					else
						*outImage = [currPic imageOrCursor];
				}

				if( outName )
					*outName = [currPic name];
				if( outID )
					*outID = [currPic pictureID];
				if( outFileName )
					*outFileName = [currPic filename];
			}
			numPics++;
		}
	}
}



-(NSCursor*)	cursorWithName: (NSString*)theName
{
	theName = [theName lowercaseString];
	for( UKPropPictureEntry* currPic in mPictures )
	{
		if( [[currPic pictureType] isEqualToString: @"cursor"]
			&& [[currPic name] isEqualToString: theName])
		{
			if( ![currPic imageOrCursor] )
			{
				NSImage*	img = [self imageNamed: [currPic filename]];
				NSCursor*	curs = [[[NSCursor alloc] initWithImage: img hotSpot: [currPic hotSpot]] autorelease];
				[currPic setImageOrCursor: curs];
				return curs;
			}
			else
				return [currPic imageOrCursor];
			break;
		}
	}
	
	if( [theName isEqualToString: @"hand"] )
		return [NSCursor pointingHandCursor];
	else
		return nil;
}


-(NSCursor*)	cursorWithID: (NSInteger)theID
{
	for( UKPropPictureEntry* currPic in mPictures )
	{
		if( [currPic pictureID] == theID
			&& [[currPic pictureType] isEqualToString: @"cursor"] )
		{
			if( ![currPic imageOrCursor] )
			{
				NSImage*	img = [self imageNamed: [currPic filename]];
				NSCursor*	curs = [[[NSCursor alloc] initWithImage: img hotSpot: [currPic hotSpot]] autorelease];
				[currPic setImageOrCursor: curs];
				return curs;
			}
			else
				return [currPic imageOrCursor];
			break;
		}
	}
	
	if( theID == 128 )
		return [NSCursor pointingHandCursor];
	else
		return nil;
}


-(NSString*)	description
{
	return [NSString stringWithFormat: @"%@ { styles = %@, media = %@ }", [self class], mTextStyles, mPictures];
}


-(NSString*)	script
{
	return mScript;
}


-(void)	setScript: (NSString*)theScript
{
	if( mScript != theScript )
	{
		[mScript release];
		mScript = [theScript retain];
	}
}


-(NSString*)	displayName
{
	return [NSString stringWithFormat: @"Stack “%@”", [[mPath lastPathComponent] stringByDeletingPathExtension]];
}


-(NSImage*)	displayIcon
{
	return [[NSWorkspace sharedWorkspace] iconForFileType: @"xstk"];
}


-(BOOL)	searchForPattern: (NSString*)inPattern withContext: (UKPropagandaSearchContext*)inContext
			flags: (UKPropagandaSearchFlags)inFlags
{
	UKPropagandaCard*	cardToSearch = inContext.currentCard;
	if( !cardToSearch )
		cardToSearch = inContext.startCard;
	BOOL		foundSomething = NO;
	
	while( YES )
	{
		//NSLog( @"===== Searching %@ =====", [cardToSearch displayName] );
		
		foundSomething = [cardToSearch searchForPattern: inPattern withContext: inContext flags: inFlags];
		if( foundSomething )
		{
			//NSLog( @"Found something in %@", [cardToSearch displayName] );
			break;	// Yaay! we're done!
		}
		
		// Nothing found on this card? Try next card:
		NSInteger	currCardIdx = [mCards indexOfObject: cardToSearch];
		if( inFlags & UKPropagandaSearchBackwards )
		{
			currCardIdx -= 1;
			if( currCardIdx < 0 )
				currCardIdx = [mCards count] -1;
		}
		else
		{
			currCardIdx += 1;
			if( currCardIdx >= [mCards count] )
				currCardIdx = 0;
		}
		
		cardToSearch = [mCards objectAtIndex: currCardIdx];
		if( cardToSearch == inContext.startCard )	// Back at first card we searched? Nothing more to search through, exit!
		{
			//NSLog( @"End of search, back at %@", [cardToSearch displayName] );
			break;
		}
	}
	
	return foundSomething;
}


+(NSColor*)		peekOutlineColor
{
	return [NSColor colorWithPatternImage: [NSImage imageNamed: @"PAT_22.pbm"]];
}

@end
