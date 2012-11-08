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
    CNToggleVisualEffectNone            = 0 << 0,
    CNToggleVisualEffectOverlayBlack    = 1 << 0,
    CNToggleVisualEffectGaussianBlur    = 1 << 1
} CNToggleVisualEffect;

typedef enum {
    CNToggleAnimationEffectStatic = 0,
    CNToggleAnimationEffectFade,
    CNToggleAnimationEffectSlide
} CNToggleAnimationEffect;


/// NSUserDefaults keys to save the enum values from above
extern NSString *CNToggleEdgePreferencesKey;
extern NSString *CNToggleSizePreferencesKey;
extern NSString *CNToggleDisplayPreferencesKey;
extern NSString *CNToggleVisualEffectPreferencesKey;
extern NSString *CNToggleAnimationEffectPreferencesKey;
extern NSString *CNToggleAlphaValuePreferencesKey;

/// Notifications
/// All these notifications contains the sending CNBackstageController as the `object` value.
extern NSString *CNBackstageControllerWillOpenScreenNotification;
extern NSString *CNBackstageControllerDidOpenScreenNotification;
extern NSString *CNBackstageControllerWillCloseScreenNotification;
extern NSString *CNBackstageControllerDidCloseScreenNotification;

/// Keys that are used for the userInfo dictionary in the notifications from above
extern NSString *CNToggleScreenUserInfoKey;
extern NSString *CNToggleEdgeUserInfoKey;




/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - CNBackstage Delegate

/**
 The CNBackstage Delegate provides a set of methods the user can implement to control the functionality of its own backstage
 instance.
 */

@class CNBackstageController;


@protocol CNBackstageDelegate <NSObject>
@optional

/**
 Informs the delegate that the screen `toggleScreen` will open on edge `toggleEdge`.
 
 This delegate also post a `CNBackstageControllerWillOpenNotification` notification to the `NSNotificationCenter`. It sends the toggleScreen parameter
 as an item of the userInfo dictionary with the key `toggleScreen`.

 @param toggleScreen    The screen that will toggle the CNBackstageController's view.
 @param toggleEdge      The edge the CNBackstageController's view will appear.
 */
- (void)backstageController:(CNBackstageController *)backstageController willOpenScreen:(NSScreen *)toggleScreen onToggleEdge:(CNToggleEdge)toggleEdge;

/**
 ...
 */
- (void)backstageController:(CNBackstageController *)backstageController didOpenScreen:(NSScreen *)toggleScreen onToggleEdge:(CNToggleEdge)toggleEdge;

/**
 Informs the delegate that the screen `toggleScreen` will close on edge `toggleEdge`.

 This delegate also post a `CNBackstageControllerWillCloseNotification` notification to the `NSNotificationCenter`. It sends the toggleScreen parameter
 as an item of the userInfo dictionary with the key `toggleScreen`.

 @param toggleScreen    The screen that will close the CNBackstageController's view.
 @param toggleEdge      The edge the CNBackstageController's view did appear.
 */
- (void)backstageController:(CNBackstageController *)backstageController willCloseScreen:(NSScreen *)toggleScreen onToggleEdge:(CNToggleEdge)toggleEdge;

/**
 ...
 */
- (void)backstageController:(CNBackstageController *)backstageController didCloseScreen:(NSScreen *)toggleScreen onToggleEdge:(CNToggleEdge)toggleEdge;
@end





/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - CNBackstageController



/**
 The use of `CNBackstageController` is quite simple and straight forward. Normally with `CNBackstageController` you create a
 so called agent app. They do not appear in the Dock or the Force Quit window. To create an agent app a special property in your
 Info.plist must be set. Its name is `LSUIElement` and its value must be `YES`.
 
 And now just follow these steps:

 1. Open Xcode and create a new *Cocoa Application* project.<br />
 2. Click on the *MainMenu.xib* file in your Project Browser, locate the Object Browser and delete all included items,
    **except** the **Application Delegate**  object.

    It should look like this one:

    <img src="/images/XcodeObjectsBrowser.png">

 3. Create your `NSViewController` instance with a NIB file containing all your application sepcific stuff, place your controls
    and objects and make all the connections in Interface Builder related to your needs.
 4. In your AppDelegate define two properties. One will be our backstage controller, the other one will be our `NSViewController`
    from step 3.

        @property (strong) CNBackstageController *backstageController;      // your backstage controller
        @property (strong) CNApplicationViewController *appController;      // your application view controller

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

/**
 Returns the singleton instance of `CNBackstageController`.
 
 The singleton instance of `CNBackstageController`.
 */
+ (id)sharedInstance;

/**
 An instance of `NSViewController` that contains your application view.
 
 The applicationViewController can be any derivate of `NSWindowController`. `CNBackstageController` will handle its view as your application view.
 When you set this property `CNBackstageController` will automatically set its delegate to the applicationViewController. Later you can overwrite the delegate dependent on your needs.
 */
@property (strong, nonatomic) NSViewController <CNBackstageDelegate> *applicationViewController;

/**
 Property for getting and setting the receivers delegate.

 @return    The receivers delegate.
 */
@property (strong) id<CNBackstageDelegate>delegate;



