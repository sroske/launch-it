//
//  GameLayer.m
//  LaunchIt
//
//  Created by Shawn Roske on 6/28/09.
//  Copyright 2009 Bitgun. All rights reserved.
//

#import "GameLayer.h"

#define PTM_RATIO 32
#define MAX_VELOCITY 22
#define MAX_VELOCITY_IN_PX 150
#define BULLET_GROUP_INDEX -1 // negative for no collisions
#define CATCHER_SPEED_PX 20
#define CAPTURE_SHAPE_NOTIFICATION @"CaptureShape"

enum {
	kTagTileMap = 1,
	kTagSpriteManager = 1,
	kTagAnimation1 = 1,
	kCatcherSprite = 2,
};

void CatcherContactListener::Add(const b2ContactPoint* point)
{
	// handle add point
}

void CatcherContactListener::Persist(const b2ContactPoint* point)
{
	// handle persist point
	if (point->separation < -0.4f && point->velocity.y < 0)
	{
		NSDictionary *dict = [NSDictionary dictionaryWithObject:(AtlasSprite *)point->shape2->GetBody()->GetUserData()
														 forKey:@"sprite"];
		[[NSNotificationCenter defaultCenter] postNotificationName:CAPTURE_SHAPE_NOTIFICATION 
															object:nil
														  userInfo:dict];
	}
}

void CatcherContactListener::Remove(const b2ContactPoint* point)
{
	// handle remove point
}

void CatcherContactListener::Result(const b2ContactResult* point)
{
	// handle results
}

@interface GameLayer (Private)

- (void)setupCatcher;
- (void)tick:(ccTime)dt;
- (void)addNewSpriteWithCoords:(CGPoint)p andVector:(b2Vec2)vector;

@end

@implementation GameLayer

