//
//  CNBackstageController.h
//
//  Created by cocoanaut.com on 10.04.12.
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

#import <Cocoa/Cocoa.h>
#import "NSScreen+CNBackstageController.h"




typedef enum {
    CNToggleEdgeTop = 0,
    CNToggleEdgeBottom,
    CNToggleEdgeLeft,
    CNToggleEdgeRight,
    CNToggleEdgeSplitHorizontal,
    CNToggleEdgeSplitVertical
} CNToggleEdge;

enum {
    CNToggleSizeHalfScreen = 0,                         // in relation to the toggleEdge property the toggle size will be the half of a screen (height or width), or...
    CNToggleSizeQuarterScreen,                          // the quarter of a screen (height or width)
    CNToggleSizeThreeQuarterScreen,                     // three quarter of a screen (height or width)
    CNToggleSizeOneThirdScreen,                         // one third of a screen (height or width)
    CNToggleSizeTwoThirdsScreen                         // two thirds of a screen (height or width)
};
typedef NSInteger CNToggleSize;

typedef enum {
    CNToggleDisplayMain = 0,                            // Main Display means where the system statusbar is placed
    CNToggleDisplaySecond,
    CNToggleDisplayThird,
    CNToggleDisplayFourth
} CNToggleDisplay;

typedef enum {
    CNToggleEffectNone         = 0x00,
    CNToggleEffectBlackOverlay = 0x01
} CNToggleEffect;

typedef enum {
    CNApplicationViewBehaviorStatic = 1 << 0,
    CNApplicationViewBehaviorFade   = 1 << 1,
    CNApplicationViewBehaviorSlide  = 1 << 2
} CNApplicationViewBehavior;




/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - CNBackstage Delegate

/**
 The CNBackstage Delegate provides a set of methods the user can implement to control the functionality of
 <CNBackstageController>.
 */

@protocol CNBackstageDelegate <NSObject>
@optional

/**
 Informs the delegate that the screen `toggleScreen` will toggle on edge `toggleEdge`.

 @param toggleScreen    The screen that will toggle the CNBackstageController's view.
 @param toggleEdge      The edge the CNBackstageController's view will appear.
 */
- (void)screen:(NSScreen *)toggleScreen willToggleOnEdge:(CNToggleEdge)toggleEdge;

/**
 Informs the delegate that the screen `toggleScreen` did toggle on edge `toggleEdge`.

 @param toggleScreen    The screen that did toggle the CNBackstageController's view.
 @param toggleEdge      The edge the CNBackstageController's view did appear.
 */
- (void)screen:(NSScreen *)toggleScreen didToggleOnEdge:(CNToggleEdge)toggleEdge;
@end




/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - CNBackstageController


/**
 `CNBackstageController` is an derivative of `NSWindowController` and a special impelementation to show you the content
 you would like to see. The goal of `CNBackstageController` is to provide the developer a slightly different interface
 for presenting an application. It mimics the behavior you've just seen Notification Center of Mountain Lion.
 Instead of showing a normal window and menu bar an application build with `CNBackstageController` offer you a *behind the Finder*-like
 desktop and will be shown with smooth animations. The common use is an application nested as a statusbar item that is not 
 visible in the Dock.

 The use of `CNBackstageController` is quite simple and straight forward. If you would like to create a new aplication project
 that uses `CNBackstageController` just follow these steps:
 
 1. Open Xcode and create a new *Cocoa Application* project. Now click on the *MainMenu.xib* file in your Project Browser, locate
    the Object Browser and delete all included items, **but** the **Application Delegate**  object.
    
    It should look like this one:
 
    <img src="/images/XcodeObjectsBrowser.png">

 */


//@protocol CNBackstageDelegate;
@interface CNBackstageController : NSWindowController

/** @name Initialization */

/**
 delegate
 */
@property (strong) id<CNBackstageDelegate>delegate;


/**
 initWithApplicationViewController:
 */
- (id)initWithApplicationViewController:(NSViewController *)applicationViewController;




/** @name Properties */

/**
 The edge where the view of `applicationWindow` should appear.
 
 This property is controlled by one of four possible values:
 
    enum {
        CNToggleEdgeTop = 0,
        CNToggleEdgeBottom,
        CNToggleEdgeLeft,
        CNToggleEdgeRight,
        CNToggleEdgeSplitHorizontal,
        CNToggleEdgeSplitVertical
    };
    typedef NSUInteger CNToggleEdge;

 `CNToggleEdgeTop`<br>
 The applicationView will appear from the top side of the screen that was selected by the property `toggleDisplay`.<br>
 This is the default value.
 
 `CNToggleEdgeBottom`<br>
 The applicationView will appear from the bottom side of the screen that was selected by the property `toggleDisplay`.
 
 `CNToggleEdgeLeft`<br>
 The applicationView will appear from the left side of the screen that was selected by the property `toggleDisplay`.
 
 `CNToggleEdgeRight`<br>
 The applicationView will appear from the right side of the screen that was selected by the property `toggleDisplay`.
 
 `CNToggleEdgeSplitHorizontal`<br>
 Not yet implemented.
 
 `CNToggleEdgeSplitVertical`<br>
 Not yet implemented.
 */
