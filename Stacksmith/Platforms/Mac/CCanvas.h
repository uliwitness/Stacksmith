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
	
	TCoordinate	GetH() const				{ return mPoint.x; }
	TCoordinate	GetV() const			{ return mPoint.y; }
	void		SetH( TCoordinate inH )	{ mPoint.x = inH; }
	void		SetV( TCoordinate inV )	{ mPoint.y = inV; }
	
	const CGPoint&	GetMacPoint()		{ return mPoint; }	// Only for platform-specific code to get the underlying type back out.
	
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

	TCoordinate	GetWidth() const					{ return mSize.width; }
	TCoordinate	GetHeight() const					{ return mSize.height; }
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
	
	TCoordinate	GetH() const			{ return mRect.origin.x; }
	TCoordinate	GetV() const			{ return mRect.origin.y; }
	void		SetH( TCoordinate inH )	{ mRect.origin.x = inH; }
	void		SetV( TCoordinate inV )	{ mRect.origin.y = inV; }
	TCoordinate	GetWidth() const					{ return mRect.size.width; }
	TCoordinate	GetHeight() const					{ return mRect.size.height; }
	void		SetWidth( TCoordinate inWidth )		{ mRect.size.width = inWidth; }
	void		SetHeight( TCoordinate inHeight )	{ mRect.size.height = inHeight; }
	
	CPoint		GetOrigin() const					{ return CPoint(mRect.origin); }
	void		SetOrigin( CPoint pos )				{ mRect.origin = pos.mPoint; }
	CSize		GetSize() const						{ return CSize(mRect.size); }
	void		SetSize( CSize size )				{ mRect.size = size.mSize; }
	
	TCoordinate	GetHCenter()						{ return mRect.origin.x + (mRect.size.width / 2.0); }
	TCoordinate	GetVCenter()						{ return mRect.origin.y + (mRect.size.height / 2.0); }
	TCoordinate	GetMaxH()							{ return mRect.origin.x + mRect.size.width; }
	TCoordinate	GetMaxV()							{ return mRect.origin.y + mRect.size.height; }

	void		ResizeByMovingMinHEdgeTo( TCoordinate inH )	{ mRect.size.width += mRect.origin.x -inH; mRect.origin.x = inH; }
	void		ResizeByMovingMinVEdgeTo( TCoordinate inV )	{ mRect.size.height += mRect.origin.y -inV; mRect.origin.y = inV; }
	void		ResizeByMovingMaxHEdgeTo( TCoordinate inH )	{ mRect.size.width = inH -mRect.origin.x; }
	void		ResizeByMovingMaxVEdgeTo( TCoordinate inV )	{ mRect.size.height = inV -mRect.origin.y; }
	
	void		Inset( TCoordinate h, TCoordinate v )	{ mRect.origin.x += h; mRect.size.width -= h * 2.0; mRect.origin.y += v; mRect.size.height -= v * 2.0; }
	
	bool		ContainsPoint( const CPoint& inPos )	{ return( inPos.GetH() >= mRect.origin.x && inPos.GetH() < (mRect.origin.x + mRect.size.width) && inPos.GetV() >= mRect.origin.y && inPos.GetV() < (mRect.origin.y + mRect.size.height) ); }
	
	const CGRect&	GetMacRect() const	{ return mRect; }	// Only for platform-specific code to get the underlying type back out.
	
	static CRect	RectAroundPoints( const CPoint& a, const CPoint& b );
	
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
	bool	operator ==( const CColor& inColor ) const;
	
	WILDNSColorPtr	GetMacColor() const	{ return mColor; }
	
protected:
	WILDNSColorPtr		mColor;	// Always in NSCalibratedRGBColorSpace

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
	
	CRect	GetSurroundingRect() const;
	
	bool	IsEmpty() const;
	
	CPath& operator =( const CPath& inPath );
	
protected:
	CGMutablePathRef	mBezierPath;

	friend class CCanvas;
};


// The following are platform-agnostic wrappers around the
//	Mac data type. Size and values of these may be different
//	on other platforms.
typedef unsigned long TCompositingMode;

extern TCompositingMode	ECompositingModeAlphaComposite;
extern TCompositingMode	ECompositingModeCopy;


class CGraphicsState
{
public:
	CGraphicsState() { mGraphicsStateSeed = ++sGraphicsStateSeed; }
	
	void		SetLineColor( CColor inColor )				{ mLineColor = inColor; mGraphicsStateSeed = ++sGraphicsStateSeed; }
	CColor		GetLineColor() const						{ return mLineColor; }
	
	void		SetFillColor( CColor inColor )				{ mFillColor = inColor; mGraphicsStateSeed = ++sGraphicsStateSeed; }
	CColor		GetFillColor() const						{ return mFillColor; }

	void		SetLineThickness( TCoordinate inThickness )	{ mLineThickness = inThickness; mGraphicsStateSeed = ++sGraphicsStateSeed; }
	TCoordinate	GetLineThickness() const					{ return mLineThickness; }

	void				SetCompositingMode( TCoordinate inMode )	{ mCompositingMode = inMode; mGraphicsStateSeed = ++sGraphicsStateSeed; }
	TCompositingMode	GetCompositingMode() const					{ return mCompositingMode; }

protected:
	TCoordinate			mLineThickness = 1.0;
	CColor				mLineColor = CColor(0,0,0,65535);
	CColor				mFillColor = CColor(0,0,0,0);
	TCompositingMode	mCompositingMode = ECompositingModeAlphaComposite;
	size_t				mGraphicsStateSeed;

	static size_t		sGraphicsStateSeed;
	
	friend class CCanvas;
};


class CImageCanvas;


class CCanvas
{
public:
	CCanvas() : mLastGraphicsStateSeed(0) {}
	virtual ~CCanvas() {}
	
	virtual CRect	GetRect() const = 0;
	
	virtual void	BeginDrawing() {};
	virtual void	EndDrawing() {};
	
	virtual void	StrokeRect( const CRect& inRect, const CGraphicsState& inState );
	virtual void	FillRect( const CRect& inRect, const CGraphicsState& inState );
	virtual void	ClearRect( const CRect& inRect );
	virtual void	StrokeOval( const CRect& inRect, const CGraphicsState& inState );
	virtual void	FillOval( const CRect& inRect, const CGraphicsState& inState );
	virtual void	StrokeRoundRect( const CRect& inRect, TCoordinate inCornerRadius, const CGraphicsState& inState );
	virtual void	FillRoundRect( const CRect& inRect, TCoordinate inCornerRadius, const CGraphicsState& inState );
	virtual void	StrokeLineFromPointToPoint( const CPoint& inStart, const CPoint& inEnd, const CGraphicsState& inState );

	virtual CPath	RegularPolygon( const CPoint& centerPos, const CPoint& desiredCorner, TCoordinate numberOfCorners );

	virtual void	StrokePath( const CPath& inPath, const CGraphicsState& inState );
	virtual void	FillPath( const CPath& inPath, const CGraphicsState& inState );

	virtual void	DrawImageInRect( const CImageCanvas& inImage, const CRect& inBox );
	virtual void	DrawImageAtPoint( const CImageCanvas& inImage, const CPoint& inPos );
	
	virtual CColor	ColorAtPosition( const CPoint& pos );

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
	
	virtual CRect	GetRect() const { return CRect(mBounds); };
	
	virtual void	BeginDrawing();
	virtual void	EndDrawing();
	
protected:
	CGRect						mBounds;
	WILDNSGraphicsContextPtr	mContext;
	WILDNSGraphicsContextPtr	mPreviousContext;
};

} /* namespace Carlson */

#endif /* CCanvas_h */
