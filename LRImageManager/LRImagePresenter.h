// LRImagePresenter.h
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

@class LRImageManager;

/**
 This class is not meant to be used directly. Use LRImageManager instead.
 */
@interface LRImagePresenter : NSObject

@property (nonatomic, weak) LRImageManager *imageManager;

- (instancetype)initWithImageView:(UIImageView *)imageView
                 placeholderImage:(UIImage *)placeholderImage
                activityIndicator:(UIView<LRActivityIndicator> *)activityIndicator
                         imageURL:(NSURL *)imageURL
                             size:(CGSize)size
                       imageCache:(id<LRImageCache>)imageCache
              cacheStorageOptions:(LRCacheStorageOptions)cacheStorageOptions
              postProcessingBlock:(LRImagePostProcessingBlock)postProcessingBlock;

- (instancetype)initWithButton:(UIButton *)button
                         state:(UIControlState)state
              placeholderImage:(UIImage *)placeholderImage
             activityIndicator:(UIView<LRActivityIndicator> *)activityIndicator
                      imageURL:(NSURL *)imageURL size:(CGSize)size
                    imageCache:(id<LRImageCache>)imageCache
           cacheStorageOptions:(LRCacheStorageOptions)cacheStorageOptions
           postProcessingBlock:(LRImagePostProcessingBlock)postProcessingBlock;

- (void)startPresentingWithCompletionHandler:(LRImageCompletionHandler)completionHandler;

- (void)cancelPresenting;

@end
