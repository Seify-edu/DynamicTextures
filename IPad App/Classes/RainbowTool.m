//
//  RainbowTool.m
//  DynamicTextures
//
//  Created by Иван Ерасов on 27.06.12.
//  Copyright (c) 2012 Aplica. All rights reserved.
//

#import "RainbowTool.h"

@interface RainbowTool()

@property (readwrite) rainbowToolState state;

@end

@implementation RainbowTool

@synthesize alpha;
@synthesize indicatorPosition;
@synthesize state;
@synthesize delegate;

-(void)changeSelectedColor
{
	CGPoint colorP = CGPointMake(indicatorPositionInTool.x - (colorMapScreenRect.origin.x - position.origin.x), 
                                 indicatorPositionInTool.y - (colorMapScreenRect.origin.y - position.origin.y));
	
	CGFloat color[4];
	[colorMap getPixel:color atX:colorP.x y:colorP.y];
	
	if (color[3] > 0.9) 
    {
		color[3] = 1;
        
        if(delegate != nil)
            [delegate newColorSelectedWithRed:color[0] green:color[1] blue:color[2] alpha:1];
	}
}


- (id)init
{
    self = [super init];
    
    if (self)
    {
        colorMap = [[[UIImage imageNamed:@"ColorMap.png"] imageBitmapRep] retain];
        
        CGSize colorMapsize = colorMap.size;
        colorMapScreenRect = CGRectMake(RAINBOW_TOOL_OFFSET_X - 7, 
                                        RAINBOW_TOOL_OFFSET_Y + 7, 
                                        colorMapsize.width, 
                                        colorMapsize.height);
        [self changeStateTo:RAINBOW_TOOL_STATE_OUT_OF_SCREEN AtTime:CFAbsoluteTimeGetCurrent()];
    }
    
    return self;
}

- (void)dealloc
{
    [animation release]; animation = nil;
    [colorMap release]; colorMap = nil;
    [super dealloc];
}

- (ThreeDAnimation *)animation
{
    if (!animation)
    {
        animation = [[ThreeDAnimation alloc] init];
        animation.state = ANIMATION_STATE_STOPPED;
        animation.delegate = self;
    }
    
    return animation;
}

-(CGRect)position
{
    return position;
}
-(void)setPosition:(CGRect)positionValue
{
    position = positionValue;
    
    indicatorPosition.x = position.origin.x + indicatorPositionInTool.x;
    indicatorPosition.y = position.origin.y + indicatorPositionInTool.y;
}

#pragma mark - State Machine

- (void)changeStateTo:(rainbowToolState)newstate AtTime:(double)currtime
{
    switch (newstate) 
    {
        case RAINBOW_TOOL_STATE_OUT_OF_SCREEN:
        {
            break;
        }
            
        case RAINBOW_TOOL_STATE_ON_SCREEN:
        {
            break;
        }
            
        case RAINBOW_TOOL_STATE_APPEARS_ON_SCREEN:
        {
            // анимируем выезд радуги на экран
            self.animation.startAlpha = self.alpha;
            self.animation.endAlpha = 1.0;
            
            self.animation.startPosition = self.position;
            self.animation.endPosition = CGRectMake(RAINBOW_TOOL_OFFSET_X, 
                                                    RAINBOW_TOOL_OFFSET_Y, 
                                                    RAINBOW_TOOL_WIDTH, 
                                                    RAINBOW_TOOL_HEIGHT);
            
            self.animation.startTime = currtime + (DRAWING_TOOLS_BOX_UNHIDING_DURATION - RAINBOW_TOOL_UNHIDING_DURATION);
            self.animation.endTime = self.animation.startTime + RAINBOW_TOOL_UNHIDING_DURATION;
            
            break;
        }
            
        case RAINBOW_TOOL_STATE_DISAPPEARS_FROM_SCREEN:
        {
            self.animation.startAlpha = self.alpha;
            self.animation.endAlpha = 1.0;
            
            self.animation.startPosition = self.position;
            self.animation.endPosition = CGRectMake(-RAINBOW_TOOL_WIDTH, 
                                                    RAINBOW_TOOL_OFFSET_Y, 
                                                    RAINBOW_TOOL_WIDTH, 
                                                    RAINBOW_TOOL_HEIGHT);
            
            self.animation.startTime = currtime;
            self.animation.endTime = self.animation.startTime + RAINBOW_TOOL_HIDING_DURATION;
            
            self.animation.state = ANIMATION_STATE_PLAYING;
            
            break;
        }          
            
        default:
        {
            NSLog(@"%@ : %@ unexpected new state: %d !", self, NSStringFromSelector(_cmd), newstate);
            break;
        }
    }
    
    self.state = newstate;
    
}

