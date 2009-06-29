//
//  GameLayer.h
//  LaunchIt
//
//  Created by Shawn Roske on 6/28/09.
//  Copyright 2009 Bitgun. All rights reserved.
//

#import "cocos2d.h"
#import "Box2D.h"

class CatcherContactListener : public b2ContactListener
{
public:
	void Add(const b2ContactPoint* point);
	void Persist(const b2ContactPoint* point);
	void Remove(const b2ContactPoint* point);
	void Result(const b2ContactResult* point);
};

@interface GameLayer : Layer {
	b2World *world;
	AtlasSprite *boxSprite;
	CFMutableDictionaryRef touchLocations;
	int direction;
	b2Body *body;
	b2Body *catcherBody;
	CatcherContactListener *listener;
	NSMutableArray *captured;
}

@end
