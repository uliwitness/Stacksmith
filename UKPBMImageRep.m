/* =============================================================================
    PROJECT:	Propagands
	FILE:       UKPBMImageRep.h
    
    COPYRIGHT:  (c) 2010 by M. Uli Kusterer, all rights reserved.
    
    AUTHORS:    M. Uli Kusterer - UK
    
	PURPOSE:	Draw one type of PBM P4 format image. It expects P4 on the
				first line, the size with a single space between each dimension
				on the second, and then the bitmap data on the last line.
    
    REVISIONS:
        2010-02-28  UK  Created.
   ========================================================================== */

#import "UKPBMImageRep.h"


#if 0

@implementation UKPBMImageRep

+(BOOL) canInitWithData: (NSData*)theData
{
    const char*	bytes = [theData bytes];
	return( bytes[0] == 'P' && bytes[1] == '4' && bytes[2] == '\n' );
}


+(NSArray*) imageUnfilteredFileTypes
{
    return [NSArray arrayWithObject: @"pbm"];
}


+(NSArray*) imageUnfilteredPasteboardTypes
{
    return [NSArray array];
}


+(id)	imageRepWithData: (NSData*)theData
{
    const char*	bytes = [theData bytes];
	if( bytes[0] != 'P' || bytes[1] != '4' || bytes[2] != '\n' )
		return nil;
    
	NSMutableString*	widthStr = [NSMutableString string];
	NSMutableString*	heightStr = [NSMutableString string];
	int					x = 3;
	for( x = 3; x < [theData length] && bytes[x] != ' '; x++ )
		[widthStr appendFormat: @"%c", bytes[x]];
	
	++x;
	for( ; x < [theData length] && bytes[x] != '\n'; x++ )
		[heightStr appendFormat: @"%c", bytes[x]];
	
	NSSize	size = NSMakeSize( [widthStr intValue], [heightStr intValue] );
	int leftOverData = [theData length] -x -1;
	if( leftOverData <= 0 )
		return nil;
	
	NSInteger		rowBytes = size.width * 4;
	
	NSBitmapImageRep*	theRep = [[[NSBitmapImageRep alloc] initWithBitmapDataPlanes: NULL
									pixelsWide: size.width pixelsHigh: size.height
									bitsPerSample: 8 samplesPerPixel: 4 hasAlpha: YES isPlanar: NO
									colorSpaceName: NSCalibratedRGBColorSpace
									bytesPerRow: rowBytes bitsPerPixel: 32] autorelease];
    if( !theRep )
        return nil;
	
	unsigned char*	destByte = [theRep bitmapData];
	int				currDestIdx = 0;
	for( int x = 0; x < (size.width * size.height); x++ )
	{
		destByte[currDestIdx++] = 0x00;
		destByte[currDestIdx++] = 0x88;
		destByte[currDestIdx++] = 0x88;
		destByte[currDestIdx++] = 0x00;
	}
	
	return theRep;
}


-(void) dealloc
{
    @synchronized( self )
    {
        [pixelData release];
        pixelData = nil;
    }
    
    [super dealloc];
}

@end

#else

@implementation UKPBMImageRep

+(void) load
{
    [NSImageRep registerImageRepClass: self];
}


+(id)	imageRepWithData: (NSData*)theData
{
    return [[[self alloc] initWithData: theData] autorelease];
}


-(id)       initWithData: (NSData*)theData
{
	self = [super init];
	if( !self )
		return nil;
    
	const char*	bytes = [theData bytes];
	if( bytes[0] != 'P' || bytes[1] != '4' || bytes[2] != '\n' )
	{
		[self autorelease];
		return nil;
	}
    
	NSMutableString*	widthStr = [NSMutableString string];
	NSMutableString*	heightStr = [NSMutableString string];
	int					x = 3;
	for( x = 3; x < [theData length] && bytes[x] != ' '; x++ )
		[widthStr appendFormat: @"%c", bytes[x]];
	
	++x;
	for( ; x < [theData length] && bytes[x] != '\n'; x++ )
		[heightStr appendFormat: @"%c", bytes[x]];
	
	size = actualSize = NSMakeSize( [widthStr intValue], [heightStr intValue] );
	int leftOverData = [theData length] -x -1;
	if( leftOverData <= 0 )
	{
		[self autorelease];
		return nil;
	}
	
	NSInteger		imgOffset = x +1;	// Remember where the actual image started.
	
	NSInteger		rowBytes = (7 + size.width) / 8;
	x += (rowBytes * actualSize.height);
	
	// See if there's a second image to use as mask:
	if( [theData length] > (x +(rowBytes * actualSize.height))
		&& bytes[x +1] == '\n' && bytes[x +2] == 'P' && bytes[x +3] == '4' && bytes[x +4] == '\n' )
	{
		x += 5;
		
		[widthStr deleteCharactersInRange: NSMakeRange( 0, [widthStr length] )];
		[heightStr deleteCharactersInRange: NSMakeRange( 0, [heightStr length] )];
		for( ; x < [theData length] && bytes[x] != ' '; x++ )
			[widthStr appendFormat: @"%c", bytes[x]];
		
		++x;
		for( ; x < [theData length] && bytes[x] != '\n'; x++ )
			[heightStr appendFormat: @"%c", bytes[x]];
		
		if( [widthStr intValue] == actualSize.width && [heightStr intValue] == actualSize.height )
			maskOffset = x -imgOffset +1;
	}
	
	pixelData = [[NSData alloc] initWithBytes: bytes +imgOffset length: [theData length] -imgOffset];
	
	return self;
}


