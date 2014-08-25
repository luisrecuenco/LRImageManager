// UIImageView+LRNetworking.m
//
// Copyright (c) 2013 Luis Recuenco
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

#import "UIImageView+LRNetworking.h"
#import <objc/runtime.h>

static const LRImageViewAnimationType kDefaultImageViewAnimationType = LRImageViewAnimationTypeCrossDissolve;
static NSTimeInterval const kDefaultImageViewFadeAnimationTime = 0.25;

@implementation UIImageView (LRNetworking)

- (void)lr_setImageWithURL:(NSURL *)url
{
    [self lr_setImageWithURL:url placeholderImage:nil];
}

- (void)lr_setImageWithURL:(NSURL *)url placeholderImage:(UIImage *)placeholderImage
{
    [self lr_setImageWithURL:url
            placeholderImage:placeholderImage
         cacheStorageOptions:[LRImageManager sharedManager].imageCache.cacheStorageOptions];
}

- (void)lr_setImageWithURL:(NSURL *)url size:(CGSize)size
{
    [self lr_setImageWithURL:url placeholderImage:nil size:size];
}

- (void)lr_setImageWithURL:(NSURL *)url cacheStorageOptions:(LRCacheStorageOptions)cacheStorageOptions
{
    [self lr_setImageWithURL:url placeholderImage:nil cacheStorageOptions:cacheStorageOptions];
}

- (void)lr_setImageWithURL:(NSURL *)url
          placeholderImage:(UIImage *)placeholderImage
       cacheStorageOptions:(LRCacheStorageOptions)cacheStorageOptions
{
    [self lr_setImageWithURL:url
            placeholderImage:placeholderImage
                        size:self.frame.size
         cacheStorageOptions:cacheStorageOptions];
}

- (void)lr_setImageWithURL:(NSURL *)url
          placeholderImage:(UIImage *)placeholderImage
                      size:(CGSize)size
{
    [self lr_setImageWithURL:url
            placeholderImage:placeholderImage
                        size:size
         cacheStorageOptions:[LRImageManager sharedManager].imageCache.cacheStorageOptions];
}

- (void)lr_setImageWithURL:(NSURL *)url
          placeholderImage:(UIImage *)placeholderImage
                      size:(CGSize)size
       cacheStorageOptions:(LRCacheStorageOptions)cacheStorageOptions
{
    [[LRImageManager sharedManager] downloadImageForImageView:self
                                             placeholderImage:placeholderImage
                                            activityIndicator:self.lr_activityIndicator
                                                     imageURL:url
                                                         size:size
                                          cacheStorageOptions:cacheStorageOptions
                                            completionHandler:self.lr_completionHandler];
}

- (void)lr_cancelImageOperation;
{
    [[LRImageManager sharedManager] cancelDownloadImageForImageView:self];
}

static const void * kLRCompletionHandlerObjectKey = &kLRCompletionHandlerObjectKey;
static const void * kLRActivityIndicatorObjectKey = &kLRActivityIndicatorObjectKey;
static const void * kLRAnimationType = &kLRAnimationType;
static const void * kLRFadeAnimationTime = &kLRFadeAnimationTime;

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

- (void)lr_setAnimationType:(LRImageViewAnimationType)animationType
{
    objc_setAssociatedObject(self, kLRAnimationType, @(animationType), OBJC_ASSOCIATION_RETAIN);
}

- (LRImageViewAnimationType)lr_animationType
{
    NSNumber *animationTypeNumber = objc_getAssociatedObject(self, kLRAnimationType);
    return animationTypeNumber ? [animationTypeNumber unsignedIntegerValue] : kDefaultImageViewAnimationType;
}

#pragma mark - Animation Time

- (void)lr_setFadeAnimationTime:(NSTimeInterval)fadeAnimationTme
{
    objc_setAssociatedObject(self, kLRFadeAnimationTime, @(fadeAnimationTme), OBJC_ASSOCIATION_RETAIN);
}

- (NSTimeInterval)lr_fadeAnimationTime
{
    NSNumber *fadeAnimationTimeNumber = objc_getAssociatedObject(self, kLRFadeAnimationTime);
    return fadeAnimationTimeNumber ? [fadeAnimationTimeNumber doubleValue] : kDefaultImageViewFadeAnimationTime;
}

@end
