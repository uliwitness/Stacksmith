//
//  CCanvas.h
//  Stacksmith
//
//  Created by Uli Kusterer on 02/05/16.
//  Copyright © 2016 Uli Kusterer. All rights reserved.
//

/*
	Class to thinly wrap around typical platform-specific drawing
	calls Stacksmith needs in a way that the source code
	can be ported, but so Stacksmith still mostly uses the
	platform-specific types and code.
*/

#ifndef CCanvas_h
#define CCanvas_h


#import <CoreGraphics/CoreGraphics.h>


// Some internal, Mac-specific types. Clients shouldn't use these:
#if __OBJC__
@class NSColor;
@class NSGraphicsContext;
typedef NSColor	*					WILDNSColorPtr;
typedef NSGraphicsContext	*		WILDNSGraphicsContextPtr;
#else
typedef struct NSColor	*			WILDNSColorPtr;
typedef struct NSGraphicsContext*	WILDNSGraphicsContextPtr;
#endif


namespace Carlson {

// Typedefs and classes to turn some Mac types into names that clients may use:
typedef CGFloat TCoordinate;
typedef CGFloat TColorComponent;

class CPoint
{
public:
	CPoint() : mPoint(CGPointZero) {}
	CPoint( TCoordinate h, TCoordinate v ) : mPoint((CGPoint){h,v}) {}
	explicit CPoint( CGPoint macPoint ) : mPoint(macPoint) {}
	
	TCoordinate	GetH()					{ return mPoint.x; }
	TCoordinate	GetV()					{ return mPoint.y; }
	void		SetH( TCoordinate inH )	{ mPoint.x = inH; }
	void		SetV( TCoordinate inV )	{ mPoint.y = inV; }
	
protected:
	CGPoint	mPoint;

	friend class CRect;
	friend class CCanvas;
	friend class CPath;
};


class CSize
{
public:
	CSize() : mSize(CGSizeZero) {}
	CSize( TCoordinate width, TCoordinate height ) : mSize((CGSize){width,height}) {}
	explicit CSize( CGSize macSize ) : mSize(macSize) {}

	TCoordinate	GetWidth()							{ return mSize.width; }
	TCoordinate	GetHeight()							{ return mSize.height; }
	void		SetWidth( TCoordinate inWidth )		{ mSize.width = inWidth; }
	void		SetHeight( TCoordinate inHeight )	{ mSize.height = inHeight; }

protected:
	CGSize	mSize;
	
	friend class CRect;
	friend class CCanvas;
	friend class CPath;
	friend class CImageCanvas;
};


class CRect
{
public:
	CRect() : mRect(CGRectZero) {}
	CRect( TCoordinate h, TCoordinate v, TCoordinate width, TCoordinate height ) : mRect((CGRect){{h,v},{width,height}}) {}
	CRect( CPoint inOrigin, CSize inSize ) : mRect((CGRect){inOrigin.mPoint,inSize.mSize}) {}
	explicit CRect( const CGRect inRect ) : mRect(inRect) {}
	
	TCoordinate	GetH()					{ return mRect.origin.x; }
	TCoordinate	GetV()					{ return mRect.origin.y; }
	void		SetH( TCoordinate inH )	{ mRect.origin.x = inH; }
	void		SetV( TCoordinate inV )	{ mRect.origin.y = inV; }
	TCoordinate	GetWidth()							{ return mRect.size.width; }
	TCoordinate	GetHeight()							{ return mRect.size.height; }
	void		SetWidth( TCoordinate inWidth )		{ mRect.size.width = inWidth; }
	void		SetHeight( TCoordinate inHeight )	{ mRect.size.height = inHeight; }
	
	CPoint		GetOrigin()							{ return CPoint(mRect.origin); }
	void		SetOrigin( CPoint pos )				{ mRect.origin = pos.mPoint; }
	CSize		GetSize()							{ return CSize(mRect.size); }
	void		SetSize( CSize size )				{ mRect.size = size.mSize; }
	
protected:
	CGRect	mRect;

	friend class CCanvas;
	friend class CPath;
};


class CColor
{
public:
	CColor() : mColor(NULL) {}
	CColor( TColorComponent red, TColorComponent green, TColorComponent blue, TColorComponent alpha );
	explicit CColor( WILDNSColorPtr macColor );
	CColor( const CColor& inColor );
	~CColor();
	
