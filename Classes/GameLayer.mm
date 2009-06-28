//
//  GameLayer.m
//  LaunchIt
//
//  Created by Shawn Roske on 6/28/09.
//  Copyright 2009 Bitgun. All rights reserved.
//

#import "GameLayer.h"

@interface GameLayer (Private)

- (void)tick:(ccTime)dt;
- (void)addNewSpriteWithCoords:(CGPoint)p andVector:(b2Vec2)vector;

@end

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
		touchLocations = CFDictionaryCreateMutable(NULL, 0, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
		
		CGSize screenSize = [Director sharedDirector].winSize;
		NSLog(@"Screen width %0.2f screen height %0.2f", screenSize.width, screenSize.height);
		
		// set up world bounds, this should be larger than screen as any body that 
		// reaches the boundary will be frozen
		b2AABB worldAABB;
		float borderSize = 96/PTM_RATIO; // we want a 96 pixel border between the screen and the world bounds
		worldAABB.lowerBound.Set(-borderSize, -borderSize); // bottom left
		worldAABB.upperBound.Set(screenSize.width/PTM_RATIO + borderSize, 
								 screenSize.height/PTM_RATIO + borderSize); // top right
		b2Vec2 gravity(0.0f, -20.0f);
		world = new b2World(worldAABB, gravity, YES);
		
		// set up ground, we will make it as wide as the screen
		b2BodyDef groundBodyDef;
		groundBodyDef.position.Set(screenSize.width/PTM_RATIO/2, -1.0f);
		b2Body* groundBody = world->CreateBody(&groundBodyDef);
		b2PolygonDef groundShapeDef;
		groundShapeDef.SetAsBox(screenSize.width/PTM_RATIO/2, 1.0f);
		groundBody->CreateShape(&groundShapeDef);
		
		[self schedule:@selector(tick:)];
		
		// set up sprite
		AtlasSpriteManager *manager = [AtlasSpriteManager spriteManagerWithFile:@"blocks.png" capacity:150];
		[self addChild:manager z:0 tag:kTagSpriteManager];
		
		isTouchEnabled = YES;
	}
	return self;
}

- (void)dealloc
{
	delete world;
	world = NULL;
	CFRelease(touchLocations);
	touchLocations = NULL;
	[super dealloc];
}

#pragma mark -
#pragma mark Actions

- (void)tick:(ccTime)dt
{
	//It is recommended that a fixed time step is used with Box2D for stability
	//of the simulation, however, we are using a variable time step here.
	//You need to make an informed choice, the following URL is useful
	//http://gafferongames.com/game-physics/fix-your-timestep/
	
	world->Step(dt, 10, 8); // step the physics world
	// iterate over the bodies in the physics world
	for(b2Body* b = world->GetBodyList(); b; b = b->GetNext())
	{
		if (b->GetUserData() != NULL) 
		{
			// synchronize the AtlasSprites position and rotation with the corresponding body
			AtlasSprite* actor = (AtlasSprite *)b->GetUserData();
			actor.position = CGPointMake(b->GetPosition().x*PTM_RATIO, b->GetPosition().y*PTM_RATIO);
			actor.rotation = -1*CC_RADIANS_TO_DEGREES(b->GetAngle());
		}	
	}
}

- (void)addNewSpriteWithCoords:(CGPoint)p andVector:(b2Vec2)vector
{
	CCLOG(@"Add sprite %0.2f x %02.f",p.x, p.y);
	AtlasSpriteManager *manager = (AtlasSpriteManager*)[self getChildByTag:kTagSpriteManager];
	
	// we have a 64x64 sprite sheet with 4 different 32x32 images.  The following code is
	// just randomly picking one of the images
	int idx = (CCRANDOM_0_1() > .5 ? 0:1);
	int idy = (CCRANDOM_0_1() > .5 ? 0:1);
	AtlasSprite *sprite = [AtlasSprite spriteWithRect:CGRectMake(32*idx, 32*idy, 32, 32) spriteManager:manager];
	sprite.position = p;
	[manager addChild:sprite];
	
	// set up a 1m squared box in the physics world
	b2BodyDef bodyDef;
	bodyDef.position.Set(p.x/PTM_RATIO, p.y/PTM_RATIO);
	bodyDef.userData = sprite;
	b2Body *body = world->CreateBody(&bodyDef);
	b2PolygonDef shapeDef;
	shapeDef.SetAsBox(.5f, .5f); // these are mid points for our 1m box
	shapeDef.density = 1.0f;
	shapeDef.friction = 0.1f;
	body->CreateShape(&shapeDef);
	body->SetMassFromShapes();
	body->SetLinearVelocity(vector);
	body = NULL;
}

- (BOOL)ccTouchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
	for(UITouch *touch in touches)
	{
		CGPoint location = [touch locationInView:[touch view]];
		location = [[Director sharedDirector] convertCoordinate:location];
		if (CFDictionaryContainsKey(touchLocations, touch))
		{
			CFDictionarySetValue(touchLocations, touch, CGPointCreateDictionaryRepresentation(location));
		}
		else
		{
			CFDictionaryAddValue(touchLocations, touch, CGPointCreateDictionaryRepresentation(location));
		}
		
	}
	return kEventHandled;
}

- (BOOL)ccTouchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
	// add a new body/atlas sprite at the touched location
	for(UITouch *touch in touches) 
	{
		CGPoint l = [touch locationInView:[touch view]];
		l = [[Director sharedDirector] convertCoordinate:l];
		
		if (CFDictionaryContainsKey(touchLocations, touch))
		{
			CFDictionaryRef ref = (CFDictionaryRef)CFDictionaryGetValue(touchLocations, touch);
			CGPoint s;
			CGPointMakeWithDictionaryRepresentation(ref, &s);
			// calculate the angle and velocity
			float angle = atan2(l.y-s.y, l.x-s.x);
			b2Vec2 vect(cos(angle)*-24, sin(angle)*-24);
			[self addNewSpriteWithCoords:CGPointMake(160, 100) andVector:vect];
		}
		
		
	}
	return kEventHandled;
}

@end
