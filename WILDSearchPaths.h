//
//  WILDSearchPaths.h
//  Stacksmith
//
//  Created by Uli Kusterer on 17.04.11.
//  Copyright 2011 Uli Kusterer. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface WILDSearchPaths : NSObject
{
	NSMutableArray*		mPaths;
}

+(WILDSearchPaths*)	sharedSearchPaths;

-(NSString*)		paths;

@end
