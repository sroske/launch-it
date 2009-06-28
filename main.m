//
//  main.m
//  LaunchIt
//
//  Created by Shawn Roske on 6/28/09.
//  Copyright Bitgun 2009. All rights reserved.
//

#import <UIKit/UIKit.h>

int main(int argc, char *argv[]) {
    
    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
    int retVal = UIApplicationMain(argc, argv, nil, @"LaunchItAppDelegate");
    [pool release];
    return retVal;
}
