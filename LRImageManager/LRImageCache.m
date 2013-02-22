// LRImageCache.m
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

#import "LRImageCache.h"
#import <CommonCrypto/CommonCrypto.h>

#if DEBUG
#define LRImageClientLog(s,...) NSLog( @"\n\n------------------------------------- DEBUG -------------------------------------\n\t<%p %@:(%d)>\n\n\t%@\n---------------------------------------------------------------------------------\n\n", self, \
[[NSString stringWithUTF8String:__FUNCTION__] lastPathComponent], __LINE__, \
[NSString stringWithFormat:(s), ##__VA_ARGS__] )
#else
#define LRImageClientLog(s,...)
#endif

#if OS_OBJECT_USE_OBJC
#define LRDispatchQueuePropertyModifier strong
#else
#define LRDispatchQueuePropertyModifier assign
#endif

static const NSTimeInterval kDefaultMaxTimeInCache = 60 * 60 * 24 * 7; // 1 week
static const unsigned long long kDefaultMaxCacheDirectorySize = 100 * 1024 * 1024; // 100 MB

static NSString *const kImageCacheDirectoryName = @"LRImageCache";

@interface LRImageCache ()

@property (nonatomic, strong) NSMutableDictionary *imagesDictionary;
@property (nonatomic, strong) NSCache *imagesCache;
@property (nonatomic, LRDispatchQueuePropertyModifier) dispatch_queue_t ioQueue;
@property (nonatomic, LRDispatchQueuePropertyModifier) dispatch_queue_t syncQueue;

@end

@implementation LRImageCache

+ (LRImageCache *)sharedImageCache
{
    static LRImageCache *imageCache = nil;
    static dispatch_once_t oncePredicate;
    dispatch_once(&oncePredicate, ^{
        imageCache = [[self alloc] init];
    });
    return imageCache;
}

- (id)init
{
    self = [super init];
    
	if (self)
    {
        _imagesDictionary = [NSMutableDictionary dictionary];
        _imagesCache = [[NSCache alloc] init];
        _ioQueue = dispatch_queue_create("com.LRImageClient.LRImageCacheIOQueue", NULL);
        _syncQueue = dispatch_queue_create("com.LRImageClient.LRImageCacheSyncQueue", NULL);
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(clearMemCache)
                                                     name:UIApplicationDidReceiveMemoryWarningNotification
                                                   object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(cleanDisk)
                                                     name:UIApplicationWillTerminateNotification
                                                   object:nil];
	}
    
	return self;
}

- (UIImage *)memCachedImageForURL:(NSURL *)url size:(CGSize)size
{
    if ([url.absoluteString length] == 0) return nil;
    
    NSString *imageCacheKey = LRCacheKeyForImage(url, size);
    
    __block UIImage *memCachedImage = nil;
    
    dispatch_sync(self.syncQueue, ^{
        memCachedImage = self.imagesDictionary[imageCacheKey] ?:
                         [self.imagesCache objectForKey:imageCacheKey];
    });
    
    return memCachedImage;
}

- (UIImage *)diskCachedImageForURL:(NSURL *)url size:(CGSize)size
{
    if ([url.absoluteString length] == 0) return nil;
    
    NSString *imageCacheKey = LRCacheKeyForImage(url, size);
    NSString *filePath = LRFilePathForCacheKey(imageCacheKey);
    
    UIImage *image = nil;
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:filePath])
    {
        image = [UIImage imageWithCGImage:[UIImage imageWithContentsOfFile:filePath].CGImage
                                    scale:[[UIScreen mainScreen] scale]
                              orientation:UIImageOrientationUp];
    }
    
    return image;
}

- (void)diskCachedImageForURL:(NSURL *)url
                         size:(CGSize)size
              completionBlock:(void (^)(UIImage *image))completionBlock
{
    dispatch_async(self.ioQueue, ^{
        
        UIImage *diskCachedImage = [self diskCachedImageForURL:url size:size];
        
        if (completionBlock)
        {
            completionBlock(diskCachedImage);
        }
    });
}

- (void)cacheImage:(UIImage *)image
           withURL:(NSURL *)url
              size:(CGSize)size
    storageOptions:(LRCacheStorageOptions)storageOptions
{
    NSString *imageCacheKey = LRCacheKeyForImage(url, size);
    
    [self memCacheImage:image forKey:imageCacheKey storageOptions:storageOptions];
    
    if (!(storageOptions & LRCacheStorageOptionsOnlyMemory))
    {
        [self diskCache:image withKey:imageCacheKey];
    }
}

- (void)memCacheImage:(UIImage *)image
               forKey:(id<NSCopying>)key
       storageOptions:(LRCacheStorageOptions)storageOptions
{
    if (!image || !key) return;
    
    if (storageOptions & LRCacheStorageOptionsNSDictionary)
    {   
        dispatch_sync(self.syncQueue, ^{
            self.imagesDictionary[key] = image;
        });
    }
    else if (storageOptions & LRCacheStorageOptionsNSCache)
    {
        [self.imagesCache setObject:image
                             forKey:key
                               cost:image.size.width * image.size.height * image.scale];
    }
}

