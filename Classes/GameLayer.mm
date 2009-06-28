//
//  GameLayer.m
//  LaunchIt
//
//  Created by Shawn Roske on 6/28/09.
//  Copyright 2009 Bitgun. All rights reserved.
//

#import "GameLayer.h"

@implementation GameLayer

#define PTM_RATIO 32

enum {
	kTagTileMap = 1,
	kTagSpriteManager = 1,
	kTagAnimation1 = 1,
};

- (id)init
{
	self = [super init];
	if (self != nil)
	{
		CGSize screenSize = [Director sharedDirector].winSize;
		NSLog(@"Screen width %0.2f screen height %0.2f", screenSize.width, screenSize.height);
	}
	return self;
}

- (void)dealloc
{
	[super dealloc];
}

@end
