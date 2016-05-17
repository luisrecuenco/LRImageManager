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
@property (nonatomic, weak) UIButton *button;
@property (nonatomic, weak) UIView *targetView;
@property (nonatomic, assign) UIControlState buttonState;
@property (nonatomic, strong) UIImage *placeholderImage;
@property (nonatomic, strong) UIView<LRActivityIndicator> *activityIndicator;
@property (nonatomic, strong) NSURL *imageURL;
@property (nonatomic, assign) CGSize imageSize;
@property (nonatomic, strong) id<LRImageCache> imageCache;
@property (nonatomic, assign) LRCacheStorageOptions cacheStorageOptions;
@property (nonatomic, copy) LRImagePostProcessingBlock postProcessingBlock;
@property (nonatomic, copy) LRImageCompletionHandler completionHandler;

@end

@implementation LRImagePresenter

- (instancetype)initWithButton:(UIButton *)button
                         state:(UIControlState)state
              placeholderImage:(UIImage *)placeholderImage
             activityIndicator:(UIView<LRActivityIndicator> *)activityIndicator
                      imageURL:(NSURL *)imageURL size:(CGSize)size
                    imageCache:(id<LRImageCache>)imageCache
           cacheStorageOptions:(LRCacheStorageOptions)cacheStorageOptions
           postProcessingBlock:(LRImagePostProcessingBlock)postProcessingBlock {
    self = [super init];
    if (self) {
        _button = button;
        _targetView = button;
        _buttonState = state;
        _placeholderImage = placeholderImage;
        _activityIndicator = activityIndicator;
        _imageURL = imageURL;
        _imageSize = size;
        _imageCache = imageCache;
        _cacheStorageOptions = cacheStorageOptions;
        _postProcessingBlock = [postProcessingBlock copy];
    }
    return self;
}

- (instancetype)initWithImageView:(UIImageView *)imageView
                 placeholderImage:(UIImage *)placeholderImage
                activityIndicator:(UIView<LRActivityIndicator> *)activityIndicator
                         imageURL:(NSURL *)imageURL
                             size:(CGSize)size
                       imageCache:(id<LRImageCache>)imageCache
              cacheStorageOptions:(LRCacheStorageOptions)cacheStorageOptions
              postProcessingBlock:(LRImagePostProcessingBlock)postProcessingBlock
{
    self = [super init];
    
    if (self)
    {
        _imageView = imageView;
        _targetView = imageView;
        _placeholderImage = placeholderImage;
        _activityIndicator = activityIndicator;
        _imageURL = imageURL;
        _imageSize = size;
        _imageCache = imageCache;
        _cacheStorageOptions = cacheStorageOptions;
        _postProcessingBlock = [postProcessingBlock copy];
    }
    
    return self;
}

- (void)startPresentingWithCompletionHandler:(LRImageCompletionHandler)completionHandler
{
    self.completionHandler = completionHandler;
    
    if ([[self.imageURL absoluteString] length] == 0)
    {
        [self setPlaceholderToTarget:self.placeholderImage];
        
        if (self.completionHandler) self.completionHandler(nil, nil);
        
        return;
    }
    
    UIImage *memCachedImage = [self.imageCache memCachedImageForURL:self.imageURL size:self.imageSize];
    
    if (memCachedImage)
    {
        [self setImageToTarget:memCachedImage];
        if (self.completionHandler) self.completionHandler(memCachedImage, nil);
    }
    else
    {
        [self setPlaceholderToTarget:self.placeholderImage];
        
        CGRect activityIndicatorFrame = (CGRect){.origin = CGPointZero, .size = self.activityIndicator.frame.size};
        activityIndicatorFrame.origin.x = (self.imageView.frame.size.width - self.activityIndicator.frame.size.width) / 2;
        activityIndicatorFrame.origin.y = (self.imageView.frame.size.height - self.activityIndicator.frame.size.height) / 2;
        self.activityIndicator.frame = activityIndicatorFrame;

        self.activityIndicator.hidden = NO;
        [self.activityIndicator startAnimating];
        [self.targetView addSubview:self.activityIndicator];
        
        __weak LRImagePresenter *wself = self;
        
        LRImageCompletionHandler completionHandler = ^(UIImage *image, NSError *error) {
            
            __strong LRImagePresenter *sself = wself;
            
            dispatch_async(dispatch_get_main_queue(), ^{
                
                [sself.activityIndicator stopAnimating];
                [sself.activityIndicator removeFromSuperview];
                
                if (!image || error)
                {
                    if (sself.completionHandler) sself.completionHandler(image, error);
                    return;
                }
                
                [UIView transitionWithView:sself.targetView
                                  duration:sself.targetView.lr_animationTime
                                   options:LRAnimationTypeToAnimationOptionTransition(sself.targetView.lr_animationType) | UIViewAnimationOptionAllowUserInteraction
                                animations:^{
                                    [self setImageToTarget:image];
                                } completion:^(BOOL finished) {
                                    if (sself.completionHandler) sself.completionHandler(image, error);
                                }];
            });
        };
        
        [self.imageManager imageFromURL:self.imageURL
                                   size:self.imageSize
                    cacheStorageOptions:self.cacheStorageOptions
                            contentMode:self.targetView.contentMode
                                context:self.targetView
                    postProcessingBlock:self.postProcessingBlock
                      completionHandler:completionHandler];
    }
}

- (NSTimeInterval)animationTime {
    return 0.25f;
}

- (void)setImageToTarget:(UIImage *)image {
    if (self.imageView) {
        self.imageView.image = image;
    } else if (self.button) {
        [self.button setImage:image forState:self.buttonState];
    }
}

- (void)setPlaceholderToTarget:(UIImage *)placeholder {
    if (self.imageView) {
        self.imageView.image = placeholder;
    } else if (self.button) {
        [self.button setBackgroundImage:placeholder forState:self.buttonState];
    }
}

- (void)cancelPresenting
{
    [_imageManager cancelImageRequestFromURL:_imageURL
                                        size:_imageSize
                                     context:_imageView];
}

- (void)dealloc
{
    [self cancelPresenting];
}

NS_INLINE UIViewAnimationOptions LRAnimationTypeToAnimationOptionTransition(LRAnimationType animationType)
{
    switch (animationType)
    {
        case LRAnimationTypeNone:
            return UIViewAnimationOptionTransitionNone;
        case LRAnimationTypeCrossDissolve:
            return UIViewAnimationOptionTransitionCrossDissolve;
        case LRAnimationTypeFlipFromLeft:
            return UIViewAnimationOptionTransitionFlipFromLeft;
        case LRAnimationTypeFlipFromBottom:
            return UIViewAnimationOptionTransitionFlipFromBottom;
        case LRAnimationTypeFlipFromRight:
            return UIViewAnimationOptionTransitionFlipFromRight;
        case LRAnimationTypeFlipFromTop:
            return UIViewAnimationOptionTransitionFlipFromTop;
        case LRAnimationTypeCurlUp:
            return UIViewAnimationOptionTransitionCurlUp;
        case LRAnimationTypeCurlDown:
            return UIViewAnimationOptionTransitionCurlDown;
        default:
            return UIViewAnimationOptionTransitionNone;
    }
}

@end
