//
//  LaunchItAppDelegate.h
//  LaunchIt
//
//  Created by Shawn Roske on 6/28/09.
//  Copyright Bitgun 2009. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GameLayer.h"

@interface LaunchItAppDelegate : NSObject <UIApplicationDelegate> {
    UIWindow *window;
}

@property (nonatomic, retain) IBOutlet UIWindow *window;

@end