	TColorComponent	GetRed() const;
	TColorComponent	GetGreen() const;
	TColorComponent	GetBlue() const;
	TColorComponent	GetAlpha() const;
	
	CColor& operator =( const CColor& inColor );
	
	WILDNSColorPtr	GetMacColor() const	{ return mColor; }
	
protected:
	WILDNSColorPtr		mColor;

	friend class CGraphicsState;
	friend class CCanvas;
};


class CPath
{
public:
	CPath();
	CPath( const CPath& inOriginal );
	~CPath();
	
	void	MoveToPoint( CPoint inPoint );
	void	LineToPoint( CPoint inPoint );
	void	ConnectEndToStart();
	
	void	MoveBy( CSize inDistance );
	void	ScaleBy( CSize inHScaleVScale );
	
	CPath& operator =( const CPath& inPath );
	
protected:
	CGMutablePathRef	mBezierPath;

	friend class CCanvas;
};


class CGraphicsState
{
public:
	CGraphicsState() { mGraphicsStateSeed = ++sGraphicsStateSeed; }
	
	void		SetLineColor( CColor inColor )				{ mLineColor = inColor; mGraphicsStateSeed = ++sGraphicsStateSeed; }
	void		SetFillColor( CColor inColor )				{ mFillColor = inColor; mGraphicsStateSeed = ++sGraphicsStateSeed; }
	void		SetLineThickness( TCoordinate inThickness )	{ mLineThickness = inThickness; mGraphicsStateSeed = ++sGraphicsStateSeed; }

protected:
	TCoordinate		mLineThickness;
	CColor			mLineColor;
	CColor			mFillColor;
	size_t			mGraphicsStateSeed;

	static size_t	sGraphicsStateSeed;
	
	friend class CCanvas;
};


class CImageCanvas;


class CCanvas
{
public:
	CCanvas() : mLastGraphicsStateSeed(0) {}
	virtual ~CCanvas() {}
	
	virtual CRect	GetRect() = 0;
	
	virtual void	BeginDrawing() {};
	virtual void	EndDrawing() {};
	
	virtual void	StrokeRect( const CRect& inRect, const CGraphicsState& inState );
	virtual void	FillRect( const CRect& inRect, const CGraphicsState& inState );
	virtual void	StrokeOval( const CRect& inRect, const CGraphicsState& inState );
	virtual void	FillOval( const CRect& inRect, const CGraphicsState& inState );
	virtual void	StrokeRoundRect( const CRect& inRect, TCoordinate inCornerRadius, const CGraphicsState& inState );
	virtual void	FillRoundRect( const CRect& inRect, TCoordinate inCornerRadius, const CGraphicsState& inState );
	virtual void	StrokeLineFromPointToPoint( const CPoint& inStart, const CPoint& inEnd, const CGraphicsState& inState );
	virtual void	StrokePath( const CPath& inPath, const CGraphicsState& inState );
	virtual void	FillPath( const CPath& inPath, const CGraphicsState& inState );
	virtual void	DrawImageInRect( const CImageCanvas& inImage, const CRect& inBox );
	virtual void	DrawImageAtPoint( const CImageCanvas& inImage, const CPoint& inPos );

protected:
	CCanvas&	operator =( const CCanvas& inOriginal ) { assert(false); return *this; }

	void		ApplyGraphicsStateIfNeeded( const CGraphicsState& inState );
	
	size_t		mLastGraphicsStateSeed;
};


// This is a concrete kind of CCanvas instance that platform-specific code will hand
//	to platform-agnostic code:
class CMacCanvas : public CCanvas
{
public:
	CMacCanvas( WILDNSGraphicsContextPtr inContext, CGRect inBounds );
	virtual ~CMacCanvas();
	
	virtual CRect	GetRect() { return CRect(mBounds); };
	
	virtual void	BeginDrawing();
	virtual void	EndDrawing();
	
protected:
	CGRect						mBounds;
	WILDNSGraphicsContextPtr	mContext;
	WILDNSGraphicsContextPtr	mPreviousContext;
};

} /* namespace Carlson */

#endif /* CCanvas_h */
