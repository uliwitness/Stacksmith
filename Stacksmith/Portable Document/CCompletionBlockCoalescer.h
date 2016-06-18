//
//  CCompletionBlockCoalescer.h
//  Stacksmith
//
//  Created by Uli Kusterer on 08/06/16.
//  Copyright © 2016 Uli Kusterer. All rights reserved.
//

#ifndef CCompletionBlockCoalescer_h
#define CCompletionBlockCoalescer_h

/*
	Need to call a completion block when the last of several asynchronous
	operations have finished?
	This object will ignore all but the last call. You can also indicate
	an error and make only that error call go through and all others to
	be ignored by calling Abort() instead.
*/

#include <climits>
#include <memory>
#include <functional>


namespace Carlson
{

template<class paramT>
class CCompletionBlockCoalescer
{
public:
	CCompletionBlockCoalescer( size_t numCallsToCombine, std::function<void(paramT)> block ) : mNumCallsToCombine(numCallsToCombine), mBlock(block) {}
	
	void		Abort( paramT ) { mNumCallsToCombine = SIZE_T_MAX; }
	void		Success( paramT inParam ) { if( mNumCallsToCombine == SIZE_T_MAX ) return; if( (--mNumCallsToCombine) == 0 ) mBlock( inParam ); }
	
protected:
	size_t							mNumCallsToCombine;
	std::function<void(paramT)>		mBlock;
};

} /* namespace Carlson */

#endif /* CCompletionBlockCoalescer_h */
