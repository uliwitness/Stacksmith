//
//  WILDPlayerView.h
//  Stacksmith
//
//  Created by Uli Kusterer on 2014-03-02.
//  Copyright (c) 2014 Uli Kusterer. All rights reserved.
//

#import <AVKit/AVKit.h>
#include "CMoviePlayerPart.h"


@interface WILDPlayerView : AVPlayerView

@property (assign) Carlson::CMoviePlayerPart*	owningPart;

@end
