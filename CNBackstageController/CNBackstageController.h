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
#import "CNBackstageDefinitions.h"
#import "CNBackstageDelegate.h"




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



#pragma mark - Animation, Effects & Sizing
/** @name Animation, Effects & Sizing */

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
 Property that defines the toggle width and height the view of applicationViewController should appear on activation.
 
 To set its value you should make use of the convenience function `CNMakeToggleSize(NSUInteger aWidth, NSUInteger aHeight)`. 

 **The CNToggleSize data type**

    typedef struct {
        NSUInteger width;
        NSUInteger height;
    } CNToggleSize;

 To set the width and height attributes of toggleSize you can use any value that is in the range of your displays resolution. These are *absolute values*.<br />
 Furthermore you can choose between five constants to set *relative values* for `toggleSize.width` and `toggleSize.height`. Dependent on your display size the *absolute values* related to these constants are calculated in real time.

 **The predfined CNToggleSize constants to set relative values**

    enum {
        CNToggleSizeHalfScreen = 0,
        CNToggleSizeQuarterScreen,
        CNToggleSizeThreeQuarterScreen,
        CNToggleSizeOneThirdScreen,
        CNToggleSizeTwoThirdsScreen
    };

 So, the usage of that convenience function may look different, because it's allowed to mix absolute and relative values.
 
 **Examples for the use of CNMakeToggleSize()**

    CNBackstageController *myController = [CNBackstageController sharedInstance];

    // by setting toggleEdge to CNToggleEdgeTop just toggleSize.height with the 
    // value of 300 pixel is relevant
    myController.toggleEdge = CNToggleEdgeTop;
    myController.toggleSize = CNMakeToggleSize(650, 300);

    //
    myController.toggleEdge = CNToggleEdgeRight;
    myController.toggleSize = CNMakeToggleSize(450, CNToggleSizeQuarterScreen);

    //
    myController.toggleSize = CNMakeToggleSize(CNToggleSizeHalfScreen, CNToggleSizeOneThirdScreen);

 What will happen on these three examples? So, let me explain a bit more.<br />
 
 **First example**
 
 It will set the `toggleSize.width` to 650 pixel and the `toggleSize.height` to 300 pixel. Width and height are used related to the value  of the toggleEdge property. The `toggleSize.width` attribute finds use if toggleEdge has the value `CNToggleEdgeLeft`, `CNToggleEdgeRight` or `CNToggleEdgeSplitHorizontal`. The `toggleSize.height` attribute will be used if toggleEdge has the value `CNToggleEdgeTop`, `CNToggleEdgeBottom` or `CNToggleEdgeSplitVertical`.
 
 **Second example**
 
 It uses an absolute value of 450 pixel for `toggleSize.width` and a relative value of `CNToggleSizeQuarterScreen` for `toggleSize.height`. That relative value will  be automatically converted to an absolute pixel value in the moment the applicationView will appear.

 **Third example**

 It use relative values for both, `toggleSize.width` and `toggleSize.height`. Both relative values will be automatically converted to an absolute pixel value in the moment the applicationView will appear.

 **Constant description**

 `CNToggleSizeHalfScreen`<br />
 The applicationView will appear using the half screen width or height (depending on the value given in `toggleEdge`).<br />
 
 `CNToggleSizeQuarterScreen`<br />
 The applicationView will appear using the quarter screen width or height (depending on the value given in `toggleEdge`).
 
 `CNToggleSizeThreeQuarterScreen`<br />
 The applicationView will appear using three quarter of a screen (height or width, depending on the value given in `toggleEdge`).
 
 `CNToggleSizeOneThirdScreen`<br />
 The applicationView will appear using one third of a screen (height or width, depending on the value given in `toggleEdge`).
 
 `CNToggleSizeTwoThirdsScreen`<br />
 The applicationView will appear using two thirds of a screen (height or width, depending on the value given in `toggleEdge`).
 
 **Default value**
 
 The default value of toggleSize is `CNMakeToggleSize(CNToggleSizeQuarterScreen, CNToggleSizeQuarterScreen)`.

 */
@property (assign, nonatomic) CNToggleSize toggleSize;

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
 Boolean property that indicates whether the user can resize the coverage of applicationView or not.
 
 */
@property (assign) BOOL applicationViewResizeable;

/**
 ...
 */
@property (assign) NSSize applicationViewMinSize;


#pragma mark - Managing the Layout
/** @name Managing the Layout */

/**
 ...
 */
@property (strong, nonatomic) NSColor *backstageViewBackgroundColor;

/**
 Property that gets and/or sets the opacity value of the screen snapshot overlays.
 */
@property (assign) CGFloat overlayAlpha;

/**
 Boolean property to control the drawing of shadows on applicationView.

 
 */
@property (assign) BOOL useShadowsOnApplicationView;


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