#pragma mark - Physics

- (void)updatePhysicsAtTime:(double)currtime
{
    [self.animation updatePhysicsAtTime:currtime];
    
    if (self.animation.state == ANIMATION_STATE_PLAYING)
    {
        self.alpha = animation.alpha;
        self.position = animation.position;
    }
    
    switch (state) 
    {
        case RAINBOW_TOOL_STATE_OUT_OF_SCREEN:
        {
            break;
        }
            
        case RAINBOW_TOOL_STATE_ON_SCREEN:
        {
            break;
        }
            
        case RAINBOW_TOOL_STATE_APPEARS_ON_SCREEN:
        {
            break;
        }
            
        case RAINBOW_TOOL_STATE_DISAPPEARS_FROM_SCREEN:
        {
            break;
        }
            
        default:
        {
            NSLog(@"%@ : %@ WARNING!!! unexpected RainbowTool state : %d", self, NSStringFromSelector(_cmd), self.state);
            break;
        }
    }
}

#pragma mark - ThreeDAnimation Delegate methods

- (void)animationEnded
{
    self.position = animation.position;
    self.alpha = animation.alpha;
    
    if(state == RAINBOW_TOOL_STATE_DISAPPEARS_FROM_SCREEN)
        [self changeStateTo:RAINBOW_TOOL_STATE_OUT_OF_SCREEN AtTime:CFAbsoluteTimeGetCurrent()];
    else if(state == RAINBOW_TOOL_STATE_APPEARS_ON_SCREEN)
        [self changeStateTo:RAINBOW_TOOL_STATE_ON_SCREEN AtTime:CFAbsoluteTimeGetCurrent()];
}

#pragma mark - Gesture handlers

- (void)touchBeganAtLocation:(CGPoint)location
{
    if(state == RAINBOW_TOOL_STATE_ON_SCREEN && CGRectContainsPoint(colorMapScreenRect, location))
    {
        movingIndicator = YES;
        
        indicatorPosition = location;
        indicatorPositionInTool = CGPointMake(location.x - position.origin.x, location.y - position.origin.y);
        
        [self changeSelectedColor];
    }
}

- (void)touchMovedAtLocation:(CGPoint)location PreviousLocation:(CGPoint)previousLocation
{
//    NSLog(@"%@ : %@ begin", self, NSStringFromSelector(_cmd));

    if(movingIndicator && CGRectContainsPoint(colorMapScreenRect, location))
    {
        indicatorPosition = location;
        indicatorPositionInTool = CGPointMake(location.x - position.origin.x, location.y - position.origin.y);
        [self changeSelectedColor];
    }
    
//    NSLog(@"%@ : %@ end", self, NSStringFromSelector(_cmd));

}

- (void)touchEndedAtLocation:(CGPoint)location
{
    movingIndicator = NO;
}

- (void)touchesCancelledLocation:(CGPoint)location
{
    movingIndicator = NO;
}

#pragma mark - Save & Restore state

- (void)saveState
{
    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
    
    [defaults setFloat:indicatorPositionInTool.x forKey:@"IndicatorPositionInRainbowToolX"];
    [defaults setFloat:indicatorPositionInTool.y forKey:@"IndicatorPositionInRainbowToolY"];
    
    [defaults synchronize];
}

- (void)restoreState
{
    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
    indicatorPositionInTool = CGPointMake([defaults floatForKey:@"IndicatorPositionInRainbowToolX"], [defaults floatForKey:@"IndicatorPositionInRainbowToolY"]);
    if(CGPointEqualToPoint(indicatorPositionInTool, CGPointZero))
        indicatorPositionInTool = CGPointMake(41, 341);
    [self changeSelectedColor];
}


@end
