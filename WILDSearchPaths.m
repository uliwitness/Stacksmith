//
//  WILDSearchPaths.m
//  Stacksmith
//
//  Created by Uli Kusterer on 17.04.11.
//  Copyright 2011 Uli Kusterer. All rights reserved.
//

#import "WILDSearchPaths.h"


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

@end
