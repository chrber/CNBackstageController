//
//  NSScreen+CNBackstageController.m
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

#import "NSScreen+CNBackstageController.h"


#define kDefaultsDockDesktopKey     @"com.apple.dock"
#define kDefaultsDomainDesktopKey   @"com.apple.desktop"

#define kNSScreenNumberKey          @"NSScreenNumber"
#define kImageFilePathKey           @"ImageFilePath"

enum {
    CNDockOrientationLeft = 0,
    CNDockOrientationRight = 1,
    CNDockOrientationBottom = 2
};
typedef NSUInteger CNDockOrientation;



@interface NSScreen (CNBackstageControllerExtension)
+ (CNDockOrientation)dockOrientation;
+ (NSArray*)dockOrientations;
@end


@implementation NSScreen (CNBackstageController)

// --------------------------------------------------------------------------------------------------------------------------
#pragma mark - API
// --------------------------------------------------------------------------------------------------------------------------

+ (NSScreen*)screenWithMenubar
{
    NSScreen *result;
    for (NSScreen *screen in [NSScreen screens]) {
        NSRect totalFrame = [screen frame];
        NSRect visibleFrame = [screen visibleFrame];
        
        if (totalFrame.size.height > visibleFrame.size.height) {
            result = screen;
        }
    }
    return result;
}

+ (NSScreen*)screenWithDisplayID:(CGDirectDisplayID)displayID
{
    NSScreen *result;
    for (NSScreen *aScreen in [NSScreen screens]) {
        if ([[[aScreen deviceDescription] valueForKey:@"NSScreenNumber"] intValue] == displayID) {
            result = aScreen;
            break;
        }
    }
    return result;
}

+ (NSImage*)desktopImageForScreen:(NSScreen*)aScreen
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSDictionary *desktopDefaults = [defaults persistentDomainForName:kDefaultsDomainDesktopKey];
    NSDictionary *screenDefaults = [desktopDefaults objectForKey:[[aScreen deviceDescription] valueForKey:kNSScreenNumberKey]];
    return [NSImage imageNamed:[screenDefaults valueForKey:kImageFilePathKey]];
}

- (BOOL)containsDock
{
    NSRect totalFrame = [self frame];
    NSRect visibleFrame = [self visibleFrame];
    int statusBarThickness = (self.isMainScreen ? [[NSStatusBar systemStatusBar] thickness] : 0);
    BOOL result = YES;
    
    switch ([NSScreen dockOrientation]) {
        case CNDockOrientationLeft:
        case CNDockOrientationRight:
            result = (visibleFrame.size.width == totalFrame.size.width ? NO : YES);
            break;
            
        case CNDockOrientationBottom:
            result = (visibleFrame.size.height == (totalFrame.size.height - statusBarThickness) ? NO : YES);
            break;
    }
    return result;
}

- (BOOL)containsMenuBar
{
    CGDirectDisplayID myDisplayID = (CGDirectDisplayID)[[[self deviceDescription] valueForKey:kNSScreenNumberKey] unsignedIntValue];
    CGDirectDisplayID menuBarScreenDisplayID = (CGDirectDisplayID)[[[[NSScreen screenWithMenubar] deviceDescription] valueForKey:kNSScreenNumberKey] unsignedIntValue];
    return (myDisplayID == menuBarScreenDisplayID);
}

- (BOOL)isMainScreen
{
    int mainscreen = [[[[NSScreen mainScreen] deviceDescription] valueForKey:kNSScreenNumberKey] intValue];
    int currentscreen = [[[self deviceDescription] valueForKey:kNSScreenNumberKey] intValue];
    return (mainscreen == currentscreen);
}

- (CGImageRef)snapshotOfType:(NSBitmapImageFileType)imageFileType
{
    @try {
        switch (imageFileType) {
            case NSTIFFFileType:
            case NSBMPFileType:
            case NSGIFFileType:
            case NSJPEGFileType:
            case NSPNGFileType:
            case NSJPEG2000FileType: {
                CGDirectDisplayID displayID = (CGDirectDisplayID)[[[self deviceDescription] valueForKey:kNSScreenNumberKey] unsignedIntValue];
                CGRect rect = NSRectToCGRect([self frame]);
                rect.origin = CGPointMake(0, 0);
                CGImageRef snapshotImageRef = CGDisplayCreateImageForRect(displayID, rect);
                NSBitmapImageRep *snapshot = [[NSBitmapImageRep alloc] initWithCGImage:snapshotImageRef];
                return [snapshot CGImage];
                break;
            }
                
            default: {
                NSException *wrongFileTypeException = [NSException exceptionWithName:@"CNUnknownBitmapImageFileTypeException"
                                                                              reason:[NSString stringWithFormat:@"The given bitmap image file type is unknown (%li).", imageFileType]
                                                                            userInfo:nil];
                @throw wrongFileTypeException;
                break;
            }
        }
    }
    @catch (NSException *wrongFileTypeException) {
        NSLog(@"ERROR: Caught %@: %@", [wrongFileTypeException name], [wrongFileTypeException reason]);
    }
    return NULL;
}

- (NSString*)desktopImageFilePath
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSDictionary *desktopDefaults = [defaults persistentDomainForName:kDefaultsDomainDesktopKey];
    NSDictionary *screenDefaults = [desktopDefaults objectForKey:[[self deviceDescription] valueForKey:kNSScreenNumberKey]];
    return [screenDefaults valueForKey:kImageFilePathKey];
}

- (NSImage*)desktopImage
{
    return [NSImage imageNamed:[self desktopImageFilePath]];
}


// --------------------------------------------------------------------------------------------------------------------------
#pragma mark - Private Helper
// --------------------------------------------------------------------------------------------------------------------------

+ (CNDockOrientation)dockOrientation
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSDictionary *dockDefaults = [defaults persistentDomainForName:kDefaultsDockDesktopKey];
    return [self.dockOrientations indexOfObject:[dockDefaults valueForKey:@"orientation"]];
}

+ (NSArray*)dockOrientations { return [NSArray arrayWithObjects:@"left", @"right", @"bottom", nil]; }

@end
