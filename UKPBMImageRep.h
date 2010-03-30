/* =============================================================================
    PROJECT:	Propagands
	FILE:       UKPBMImageRep.h
    
    COPYRIGHT:  (c) 2010 by M. Uli Kusterer, all rights reserved.
    
    AUTHORS:    M. Uli Kusterer - UK
    
	PURPOSE:	Draw one type of PBM P4 format image. It expects P4 on the
				first line, the size with a single space between each dimension
				on the second, and then the bitmap data on the next line.
				
				If there is a second PBM image in the file, and that image is
				the same size as the first, it will be used as an alpha mask.
    
    REVISIONS:
        2010-02-28  UK  Created.
   ========================================================================== */

// -----------------------------------------------------------------------------
//  Headers:
// -----------------------------------------------------------------------------

#import <Cocoa/Cocoa.h>


// -----------------------------------------------------------------------------
//  Image representation class for use in NSImage:
// -----------------------------------------------------------------------------

@interface UKPBMImageRep : NSImageRep
{
	NSData*		pixelData;
	NSSize		size;
	NSSize		actualSize;
	NSInteger	maskOffset;
}

@end
