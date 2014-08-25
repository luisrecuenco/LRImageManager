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
#import "LRImageManager+Private.h"

@interface LRImagePresenter ()

@property (nonatomic, weak) UIImageView *imageView;
@property (nonatomic, strong) UIImage *placeholderImage;
@property (nonatomic, strong) UIView<LRActivityIndicator> *activityIndicator;
@property (nonatomic, strong) NSURL *imageURL;
@property (nonatomic, assign) CGSize imageSize;
@property (nonatomic, strong) id<LRImageCache> imageCache;
@property (nonatomic, assign) LRCacheStorageOptions cacheStorageOptions;
@property (nonatomic, copy) LRImageCompletionHandler completionHandler;

@end

@implementation LRImagePresenter

- (instancetype)initWithImageView:(UIImageView *)imageView
                 placeholderImage:(UIImage *)placeholderImage
                activityIndicator:(UIView<LRActivityIndicator> *)activityIndicator
                         imageURL:(NSURL *)imageURL
                             size:(CGSize)size
                       imageCache:(id<LRImageCache>)imageCache
              cacheStorageOptions:(LRCacheStorageOptions)cacheStorageOptions
{
    self = [super init];
    
    if (self)
    {
        _imageView = imageView;
        _placeholderImage = placeholderImage;
        _activityIndicator = activityIndicator;
        _imageURL = imageURL;
        _imageSize = size;
        _imageCache = imageCache;
        _cacheStorageOptions = cacheStorageOptions;
    }
    
    return self;
}

- (void)startPresentingWithCompletionHandler:(LRImageCompletionHandler)completionHandler
{
    self.completionHandler = completionHandler;
    
    if ([[self.imageURL absoluteString] length] == 0)
    {
        self.imageView.image = self.placeholderImage;
        
        if (self.completionHandler) self.completionHandler(nil, nil);
        
        return;
    }
    
    UIImage *memCachedImage = [self.imageCache memCachedImageForURL:self.imageURL size:self.imageSize];
    
    if (memCachedImage)
    {
        self.imageView.image = memCachedImage;
        
        if (self.completionHandler) self.completionHandler(memCachedImage, nil);
    }
    else
    {
        self.imageView.image = self.placeholderImage;
        
        self.activityIndicator.center = self.imageView.center;
        self.activityIndicator.hidden = NO;
        [self.activityIndicator startAnimating];
        [self.imageView addSubview:self.activityIndicator];
        
        __weak LRImagePresenter *wself = self;
        
        LRImageCompletionHandler completionHandler = ^(UIImage *image, NSError *error) {
            
            if (wself.completionHandler) wself.completionHandler(image, error);

            __strong LRImagePresenter *sself = wself;
                        
            dispatch_async(dispatch_get_main_queue(), ^{

                [sself.activityIndicator stopAnimating];
                [sself.activityIndicator removeFromSuperview];

                if (!image || error) return;
                    
                [UIView transitionWithView:sself.imageView
                                  duration:sself.imageView.fadeAnimationTime
                                   options:LRImageViewAnimationTypeToAnimationOptionTransition(sself.imageView.animationType)
                                animations:^{
                                    sself.imageView.image = image;
                                } completion:NULL];
            });
        };
        
        [self.imageManager imageFromURL:self.imageURL
                                   size:self.imageSize
                    cacheStorageOptions:self.cacheStorageOptions
                            contentMode:self.imageView.contentMode
                                context:self.imageView
                      completionHandler:completionHandler];
    }
}

- (void)cancelPresenting
{
    [self.imageManager cancelImageRequestFromURL:_imageURL
                                            size:_imageSize
                                         context:_imageView];
}

- (void)dealloc
{
    [self cancelPresenting];
}

NS_INLINE UIViewAnimationOptions LRImageViewAnimationTypeToAnimationOptionTransition(LRImageViewAnimationType animationType)
{
    switch (animationType)
    {
        case LRImageViewAnimationTypeNone:
            return UIViewAnimationOptionTransitionNone;
        case LRImageViewAnimationTypeCrossDissolve:
            return UIViewAnimationOptionTransitionCrossDissolve;
        case LRImageViewAnimationTypeFlipFromLeft:
            return UIViewAnimationOptionTransitionFlipFromLeft;
        case LRImageViewAnimationTypeFlipFromBottom:
            return UIViewAnimationOptionTransitionFlipFromBottom;
        case LRImageViewAnimationTypeFlipFromRight:
            return UIViewAnimationOptionTransitionFlipFromRight;
        case LRImageViewAnimationTypeFlipFromTop:
            return UIViewAnimationOptionTransitionFlipFromTop;
        case LRImageViewAnimationTypeCurlUp:
            return UIViewAnimationOptionTransitionCurlUp;
        case LRImageViewAnimationTypeCurlDown:
            return UIViewAnimationOptionTransitionCurlDown;
        default:
            return UIViewAnimationOptionTransitionNone;
    }
}

@end
