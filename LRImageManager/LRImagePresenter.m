// LRImagePresenter.m
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

#import "LRImagePresenter.h"
#import "LRImageManager.h"
#import "LRImageManager+Private.h"

static NSTimeInterval const kImageFadeAnimationTime = 0.25f;

@interface LRImagePresenter ()

@property (nonatomic, weak) UIImageView *imageView;
@property (nonatomic, strong) NSURL *imageURL;
@property (nonatomic, strong) UIImage *placeholderImage;
@property (nonatomic, assign) CGSize imageSize;
@property (nonatomic, assign) BOOL diskCache;
@property (nonatomic, assign) LRCacheStorageOptions storageOptions;
@property (nonatomic, assign) LRImageViewAnimationOptions animationOptions;
@property (nonatomic, copy) LRNetImageBlock completionBlock;

@property (nonatomic, assign, getter = isCancelled) BOOL cancelled;

@end

@implementation LRImagePresenter

+ (instancetype)presenterForImageView:(UIImageView *)imageView
                              withURL:(NSURL *)url
                     placeholderImage:(UIImage *)placeholderImage
                                 size:(CGSize)size
                            diskCache:(BOOL)diskCache
                       storageOptions:(LRCacheStorageOptions)storageOptions
                     animationOptions:(LRImageViewAnimationOptions)animationOptions
{
    return [[self alloc] initWithImageView:imageView
                                   withURL:url
                          placeholderImage:placeholderImage
                                      size:size
                                 diskCache:diskCache
                            storageOptions:storageOptions
                          animationOptions:animationOptions];
}

- (id)initWithImageView:(UIImageView *)imageView
                withURL:(NSURL *)url
       placeholderImage:(UIImage *)placeholderImage
                   size:(CGSize)size
              diskCache:(BOOL)diskCache
         storageOptions:(LRCacheStorageOptions)storageOptions
       animationOptions:(LRImageViewAnimationOptions)animationOptions
{
    self = [super init];
    
    if (self)
    {
        _imageView = imageView;
        _imageURL = url;
        _imageSize = size;
        _placeholderImage = placeholderImage;
        _diskCache = diskCache;
        _storageOptions = storageOptions;
        _animationOptions = animationOptions;
    }
    
    return self;
}

- (void)startPresentingWithCompletionBlock:(LRNetImageBlock)completionBlock
{
    self.completionBlock = completionBlock;
    
    if ([self.imageURL.absoluteString length] == 0)
    {
        self.imageView.image = self.placeholderImage;
        
        if (self.completionBlock) self.completionBlock(nil, [self isCancelled]);
        
        return;
    }
    
    UIImage *memCachedImage = [[LRImageCache sharedImageCache] memCachedImageForURL:self.imageURL
                                                                               size:self.imageSize];
    if (memCachedImage)
    {
        self.imageView.image = memCachedImage;

        if (self.completionBlock) self.completionBlock(memCachedImage, [self isCancelled]);
    }
    else
    {
        self.imageView.image = self.placeholderImage;
        
        __weak LRImagePresenter *wself = self;
        
        LRImageCompletionHandler completionHandler = ^(UIImage *image, NSError *error) {
            
            if (wself.completionBlock) wself.completionBlock(image, [wself isCancelled]);
            
            __strong LRImagePresenter *sself = wself;
            
            dispatch_async(dispatch_get_main_queue(), ^{
                
                if (!image || error || [sself isCancelled]) return;
                
                if (sself.animationOptions == LRImageViewAnimationOptionFade)
                {
                    [UIView transitionWithView:sself.imageView
                                      duration:kImageFadeAnimationTime
                                       options:UIViewAnimationOptionTransitionCrossDissolve
                                    animations:^{
                                        sself.imageView.image = image;
                                    } completion:NULL];
                }
                else
                {
                    sself.imageView.image = image;
                }
            });
        };
        
        [[LRImageManager sharedManager] imageFromURL:self.imageURL
                                                size:self.imageSize
                                           diskCache:self.diskCache
                                      storageOptions:self.storageOptions
                                             context:self.imageView
                                   completionHandler:completionHandler];
    }
}

- (void)startPresenting
{
    [self startPresentingWithCompletionBlock:NULL];
}

- (void)cancelPresenting
{
    _cancelled = YES;
    
    [[LRImageManager sharedManager] cancelImageRequestFromURL:_imageURL
                                                         size:_imageSize
                                                      context:self.imageView];
}

- (void)dealloc
{
    [self cancelPresenting];
}

@end
