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
    CNToggleStateClosed = -1,
    CNToggleStateOpened = 1
} CNToggleState;

typedef enum {
    CNToggleEdgeTop = 0,
    CNToggleEdgeBottom,
    CNToggleEdgeLeft,
    CNToggleEdgeRight,
    CNToggleEdgeSplitHorizontal,
    CNToggleEdgeSplitVertical
} CNToggleEdge;
static NSString *CNToggleEdgePreferencesKey = @"CNToggleEdge";

enum {
    CNToggleSizeHalfScreen = 0,                         // in relation to the toggleEdge property the toggle size will be the half of a screen (height or width), or...
    CNToggleSizeQuarterScreen,                          // the quarter of a screen (height or width)
    CNToggleSizeThreeQuarterScreen,                     // three quarter of a screen (height or width)
    CNToggleSizeOneThirdScreen,                         // one third of a screen (height or width)
    CNToggleSizeTwoThirdsScreen                         // two thirds of a screen (height or width)
};
typedef NSInteger CNToggleSize;
static NSString *CNToggleSizePreferencesKey = @"CNToggleSize";

typedef enum {
    CNToggleDisplayMain = 0,                            // Main Display means where the system statusbar is placed
    CNToggleDisplaySecond,
    CNToggleDisplayThird,
    CNToggleDisplayFourth
} CNToggleDisplay;
static NSString *CNToggleDisplayPreferencesKey = @"CNToggleDisplay";

typedef enum {
    CNToggleVisualEffectNone            = 0,
    CNToggleVisualEffectOverlayBlack    = 1 << 0,
    CNToggleVisualEffectGaussianBlur    = 1 << 1
} CNToggleVisualEffect;
static NSString *CNToggleVisualEffectPreferencesKey = @"CNToggleVisualEffect";

typedef enum {
    CNToggleAnimationEffectStatic = 0,
    CNToggleAnimationEffectFade,
    CNToggleAnimationEffectSlide
} CNToggleAnimationEffect;
static NSString *CNToggleAnimationEffectPreferencesKey = @"CNToggleAnimationEffect";

static NSString *CNToggleAlphaValuePreferencesKey = @"CNToggleAlphaValue";



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
 The use of `CNBackstageController` is quite simple and straight forward. If you would like to create a new aplication project
 that uses `CNBackstageController` just follow these steps:

 1. Open Xcode and create a new *Cocoa Application* project.<br />
 2. Click on the *MainMenu.xib* file in your Project Browser, locate the Object Browser and delete all included items,
    **except** the **Application Delegate**  object.

    It should look like this one:

    <img src="/images/XcodeObjectsBrowser.png">

 3. Create your `NSViewController` instance with a NIB file containing all your application sepcific stuff, place your controls
    and objects and make all the connections in Interface Builder related to your needs.
 4. In your AppDelegate define two properties. One will be our backstage controller, the other one will be our `NSViewController`
    from step 3.

        @property (strong) CNBackstageController *backstageController;      // our backstage controller
        @property (strong) CNApplicationViewController *appController;      // our application view controller

 5. Now you create instances for these two properties:

        - (void)applicationDidFinishLaunching:(NSNotification *)aNotification
        {
            [...]

            self.appController = [[CNApplicationViewController alloc] initWithNibName:@"CNApplicationView" bundle:nil];
            self.backstageController = [CNBackstageController sharedInstance];
            self.backstageController.applicationViewController = self.appController;
        }

 After these five steps you will have a fully functional backstage controller. Play around with all the other properties and
 see the results. You may also take a look at the Example project.
 
 ##Related Sample Code
 
 [CNBackstageController Example](https://github.com/phranck/CNBackstageController)
 */

@interface CNBackstageController : NSWindowController

/** @name Backstage Controller Creation */

+ (id)sharedInstance;

/**
 Property for getting and setting the receivers delegate.

 @return    The receivers delegate.
 */
@property (strong) id<CNBackstageDelegate>delegate;

@property (strong, nonatomic) NSViewController <CNBackstageDelegate> *applicationViewController;



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
 The aplicationView will appear in the horizontal middle of the screen. The overlaid screen content will be splitted into a left and a right half that slides apart.

 `CNToggleEdgeSplitVertical`<br>
 The aplicationView will appear in the vertical middle of the screen. The overlaid screen content will be splitted into a top and a bottom half that slides apart.
 */
@property (assign, nonatomic) CNToggleEdge toggleEdge;

/**
 Defines the inset the applicationViewController's view should toggle.
 
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
    CNBackstageController *myController = [CNBackstageController sharedInstance];
    myController.toggleEdge = CNToggleEdgeTop;
    myController.toggleSize = CNToggleSizeHalfScreen;

    // this will move in the applicationView by 369 pixels from left to right
    CNBackstageController *myController = [CNBackstageController sharedInstance];
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
 
 @note These are just constants for four displays. You may of course own more than four devices, and `CNBackstageController` will provide them all!
 */
@property (assign) CNToggleDisplay toggleDisplay;

/**
 Specifies the visual effects, while the display is toggling.
 
 On toggling the application view in and out you can use visual effects to focus the users attention more or less on its application view.
 The supported effects are specified in `CNToggleVisualEffect`. You can use multiple of these effects, combined using the C bitwise OR operator.
 
    typedef enum {
        CNToggleVisualEffectNone            = 0,
        CNToggleVisualEffectOverlayBlack    = 1 << 0,
        CNToggleVisualEffectGaussianBlur    = 1 << 1
    } CNToggleVisualEffect;

 `CNToggleVisualEffectNone`<br>
 There is no visual effect over Finder snapshot area.

 `CNToggleAnimationEffectOverlayBlack`<br>
 A black transparent overlay is shown over the Finder snapshot area. Its alpha value can be manipulated using the
 property overlayAlpha.

 `CNToggleVisualEffectGaussianBlur`<br>
 Spreads pixels of the screen snapshot by a Gaussian distribution.

 The default value is `CNToggleVisualEffectOverlayBlack`.
 
 @see overlayAlpha.
*/
@property (assign) CNToggleAnimationEffect toggleVisualEffect;

/**
 Specifies the animation effects, while the display is toggling.

 Each time if the `applicationView` is shown, the animation can make use of different effects while toggling. The supported
 effects are specified in `CNToggleAnimationEffect`.

    typedef enum {
        CNToggleAnimationEffectStatic = 0,
        CNToggleAnimationEffectFade,
        CNToggleAnimationEffectSlide
    } CNToggleAnimationEffect;

 `CNToggleAnimationEffectStatic`<br>
 While the controller is toggling, the content of the application view keep staying on its place.

 `CNToggleAnimationEffectApplicationContentFade`<br>
 While the controller is toggling, the content of the application view will be fade in.

 `CNToggleAnimationEffectApplicationContentSlide`<br>
 While the controller is toggling, the content of the application view will be slide in.

 The default value is `CNToggleAnimationEffectStatic`.
 
 @warning Using the `CNToggleAnimationEffectGaussianBlur` will decrease the animation performance!
 */
@property (assign) CNToggleAnimationEffect toggleAnimationEffect;

/**
 ...
 */
@property (strong, nonatomic) NSColor *backstageViewBackgroundColor;

/**
 ...
 */
@property (assign) CGFloat overlayAlpha;


#pragma mark - Public API
/** @name Public API */

/**
 toggleViewState
 */
- (void)toggleViewState;

/**
 ...
 */
- (CNToggleState)currentToggleState;

@end



/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - CNBackstageShadowView

@interface CNBackstageShadowView : NSView
@property (assign, nonatomic) CNToggleEdge toggleEdge;
@end
