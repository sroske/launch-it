//
//  LaunchItAppDelegate.m
//  LaunchIt
//
//  Created by Shawn Roske on 6/28/09.
//  Copyright Bitgun 2009. All rights reserved.
//

#import "LaunchItAppDelegate.h"

@implementation LaunchItAppDelegate

@synthesize window;

- (void)applicationDidFinishLaunching:(UIApplication *)application 
{
	window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
	
	// cocos2d will inherit these values
	[window setUserInteractionEnabled:YES];	
	[window setMultipleTouchEnabled:NO];
	
	// must be called before any othe call to the director
	[Director useFastDirector];
	[[Director sharedDirector] setDisplayFPS:YES];
	
	// create an openGL view inside a window
	[[Director sharedDirector] attachInView:window];
	
	// Default texture format for PNG/BMP/TIFF/JPEG/GIF images
	// It can be RGBA8888, RGBA4444, RGB5_A1, RGB565
	// You can change anytime.
	[Texture2D setDefaultAlphaPixelFormat:kTexture2DPixelFormat_RGBA8888];	

	glClearColor(0.5f,0.5f,0.5f,1.0f);
	//glClearColor(1.0f,1.0f,1.0f,1.0f);
	
	[window makeKeyAndVisible];
	
	[[Director sharedDirector] runWithScene:[GameLayer node]];
}


- (void)dealloc 
{
    [window release];
    [super dealloc];
}

// getting a call, pause the game
-(void) applicationWillResignActive:(UIApplication *)application
{
	[[Director sharedDirector] pause];
}

// call got rejected
-(void) applicationDidBecomeActive:(UIApplication *)application
{
	[[Director sharedDirector] resume];
}

// purge memroy
- (void)applicationDidReceiveMemoryWarning:(UIApplication *)application 
{
	[[TextureMgr sharedTextureMgr] removeAllTextures];
}

// next delta time will be zero
-(void) applicationSignificantTimeChange:(UIApplication *)application
{
	[[Director sharedDirector] setNextDeltaTimeZero:YES];
}


@end
