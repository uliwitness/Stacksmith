//
//  WILDIOSMainViewController.h
//  Stacksmith
//
//  Created by Uli Kusterer on 17.06.17.
//  Copyright © 2017 Uli Kusterer. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface WILDIOSMainViewController : UIViewController

+(WILDIOSMainViewController*) sharedMainViewController;

-(void) goHome;
-(void)	openURL: (NSURL*)theFile;

@end

