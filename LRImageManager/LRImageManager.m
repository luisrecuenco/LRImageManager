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
      storageOptions:(LRCacheStorageOptions)storageOptions
   completionHandler:(LRImageCompletionHandler)completionHandler
{
    if ([url.absoluteString length] == 0)
    {
        completionHandler(nil, nil);
        return;
    }
    
    // This method is supposed to be called once the memCache check has already been done.
    // Let's check anyway...
    UIImage *memCachedImage = [[LRImageCache sharedImageCache] memCachedImageForURL:url
                                                                               size:size];
    if (memCachedImage)
    {
        completionHandler(memCachedImage, nil);
        return;
    };
    
    NSString *key = LRCacheKeyForImage(url, size);
    
    @synchronized(self.ongoingOperations)
    {
        LRImageOperation *ongoingOperation = self.ongoingOperations[key];

        if (ongoingOperation && !ongoingOperation.isCancelled)
        {
            [ongoingOperation addCompletionHandler:completionHandler];
        }
        else
        {
            LRImageOperation *imageOperation = [LRImageOperation imageOperationWithURL:url
                                                                                  size:size
                                                                        storageOptions:storageOptions
                                                                     completionHandler:completionHandler];
            
            imageOperation.autoRetry = self.autoRetry;
            
            [imageOperation setCompletionBlock:^{
                
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
    if ([url.absoluteString length] == 0) return;
    
    NSString *key = LRCacheKeyForImage(url, size);
    
    @synchronized(self.ongoingOperations)
    {
        [self.ongoingOperations[key] cancel];
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
