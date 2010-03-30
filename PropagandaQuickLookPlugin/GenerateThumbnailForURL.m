#include <CoreFoundation/CoreFoundation.h>
#include <CoreServices/CoreServices.h>
#include <QuickLook/QuickLook.h>
#import <Cocoa/Cocoa.h>
#import <Quartz/Quartz.h>


@interface DummyClass : NSObject {}

@end

@implementation DummyClass

@end




/* -----------------------------------------------------------------------------
    Generate a thumbnail for file

   This function's job is to create thumbnail for designated file as fast as possible
   ----------------------------------------------------------------------------- */

OSStatus GenerateThumbnailForURL(void *thisInterface, QLThumbnailRequestRef thumbnail, CFURLRef url, CFStringRef contentTypeUTI, CFDictionaryRef options, CGSize maxSize)
{
	NSAutoreleasePool*	pool = [[NSAutoreleasePool alloc] init];
	
		NSURL*	thumbURL = [(NSURL*)url URLByAppendingPathComponent: @"thumbnail.tiff"];
		
		NSDictionary*		optionsDict = [NSDictionary dictionaryWithObjectsAndKeys: (NSNumber*)kCFBooleanFalse, kQLThumbnailOptionIconModeKey, nil];
		QLThumbnailRequestSetImageAtURL( thumbnail, (CFURLRef) thumbURL, (CFDictionaryRef)optionsDict );
		
	[pool release];
	
    return noErr;
}



void CancelThumbnailGeneration(void* thisInterface, QLThumbnailRequestRef thumbnail)
{
    // implement only if supported
}
