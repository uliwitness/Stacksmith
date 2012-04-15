//
//  WILDPictureView.m
//  Propaganda
//
//  Created by Uli Kusterer on 21.03.10.
//  Copyright 2010 The Void Software. All rights reserved.
//

#import "WILDPictureView.h"
#import "WILDTools.h"
#import "WILDPartView.h"


@implementation WILDPictureView

-(id)	hitTest: (NSPoint)aPoint
{
	if( currentTool != nil )
	{
		if( NSPointInRect( aPoint, [self visibleRect] ) )
			return self;
	}
	
	return nil;
}

@end
