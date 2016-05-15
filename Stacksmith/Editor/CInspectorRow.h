//
//  CInspectorRow.h
//  Stacksmith
//
//  Created by Uli Kusterer on 15/05/16.
//  Copyright © 2016 Uli Kusterer. All rights reserved.
//

#ifndef CInspectorRow_h
#define CInspectorRow_h


#include <string>
#include <vector>


typedef enum
{
	EInspectorRowType_Invalid,
	EInspectorRowTypeSeparator,	// Section separator.
	EInspectorRowTypeLabel,		// Non-editable text field (like for showing ID).
	EInspectorRowTypeEditField,	// Editable text field (for showing & editing name).
	EInspectorRowTypeCheckbox,
	EInspectorRowTypePopup,
	EInspectorRowTypeColorPicker,
	EInspectorRowTypeAngleDial,
	EInspectorRowTypeButton
} TInspectorRowType;


class CInspectorRow
{
public:
	TInspectorRowType			mType;
	std::string					mLabel;
	std::string					mToolTip;
	std::vector<std::string>	mPopupChoices;
	std::string					mPropertyName;
};

#endif /* CInspectorRow_h */
