// LRImageOperation.m
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

#import "LRImageOperation.h"
#import "UIImage+LRImageManagerAdditions.h"
#import "Reachability.h"

NSString *const LRImageOperationErrorDomain = @"LRImageOperationErrorDomain";

static NSTimeInterval const kImageRequestDefaultWiFiTimeout = 15.0;
static NSTimeInterval const kImageRequestDefaultWWANTimeout = 60.0;
static NSTimeInterval const kImageRetryDelay = 2.5;

@interface LRImageOperation ()

// NSOperation flags
@property (nonatomic, getter = isExecuting) BOOL executing;
@property (nonatomic, getter = isFinished) BOOL finished;
@property (nonatomic, getter = isCancelled) BOOL cancelled;

// Inputs
@property (nonatomic, strong) NSURL *url;
@property (nonatomic, assign) CGSize size;
@property (nonatomic, copy) LRImageURLModifierBlock imageURLModifier;
@property (nonatomic, strong) id<LRImageCache> imageCache;
@property (nonatomic, assign) LRCacheStorageOptions cacheStorageOptions;
@property (nonatomic, assign) UIViewContentMode contentMode;
@property (nonatomic, strong) NSMutableArray *completionHandlers;

// Outputs
@property (nonatomic, strong) UIImage *image;
@property (nonatomic, strong) NSError *error;

// NSURLConnection wise
@property (nonatomic, weak) NSURLConnection *connection;
@property (nonatomic, strong) NSMutableData *downloadedData;
@property (nonatomic, strong) NSURLResponse *response;
@property (nonatomic, strong) NSSet *autoRetryErrorCodes;

@property (nonatomic, strong) NSHashTable *contexts;

@property (nonatomic, strong) dispatch_queue_t syncQueue;

@end

@implementation LRImageOperation

@synthesize executing = _executing;
@synthesize finished = _finished;
@synthesize cancelled = _cancelled;

- (instancetype)initWithURL:(NSURL *)url
                       size:(CGSize)size
           imageURLModifier:(LRImageURLModifierBlock)imageURLModifier
                 imageCache:(id<LRImageCache>)imageCache
        cacheStorageOptions:(LRCacheStorageOptions)cacheStorageOptions
                contentMode:(UIViewContentMode)contentMode
          completionHandler:(LRImageCompletionHandler)completionHandler
{
    self = [super init];
    
    if (self)
    {
        _url = url;
        _size = size;
        _imageURLModifier = [imageURLModifier copy];
        _imageCache = imageCache;
        _cacheStorageOptions = cacheStorageOptions;
        _contentMode = contentMode;
        _completionHandlers = [NSMutableArray array];
        _connection = [self imageURLConnectionWithURL:_url size:_size];
        _syncQueue = dispatch_queue_create("com.LRImageOperation.LRImageOperationQueue", DISPATCH_QUEUE_SERIAL);
        
        [self addCompletionHandler:completionHandler];
    }
    
    return self;
}

- (NSURLConnection *)imageURLConnectionWithURL:(NSURL *)url size:(CGSize)size
{
    NSURL *imageURL = self.imageURLModifier ? self.imageURLModifier(url, size) : url;
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:imageURL];
    request.timeoutInterval = [self imageRequestTimeout];
    [request addValue:@"image/*" forHTTPHeaderField:@"Accept"];
    
    return [[NSURLConnection alloc] initWithRequest:request delegate:self startImmediately:NO];
}

- (BOOL)isConcurrent
{
    return YES;
}

- (void)start
{
    @synchronized(self)
    {
        if ([self isCancelled])
        {
            self.executing = NO;
            self.finished = YES;
        }
        else if (![self isExecuting])
        {
            self.executing = YES;
            
            self.image = [self.imageCache diskCachedImageForURL:self.url size:self.size];
            
            if (self.image)
            {
                [self.imageCache cacheImage:self.image
                                    withURL:self.url
                                       size:self.size
                        cacheStorageOptions:self.cacheStorageOptions];
                
                [self finish];
            }
            else
            {
                [self startConnection];
            }
        }
    }
}

