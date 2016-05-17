//
//  UIView+LRNetworking.m
//  Youla
//
//  Created by Develop Allgoritm on 17/05/16.
//  Copyright © 2016 allgoritm. All rights reserved.
//

#import "UIView+LRNetworking.h"
#import <objc/runtime.h>

static const LRAnimationType kDefaultImageViewAnimationType = LRAnimationTypeCrossDissolve;
static NSTimeInterval const kDefaultImageViewAnimationTime = 0.25;

@implementation UIView (LRNetworking)

static const void * kLRCompletionHandlerObjectKey = &kLRCompletionHandlerObjectKey;
static const void * kLRActivityIndicatorObjectKey = &kLRActivityIndicatorObjectKey;
static const void * kLRAnimationType = &kLRAnimationType;
static const void * kLRAnimationTime = &kLRAnimationTime;
static const void * kLRPostProcessingBlock = &kLRPostProcessingBlock;

#pragma mark - Completion Block

- (void)lr_setCompletionHandler:(LRImageCompletionHandler)completionHandler
{
    objc_setAssociatedObject(self, kLRCompletionHandlerObjectKey, completionHandler, OBJC_ASSOCIATION_COPY);
}

- (LRImageCompletionHandler)lr_completionHandler
{
    return objc_getAssociatedObject(self, kLRCompletionHandlerObjectKey);
}

#pragma mark - Activity Indicator

- (void)lr_setActivityIndicator:(UIView<LRActivityIndicator> *)activityIndicator
{
    [self.lr_activityIndicator removeFromSuperview];
    
    objc_setAssociatedObject(self, kLRActivityIndicatorObjectKey, activityIndicator, OBJC_ASSOCIATION_RETAIN);
}

- (UIView<LRActivityIndicator> *)lr_activityIndicator
{
    return objc_getAssociatedObject(self, kLRActivityIndicatorObjectKey);
}

#pragma mark - Animation Type

- (void)lr_setAnimationType:(LRAnimationType)animationType
{
    objc_setAssociatedObject(self, kLRAnimationType, @(animationType), OBJC_ASSOCIATION_RETAIN);
}

- (LRAnimationType)lr_animationType
{
    NSNumber *animationTypeNumber = objc_getAssociatedObject(self, kLRAnimationType);
    return animationTypeNumber ? [animationTypeNumber unsignedIntegerValue] : kDefaultImageViewAnimationType;
}

#pragma mark - Animation Time

- (void)lr_setAnimationTime:(NSTimeInterval)animationTme
{
    objc_setAssociatedObject(self, kLRAnimationTime, @(animationTme), OBJC_ASSOCIATION_RETAIN);
}

- (NSTimeInterval)lr_animationTime
{
    NSNumber *animationTimeNumber = objc_getAssociatedObject(self, kLRAnimationTime);
    return animationTimeNumber ? [animationTimeNumber doubleValue] : kDefaultImageViewAnimationTime;
}

#pragma mark - Post Processing block

- (void)lr_setPostProcessingBlock:(LRImagePostProcessingBlock)postProcessingBlock
{
    objc_setAssociatedObject(self, kLRPostProcessingBlock, postProcessingBlock, OBJC_ASSOCIATION_COPY);
}

- (LRImagePostProcessingBlock)lr_postProcessingBlock
{
    return objc_getAssociatedObject(self, kLRPostProcessingBlock);
}

@end
