//
//  WILDSearchPaths.m
//  Stacksmith
//
//  Created by Uli Kusterer on 17.04.11.
//  Copyright 2011 Uli Kusterer. All rights reserved.
//

#import "WILDSearchPaths.h"
#import "UKHelperMacros.h"


@implementation WILDSearchPaths

+(WILDSearchPaths*)	sharedSearchPaths
{
	static WILDSearchPaths*	sSharedSearchPaths = nil;
	if( !sSharedSearchPaths )
		sSharedSearchPaths = [[WILDSearchPaths alloc] init];
	return sSharedSearchPaths;
}


-(id)	init
{
    self = [super init];
    if (self)
	{
        mPaths = [[NSMutableArray alloc] init];
		[mPaths addObject: [[[NSBundle mainBundle] bundlePath] stringByDeletingLastPathComponent]];
		[mPaths addObject: [[NSBundle mainBundle] resourcePath]];
    }
    
    return self;
}

- (void)dealloc
{
	DESTROY_DEALLOC(mPaths);
	
    [super dealloc];
}


-(NSArray*)	paths
{
	return mPaths;
}


-(NSURL*)		stackURLForName: (NSString*)inStackName;
{
	NSString	*	homeStackPath = nil;
	NSString	*	standaloneStackPath = [[NSBundle mainBundle] pathForResource: inStackName ofType: @"xstk"];
	if( standaloneStackPath && [[NSFileManager defaultManager] fileExistsAtPath: standaloneStackPath] )
		homeStackPath = standaloneStackPath;
	else
		standaloneStackPath = [[NSBundle mainBundle] pathForResource: inStackName ofType: @""];
	
	if( standaloneStackPath && [[NSFileManager defaultManager] fileExistsAtPath: standaloneStackPath] )
		homeStackPath = standaloneStackPath;
	else
        standaloneStackPath = [[[[NSBundle mainBundle] bundlePath] stringByDeletingLastPathComponent] stringByAppendingPathComponent: [inStackName stringByAppendingString: @".xstk"]];
	
	if( standaloneStackPath && [[NSFileManager defaultManager] fileExistsAtPath: standaloneStackPath] )
		homeStackPath = standaloneStackPath;
	else
        homeStackPath = [[[[NSBundle mainBundle] bundlePath] stringByDeletingLastPathComponent] stringByAppendingPathComponent: inStackName];
	
	NSURL	*	stackURL = homeStackPath ? [NSURL fileURLWithPath: homeStackPath] : nil;
	
	return stackURL;
}


@end
