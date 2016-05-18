//
//  UIView+LRNetworking.h
//  Youla
//
//  Created by Develop Allgoritm on 17/05/16.
//  Copyright © 2016 allgoritm. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LRImageManager.h"

typedef NS_ENUM(NSUInteger, LRAnimationType)
{
    LRAnimationTypeNone,
    LRAnimationTypeCrossDissolve,
    LRAnimationTypeFlipFromLeft,
    LRAnimationTypeFlipFromRight,
    LRAnimationTypeFlipFromTop,
    LRAnimationTypeFlipFromBottom,
    LRAnimationTypeCurlUp,
    LRAnimationTypeCurlDown,
};

@interface UIView (LRNetworking)

@property (nonatomic, strong, setter = lr_setActivityIndicator:) UIView<LRActivityIndicator> *lr_activityIndicator;

@property (nonatomic, copy, setter = lr_setPostProcessingBlock:) LRImagePostProcessingBlock lr_postProcessingBlock;

@property (nonatomic, copy, setter = lr_setCompletionHandler:) LRImageCompletionHandler lr_completionHandler;

@property (nonatomic, setter = lr_setAnimationType:) LRAnimationType lr_animationType;
@property (nonatomic, setter = lr_setAnimationTime:) NSTimeInterval lr_animationTime;
@property (nonatomic, setter = lr_setImageURL:) NSURL *lr_imageURL;

@end
