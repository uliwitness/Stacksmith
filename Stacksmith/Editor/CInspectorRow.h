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
	EInspectorRowTypeSeparator,			// Section separator.
	EInspectorRowTypeLabel,				// Non-editable text field (like for showing ID).
	EInspectorRowTypeEditField,			// Editable text field (for showing & editing name).
	EInspectorRowTypeCheckbox,			// A checkbox button with the label to its right.
	EInspectorRowTypePopup,				// A popup menu listing the items from mPopUpChoices.
	EInspectorRowTypeColorPicker,		// A color swatch that can be clicked to change its color.
	EInspectorRowTypeAngleDial,			// A dial for indicating an angle (part rotation or shadow angle).
	EInspectorRowTypeButton,			// A Pushbutton with mLabel as its title.
	EInspectorRowTypeThreeLabelColumns	// 3 columns, each containing a label and a value below it (taken from mPopUpChoices).
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
