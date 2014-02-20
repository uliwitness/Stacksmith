//
//  CWebBrowserPart.h
//  Stacksmith
//
//  Created by Uli Kusterer on 2014-01-02.
//  Copyright (c) 2014 Uli Kusterer. All rights reserved.
//

#ifndef __Stacksmith__CWebBrowserPart__
#define __Stacksmith__CWebBrowserPart__

#include "CVisiblePart.h"

namespace Carlson {

class CWebBrowserPart : public CVisiblePart
{
public:
	explicit CWebBrowserPart( CLayer *inOwner ) : CVisiblePart( inOwner ) {};
	
	virtual bool			GetPropertyNamed( const char* inPropertyName, size_t byteRangeStart, size_t byteRangeEnd, LEOContext* inContext, LEOValuePtr outValue );
	virtual bool			SetValueForPropertyNamed( LEOValuePtr inValue, LEOContext* inContext, const char* inPropertyName, size_t byteRangeStart, size_t byteRangeEnd );
	virtual void			SetCurrentURL( const std::string& inURL )	{ mCurrentURL = inURL; IncrementChangeCount(); }	// Doesn't load the URL! Just called once it is loaded.
	virtual std::string		GetCurrentURL()								{ return mCurrentURL; };
	virtual void			WakeUp();
	
protected:
	virtual void			LoadPropertiesFromElement( tinyxml2::XMLElement * inElement );
	virtual void			SavePropertiesToElementOfDocument( tinyxml2::XMLElement * inElement, tinyxml2::XMLDocument * inDocument );
	
	virtual void			LoadCurrentURL( const std::string& inURL )	{ /* Download, and then: */ SetCurrentURL(inURL); }
	
	virtual const char*		GetIdentityForDump()	{ return "Web Browser"; };
	virtual void			DumpProperties( size_t inIndent );

protected:
	std::string		mCurrentURL;
};

}

#endif /* defined(__Stacksmith__CWebBrowserPart__) */
