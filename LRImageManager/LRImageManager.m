// LRImageManager.m
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
#import "LRImageOperation+Private.h"
#import "LRImagePresenter.h"

NSString *const LRImageManagerDidStartLoadingImageNotification = @"LRImageManagerDidStartLoadingImageNotification";
NSString *const LRImageManagerDidStopLoadingImageNotification = @"LRImageManagerDidStopLoadingImageNotification";
NSString *const LRImageManagerURLUserInfoKey = @"LRImageManagerURLUserInfoKey";
NSString *const LRImageManagerSizeUserInfoKey = @"LRImageManagerSizeUserInfoKey";

#if !__has_feature(objc_arc)
#error "LRImageManager requires ARC support."
#endif

#ifndef NS_BLOCKS_AVAILABLE
#error "LRImageManager requires blocks."
#endif

@interface LRImageManager ()

@property (nonatomic, strong) NSOperationQueue *operationQueue;
@property (nonatomic, strong) NSMutableDictionary *ongoingOperations;
@property (nonatomic, strong) NSMapTable *presentersMap;

@end

@implementation LRImageManager

+ (instancetype)sharedManager;
{
    static LRImageManager *sharedManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedManager = [[self alloc] init];
    });
    return sharedManager;
}

- (instancetype)init
{
    self = [super init];

    if (self)
    {
        _operationQueue = [[NSOperationQueue alloc] init];
        _ongoingOperations = [NSMutableDictionary dictionary];
        _presentersMap = [NSMapTable mapTableWithKeyOptions:NSPointerFunctionsWeakMemory
                                               valueOptions:NSPointerFunctionsStrongMemory];
    }

    return self;
}

- (void)imageFromURL:(NSURL *)url
                size:(CGSize)size
   completionHandler:(LRImageCompletionHandler)completionHandler
{
    [self imageFromURL:url
                  size:size
   postProcessingBlock:NULL
     completionHandler:completionHandler];
}

- (void)imageFromURL:(NSURL *)url
                size:(CGSize)size
 postProcessingBlock:(LRImagePostProcessingBlock)postProcessingBlock
   completionHandler:(LRImageCompletionHandler)completionHandler
{
    [self imageFromURL:url
                  size:size
   cacheStorageOptions:self.imageCache.cacheStorageOptions
   postProcessingBlock:postProcessingBlock
     completionHandler:completionHandler];
}

- (void)imageFromURL:(NSURL *)url
                size:(CGSize)size
 cacheStorageOptions:(LRCacheStorageOptions)cacheStorageOptions
   completionHandler:(LRImageCompletionHandler)completionHandler
{
    [self imageFromURL:url
                  size:size
   cacheStorageOptions:cacheStorageOptions
   postProcessingBlock:NULL
     completionHandler:completionHandler];
}

- (void)imageFromURL:(NSURL *)url
                size:(CGSize)size
 cacheStorageOptions:(LRCacheStorageOptions)cacheStorageOptions
 postProcessingBlock:(LRImagePostProcessingBlock)postProcessingBlock
   completionHandler:(LRImageCompletionHandler)completionHandler
{
    [self imageFromURL:url
                  size:size
   cacheStorageOptions:cacheStorageOptions
           contentMode:UIViewContentModeScaleAspectFill
               context:NULL
   postProcessingBlock:postProcessingBlock
     completionHandler:completionHandler];
}

