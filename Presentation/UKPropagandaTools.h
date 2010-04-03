//
//  UKPropagandaTools.h
//  Stacksmith
//
//  Created by Uli Kusterer on 03.04.10.
//  Copyright 2010 The Void Software. All rights reserved.
//

#import <Foundation/Foundation.h>


@protocol UKPropagandaSelectableView <NSObject>

-(void)	setNeedsDisplay: (BOOL)inState;
-(void)	setSelected: (BOOL)inState;

@end


// The different tools the selection view can support:
enum
{
	UKPropagandaBrowseTool = 1,
	UKPropagandaButtonTool,
	UKPropagandaFieldTool,
	UKPropagandaSelectTool,
	UKPropagandaLassoTool,
	UKPropagandaPencilTool,
	UKPropagandaBrushTool,
	UKPropagandaEraserTool,
	UKPropagandaLineTool,
	UKPropagandaSprayTool,
	UKPropagandaRectangleTool,
	UKPropagandaRoundRectTool,
	UKPropagandaBucketTool,
	UKPropagandaOvalTool,
	UKPropagandaCurveTool,
	UKPropagandaTextTool,
	UKPropagandaRegularPolygonTool,
	UKPropagandaPolygonTool
};
typedef NSInteger	UKPropagandaTool;


// Helper class that has a timer and tells all currently selected views to
//	update. It also maintains the pattern phase used for the selection's
//	marching ants animation, so they all march the same way.

@interface UKPropagandaTools : NSObject
{
	NSMutableArray*		nonRetainingClients;
	NSInteger			animationPhase;
	NSTimer*			animationTimer;
	NSColor*			peekPattern;
	UKPropagandaTool	tool;
}

+(UKPropagandaTools*)	propagandaTools;

+(BOOL)					toolIsPaintTool: (UKPropagandaTool)theTool;
+(NSCursor*)			cursorForTool: (UKPropagandaTool)theTool;

-(void)					animate: (id)sender;
-(NSInteger)			animationPhase;

-(void)					addClient: (id<UKPropagandaSelectableView>)theClient;
-(void)					removeClient: (id<UKPropagandaSelectableView>)theClient;
-(void)					deselectAllClients;

-(NSColor*)				peekPattern;

-(UKPropagandaTool)		currentTool;
-(void)					setCurrentTool: (UKPropagandaTool)theTool;


-(NSInteger)			numberOfSelectedClients;

@end