- (void)diskCache:(UIImage *)image withKey:(NSString *)key
{
    if (!image || !key) return;
    
    dispatch_async(self.ioQueue, ^{
        
        NSFileManager *fileManager = [NSFileManager defaultManager];
        NSString *imageCacheDirectoryPath = LRPathToImageCacheDirectory();
        
        if (![fileManager fileExistsAtPath:imageCacheDirectoryPath])
        {
            NSError *error = nil;
            
            if (![fileManager createDirectoryAtPath:imageCacheDirectoryPath
                        withIntermediateDirectories:YES
                                         attributes:nil
                                              error:&error])
            {
                LRImageClientLog(@"Error creating cache directory at path: %@ | error: %@", imageCacheDirectoryPath, [error localizedDescription]);
            }
            else
            {
                LRImageClientLog(@"Cache directory successfully created at path: %@", imageCacheDirectoryPath);
            }
        }
        
        NSString *filePath = LRFilePathForCacheKey(key);
        
        if (![fileManager fileExistsAtPath:filePath])
        {
            NSData *data = UIImageJPEGRepresentation(image, 1.0f);
            
            if (![fileManager createFileAtPath:filePath
                                      contents:data
                                    attributes:nil])
            {
                LRImageClientLog(@"Error caching image at path: %@", filePath);
            }
            else
            {
                LRImageClientLog(@"Image successfully cached at path: %@", filePath);
            }
        }
    });
}

- (void)clearMemCache
{
    dispatch_sync(self.syncQueue, ^{
        [self.imagesDictionary removeAllObjects];
    });
    
    // Not necessary, SO should've done the work.
    [self.imagesCache removeAllObjects];
}

- (void)clearDiskCache
{
    dispatch_async(self.ioQueue, ^{
        
        NSFileManager *fileManager = [NSFileManager defaultManager];
        NSString *directoryPath = LRPathToImageCacheDirectory();
        
        NSError *error = nil;
        
        if (![fileManager removeItemAtPath:directoryPath error:&error])
        {
            LRImageClientLog(@"Error deleting cache directory at path: %@ | error: %@", directoryPath, [error localizedDescription]);
        }
        else
        {
            LRImageClientLog(@"Cache directory removed successfully");
        }
    });
}

- (void)cleanDisk
{
    if (LRCacheDirectorySize() <= self.maxDirectorySize) return;
    
    dispatch_async(self.ioQueue, ^{
        
        NSDirectoryEnumerator *fileEnumerator = [[NSFileManager defaultManager] enumeratorAtPath:LRPathToImageCacheDirectory()];
        
        NSFileManager *fileManager = [NSFileManager defaultManager];
        
        NSDate *now = [NSDate date];
        
        for (NSString *fileName in fileEnumerator)
        {
            NSString *filePath = [LRPathToImageCacheDirectory() stringByAppendingPathComponent:fileName];
            NSDictionary *fileAttributes = [fileManager attributesOfItemAtPath:filePath error:nil];
            
            if ([now timeIntervalSinceDate:[fileAttributes fileModificationDate]] > self.maxTimeInCache)
            {
                NSError *error = nil;
                
                if (![fileManager removeItemAtPath:filePath error:&error])
                {
                    LRImageClientLog(@"Error deleting file item at path: %@ | error: %@", filePath, [error localizedDescription]);
                }
                else
                {
                    LRImageClientLog(@"File item removed successfully at path: %@", filePath);
                }
            }
        }
        
        // Still bigger? let's clear it all (TODO: LRU or similar, not so harsh)
        if (LRCacheDirectorySize() > self.maxDirectorySize)
        {
            [self clearDiskCache];
        }
    });
}

NS_INLINE NSString *LRPathToImageCacheDirectory(void)
{
    static NSString *pathToImageCache = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		NSArray *cachesDirectories = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
		pathToImageCache = [cachesDirectories[0]
                            stringByAppendingPathComponent:kImageCacheDirectoryName];
	});
    
	return pathToImageCache;
}

NS_INLINE NSString *LRFilePathForCacheKey(NSString *cacheKey)
{
	return [LRPathToImageCacheDirectory() stringByAppendingPathComponent:cacheKey];
}

NS_INLINE NSString *LRMD5(NSString *str)
{
    const char *cStr = [str UTF8String];
    unsigned char result[16];
    CC_MD5( cStr, strlen(cStr), result );
    return [NSString stringWithFormat:
            @"%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X",
            result[0], result[1], result[2], result[3],
            result[4], result[5], result[6], result[7],
            result[8], result[9], result[10], result[11],
            result[12], result[13], result[14], result[15]
            ];
}

NS_INLINE unsigned long long LRCacheDirectorySize()
{
    unsigned long long size = 0;
    
    NSDirectoryEnumerator *fileEnumerator = [[NSFileManager defaultManager] enumeratorAtPath:LRPathToImageCacheDirectory()];
    
    for (NSString *fileName in fileEnumerator)
    {
        NSString *filePath = [LRPathToImageCacheDirectory() stringByAppendingPathComponent:fileName];
        NSDictionary *fileAttributes = [[NSFileManager defaultManager] attributesOfItemAtPath:filePath error:nil];
        size += [fileAttributes fileSize];
    }
    
    return size;
}

NSString *LRCacheKeyForImage(NSURL *url, CGSize size)
{
    return LRMD5([url.absoluteString stringByAppendingString:NSStringFromCGSize(size)]);
}

- (NSTimeInterval)maxTimeInCache
{
    return _maxTimeInCache ?: kDefaultMaxTimeInCache;
}

- (unsigned long long)maxDirectorySize
{
    return _maxDirectorySize ?: kDefaultMaxCacheDirectorySize;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
#if !OS_OBJECT_USE_OBJC
    if (_syncQueue != NULL)
    {
        dispatch_release(_syncQueue);
    }
    
    if (_ioQueue != NULL)
    {
        dispatch_release(_ioQueue);
    }
#endif
    _syncQueue = NULL;
    _ioQueue = NULL;
}

@end
