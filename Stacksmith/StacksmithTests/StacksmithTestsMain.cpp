//
//  StacksmithTestsMain.cpp
//  StacksmithTests
//
//  Created by Uli Kusterer on 2014-01-26.
//  Copyright (c) 2014 Uli Kusterer. All rights reserved.
//

#include <iostream>
#include "CAttributedString.h"
#include "CStyleSheet.h"


using namespace Carlson;


static size_t	sFailed = 0, sPassed = 0;


void	WILDTest( const char* expr, const char* found, const char* expected )
{
	if( strcmp(expected, found) == 0 )
	{
		std::cout << "note: " << expr << std::endl;
		sPassed++;
	}
	else
	{
		std::cout << "error: " << expr << " -> \"" << expected << "\" == \"" << found << "\"" << std::endl;
		sFailed++;
	}
}


template<class T>
void	WILDTest( const char* expr, T found, T expected )
{
	if( expected == found )
	{
		std::cout << "note: " << expr << std::endl;
		sPassed++;
	}
	else
	{
		std::cout << "error: " << expr << " -> " << expected << " == " << found << std::endl;
		sFailed++;
	}
}



int main(int argc, const char * argv[])
{
	{
		CAttributedString		attrStr;
		CStyleSheet				styles;
		tinyxml2::XMLDocument	doc;
		
		doc.Parse( "<text>This is <span class=\"style1\">absolutely</span><span class=\"style2\"> fabulous</span></text>" );
		
		tinyxml2::XMLElement*	elem = doc.FirstChildElement( "text" );
		
		styles.LoadFromStream( ".style1 { font-weight: bold; } .style2 { text-style: italic; }" );
		std::string	css = styles.GetCSS();
		
		WILDTest( "Read & Output round trip.", css.c_str(), ".style1\n{\n	font-weight: bold;\n}\n.style2\n{\n	text-style: italic;\n}\n" );
		WILDTest( "Number of classes", styles.GetNumClasses(), size_t(2) );
		WILDTest( ".style1 is there", styles.GetClassAtIndex(0).c_str(), ".style1" );
		auto styleOne = styles.GetStyleForClass("style1");
		WILDTest( ".style1 contains 1 style", styleOne.size(), size_t(1) );
		WILDTest( ".style1 is bold", styleOne["font-weight"].c_str(), "bold" );
		WILDTest( ".style2 is there", styles.GetClassAtIndex(1).c_str(), ".style2" );
		auto styleTwo = styles.GetStyleForClass("style2");
		WILDTest( ".style2 contains 1 style", styleTwo.size(), size_t(1) );
		WILDTest( ".style2 is italic", styleTwo["text-style"].c_str(), "italic" );
		
		attrStr.LoadFromElementWithStyles( elem , styles );
		
		CStyleSheet				writtenStyles;
		CAttributedString		loadedStr;
		tinyxml2::XMLDocument	doc2;
		tinyxml2::XMLElement*	elem2 = doc2.NewElement( "text" );
		doc2.InsertEndChild(elem2);
		attrStr.SaveToXMLDocumentElementStyleSheet( &doc2, elem2, &writtenStyles );

		WILDTest( "Output & Read round trip.", writtenStyles.GetCSS().c_str(), ".style1\n{\n	font-weight: bold;\n}\n.style2\n{\n	text-style: italic;\n}\n" );
		WILDTest( "Number of classes", writtenStyles.GetNumClasses(), size_t(2) );
		WILDTest( ".style1 is there", writtenStyles.GetClassAtIndex(0).c_str(), ".style1" );
		styleOne = writtenStyles.GetStyleForClass("style1");
		WILDTest( ".style1 contains 1 style", styleOne.size(), size_t(1) );
		WILDTest( ".style1 is bold", styleOne["font-weight"].c_str(), "bold" );
		WILDTest( ".style2 is there", writtenStyles.GetClassAtIndex(1).c_str(), ".style2" );
		styleTwo = writtenStyles.GetStyleForClass("style2");
		WILDTest( ".style2 contains 1 style", styleTwo.size(), size_t(1) );
		WILDTest( ".style2 is italic", styleTwo["text-style"].c_str(), "italic" );
	}
	
    return (int)sFailed;
}

