//
//  CFieldPartIOS.hpp
//  Stacksmith
//
//  Created by Uli Kusterer on 20.06.17.
//  Copyright © 2017 Uli Kusterer. All rights reserved.
//

#ifndef CFieldPartIOS_hpp
#define CFieldPartIOS_hpp

#include "CFieldPart.h"
#include "CIOSPartBase.h"


@class WILDFieldActionTarget;


namespace Carlson
{
	
	class CFieldPartIOS : public CFieldPart, public CIOSPartBase
	{
	public:
		CFieldPartIOS( CLayer *inOwner ) : CFieldPart(inOwner) {}
		
		virtual UIView	*	GetView() override { return mView; };
		virtual void		CreateViewIn( UIView * inParentView ) override;
		virtual void		DestroyView() override;
		
		virtual void		GetSelectedRange( LEOChunkType* outType, size_t* outStartOffs, size_t* outEndOffs ) override;
		virtual void		SetSelectedRange( LEOChunkType inType, size_t inStartOffs, size_t inEndOffs ) override;

	protected:
		static size_t		UTF32OffsetFromUTF16OffsetInCocoaString( NSInteger inCharOffs, NSString* cocoaStr );
		static NSInteger	UTF16OffsetFromUTF32OffsetInCocoaString( size_t inUTF32Offs, NSString* cocoaStr );
		static size_t		UTF8OffsetFromUTF16OffsetInCocoaString( NSInteger inCharOffs, NSString* cocoaStr );

		UITextField				*	mView = nil;
		WILDFieldActionTarget	*	mActionTarget = nil;
	};
	
} /* namespace Carlson */

#endif /* CFieldPartIOS_hpp */