- (void)startConnection
{
    if ([self isCancelled]) return;
    
    [self.connection scheduleInRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
    [self.connection start];
}

- (void)cancel
{
    @synchronized(self)
    {
        if (![self isCancelled] && ![self isFinished])
        {
            self.cancelled = YES;
            [self.connection cancel];
            
            NSDictionary *userInfo = @{NSLocalizedDescriptionKey : @"Operation was cancelled"};
            NSError *error = [NSError errorWithDomain:NSURLErrorDomain
                                                 code:NSURLErrorCancelled
                                             userInfo:userInfo];
            
            [self connection:self.connection didFailWithError:error];
        }
    }
}

- (void)finish
{
    @synchronized(self)
    {
        if ([self isExecuting] && ![self isFinished])
        {
            self.executing = NO;
            self.finished = YES;
            
            @synchronized(self.completionHandlers)
            {
                for (LRImageCompletionHandler completionHandler in self.completionHandlers)
                {
                    completionHandler(self.image, self.error);
                }
            }
        }
    }
}

#pragma mark - NSOperation flags

- (void)setExecuting:(BOOL)executing
{
    [self willChangeValueForKey:@"isExecuting"];
    _executing = executing;
    [self didChangeValueForKey:@"isExecuting"];
}

- (void)setFinished:(BOOL)finished
{
    [self willChangeValueForKey:@"isFinished"];
    _finished = finished;
    [self didChangeValueForKey:@"isFinished"];
}

- (void)setCancelled:(BOOL)cancelled
{
    [self willChangeValueForKey:@"isCancelled"];
    _cancelled = cancelled;
    [self didChangeValueForKey:@"isCancelled"];
}

#pragma mark NSURLConnectionDelegate

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    dispatch_async(self.syncQueue, ^{
        if (self.downloadedData == nil)
        {
            self.downloadedData = [[NSMutableData alloc] initWithCapacity:
                                   (NSUInteger)MAX(0, self.response.expectedContentLength)];
        }
        
        [self.downloadedData appendData:data];
    });
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    self.response = response;
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    self.error = error;
    
    if (self.autoRetry && [self.autoRetryErrorCodes containsObject:@(error.code)])
    {
        self.connection = [self imageURLConnectionWithURL:self.url size:self.size];
        [self performSelector:@selector(startConnection) withObject:nil afterDelay:kImageRetryDelay];
    }
    else
    {
        [self finish];
    }
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    if ([self.response respondsToSelector:@selector(statusCode)])
    {
        NSInteger statusCode = [(NSHTTPURLResponse *)self.response statusCode];
        
        if (statusCode >= 400)
        {
            NSString *message = [NSString stringWithFormat:
                                 @"Error code %lu when downloading image with URL: %@ and size: %@",
                                 (long)statusCode, self.url, NSStringFromCGSize(self.size)];
            
            NSDictionary *userInfo = @{NSLocalizedDescriptionKey : message};
            self.error = [NSError errorWithDomain:LRImageOperationErrorDomain
                                             code:statusCode
                                         userInfo:userInfo];
            
            [self finish];
        }
        else
        {
            [self postProcessImageDownload];
        }
    };
}

- (void)postProcessImageDownload
{
    dispatch_async(self.syncQueue, ^{
        
        __attribute__((objc_precise_lifetime)) UIImage *imageFromData = [UIImage imageWithData:self.downloadedData];
        
        if (imageFromData)
        {
            self.image = [UIImage imageWithCGImage:imageFromData.CGImage
                                             scale:[[UIScreen mainScreen] scale]
                                       orientation:UIImageOrientationUp];
        }
        
        BOOL shouldResize = !CGSizeEqualToSize(self.size, self.image.size) &&
                            !CGSizeEqualToSize(self.size, CGSizeZero);
        
        if (shouldResize)
        {
            self.image = [self.image lr_resizedImageWithContentMode:self.contentMode bounds:self.size];
        }
        
        self.image = [self.image lr_decompressImage];
        
        [self.imageCache cacheImage:self.image
                            withURL:self.url
                               size:self.size
                cacheStorageOptions:self.cacheStorageOptions];
        
        [self finish];
    });
}

#pragma mark - Autoretry Error Codes

- (NSSet *)autoRetryErrorCodes
{
    static NSSet *autoretryErrorCodes = nil;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        autoretryErrorCodes = [NSSet setWithObjects:
                               @(NSURLErrorTimedOut),
                               @(NSURLErrorCannotFindHost),
                               @(NSURLErrorCannotConnectToHost),
                               @(NSURLErrorDNSLookupFailed),
                               @(NSURLErrorNotConnectedToInternet),
                               @(NSURLErrorNetworkConnectionLost),
                               nil];
    });
    
    return autoretryErrorCodes;
}

#pragma mark - Add completion handler

- (void)addCompletionHandler:(LRImageCompletionHandler)completionHandler
{
    if (completionHandler)
    {
        @synchronized(_completionHandlers)
        {
            [_completionHandlers addObject:[completionHandler copy]];
        }
    }
}

#pragma mark - Contexts management

- (NSUInteger)numberOfContexts
{
    return [self.contexts count];
}

- (void)addContext:(id)context
{
    [self.contexts addObject:context];
}

- (void)removeContext:(id)context
{
    [self.contexts removeObject:context];
}

- (NSHashTable *)contexts
{
    if (!_contexts)
    {
        _contexts = [NSHashTable hashTableWithOptions:NSPointerFunctionsWeakMemory];
    }
    return _contexts;
}

#pragma mark - Image Request Timeout

- (NSTimeInterval)imageRequestTimeout
{
    Reachability *reachability = [Reachability reachabilityForInternetConnection];
    
    if ([reachability isReachableViaWiFi])
    {
        return kImageRequestDefaultWiFiTimeout;
    }
    else
    {
        return kImageRequestDefaultWWANTimeout;
    }
}

@end
