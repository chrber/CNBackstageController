//
//  CNBackstageDefinitions.h
//
//  Created by cocoa:naut on 09.11.12.
//  Copyright (c) 2012 cocoa:naut. All rights reserved.
//

/*
 The MIT License (MIT)
 Copyright © 2012 Frank Gregor, <phranck@cocoanaut.com>

 Permission is hereby granted, free of charge, to any person obtaining a copy
 of this software and associated documentation files (the “Software”), to deal
 in the Software without restriction, including without limitation the rights
 to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the Software is
 furnished to do so, subject to the following conditions:

 The above copyright notice and this permission notice shall be included in
 all copies or substantial portions of the Software.

 THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 THE SOFTWARE.
 */


#ifndef CNBackstageDefinitions_h
#define CNBackstageDefinitions_h


/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

typedef enum {
    CNToggleStateCollapsed = -1,                        // indictates that the current state of CNBackstageController is 'closed' (meaning: no applicationView is visible)
    CNToggleStateExpanded = 1                           // indictates that the current state of CNBackstageController is 'opened' (meaning: the applicationView is visible)
} CNToggleState;

typedef enum {
    CNToggleEdgeTop = 0,                                // on activating the CNBackstageController app, the current applicationView will appear on the top edge of the screen defined by the property `toggleDisplay`
    CNToggleEdgeBottom,                                 // on activating the CNBackstageController app, the current applicationView will appear on the bottom edge of the screen defined by the property `toggleDisplay`
    CNToggleEdgeLeft,                                   // on activating the CNBackstageController app, the current applicationView will appear on the left edge of the screen defined by the property `toggleDisplay`
    CNToggleEdgeRight,                                  // on activating the CNBackstageController app, the current applicationView will appear on the right edge of the screen defined by the property `toggleDisplay`
    CNToggleEdgeSplitHorizontal,                        // on activating the CNBackstageController app, the current applicationView will appear horizontal centered
    CNToggleEdgeSplitVertical                           // on activating the CNBackstageController app, the current applicationView will appear vertical centered
} CNToggleEdge;

enum {
    CNToggleSizeHalfScreen = 0,                         // in relation to the toggleEdge property the toggle size will be the half of a screen (height or width), or...
    CNToggleSizeQuarterScreen,                          // the quarter of a screen (height or width)
    CNToggleSizeThreeQuarterScreen,                     // three quarter of a screen (height or width)
    CNToggleSizeOneThirdScreen,                         // one third of a screen (height or width)
    CNToggleSizeTwoThirdsScreen                         // two thirds of a screen (height or width)
};
typedef struct {
    NSUInteger width;
    NSUInteger height;
} CNToggleSize;

typedef enum {
    CNToggleDisplayMain = 0,                            // Main Display means where the system statusbar is placed
    CNToggleDisplaySecond,
    CNToggleDisplayThird,
    CNToggleDisplayFourth
} CNToggleDisplay;

typedef enum {
    CNToggleVisualEffectNone            = 0 << 0,
    CNToggleVisualEffectOverlayBlack    = 1 << 0,
    CNToggleVisualEffectGaussianBlur    = 1 << 1
} CNToggleVisualEffect;

typedef enum {
    CNToggleAnimationEffectStatic = 0,
    CNToggleAnimationEffectFade,
    CNToggleAnimationEffectSlide
} CNToggleAnimationEffect;

typedef struct {
    CGFloat deltaX;
    CGFloat deltaY;
} CNToggleFrameDeltas;



/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/// NSUserDefaults keys
/// These keys are used to save the enum values from above. CNBackstageController will handle the serialization of it automatically.
extern NSString *CNToggleEdgePreferencesKey;
extern NSString *CNToggleSizePreferencesKey;
extern NSString *CNToggleSizeWidthPreferencesKey;
extern NSString *CNToggleSizeHeightPreferencesKey;
extern NSString *CNToggleDisplayPreferencesKey;
extern NSString *CNToggleVisualEffectPreferencesKey;
extern NSString *CNToggleAnimationEffectPreferencesKey;
extern NSString *CNToggleAlphaValuePreferencesKey;
extern NSString *CNToggleUseShadowsPreferencesKey;


/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/// Notifications
/// All these notifications contains the sending CNBackstageController as the `object` value. The userInfo dictionary contains two objects.
/// The first is the NSScreen object of the current toggle screen defined by the `toggleScreen` property using the dictionary key `CNToggleScreenUserInfoKey`.
/// The second is the toggle edge the application view will appear defined by the `toggleEdge` property, wrapped in a NSNumber object using the dictionary key `CNToggleEdgeUserInfoKey`.
extern NSString *CNBackstageControllerWillExpandOnScreenNotification;
extern NSString *CNBackstageControllerDidExpandOnScreenNotification;
extern NSString *CNBackstageControllerWillCollapseOnScreenNotification;
extern NSString *CNBackstageControllerDidCollapseOnScreenNotification;
extern NSString *CNBackstageControllerWillDragOnScreenNotification;
extern NSString *CNBackstageControllerDidDragOnScreenNotification;


/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/// Keys that are used for the userInfo dictionary in the notifications from above
extern NSString *CNToggleScreenUserInfoKey;
extern NSString *CNToggleEdgeUserInfoKey;


/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/// Convenience Functions
extern CNToggleSize CNMakeToggleSize(NSUInteger aWidth, NSUInteger aHeight);
extern CNToggleFrameDeltas CNMakeToggleFrameDeltas(CGFloat deltaX, CGFloat deltaY);


#endif
