//
//  GestureControl.h
//  Gesture
//
//  Created by TangYanQiong on 2017/3/27.
//  Copyright © 2017年 TangYanQiong. All rights reserved.
//

#import <UIKit/UIKit.h>

#pragma mark - GestureObject -

/**
 手势TYPE
 */
typedef enum {
    SDK_GESTURE_TYPE_NONE,                       //无类型
    SDK_GESTURE_TYPE_SZ_SLIDE,                   //竖直滑动手势
    SDK_GESTURE_TYPE_SP_SLIDE,                   //水平滑动手势
    SDK_GESTURE_TYPE_CLICK,                      //点击手势，目前只支持单击和双击
    SDK_GESTURE_TYPE_LONG_PRESS                  //长按手势
} SDK_GESTURE_TYPE;

/**
 手势滑动TYPE
 */
typedef enum {
    SDK_SLIDE_TYPE_NONE,                        //无类型
    SDK_SLIDE_TYPE_CHANGE,                      //滑动中
    SDK_SLIDE_TYPE_END                          //滑动结束
} SDK_SLIDE_TYPE;

@interface GestureObject : NSObject
@property (nonatomic) SDK_GESTURE_TYPE type;
/**
 设置手势滑动距离触发对外手势响应事件，不是滑动手势则不设置
 应用type：SDK_GESTURE_TYPE_V_SLIDE 与 SDK_GESTURE_TYPE_H_SLIDE
 */
@property (nonatomic) NSInteger moveInterval;
/**
 最小长按时间
 应用type：SDK_GESTURE_TYPE_LONG_PRESS
 */
@property (nonatomic) CFTimeInterval minimumPressDuration;
/**
 手势作用区域
 */
@property (nonatomic) CGRect frame;
@end

#pragma mark - GestureControl -

@protocol GestureDelegate <NSObject>
@optional
/**
 回调点击事件

 @param clickTimes 被点击的次数，一般为单击或双击
 */
- (void)clickEvent:(NSUInteger)clickTimes;

/**
 水平滑动触发事件

 @param gestureDirection 手势方向
 @param slideType 手势滑动的状态
 @param gestureObj 当前响应手势对象
 */
- (void)SP_slideEventWith:(UISwipeGestureRecognizerDirection)gestureDirection slideType:(SDK_SLIDE_TYPE)slideType andObject:(GestureObject *)gestureObj;

/**
 竖直滑动触发事件

 @param gestureDirection 手势方向
 @param slideType 手势滑动的状态
 @param gestureObj 当前响应手势对象
 */
- (void)SZ_slideEventWith:(UISwipeGestureRecognizerDirection)gestureDirection slideType:(SDK_SLIDE_TYPE)slideType andObject:(GestureObject *)gestureObj;

/**
 长按触发事件
 */
- (void)longPressEventWithObject:(GestureObject *)gestureObj;
@end

@interface GestureControl : UIControl
@property (nonatomic, assign) id <GestureDelegate> delegate;

/**
 创建单个手势控件

 @param gestureObj 传入想要创建的手势对象
 @param target 手势控件目标对象
 @return 返回手势控件对象
 */
+ (GestureControl *)createControlSignleBy:(GestureObject *)gestureObj withTarget:(id)target;

/**
 创建多个手势控件
 
 @param controlFrame 手势控件frame
 @param gestureObjsArr 传入想要创建的手势对象集合
 @param target 手势控件目标对象
 @return 返回手势控件对象
 */
+ (GestureControl *)createControlMultipleBy:(CGRect)controlFrame withObjects:(NSArray *)gestureObjsArr target:(id)target;

@end
