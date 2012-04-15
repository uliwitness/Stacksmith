//
//  WILDTools.h
//  Stacksmith
//
//  Created by Uli Kusterer on 03.04.10.
//  Copyright 2010 The Void Software. All rights reserved.
//

#import <AppKit/AppKit.h>


@protocol WILDSelectableView <NSObject>

-(void)	setNeedsDisplay: (BOOL)inState;
-(void)	setSelected: (BOOL)inState;

@optional
-(BOOL)	isSelected;
-(void)	animate: (id)sender;

@end


// The different tools the selection view can support:
enum
{
	WILDBrowseTool = 1,
	WILDPointerTool,
	WILDButtonTool,
	WILDFieldTool,
	WILDMoviePlayerTool,	//	5
	WILDSelectTool,
	WILDLassoTool,
	WILDPencilTool,
	WILDBrushTool,
	WILDEraserTool,			// 10
	WILDLineTool,
	WILDSprayTool,
	WILDRectangleTool,
	WILDRoundRectTool,
	WILDBucketTool,			// 15
	WILDOvalTool,
	WILDCurveTool,
	WILDTextTool,
	WILDRegularPolygonTool,
	WILDPolygonTool			// 20
};
typedef NSInteger	WILDTool;


#define	WILDFirstPaintTool		WILDSelectTool


// Helper class that has a timer and tells all currently selected views to
//	update. It also maintains the pattern phase used for the selection's
//	marching ants animation, so they all march the same way.

@interface WILDTools : NSObject
{
	NSMutableArray*		nonRetainingClients;
	NSInteger			animationPhase;
	NSTimer*			animationTimer;
	NSColor*			peekPattern;
	WILDTool	tool;
}

+(WILDTools*)			sharedTools;

+(BOOL)					toolIsPaintTool: (WILDTool)theTool;
+(NSCursor*)			cursorForTool: (WILDTool)theTool;

-(void)					animate: (id)sender;
-(NSInteger)			animationPhase;

-(void)					addClient: (id<WILDSelectableView>)theClient;
-(void)					removeClient: (id<WILDSelectableView>)theClient;
-(void)					deselectAllClients;

-(NSColor*)				peekPattern;

-(WILDTool)				currentTool;
-(void)					setCurrentTool: (WILDTool)theTool;

-(NSInteger)			numberOfSelectedClients;
-(NSSet*)				clients;

@end
