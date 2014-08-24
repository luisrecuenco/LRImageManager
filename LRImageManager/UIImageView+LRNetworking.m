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

static const LRImageViewAnimationType kDefaultImageViewAnimationType = LRImageViewAnimationTypeFade;

static const void * kLRCompletionHandlerObjectKey = &kLRCompletionHandlerObjectKey;

@interface UIImageView (LRImageViewAdditons)

@property (nonatomic, copy) LRImageCompletionHandler completionHandler;

@end

@implementation UIImageView (LRImageViewAdditons)

@dynamic completionHandler;

@end

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
    [self lr_setImageWithURL:url
            placeholderImage:placeholderImage
                        size:size
         cacheStorageOptions:cacheStorageOptions
               animationType:kDefaultImageViewAnimationType];
}

- (void)lr_setImageWithURL:(NSURL *)url
          placeholderImage:(UIImage *)placeholderImage
                      size:(CGSize)size
       cacheStorageOptions:(LRCacheStorageOptions)cacheStorageOptions
             animationType:(LRImageViewAnimationType)animationType
{
    [[LRImageManager sharedManager] downloadImageForImageView:self
                                                     imageURL:url
                                             placeholderImage:placeholderImage
                                                         size:size
                                          cacheStorageOptions:cacheStorageOptions
                                                animationType:animationType
                                            completionHandler:self.completionHandler];
}

- (void)cancelImageOperation;
{
    [[LRImageManager sharedManager] cancelDownloadImageForImageView:self];
}

#pragma mark - Completion Block

- (void)setCompletionHandler:(LRImageCompletionHandler)completionHandler
{
    objc_setAssociatedObject(self, kLRCompletionHandlerObjectKey, completionHandler, OBJC_ASSOCIATION_COPY);
}

- (LRImageCompletionHandler)completionHandler
{
    return (LRImageCompletionHandler)objc_getAssociatedObject(self, kLRCompletionHandlerObjectKey);
}

@end
