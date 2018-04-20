//
//  GestureControl.m
//  Gesture
//
//  Created by TangYanQiong on 2017/3/27.
//  Copyright © 2017年 TangYanQiong. All rights reserved.
//

#import "GestureControl.h"

@implementation GestureObject
@end

@interface GestureControl () <UIGestureRecognizerDelegate>
/**
 pan手势的存储的手势，以及对应的手势对象
 */
@property (nonatomic, strong) NSMutableArray *gestureRecognizersArr, *gestureObjsArr;
/**
 当前正在展示的手势类型
 */
@property (nonatomic) SDK_GESTURE_TYPE nowShowGestureType;
/**
 当前滑动的方向
 */
@property (nonatomic) UISwipeGestureRecognizerDirection nowSwipeGestureRecognizerDirection;

/**
 移动手势的point
 */
@property (nonatomic) CGPoint movePoint;
/**
 原有本Control Frame
 */
@property (nonatomic) CGRect originalFrame;
@end
@implementation GestureControl

#pragma mark - Outside Methods -

+ (GestureControl *)createControlSignleBy:(GestureObject *)gestureObj withTarget:(id)target
{
    if (gestureObj.frame.size.width > 0 && gestureObj.frame.size.height > 0 && target) {
        GestureControl *tempGestureControl = [[GestureControl alloc] initWithFrame:gestureObj.frame];
        tempGestureControl.originalFrame = gestureObj.frame;
        tempGestureControl.delegate = target;
        [tempGestureControl addGestureBy:gestureObj];
        if ([target isKindOfClass:[UIView class]]) {
            [target addSubview:tempGestureControl];
        }else if ([target isKindOfClass:[UIViewController class]]){
            [((UIViewController *)target).view addSubview:tempGestureControl];
        }
        return tempGestureControl;
    }else{
        return nil;
    }
}

+ (GestureControl *)createControlMultipleBy:(CGRect)controlFrame withObjects:(NSArray *)gestureObjsArr target:(id)target
{
    if (controlFrame.size.width > 0 && controlFrame.size.height > 0 && target) {
        GestureControl *tempGestureControl = [[GestureControl alloc] initWithFrame:controlFrame];
        tempGestureControl.originalFrame = controlFrame;
        tempGestureControl.delegate = target;
        [gestureObjsArr enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            [tempGestureControl addGestureBy:obj];
        }];
        if ([target isKindOfClass:[UIView class]]) {
            [target addSubview:tempGestureControl];
        }else if ([target isKindOfClass:[UIViewController class]]){
            [((UIViewController *)target).view addSubview:tempGestureControl];
        }
        return tempGestureControl;
    }else{
        return nil;
    }
}

#pragma mark - Set/Get Methods -

- (NSMutableArray *)gestureRecognizersArr
{
    if (!_gestureRecognizersArr) {
        _gestureRecognizersArr = [NSMutableArray array];
    }
    return _gestureRecognizersArr;
}

- (NSMutableArray *)gestureObjsArr
{
    if (!_gestureObjsArr) {
        _gestureObjsArr = [NSMutableArray array];
    }
    return _gestureObjsArr;
}

#pragma mark - Inside Methods -

