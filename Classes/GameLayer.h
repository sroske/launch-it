//
//  GameLayer.h
//  LaunchIt
//
//  Created by Shawn Roske on 6/28/09.
//  Copyright 2009 Bitgun. All rights reserved.
//

#import "cocos2d.h"
#import "Box2D.h"

@interface GameLayer : Layer {
	b2World* world;
	AtlasSprite* boxSprite;
}

@end