#pragma mark Animation & Effects
/** @name Animation & Effects */

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

 `CNToggleEdgeTop`<br />
 The applicationView will appear from the top side of the screen that was selected by the property `toggleDisplay`.<br />
 This is the default value.
 
 `CNToggleEdgeBottom`<br />
 The applicationView will appear from the bottom side of the screen that was selected by the property `toggleDisplay`.
 
 `CNToggleEdgeLeft`<br />
 The applicationView will appear from the left side of the screen that was selected by the property `toggleDisplay`.
 
 `CNToggleEdgeRight`<br />
 The applicationView will appear from the right side of the screen that was selected by the property `toggleDisplay`.
 
 `CNToggleEdgeSplitHorizontal`<br />
 The aplicationView will appear in the horizontal middle of the screen. The overlaid screen content will be splitted into a left and a right half that slides apart.

 `CNToggleEdgeSplitVertical`<br />
 The aplicationView will appear in the vertical middle of the screen. The overlaid screen content will be splitted into a top and a bottom half that slides apart.
 */
@property (assign, nonatomic) CNToggleEdge toggleEdge;

/**
 Defines the inset the applicationViewController's view should toggle.
 
 There are five pre defined constants. The meaning its values are related the selected toggleEdge.
 
    enum {
        CNToggleSizeHalfScreen = 0,
        CNToggleSizeQuarterScreen,
        CNToggleSizeThreeQuarterScreen,
        CNToggleSizeOneThirdScreen,
        CNToggleSizeTwoThirdsScreen
    };
    typedef NSInteger CNToggleSize;

 `CNToggleSizeHalfScreen`<br />
 The applicationView will move in by the half screen width or height (depending on the value given in `toggleEdge`).<br />
 This is the default value.
 
 `CNToggleSizeQuarterScreen`<br />
 The applicationView will move in by the quarter screen width or height (depending on the value given in `toggleEdge`).
 
 `CNToggleSizeThreeQuarterScreen`<br />
 The applicationView will move in by three quarter of a screen (height or width, depending on the value given in `toggleEdge`).
 
 `CNToggleSizeOneThirdScreen`<br />
 The applicationView will move in by one third of a screen (height or width, depending on the value given in `toggleEdge`).
 
 `CNToggleSizeTwoThirdsScreen`<br />
 The applicationView will move in by two thirds of a screen (height or width, depending on the value given in `toggleEdge`).
 
 Additionally you can specify a 'free form' size in pixels. If `toggleSize` has a negative value `CNBackstageController` will multiply it with -1 to make it positive.
 Dependent on the selected toggleEdge `CNBackstageController` validates the given toggleSize as follows:
 
 * If you would like to toggle on the top or bottom screen edge `CNBackstageController` validates the given toggleSize against the screen height.
 If the given toggleSize is greater than the screen height `CNBackstageController` will automatically fallback to `CNToggleSizeQuarterScreen`.
 * If you would like to toggle on the left or right screen edge `CNBackstageController` validates the given toggleSize against the screen width.
 
 ####Example
 
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
 Specifies the display to show the `applicationView` on.
 
 There are just four displays supported. You can specify it with one of these constants:
 
    enum {
        CNToggleDisplayMain = 0,            // Main Display means where the system statusbar is placed
        CNToggleDisplaySecond,
        CNToggleDisplayThird,
        CNToggleDisplayFourth
    };
    typedef NSUInteger CNToggleDisplay;

 `CNToggleDisplayMain`<br />
 The default value. Main display means that display where the system statusbar is placed.
 
 @note These are just constants for four displays. You may of course own more than four displays, and `CNBackstageController` will provide them all!
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

 `CNToggleVisualEffectNone`<br />
 There is no visual effect over Finder snapshot area.

 `CNToggleAnimationEffectOverlayBlack`<br />
 A black transparent overlay is shown over the Finder snapshot area. Its alpha value can be manipulated using the
 property overlayAlpha.

 `CNToggleVisualEffectGaussianBlur`<br />
 Spreads pixels of the screen snapshot by a Gaussian distribution.

 **Default Value**<br />
 `CNToggleVisualEffectOverlayBlack`<br />

 @warning Using the `CNToggleAnimationEffectGaussianBlur` will decrease the animation performance!
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

 `CNToggleAnimationEffectStatic`<br />
 While the controller is toggling, the content of the application view keep staying on its place.

 `CNToggleAnimationEffectApplicationContentFade`<br />
 While the controller is toggling, the content of the application view will be fade in.

 `CNToggleAnimationEffectApplicationContentSlide`<br />
 While the controller is toggling, the content of the application view will be slide in.

 The default value is `CNToggleAnimationEffectStatic`.
 */
@property (assign) CNToggleAnimationEffect toggleAnimationEffect;

/**
 ...
 */
@property (strong, nonatomic) NSColor *backstageViewBackgroundColor;

/**
 Property that gets and/or sets the opacity value of the screen snapshot overlays.
 */
@property (assign) CGFloat overlayAlpha;


#pragma mark - API
/** @name API */

/**
 Changes the current view state of applicationView, dependent on the currentViewState.
 
 If the currentViewState has the value `CNToggleStateClosed`, then `CNBackstageController` will open the applicationView.
 Otherwise it will be closed.
 */
- (void)toggleViewState;

/**
 Shows `CNBackstageController`s applicationView.
 
 Changes the currentViewState to `CNToggleStateOpened`.
 */
- (void)changeViewStateToOpen;

/**
 Hides `CNBackstageController`s applicationView.

 Changes the currentViewState to `CNToggleStateClosed`.
 */
- (void)changeViewStateToClose;

/**
 Returns the current view state of applicationView.
 
 @return If the applicationView is visible the return value will be `CNToggleStateOpened`, otherwise `CNToggleStateClosed`.
 */
- (CNToggleState)currentViewState;

@end



/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - CNBackstageShadowView

@interface CNBackstageShadowView : NSView
@property (assign, nonatomic) CNToggleEdge toggleEdge;
@end