-(void) dealloc
{
    @synchronized( self )
    {
        [pixelData release];
        pixelData = nil;
    }
    
    [super dealloc];
}

-(BOOL) draw
{
	NSRect  box = NSZeroRect;
	box.size = size;
    
	const unsigned char*		data[5] = { 0 };
	data[0] = [pixelData bytes];
	if( maskOffset != 0 )
		data[1] = [pixelData bytes] +maskOffset;
	else
		data[1] = [pixelData bytes];
	
	BOOL		haveMask = YES; //maskOffset != 0;
	NSInteger	samplesPerPixel = haveMask ? 2 : 1;
	
	NSDrawBitmap( box, actualSize.width, actualSize.height,
					1 /*bps*/, samplesPerPixel /*spp*/, 1 /*bpp*/, (7 + actualSize.width) / 8 /*Bpr*/,
					YES /*planar*/, haveMask /*alpha*/,
					NSDeviceBlackColorSpace, data );
	
	return YES;
}


-(BOOL) drawAtPoint: (NSPoint)point
{
	NSRect  box = { { 0, 0 }, { 0, 0 } };
//	box.origin.x = truncf(point.x) +0.5;
//	box.origin.y = truncf(point.y) +0.5;
	box.size = size;
	
	const unsigned char*		data[5] = { 0 };
	data[0] = [pixelData bytes];
	if( maskOffset != 0 )
		data[1] = [pixelData bytes] +maskOffset;
	else
		data[1] = [pixelData bytes];
	BOOL		haveMask = YES; //maskOffset != 0;
	NSInteger	samplesPerPixel = haveMask ? 2 : 1;
	
	NSDrawBitmap( box, actualSize.width, actualSize.height,
					1 /*bps*/, samplesPerPixel /*spp*/, 1 /*bpp*/, (7 + actualSize.width) / 8 /*Bpr*/,
					YES /*planar*/, haveMask /*alpha*/,
					NSDeviceBlackColorSpace, data );
    
	return YES;
}

-(BOOL) drawInRect: (NSRect)rect
{
	NSRect		box = rect;
//	box.origin.x = truncf(rect.origin.x) +0.5;
//	box.origin.y = truncf(rect.origin.y) +0.5;
	
	const unsigned char*		data[5] = { 0 };
	data[0] = [pixelData bytes];
	if( maskOffset != 0 )
		data[1] = [pixelData bytes] +maskOffset;
	else
		data[1] = [pixelData bytes];
	BOOL		haveMask = YES; //maskOffset != 0;
	NSInteger	samplesPerPixel = haveMask ? 2 : 1;
	
	NSDrawBitmap( box, actualSize.width, actualSize.height,
					1 /*bps*/, samplesPerPixel /*spp*/, 1 /*bpp*/, (7 + actualSize.width) / 8 /*Bpr*/,
					YES /*planar*/, haveMask /*alpha*/,
					NSDeviceBlackColorSpace, data );
    
	return YES;
}

-(BOOL) hasAlpha
{
	return NO;
}


-(BOOL) isOpaque
{
	return YES;
}


-(NSString*)    colorSpaceName
{
	return NSDeviceBlackColorSpace;
}


-(NSInteger)  bitsPerSample
{
	return 1;
}

-(NSInteger)  pixelsWide
{
	return size.width;
}

-(NSInteger)  pixelsHigh
{
	return size.height;
}

-(NSSize)   size
{
	return size;
}

-(void) setSize: (NSSize)sz
{
	size = sz;
}

+(BOOL) canInitWithData: (NSData*)theData
{
    const char*	bytes = [theData bytes];
	return( bytes[0] == 'P' && bytes[1] == '4' && bytes[2] == '\n' );
}


+(NSArray*) imageUnfilteredFileTypes
{
    return [NSArray arrayWithObject: @"pbm"];
}


+(NSArray*) imageUnfilteredPasteboardTypes
{
    return [NSArray array];
}


@end


#endif