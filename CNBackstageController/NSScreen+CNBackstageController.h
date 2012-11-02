//
//  NSScreen+CNBackstageController.h
//
//  Created by cocoa:naut on 22.04.12.
//  Copyright (c) 2012 cocoanaut.com. All rights reserved.
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
#import <QuartzCore/QuartzCore.h>

@interface NSScreen (CNBackstageController)

/**
 Returns the `NSScreen` that contains the system menu bar.
 
 @return    A NSScreen object.
 */
+ (NSScreen*)screenWithMenubar;

/**
 Returns the `NSScreen` of the given displayID.
 
 @param     The ID of the requested display.
 @return    A NSScreen object.
 */
+ (NSScreen*)screenWithDisplayID:(CGDirectDisplayID)displayID;

/**
 Creates and returns a desktop image.
 
 This method returns an instance of `NSImage` representing the desktop image of the given `NSScreen`.
 
 @return    A `NSImage` object with the desktop image.
 */
+ (NSImage*)desktopImageForScreen:(NSScreen*)aScreen;

/**
 Boolean value that indicates whether the current screen contains the Dock.
 
 @return    `YES` if the current screen contains the Dock, otherwise `NO`.
 */
- (BOOL)containsDock;

/**
 Boolean value that indicates whether the current screen contains the system menu bar.
 
 @return    `YES` if the current screen contains the system menu bar, otherwise `NO`.
 */
- (BOOL)containsMenuBar;

/**
 Boolean value that indicates whether the current screen is the main screen.
 
 The main screen refers to the screen containing the window that is currently receiving keyboard events.
 
 @return    `YES` if the current screen is the main screen, otherwise `NO`.
 */
- (BOOL)isMainScreen;


/**
 Creates and returns an snapshot of the screen with given image file type.
 
 Allowed image file type values are:
 
    enum {
        NSTIFFFileType,
        NSBMPFileType,
        NSGIFFileType,
        NSJPEGFileType,
        NSPNGFileType,
        NSJPEG2000FileType
    };
    typedef NSUInteger NSBitmapImageFileType;
 
 These values are defined in the [NSBitmapImageRep Class Reference](http://developer.apple.com/library/mac/#documentation/cocoa/reference/applicationkit/classes/nsbitmapimagerep_class/reference/reference.html).
 
 */
- (CGImageRef)snapshotOfType:(NSBitmapImageFileType)imageFileType;

/**
 Returns the file path of the current desktop image.
 
 @return    A `NSString` object containing the complete absolute file path to the desktop image.
 */
- (NSString*)desktopImageFilePath;

/**
 Creates and returns the current desktop image.
 
 This method returns an instance of `NSImage` representing the current desktop image of the receiver.
 
 @return    A `NSImage` object with the desktop image.
 */
- (NSImage*)desktopImage;


@end
