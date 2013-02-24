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

static CGFloat const kImageViewFadeAnimationTime = 0.25f;

static char kLRImagePresenterObjectKey;

@interface UIImageView (LRImageViewAdditons)

@property (nonatomic, strong) LRImagePresenter *imagePresenter;

@end

@implementation UIImageView (LRImageViewAdditons)

@dynamic imagePresenter;

@end

@implementation UIImageView (LRNetworking)

- (void)setImageWithURL:(NSURL *)url
{
    [self setImageWithURL:url placeholderImage:nil];
}

- (void)setImageWithURL:(NSURL *)url
       placeholderImage:(UIImage *)placeholderImage
{
    [self setImageWithURL:url
         placeholderImage:placeholderImage
           storageOptions:LRCacheStorageOptionsNSCache];
}

- (void)setImageWithURL:(NSURL *)url
       placeholderImage:(UIImage *)placeholderImage
         storageOptions:(LRCacheStorageOptions)storageOptions
{
    [self setImageWithURL:url
         placeholderImage:placeholderImage
                     size:self.frame.size
           storageOptions:storageOptions];
}

- (void)setImageWithURL:(NSURL *)url
       placeholderImage:(UIImage *)placeholderImage
                   size:(CGSize)size
         storageOptions:(LRCacheStorageOptions)storageOptions
{
    [self setImageWithURL:url
         placeholderImage:placeholderImage
                     size:size
           storageOptions:storageOptions
         animationOptions:LRImageViewAnimationOptionFade];
}

- (void)setImageWithURL:(NSURL *)url
       placeholderImage:(UIImage *)placeholderImage
                   size:(CGSize)size
         storageOptions:(LRCacheStorageOptions)storageOptions
       animationOptions:(LRImageViewAnimationOptions)animationOptions
{
    [self cancelImageOperation];
    
    self.imagePresenter = [LRImagePresenter presenterForImageView:self
                                                          withURL:url
                                                 placeholderImage:placeholderImage
                                                             size:size
                                                   storageOptions:storageOptions
                                                 animationOptions:animationOptions];
    
    [self.imagePresenter startPresenting];
}

- (void)cancelImageOperation;
{
    [self.imagePresenter cancelPresenting];
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