- (void)imageFromURL:(NSURL *)url
                size:(CGSize)size
 cacheStorageOptions:(LRCacheStorageOptions)cacheStorageOptions
         contentMode:(UIViewContentMode)contentMode
             context:(id)context
 postProcessingBlock:(LRImagePostProcessingBlock)postProcessingBlock
   completionHandler:(LRImageCompletionHandler)completionHandler
{
    if ([[url absoluteString] length] == 0)
    {
        if (completionHandler)
        {
            completionHandler(nil, nil);
        }
        return;
    }

    CGSize integralSize = LRIntegralSize(size);

    UIImage *memCachedImage = [self.imageCache memCachedImageForURL:url size:integralSize];

    if (memCachedImage)
    {
        if (completionHandler)
        {
            completionHandler(memCachedImage, nil);
        }
        return;
    };

    NSString *key = LROngoingOperationKey(url, integralSize);

    LRImageOperation *ongoingOperation = self.ongoingOperations[key];

    if (ongoingOperation && ![ongoingOperation isCancelled])
    {
        [ongoingOperation addCompletionHandler:completionHandler];
        [ongoingOperation addContext:context];
    }
    else
    {
        LRImageOperation *imageOperation = [[LRImageOperation alloc] initWithURL:url
                                                                            size:integralSize
                                                                      imageCache:self.imageCache
                                                             cacheStorageOptions:cacheStorageOptions
                                                                     contentMode:contentMode
                                                                imageURLModifier:self.imageURLModifier
                                                             postProcessingBlock:postProcessingBlock
                                                               completionHandler:completionHandler];

        [imageOperation addContext:context];

        imageOperation.autoRetry = self.autoRetry;
        imageOperation.allowUntrustedHTTPSConnections = self.allowUntrustedHTTPSConnections;
        imageOperation.cachePolicy = self.cachePolicy;
        imageOperation.wifiTimeout = self.wifiTimeout;
        imageOperation.wwanTimeout = self.wwanTimeout;

        NSDictionary *userInfo = [self userInfoDictionaryForURL:url size:integralSize];

        [imageOperation setCompletionBlock:^{

            dispatch_async(dispatch_get_main_queue(), ^{

                [[NSNotificationCenter defaultCenter] postNotificationName:LRImageManagerDidStopLoadingImageNotification
                                                                    object:self
                                                                  userInfo:userInfo];

                [self.ongoingOperations removeObjectForKey:key];

                if (self.showNetworkActivityIndicator && [self.ongoingOperations count] == 0)
                {
                    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
                }
            });
        }];

        self.ongoingOperations[key] = imageOperation;

        [self.operationQueue addOperation:imageOperation];

        [[NSNotificationCenter defaultCenter] postNotificationName:LRImageManagerDidStartLoadingImageNotification
                                                            object:self
                                                          userInfo:userInfo];

        if (self.showNetworkActivityIndicator)
        {
            [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
        }
    }
}

- (NSDictionary *)userInfoDictionaryForURL:(NSURL *)url size:(CGSize)size
{
    return @{ LRImageManagerURLUserInfoKey : url,
              LRImageManagerSizeUserInfoKey : [NSValue valueWithCGSize:size] };
}

- (void)cancelImageRequestFromURL:(NSURL *)url size:(CGSize)size
{
    [self cancelImageRequestFromURL:url size:size context:NULL];
}

- (void)cancelImageRequestFromURL:(NSURL *)url size:(CGSize)size context:(id)context
{
    if ([[url absoluteString] length] == 0) return;

    NSString *key = LROngoingOperationKey(url, LRIntegralSize(size));

    LRImageOperation *imageOperation = self.ongoingOperations[key];

    [imageOperation removeContext:context];

    if ([imageOperation numberOfContexts] == 0)
    {
        [imageOperation cancel];
    }
}

- (void)cancelAllRequests
{
    NSArray *ongoingOperations = [[self.ongoingOperations allValues] copy];
    [ongoingOperations makeObjectsPerformSelector:@selector(cancel)];
}

#pragma mark - UIImageView specifics

- (void)downloadImageForImageView:(UIImageView *)imageView
                 placeholderImage:(UIImage *)placeholderImage
                activityIndicator:(UIView<LRActivityIndicator> *)activityIndicator
                         imageURL:(NSURL *)imageURL
                             size:(CGSize)size
              cacheStorageOptions:(LRCacheStorageOptions)cacheStorageOptions
              postProcessingBlock:(LRImagePostProcessingBlock)postProcessingBlock
                completionHandler:(LRImageCompletionHandler)completionHandler
{
    LRImagePresenter *presenter = [[LRImagePresenter alloc] initWithImageView:imageView
                                                             placeholderImage:placeholderImage
                                                            activityIndicator:activityIndicator
                                                                     imageURL:imageURL
                                                                         size:LRIntegralSize(size)
                                                                   imageCache:self.imageCache
                                                          cacheStorageOptions:cacheStorageOptions
                                                          postProcessingBlock:postProcessingBlock];

    presenter.imageManager = self;

    // Previous presenter for this imageView will deallocate and cancel itself
    [self.presentersMap setObject:presenter forKey:imageView];

    __weak typeof(imageView) wImageView = imageView;
    [presenter startPresentingWithCompletionHandler:^(UIImage *image, NSError *error) {
        __weak typeof(wImageView) sImageView = wImageView;
        [self cancelDownloadImageForImageView:sImageView];
        if (completionHandler) completionHandler(image, error);
    }];
}

- (void)downloadImageForButton:(UIButton *)button
                         state:(UIControlState)buttonState
                 placeholderImage:(UIImage *)placeholderImage
                activityIndicator:(UIView<LRActivityIndicator> *)activityIndicator
                         imageURL:(NSURL *)imageURL
                             size:(CGSize)size
              cacheStorageOptions:(LRCacheStorageOptions)cacheStorageOptions
              postProcessingBlock:(LRImagePostProcessingBlock)postProcessingBlock
                completionHandler:(LRImageCompletionHandler)completionHandler
{
    LRImagePresenter *presenter = [[LRImagePresenter alloc] initWithButton:button
                                                                     state:buttonState
                                                          placeholderImage:placeholderImage
                                                         activityIndicator:activityIndicator
                                                                  imageURL:imageURL
                                                                      size:LRIntegralSize(size)
                                                                imageCache:self.imageCache
                                                       cacheStorageOptions:cacheStorageOptions
                                                       postProcessingBlock:postProcessingBlock];
    
    presenter.imageManager = self;
    
    // Previous presenter for this imageView will deallocate and cancel itself
    [self.presentersMap setObject:presenter forKey:button];
    
    __weak typeof(button) wButton = button;
    [presenter startPresentingWithCompletionHandler:^(UIImage *image, NSError *error) {
        __weak typeof(wButton) sButton = wButton;
        [self cancelDownloadImageForButton:sButton];
        if (completionHandler) completionHandler(image, error);
    }];
}

- (void)cancelDownloadImageForImageView:(UIImageView *)imageView
{
    LRImagePresenter *presenter = [self.presentersMap objectForKey:imageView];
    [presenter cancelPresenting];
    [self.presentersMap removeObjectForKey:imageView];
}

- (void)cancelDownloadImageForButton:(UIButton *)button
{
    LRImagePresenter *presenter = [self.presentersMap objectForKey:button];
    [presenter cancelPresenting];
    [self.presentersMap removeObjectForKey:button];
}


#pragma mark - Integral size

NS_INLINE CGSize LRIntegralSize(CGSize size)
{
    return (CGSize){ceilf(size.width), ceilf(size.height)};
}

#pragma mark - Ongoing Operation Key

NS_INLINE NSString *LROngoingOperationKey(NSURL *url, CGSize size)
{
    NSString *ongoingOperationKey = nil;

    if (url)
    {
        ongoingOperationKey = [NSString stringWithFormat:@"%@-%lu-%lu", [url absoluteString], (unsigned long)size.width, (unsigned long)size.height];
    }

    return ongoingOperationKey;
}

#pragma mark - Image Cache

- (id<LRImageCache>)imageCache
{
    return _imageCache ?: (_imageCache = [[LRImageCache alloc] init]);
}

@end
