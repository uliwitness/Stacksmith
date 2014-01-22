//
//  CMoviePlayerPart.h
//  Stacksmith
//
//  Created by Uli Kusterer on 2014-01-02.
//  Copyright (c) 2014 Uli Kusterer. All rights reserved.
//

#ifndef __Stacksmith__CMoviePlayerPart__
#define __Stacksmith__CMoviePlayerPart__

#include "CVisiblePart.h"

namespace Carlson {

class CMoviePlayerPart : public CVisiblePart
{
public:
	explicit CMoviePlayerPart( CLayer *inOwner ) : CVisiblePart( inOwner ), mStarted(false), mControllerVisible(false) {};
	
	virtual bool			GetPropertyNamed( const char* inPropertyName, size_t byteRangeStart, size_t byteRangeEnd, LEOContext* inContext, LEOValuePtr outValue );
	virtual bool			SetValueForPropertyNamed( LEOValuePtr inValue, LEOContext* inContext, const char* inPropertyName, size_t byteRangeStart, size_t byteRangeEnd );
	
protected:
	virtual void			LoadPropertiesFromElement( tinyxml2::XMLElement * inElement );
	virtual void			SavePropertiesToElementOfDocument( tinyxml2::XMLElement * inElement, tinyxml2::XMLDocument * inDocument );
	
	virtual const char*		GetIdentityForDump()	{ return "Movie Player"; };
	virtual void			DumpProperties( size_t inIndent );
	
	bool					GetStarted()								{ return mStarted; };
	virtual void			SetStarted( bool inStart )					{ mStarted = inStart; };
	bool					GetControllerVisible()						{ return mControllerVisible; };
	virtual void			SetControllerVisible( bool inStart )		{ mControllerVisible = inStart; };
	virtual LEOInteger		GetCurrentTime()							{ return 0LL; };
	virtual void			SetCurrentTime( LEOInteger inTicks )		{};
	std::string				GetMediaPath()								{ return mMediaPath; };
	virtual void			SetMediaPath( const std::string& inPath )	{ mMediaPath = inPath; };

protected:
	std::string			mMediaPath;
	bool				mControllerVisible;
	bool				mStarted;
};

}

#endif /* defined(__Stacksmith__CMoviePlayerPart__) */
