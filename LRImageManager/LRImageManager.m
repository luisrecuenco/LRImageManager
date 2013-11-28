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

#if !__has_feature(objc_arc)
#error "LRImageManager requires ARC support."
#endif

#ifndef NS_BLOCKS_AVAILABLE
#error "LRImageManager requires blocks."
#endif

@interface LRImageManager ()

@property (nonatomic, strong) NSOperationQueue *operationQueue;
@property (nonatomic, strong) NSMutableDictionary *ongoingOperations;

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

- (id)init
{
    self = [super init];
    
    if (self)
    {
        _operationQueue = [[NSOperationQueue alloc] init];
        _operationQueue.maxConcurrentOperationCount = 2;
        _ongoingOperations = [NSMutableDictionary dictionary];
    }
    
    return self;
}

- (void)imageFromURL:(NSURL *)url
                size:(CGSize)size
   completionHandler:(LRImageCompletionHandler)completionHandler
{
    [self imageFromURL:url
                  size:size
             diskCache:![LRImageCache sharedImageCache].skipDiskCache
        storageOptions:[LRImageCache sharedImageCache].defaultCacheStorageOption
     completionHandler:completionHandler];
}

- (void)imageFromURL:(NSURL *)url
                size:(CGSize)size
           diskCache:(BOOL)diskCache
   completionHandler:(LRImageCompletionHandler)completionHandler
{
    [self imageFromURL:url
                  size:size
             diskCache:diskCache
        storageOptions:[LRImageCache sharedImageCache].defaultCacheStorageOption
     completionHandler:completionHandler];
}

- (void)imageFromURL:(NSURL *)url
                size:(CGSize)size
      storageOptions:(LRCacheStorageOptions)storageOptions
   completionHandler:(LRImageCompletionHandler)completionHandler
{
    [self imageFromURL:url
                  size:size
             diskCache:![LRImageCache sharedImageCache].skipDiskCache
        storageOptions:storageOptions
     completionHandler:completionHandler];
}

- (void)imageFromURL:(NSURL *)url
                size:(CGSize)size
           diskCache:(BOOL)diskCache
      storageOptions:(LRCacheStorageOptions)storageOptions
   completionHandler:(LRImageCompletionHandler)completionHandler
{
    [self imageFromURL:url
                  size:size
             diskCache:diskCache
        storageOptions:storageOptions
               context:NULL
     completionHandler:completionHandler];
}

- (void)imageFromURL:(NSURL *)url
                size:(CGSize)size
           diskCache:(BOOL)diskCache
      storageOptions:(LRCacheStorageOptions)storageOptions
             context:(id)context
   completionHandler:(LRImageCompletionHandler)completionHandler
{
    if ([url.absoluteString length] == 0)
    {
        if (completionHandler)
        {
            completionHandler(nil, nil);
        }
        return;
    }
    
    // This method is supposed to be called once the memCache check has already been done.
    // Let's check anyway...
    UIImage *memCachedImage = [[LRImageCache sharedImageCache] memCachedImageForURL:url
                                                                               size:size];
    if (memCachedImage)
    {
        if (completionHandler)
        {
            completionHandler(memCachedImage, nil);
        }
        return;
    };
    
    NSString *key = LRCacheKeyForImage(url, size);
    
    @synchronized(self.ongoingOperations)
    {
        LRImageOperation *ongoingOperation = self.ongoingOperations[key];

        if (ongoingOperation && ![ongoingOperation isCancelled])
        {
            [ongoingOperation addCompletionHandler:completionHandler];
            [ongoingOperation addContext:context];
        }
        else
        {
            LRImageOperation *imageOperation = [LRImageOperation imageOperationWithURL:url
                                                                                  size:size
                                                                             diskCache:diskCache
                                                                        storageOptions:storageOptions
                                                                     completionHandler:completionHandler];
            
            [imageOperation addContext:context];

            imageOperation.autoRetry = self.autoRetry;
            
			__weak typeof(self) _weak_self = self;
            [imageOperation setCompletionBlock:^{
				__strong typeof(_weak_self) self = _weak_self;
                
                [self.ongoingOperations removeObjectForKey:key];
                
                if (self.showNetworkActivityIndicator && [self.ongoingOperations count] == 0)
                {
                    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
                }
            }];
            
            self.ongoingOperations[key] = imageOperation;
                        
            [self.operationQueue addOperation:imageOperation];
            
            if (self.showNetworkActivityIndicator)
            {
                [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
            }
        }
    }
}

- (void)cancelImageRequestFromURL:(NSURL *)url
                             size:(CGSize)size
{
    [self cancelImageRequestFromURL:url size:size context:NULL];
}

- (void)cancelImageRequestFromURL:(NSURL *)url
                             size:(CGSize)size
                          context:(id)context
{
    if ([url.absoluteString length] == 0) return;
    
    NSString *key = LRCacheKeyForImage(url, size);
    
    @synchronized(self.ongoingOperations)
    {
        LRImageOperation *imageOperation = self.ongoingOperations[key];
        
        [imageOperation removeContext:context];
        
        if ([imageOperation numberOfContexts] == 0)
        {
            [imageOperation cancel];
        }
    }
}

- (void)cancelAllRequests
{
    @synchronized(self.ongoingOperations)
    {
        NSArray *ongoingOperations = [[self.ongoingOperations allValues] copy];
        [ongoingOperations makeObjectsPerformSelector:@selector(cancel)];
    }
}

@end
