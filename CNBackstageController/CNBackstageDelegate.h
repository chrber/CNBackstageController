//
//  CNBackstageDelegate.h
//  CNBackstageController Example
//
//  Created by cocoa:naut on 09.11.12.
//  Copyright (c) 2012 cocoa:naut. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CNBackstageDefinitions.h"


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
- (void)backstageController:(CNBackstageController *)backstageController willExpandOnScreen:(NSScreen *)toggleScreen onToggleEdge:(CNToggleEdge)toggleEdge;

/**
 ...
 */
- (void)backstageController:(CNBackstageController *)backstageController didExpandOnScreen:(NSScreen *)toggleScreen onToggleEdge:(CNToggleEdge)toggleEdge;

/**
 Informs the delegate that the screen `toggleScreen` will close on edge `toggleEdge`.

 This delegate also post a `CNBackstageControllerWillCloseNotification` notification to the `NSNotificationCenter`. It sends the toggleScreen parameter
 as an item of the userInfo dictionary with the key `toggleScreen`.

 @param toggleScreen    The screen that will close the CNBackstageController's view.
 @param toggleEdge      The edge the CNBackstageController's view did appear.
 */
- (void)backstageController:(CNBackstageController *)backstageController willCollapseOnScreen:(NSScreen *)toggleScreen onToggleEdge:(CNToggleEdge)toggleEdge;

/**
 ...
 */
- (void)backstageController:(CNBackstageController *)backstageController didCollapseOnScreen:(NSScreen *)toggleScreen onToggleEdge:(CNToggleEdge)toggleEdge;

/**
 ...
 */
- (void)backstageController:(CNBackstageController *)backstageController willDragOnScreen:(NSScreen *)toggleScreen onToggleEdge:(CNToggleEdge)toggleEdge;

/**
 ...
 */
- (void)backstageController:(CNBackstageController *)backstageController didDragOnScreen:(NSScreen *)toggleScreen onToggleEdge:(CNToggleEdge)toggleEdge;
@end