- (void)addGestureBy:(GestureObject *)gestureObj
{
    UIGestureRecognizer *tempGesture = nil;
    
    switch (gestureObj.type)
    {
        //注：虽然都是pan手势，但是仍需分开处理事件，避免手势在一起影响重复调用
        case SDK_GESTURE_TYPE_SP_SLIDE:
        {
            UIPanGestureRecognizer *panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handle_SP_Swipe:)];
            panGesture.delegate = self;
            [self addGestureRecognizer:panGesture];
            
            tempGesture = panGesture;
        }
            break;
        case SDK_GESTURE_TYPE_SZ_SLIDE:
        {
            UIPanGestureRecognizer *panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handle_SZ_Swipe:)];
            panGesture.delegate = self;
            [self addGestureRecognizer:panGesture];
            
            tempGesture = panGesture;
        }
            break;
        //
        case SDK_GESTURE_TYPE_CLICK:
        {
            UITapGestureRecognizer *singleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapAction:)];
            singleTap.delegate = self;
            singleTap.numberOfTapsRequired = 1;
            [self addGestureRecognizer:singleTap];
            
            UITapGestureRecognizer *doubleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapAction:)];
            doubleTap.delegate = self;
            doubleTap.numberOfTapsRequired = 2;
            [self addGestureRecognizer:doubleTap];
            
            //当没有检测到doubleTap或者检测doubleTap失败，singleTap才有效
            [singleTap requireGestureRecognizerToFail:doubleTap];
        }
            break;
        case SDK_GESTURE_TYPE_LONG_PRESS:
        {
            UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPressAction:)];
            longPress.delegate = self;
            longPress.minimumPressDuration = gestureObj.minimumPressDuration;
            [self addGestureRecognizer:longPress];
            
            tempGesture = longPress;
        }
            break;
        default:
            break;
    }
    
    if (tempGesture)
    {
        [self.gestureRecognizersArr addObject:tempGesture];
        [self.gestureObjsArr addObject:gestureObj];
    }
}

- (GestureObject *)getGestureObjectBy:(UIGestureRecognizer *)gestureRecognizer
{
    GestureObject *gestureObj = nil;
    if ([self.gestureRecognizersArr containsObject:gestureRecognizer]) {
        NSInteger gestureIndex = [self.gestureRecognizersArr indexOfObject:gestureRecognizer];
        gestureObj = [self.gestureObjsArr objectAtIndex:gestureIndex];
    }
    return gestureObj;
}

#pragma mark - UIGestureRecognizerDelegate -

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer
{
    GestureObject *getureObj = [self getGestureObjectBy:gestureRecognizer];
    CGPoint loaction = [gestureRecognizer locationInView:self.superview];
    if ((getureObj && CGRectContainsPoint(getureObj.frame, loaction)) || !getureObj) {
        return YES;
    }else{
        return NO;
    }
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    return YES;
}

#pragma mark - UIGestureRecognizer Action -

- (void)handle_SP_Swipe:(UIPanGestureRecognizer *)panGesture
{
    if (self.delegate && [self.delegate respondsToSelector:@selector(SP_slideEventWith:slideType:andObject:)])
    {
        GestureObject *gestureObj = [self getGestureObjectBy:panGesture];
        if (!gestureObj || gestureObj.type != SDK_GESTURE_TYPE_SP_SLIDE) return;
        if (self.nowShowGestureType != SDK_GESTURE_TYPE_NONE && self.nowShowGestureType != gestureObj.type) return;
        
        if (panGesture.state == UIGestureRecognizerStateChanged)
        {
            CGPoint translation = [panGesture translationInView:self.superview];
            CGFloat distanceX = fabs(fabs(self.movePoint.x)-fabs(translation.x));
            
            //不满足X方向滑动有效距离则return
            if (distanceX < gestureObj.moveInterval)
                return;
            
            //水平方向的滑动
            if (self.movePoint.x >= translation.x) {
                //向左滑动
                [self.delegate SP_slideEventWith:UISwipeGestureRecognizerDirectionLeft slideType:SDK_SLIDE_TYPE_CHANGE andObject:gestureObj];
                self.nowSwipeGestureRecognizerDirection = UISwipeGestureRecognizerDirectionLeft;
            }else{
                //向右滑动
                [self.delegate SP_slideEventWith:UISwipeGestureRecognizerDirectionRight slideType:SDK_SLIDE_TYPE_CHANGE andObject:gestureObj];
                self.nowSwipeGestureRecognizerDirection = UISwipeGestureRecognizerDirectionRight;
            }
            
            self.movePoint = translation;
            self.nowShowGestureType = gestureObj.type;
        } else {
            if (self.nowShowGestureType == gestureObj.type) {
                [self.delegate SP_slideEventWith:self.nowSwipeGestureRecognizerDirection
                                       slideType:SDK_SLIDE_TYPE_END
                                       andObject:gestureObj];
                
                self.movePoint = CGPointMake(0, 0);
                self.nowShowGestureType = SDK_GESTURE_TYPE_NONE;
            }
        }
    }
}

