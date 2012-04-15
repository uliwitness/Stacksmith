//
//  WILDInputPanelController.h
//  Stacksmith
//
//  Created by Uli Kusterer on 04.05.11.
//  Copyright 2011 Uli Kusterer. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface WILDInputPanelController : NSObject
{
@private
    NSPanel		*	window;
	NSTextField	*	answerField;
}

@property (retain) NSWindow		*	window;
@property (retain) NSTextField	*	answerField;

+(id)	inputPanelWithPrompt: (NSString*)inPrompt answer: (NSString*)inAnswer;

-(id)	initWithPrompt: (NSString*)inPrompt answer: (NSString*)inAnswer;

-(NSInteger)	runModal;

-(NSString*)	answerString;

-(IBAction)		doOKButton: (id)sender;
-(IBAction)		doCancelButton: (id)sender;

@end
