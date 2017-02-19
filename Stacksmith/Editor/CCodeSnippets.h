//
//  CCodeSnippets.h
//  Stacksmith
//
//  Created by Uli Kusterer on 18/02/2017.
//  Copyright © 2017 Uli Kusterer. All rights reserved.
//

#pragma once

#include <vector>
#include <string>
#include "CConcreteObject.h"


namespace Carlson
{
	class CCodeSnippetsEntry
	{
	public:
		virtual ~CCodeSnippetsEntry()	{}
		
		virtual std::string	GetName() = 0;
	};


	class CCodeSnippetsBlockEntry : public CCodeSnippetsEntry
	{
	public:
		virtual std::string	GetName() override	{ return mName; }
		virtual void			SetName( std::string inName )	{ mName = inName; }
		std::string	GetImageName()				{ return mImageName; }
		virtual void			SetImageName( std::string inImageName )	{ mImageName = inImageName; }
	
		CAddHandlerListEntry	mHandlerEntry;
		
	protected:
		std::string	mName;
		std::string mImageName;
	};


	class CCodeSnippetsSection : public CCodeSnippetsEntry
	{
	public:
		virtual std::string		GetName() override	{ return mName; }
		virtual void			SetName( std::string inName )	{ mName = inName; }
		
		size_t					GetNumBlockEntries()					{ return mBlocks.size(); }
		CCodeSnippetsBlockEntry&	GetBlockEntryAt( size_t inItemIndex )	{ return mBlocks[inItemIndex]; }
		void	AddBlockEntry( const CCodeSnippetsBlockEntry& inBlock )	{ mBlocks.push_back( inBlock ); }
	
	protected:
		std::string	mName;
		std::vector<CCodeSnippetsBlockEntry>	mBlocks;
	};

	class CCodeSnippets
	{
	public:
		void	Clear()	{ mSections.clear(); }
		
		CCodeSnippetsSection&		GetSectionAt( size_t inSection ) { return mSections[inSection]; }
		CCodeSnippetsBlockEntry&	GetBlockEntryAt( size_t inSection, size_t inItemIndex ) { return mSections[inSection].GetBlockEntryAt( inItemIndex); }
		
		size_t	GetNumSections()	{ return mSections.size(); }
		CCodeSnippetsSection*	AddSection( const CCodeSnippetsSection& inSection )	{ mSections.push_back( inSection ); return &(mSections.back()); }
		
		void	AddSectionsAndBlocksFromHandlerList( const std::vector<CAddHandlerListEntry>& inHandlerList );
		
	protected:
		std::vector<CCodeSnippetsSection> mSections;
	};

} // namespace Carlson
