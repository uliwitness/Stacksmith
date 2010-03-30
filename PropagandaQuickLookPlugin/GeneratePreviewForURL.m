#include <CoreFoundation/CoreFoundation.h>
#include <CoreServices/CoreServices.h>
#include <QuickLook/QuickLook.h>
#import <Cocoa/Cocoa.h>


/* -----------------------------------------------------------------------------
   Generate a preview for file

   This function's job is to create preview for designated file
   ----------------------------------------------------------------------------- */

OSStatus GeneratePreviewForURL(void *thisInterface, QLPreviewRequestRef preview, CFURLRef url, CFStringRef contentTypeUTI, CFDictionaryRef options)
{
	NSAutoreleasePool*	pool = [[NSAutoreleasePool alloc] init];
	
		NSImage*		theImage = [[[NSImage alloc] initWithContentsOfURL: [(NSURL*)url URLByAppendingPathComponent: @"preview.tiff"]] autorelease];
		
		CGContextRef		theContext = QLPreviewRequestCreateContext( preview, NSSizeToCGSize([theImage size]), true, NULL );
		[NSGraphicsContext saveGraphicsState];
		NSGraphicsContext*	ctx = [NSGraphicsContext graphicsContextWithGraphicsPort: theContext flipped: NO];
		[NSGraphicsContext setCurrentContext: ctx];
		
			[theImage drawAtPoint: NSZeroPoint fromRect: NSZeroRect operation: NSCompositeCopy fraction: 1.0];
			
		[NSGraphicsContext restoreGraphicsState];
		QLPreviewRequestFlushContext( preview, theContext );
		CFRelease( theContext );
		
	[pool release];
	
    return noErr;
}

void CancelPreviewGeneration(void* thisInterface, QLPreviewRequestRef preview)
{
    // implement only if supported
}
