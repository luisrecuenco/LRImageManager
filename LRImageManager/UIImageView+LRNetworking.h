// UIImageView+LRNetworking.h
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

#import "LRImageManager.h"

typedef NS_ENUM(NSUInteger, LRImageViewAnimationType)
{
    LRImageViewAnimationTypeNone,
    LRImageViewAnimationTypeCrossDissolve,
    LRImageViewAnimationTypeFlipFromLeft,
    LRImageViewAnimationTypeFlipFromRight,
    LRImageViewAnimationTypeFlipFromTop,
    LRImageViewAnimationTypeFlipFromBottom,
    LRImageViewAnimationTypeCurlUp,
    LRImageViewAnimationTypeCurlDown,
};

@interface UIImageView (LRNetworking)

@property (nonatomic, strong, setter = lr_setActivityIndicator:) UIView<LRActivityIndicator> *lr_activityIndicator;

@property (nonatomic, copy, setter = lr_setPostProcessingBlock:) LRImagePostProcessingBlock lr_postProcessingBlock;

@property (nonatomic, copy, setter = lr_setCompletionHandler:) LRImageCompletionHandler lr_completionHandler;

@property (nonatomic, setter = lr_setAnimationType:) LRImageViewAnimationType lr_animationType;
@property (nonatomic, setter = lr_setFadeAnimationTime:) NSTimeInterval lr_fadeAnimationTime;

- (void)lr_setImageWithURL:(NSURL *)url;

- (void)lr_setImageWithURL:(NSURL *)url
          placeholderImage:(UIImage *)placeholderImage;

- (void)lr_setImageWithURL:(NSURL *)url
                      size:(CGSize)size;

- (void)lr_setImageWithURL:(NSURL *)url
       cacheStorageOptions:(LRCacheStorageOptions)cacheStorageOptions;

- (void)lr_setImageWithURL:(NSURL *)url
          placeholderImage:(UIImage *)placeholderImage
       cacheStorageOptions:(LRCacheStorageOptions)memCacheStorageType;

- (void)lr_setImageWithURL:(NSURL *)url
          placeholderImage:(UIImage *)placeholderImage
                      size:(CGSize)size;

- (void)lr_setImageWithURL:(NSURL *)url
          placeholderImage:(UIImage *)placeholderImage
                      size:(CGSize)size
       cacheStorageOptions:(LRCacheStorageOptions)memCacheStorageType;

- (void)lr_cancelImageOperation;

@end