@property (assign, nonatomic) CNToggleEdge toggleEdge;

/**
 Defines the width the `applicationWindow`'s view should move in.
 
 This property knows two pre defined constants:
 
    enum {
        CNToggleSizeHalfScreen = 0,
        CNToggleSizeQuarterScreen,
        CNToggleSizeThreeQuarterScreen,
        CNToggleSizeOneThirdScreen,
        CNToggleSizeTwoThirdsScreen
    };
    typedef NSInteger CNToggleSize;

 `CNToggleSizeHalfScreen`<br>
 The applicationView will move in by the half screen width or height (depending on the value given in `toggleEdge`).<br>
 This is the default value.
 
 `CNToggleSizeQuarterScreen`<br>
 The applicationView will move in by the quarter screen width or height (depending on the value given in `toggleEdge`).
 
 `CNToggleSizeThreeQuarterScreen`<br>
 The applicationView will move in by three quarter of a screen (height or width, depending on the value given in `toggleEdge`).
 
 `CNToggleSizeOneThirdScreen`<br>
 The applicationView will move in by one third of a screen (height or width, depending on the value given in `toggleEdge`).
 
 `CNToggleSizeTwoThirdsScreen`<br>
 The applicationView will move in by two thirds of a screen (height or width, depending on the value given in `toggleEdge`).
 
 Additionally you can specify a 'free form' size in pixels.
 
 __Example__
 
    // this will move in the applicationView by half of the height of toggleDisplay from top to down
    CNBackstageController *myController = [CNBackstageController sharedBackstagedController];
    myController.toggleEdge = CNToggleEdgeTop;
    myController.toggleSize = CNToggleSizeHalfScreen;

    // this will move in the applicationView by 369 pixels from left to right
    CNBackstageController *myController = [CNBackstageController sharedBackstagedController];
    myController.toggleEdge = CNToggleEdgeLeft;
    myController.toggleSize = 369;
 */
@property (nonatomic, assign) CNToggleSize toggleSize;

/**
 Specifies the display where `applicationView` will be shown.
 
 There are just four displays supported. You can specify it with one of these constants:
 
    enum {
        CNToggleDisplayMain     = 0,
        CNToggleDisplaySecond   = 1,
        CNToggleDisplayThird    = 2,
        CNToggleDisplayFourth   = 3
    };
    typedef NSUInteger CNToggleDisplay;

 `CNToggleDisplayMain`<br>
 The default value. Main display means that display where the system statusbar is placed.
 */
@property (assign) CNToggleDisplay toggleDisplay;


/**
 Specifies the visible effect, while the display is toggling.
 
 Each time if the `applicationView` is shown, the animation can make use of different effects while toggling. The supported 
 effects are specified in `CNtoggleEffect`. These constants can be combined using the C-bitwise OR operator.
 
    enum {
        CNToggleEffectNone           = 0,
        CNToggleEffectBlackOverlay   = (1 << 0) 
    };
    typedef NSUInteger CNToggleEffect;

 `CNToggleEffectNone`<br>
 No effect is shown while toggling.
 
 `CNToggleEffectBlackOverlay`<br>
 A black transparent plane is shown over the Finder snapshot area.<br>
 This is the default value.
 
 The default value after instanciating a `CNBackstageController` is `CNToggleEffectBlackOverlay`.
 */
@property (assign) CNToggleEffect toggleEffect;


/**
 Property that describes the behavior of the applicationView while toggling.

    typedef enum {
        CNApplicationViewBehaviorStatic = 1 << 0,
        CNApplicationViewBehaviorFade   = 1 << 1,
        CNApplicationViewBehaviorSlide  = 1 << 2
    } CNApplicationViewBehavior;

 */
@property (assign) CNApplicationViewBehavior applicationViewBehavior;



#pragma mark - Initialization
/** @name Initialization */

/**
 Initialize and returns a `CNBackstageController` using a given `NSView`.
 
 The designated Initializer.
 `CNBackstageController` uses this view placing it as content of the resulting (internal) applicationView. In the <CNBackstageControllerDelegate>
 there is a method `buildApplicationInView:`. This method is automatically called if all default settings are done and `CNBackstageController`
 is ready for use.
 
 @return An initialized CNBackstageController instance.
 */
- (id)initWithApplicationWindow:(NSWindow *)theApplicationWindow;



#pragma mark - API
/** @name API */

/**
 toggleViewState
 */
- (void)toggleViewState;

@end





/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - CNBackstageShadowView

@interface CNBackstageShadowView : NSView
@property (assign, nonatomic) CNToggleEdge toggleEdge;
@end