- (id)init
{
	self = [super init];
	if (self != nil)
	{
		score = 0;
		direction = 1.0f+CCRANDOM_0_1();
		directionUpDown = 1.0f+CCRANDOM_0_1();
		touchLocations = CFDictionaryCreateMutable(NULL, 0, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
		captured = [[NSMutableArray alloc] init];
		
		CGSize screenSize = [Director sharedDirector].winSize;
		
		// set up world bounds, this should be larger than screen as any body that 
		// reaches the boundary will be frozen
		b2AABB worldAABB;
		float borderSize = 96/PTM_RATIO; // we want a 96 pixel border between the screen and the world bounds
		worldAABB.lowerBound.Set(-borderSize, -borderSize); // bottom left
		worldAABB.upperBound.Set(screenSize.width/PTM_RATIO+borderSize, 
								 screenSize.height/PTM_RATIO+borderSize); // top right
		b2Vec2 gravity(0.0f, -20.0f);
		world = new b2World(worldAABB, gravity, YES);
		listener = new CatcherContactListener();
		world->SetContactListener(listener);
		
		// set up cieling, we will make it as wide as the screen
		/* b2BodyDef cielingBodyDef;
		cielingBodyDef.position.Set(screenSize.width/PTM_RATIO/2, (screenSize.height+PTM_RATIO-20)/PTM_RATIO);
		b2Body* cielingBody = world->CreateBody(&cielingBodyDef);
		b2PolygonDef cielingShapeDef;
		cielingShapeDef.restitution = 0.4f;
		cielingShapeDef.SetAsBox(screenSize.width/PTM_RATIO/2, 1.0f);
		cielingBody->CreateShape(&cielingShapeDef); */
		
		// set up the left wall, we will make it as tall as the screen
		b2BodyDef leftBodyDef;
		leftBodyDef.position.Set(-1.0f, screenSize.height/PTM_RATIO/2);
		b2Body* leftBody = world->CreateBody(&leftBodyDef);
		b2PolygonDef leftShapeDef;
		leftShapeDef.restitution = 0.9f;
		leftShapeDef.SetAsBox(1.0f, screenSize.height/PTM_RATIO/2);
		leftBody->CreateShape(&leftShapeDef);
		
		// set up the right wall, we will make it as tall as the screen
		b2BodyDef rightBodyDef;
		rightBodyDef.position.Set((screenSize.width+PTM_RATIO)/PTM_RATIO, screenSize.height/PTM_RATIO/2);
		b2Body* rightBody = world->CreateBody(&rightBodyDef);
		b2PolygonDef rightShapeDef;
		rightShapeDef.restitution = 0.4f;
		rightShapeDef.SetAsBox(1.0f, screenSize.height/PTM_RATIO/2);
		rightBody->CreateShape(&rightShapeDef);
		
		[self schedule:@selector(tick:)];
		
		scoreLabel = [[Label alloc] initWithString:@"Score: 0" fontName:@"Helvetica-Bold" fontSize:20];
		scoreLabel.position = CGPointMake(160, 440);
		[self addChild:scoreLabel z:3];
		
		// set up sprites
		Sprite *launcher = [Sprite spriteWithFile:@"launcher.png"];
		launcher.position = CGPointMake(160, 100);
		[self addChild:launcher z:0];
		
		[self setupCatcher];
		
		AtlasSpriteManager *manager = [AtlasSpriteManager spriteManagerWithFile:@"blocks.png" capacity:150];
		[self addChild:manager z:1 tag:kTagSpriteManager];
		
		isTouchEnabled = YES;
		
		[[NSNotificationCenter defaultCenter] addObserver:self 
												 selector:@selector(shapeCaptured:) 
													 name:CAPTURE_SHAPE_NOTIFICATION
												   object:nil];
	}
	return self;
}

- (void)setupCatcher
{
	Sprite *catcher = [Sprite spriteWithFile:@"catcher.png"];
	catcher.position = CGPointMake(32, 320);
	[self addChild:catcher z:0 tag:kCatcherSprite];
	
	b2BodyDef bodyDef;
	bodyDef.position.Set(catcher.position.x/PTM_RATIO, (catcher.position.y+20)/PTM_RATIO);
	
	b2PolygonDef shapeDef;
	shapeDef.isSensor = true;
	shapeDef.SetAsBox(1.0f, .5f); // these are mid points for our 1m box
	shapeDef.density = 1.0f;
	shapeDef.friction = 0.1f;
	
	catcherBody = world->CreateBody(&bodyDef);
	
	catcherBody->CreateShape(&shapeDef);
}

- (void)dealloc
{
	delete world;
	delete listener;
	world = NULL;
	body = NULL;
	catcherBody = NULL;
	CFRelease(touchLocations);
	touchLocations = NULL;
	[captured release];
	[scoreLabel release];
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[super dealloc];
}

#pragma mark -
#pragma mark Actions

- (void)shapeCaptured:(NSNotification *)notification
{
	AtlasSprite *sprite = (AtlasSprite *)[notification.userInfo objectForKey:@"sprite"];
	if (sprite != NULL && ![captured containsObject:sprite])
	{
		[captured addObject:sprite];
		score += 100;
		[scoreLabel setString:[NSString stringWithFormat:@"Score: %i", score]];
	}
}

- (void)tick:(ccTime)dt
{
	//It is recommended that a fixed time step is used with Box2D for stability
	//of the simulation, however, we are using a variable time step here.
	//You need to make an informed choice, the following URL is useful
	//http://gafferongames.com/game-physics/fix-your-timestep/
	
	AtlasSpriteManager *manager = (AtlasSpriteManager*)[self getChildByTag:kTagSpriteManager];
	Sprite *catcher = (Sprite *)[self getChildByTag:kCatcherSprite];
	CGPoint p = catcher.position;
	CGFloat newx = p.x+CATCHER_SPEED_PX*dt*direction;
	if (newx - 32 <= 0 || newx + 32 >= 320) {
		direction *= -1.0f;
	}
	CGFloat newy = p.y+CATCHER_SPEED_PX*dt*directionUpDown;
	if (newy - 64 <= 0 || newy + 32 >= 440) {
		directionUpDown *= -1.0f;
	}
	catcher.position = CGPointMake(newx, newy);
	b2Vec2 vec(newx/PTM_RATIO, (newy+20)/PTM_RATIO);
	catcherBody->SetXForm(vec, 0.0f);
	
	world->Step(dt, 10, 8); // step the physics world
	// iterate over the bodies in the physics world
	b2Body* node = world->GetBodyList();
	while (node)
	{
		b2Body* b = node;
		node = node->GetNext();
		
		if (b->GetUserData() != NULL) 
		{
			// synchronize the AtlasSprites position and rotation with the corresponding body
			AtlasSprite* actor = (AtlasSprite *)b->GetUserData();
			// check to see if this is marked for capture!
			if ([captured containsObject:actor])
			{
				[captured removeObject:actor];
				
				world->DestroyBody(b);
				[manager removeChild:actor cleanup:YES];
			}
			else
			{
				actor.position = CGPointMake(b->GetPosition().x*PTM_RATIO, b->GetPosition().y*PTM_RATIO);
				actor.rotation = -1*CC_RADIANS_TO_DEGREES(b->GetAngle());
			}
		}
	}
}

- (void)addNewSpriteWithCoords:(CGPoint)p andVector:(b2Vec2)vector
{
	AtlasSpriteManager *manager = (AtlasSpriteManager*)[self getChildByTag:kTagSpriteManager];
	
	// we have a 64x64 sprite sheet with 4 different 32x32 images.  The following code is
	// just randomly picking one of the images
	int idx = (CCRANDOM_0_1() > .5 ? 0 : 1);
	int idy = (CCRANDOM_0_1() > .5 ? 0 : 1);
	AtlasSprite *sprite = [AtlasSprite spriteWithRect:CGRectMake(32*idx, 32*idy, 32, 32) spriteManager:manager];
	sprite.position = p;
	[manager addChild:sprite];
	
	// set up a 1m squared box in the physics world
	b2BodyDef bodyDef;
	bodyDef.position.Set(p.x/PTM_RATIO, p.y/PTM_RATIO);
	bodyDef.userData = sprite;
	bodyDef.isBullet = true;
	
	b2PolygonDef shapeDef;
	shapeDef.SetAsBox(.5f, .5f); // these are mid points for our 1m box
	shapeDef.density = 1.0f;
	shapeDef.friction = 0.1f;
	shapeDef.restitution = 0.1f;
	shapeDef.filter.groupIndex = BULLET_GROUP_INDEX;

	body = world->CreateBody(&bodyDef);
	
	body->CreateShape(&shapeDef);
	body->SetMassFromShapes();
	body->SetLinearVelocity(vector);
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
			float dx = l.x-s.x;
			float dy = l.y-s.y;
			
			float angle = atan2(dy, dx);
			
			float distPercent = sqrt(dx*dx+dy*dy)/MAX_VELOCITY_IN_PX;
			if (distPercent > 1.0f)
				distPercent = 1.0f;
			float speed = MAX_VELOCITY*distPercent;
			
			b2Vec2 vect(cos(angle)*-speed, sin(angle)*-speed);
			
			[self addNewSpriteWithCoords:CGPointMake(160, 100) andVector:vect];
			
			CFDictionaryRemoveValue(touchLocations, touch);
		}
		
		
	}
	return kEventHandled;
}

@end
