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
#import "LRImagePresenter.h"
#import <objc/runtime.h>

static const LRImageViewAnimationType kDefaultImageViewAnimationType = LRImageViewAnimationTypeFade;

static const void * kLRImagePresenterObjectKey;
static const void * kLRCompletionBlockObjectKey;

@interface UIImageView (LRImageViewAdditons)

@property (nonatomic, strong) LRImagePresenter *imagePresenter;

@property (nonatomic, copy) LRNetImageBlock completionBlock;

@end

@implementation UIImageView (LRImageViewAdditons)

@dynamic imagePresenter;
@dynamic completionBlock;

@end

@implementation UIImageView (LRNetworking)

- (void)lr_setImageWithURL:(NSURL *)url
{
    [self lr_setImageWithURL:url placeholderImage:nil];
}

- (void)lr_setImageWithURL:(NSURL *)url
          placeholderImage:(UIImage *)placeholderImage
{
    [self lr_setImageWithURL:url
            placeholderImage:placeholderImage
         memCacheStorageType:[LRImageCache sharedImageCache].memCacheStorageType];
}

- (void)lr_setImageWithURL:(NSURL *)url
                      size:(CGSize)size
{
    [self lr_setImageWithURL:url placeholderImage:nil size:size];
}

- (void)lr_setImageWithURL:(NSURL *)url
       memCacheStorageType:(LRMemCacheStorageType)memCacheStorageType
{
    [self lr_setImageWithURL:url placeholderImage:nil memCacheStorageType:memCacheStorageType];
}

- (void)lr_setImageWithURL:(NSURL *)url
          placeholderImage:(UIImage *)placeholderImage
       memCacheStorageType:(LRMemCacheStorageType)memCacheStorageType
{
    [self lr_setImageWithURL:url
            placeholderImage:placeholderImage
                        size:self.frame.size
         memCacheStorageType:memCacheStorageType];
}

- (void)lr_setImageWithURL:(NSURL *)url
          placeholderImage:(UIImage *)placeholderImage
                      size:(CGSize)size
{
    [self lr_setImageWithURL:url
            placeholderImage:placeholderImage
                        size:size
         memCacheStorageType:[LRImageCache sharedImageCache].memCacheStorageType];
}

- (void)lr_setImageWithURL:(NSURL *)url
          placeholderImage:(UIImage *)placeholderImage
                      size:(CGSize)size
       memCacheStorageType:(LRMemCacheStorageType)memCacheStorageType
{
    [self lr_setImageWithURL:url
            placeholderImage:placeholderImage
                        size:size
                   diskCache:![LRImageCache sharedImageCache].skipDiskCache
         memCacheStorageType:memCacheStorageType
               animationType:kDefaultImageViewAnimationType];
}

- (void)lr_setImageWithURL:(NSURL *)url
          placeholderImage:(UIImage *)placeholderImage
                      size:(CGSize)size
                 diskCache:(BOOL)diskCache
       memCacheStorageType:(LRMemCacheStorageType)memCacheStorageType
             animationType:(LRImageViewAnimationType)animationType
{
    [self cancelImageOperation];
    
    self.imagePresenter = [[LRImagePresenter alloc] initWithImageView:self
                                                             imageURL:url
                                                     placeholderImage:placeholderImage
                                                                 size:size
                                                            diskCache:diskCache
                                                  memCacheStorageType:memCacheStorageType
                                                        animationType:animationType];
    
    [self.imagePresenter startPresentingWithCompletionBlock:self.completionBlock];
}

- (void)cancelImageOperation;
{
    [self.imagePresenter cancelPresenting];
}

#pragma mark - Completion Block

- (void)setCompletionBlock:(LRNetImageBlock)completionBlock
{
    objc_setAssociatedObject(self, &kLRCompletionBlockObjectKey, completionBlock, OBJC_ASSOCIATION_COPY);
}

- (LRNetImageBlock)completionBlock
{
    return (LRNetImageBlock)objc_getAssociatedObject(self, &kLRCompletionBlockObjectKey);
}

#pragma mark - UIImageView presenter

- (LRImagePresenter *)imagePresenter
{
    return (LRImagePresenter *)objc_getAssociatedObject(self, &kLRImagePresenterObjectKey);
}

- (void)setImagePresenter:(LRImagePresenter *)imagePresenter
{
    objc_setAssociatedObject(self, &kLRImagePresenterObjectKey, imagePresenter, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end
