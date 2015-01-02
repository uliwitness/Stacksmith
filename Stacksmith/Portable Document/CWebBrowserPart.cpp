//
//  CWebBrowserPart.cpp
//  Stacksmith
//
//  Created by Uli Kusterer on 2014-01-02.
//  Copyright (c) 2014 Uli Kusterer. All rights reserved.
//

#include "CWebBrowserPart.h"
#include "CTinyXMLUtils.h"


using namespace Carlson;


void	CWebBrowserPart::LoadPropertiesFromElement( tinyxml2::XMLElement * inElement )
{
	CVisiblePart::LoadPropertiesFromElement( inElement );
	
	mCurrentURL.erase();
	CTinyXMLUtils::GetStringNamed( inElement, "currentURL", mCurrentURL );
}


void	CWebBrowserPart::SavePropertiesToElement( tinyxml2::XMLElement * inElement )
{
	CVisiblePart::SavePropertiesToElement( inElement );
	
	tinyxml2::XMLDocument	*	document = inElement->GetDocument();
	tinyxml2::XMLElement	*	elem = document->NewElement("currentURL");
	elem->SetText(GetCurrentURL().c_str());
	inElement->InsertEndChild(elem);
}


void	CWebBrowserPart::WakeUp()
{
	LoadCurrentURL( mCurrentURL );
}


bool	CWebBrowserPart::GetPropertyNamed( const char* inPropertyName, size_t byteRangeStart, size_t byteRangeEnd, LEOContext* inContext, LEOValuePtr outValue )
{
	if( strcasecmp("currentURL", inPropertyName) == 0 )
	{
		LEOInitStringValue( outValue, GetCurrentURL().c_str(), GetCurrentURL().size(), kLEOInvalidateReferences, inContext );
	}
	else
		return CVisiblePart::GetPropertyNamed( inPropertyName, byteRangeStart, byteRangeEnd, inContext, outValue );
	return true;
}


bool	CWebBrowserPart::SetValueForPropertyNamed( LEOValuePtr inValue, LEOContext* inContext, const char* inPropertyName, size_t byteRangeStart, size_t byteRangeEnd )
{
	if( strcasecmp("currentURL", inPropertyName) == 0 )
	{
		char		msgBuf[1024] = {0};
		const char* msgStr = LEOGetValueAsString( inValue, msgBuf, sizeof(msgBuf), inContext );
		if( !msgStr || (inContext->flags & kLEOContextKeepRunning) == 0 )
			return true;
		LoadCurrentURL( msgStr );
	}
	else
		return CVisiblePart::SetValueForPropertyNamed( inValue, inContext, inPropertyName, byteRangeStart, byteRangeEnd );
	return true;
}


void	CWebBrowserPart::DumpProperties( size_t inIndentLevel )
{
	const char*	indentStr = IndentString(inIndentLevel);
	
	CVisiblePart::DumpProperties( inIndentLevel );
	
	printf( "%scurrentURL = %s\n", indentStr, mCurrentURL.c_str() );
}