- (void)handle_SZ_Swipe:(UIPanGestureRecognizer *)panGesture
{
    if (self.delegate && [self.delegate respondsToSelector:@selector(SZ_slideEventWith:slideType:andObject:)])
    {
        GestureObject *gestureObj = [self getGestureObjectBy:panGesture];
        if (!gestureObj || gestureObj.type != SDK_GESTURE_TYPE_SZ_SLIDE) return;
        if (self.nowShowGestureType != SDK_GESTURE_TYPE_NONE && self.nowShowGestureType != gestureObj.type) return;
        
        if (panGesture.state == UIGestureRecognizerStateChanged)
        {
            CGPoint translation = [panGesture translationInView:self.superview];
            CGFloat distanceY = fabs(fabs(self.movePoint.y)-fabs(translation.y));
            
            
            //不满足Y方向滑动有效距离则return
            if (distanceY < gestureObj.moveInterval)
                return;
            
            //竖直方向的滑动
            if (self.movePoint.y >= translation.y) {
                //向上滑动
                [self.delegate SZ_slideEventWith:UISwipeGestureRecognizerDirectionUp slideType:SDK_SLIDE_TYPE_CHANGE andObject:gestureObj];
                self.nowSwipeGestureRecognizerDirection = UISwipeGestureRecognizerDirectionUp;
            }else{
                //向下滑动
                [self.delegate SZ_slideEventWith:UISwipeGestureRecognizerDirectionDown slideType:SDK_SLIDE_TYPE_CHANGE andObject:gestureObj];
                self.nowSwipeGestureRecognizerDirection = UISwipeGestureRecognizerDirectionDown;
            }
            
            self.movePoint = translation;
            self.nowShowGestureType = gestureObj.type;
        } else {
            if (self.nowShowGestureType == gestureObj.type) {
                [self.delegate SZ_slideEventWith:self.nowSwipeGestureRecognizerDirection
                                       slideType:SDK_SLIDE_TYPE_END
                                       andObject:gestureObj];
                
                self.movePoint = CGPointMake(0, 0);
                self.nowShowGestureType = SDK_GESTURE_TYPE_NONE;
            }
        }
    }
}

- (void)tapAction:(UITapGestureRecognizer *)tapGesture
{
    if (self.delegate && [self.delegate respondsToSelector:@selector(clickEvent:)]) {
        [self.delegate clickEvent:tapGesture.numberOfTapsRequired];
    }
}

- (void)longPressAction:(UILongPressGestureRecognizer *)longPress
{
    if (self.delegate && [self.delegate respondsToSelector:@selector(longPressEventWithObject:)]) {
        [self.delegate longPressEventWithObject:[self getGestureObjectBy:longPress]];
    }
}

#pragma mark LifeCycle -

- (void)layoutSubviews
{
    CGFloat scaleWidth = self.frame.size.width/self.originalFrame.size.width;
    CGFloat scaleHeight = self.frame.size.height/self.originalFrame.size.height;
    
    [self.gestureObjsArr enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        GestureObject *gestureObject = (GestureObject *)obj;
        if ([gestureObject isKindOfClass:[GestureObject class]]) {
            gestureObject.frame = CGRectMake(scaleWidth*gestureObject.frame.origin.x, scaleHeight*gestureObject.frame.origin.y, scaleWidth*gestureObject.frame.size.width, scaleHeight*gestureObject.frame.size.height);
        }
    }];
    
    self.originalFrame = self.frame;
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end
