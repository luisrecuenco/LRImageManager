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
#import "UIImage+LRImageManagerAdditions.h"
#import <CommonCrypto/CommonCrypto.h>

#if DEBUG
#define LRImageManagerLog(s,...) NSLog( @"\n\n------------------------------------- DEBUG -------------------------------------\n\t<%p %@:(%d)>\n\n\t%@\n---------------------------------------------------------------------------------\n\n", self, \
[[NSString stringWithUTF8String:__FUNCTION__] lastPathComponent], __LINE__, \
[NSString stringWithFormat:(s), ##__VA_ARGS__] )
#else
#define LRImageManagerLog(s,...)
#endif

static const NSTimeInterval kDefaultMaxTimeInCache = 60 * 60 * 24 * 7; // 1 week
static const unsigned long long kDefaultMaxCacheDirectorySize = 100 * 1024 * 1024; // 100 MB
static const LRCacheStorageOptions kDefaultCacheStorageOptions = LRCacheStorageOptionsNSDictionary | LRCacheStorageOptionsDiskCache;

static NSString *const kImageCacheDirectoryName = @"LRImageCache";

@interface LRImageCache ()

@property (nonatomic, copy) NSString *cacheName;
@property (nonatomic, strong) NSMutableDictionary *imagesDictionary;
@property (nonatomic, strong) NSCache *imagesCache;
@property (nonatomic, strong) dispatch_queue_t ioQueue;
@property (nonatomic, strong) dispatch_queue_t syncQueue;
@property (nonatomic, strong) NSMutableDictionary *diskCacheKeysDictionary;

@end

@implementation LRImageCache

- (instancetype)initWithName:(NSString *)name
{
    self = [super init];
    
    if (self)
    {
        _cacheName = [name copy];
        _imagesDictionary = [NSMutableDictionary dictionary];
        _imagesCache = [[NSCache alloc] init];
        _ioQueue = dispatch_queue_create("com.LRImageClient.LRImageCacheIOQueue", NULL);
        _syncQueue = dispatch_queue_create("com.LRImageClient.LRImageCacheSyncQueue", NULL);
        _diskCacheKeysDictionary = [NSMutableDictionary dictionary];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(clearMemCache)
                                                     name:UIApplicationDidReceiveMemoryWarningNotification
                                                   object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(cleanDisk)
                                                     name:UIApplicationDidEnterBackgroundNotification
                                                   object:nil];
    }
    
    return self;
}

- (instancetype)init
{
    return [self initWithName:kImageCacheDirectoryName];
}

- (UIImage *)memCachedImageForKey:(NSString *)key
{
    if ([key length] == 0) return nil;
    
    __block UIImage *memCachedImage = nil;
    
    dispatch_sync(self.syncQueue, ^{
        memCachedImage = self.imagesDictionary[key] ?: [self.imagesCache objectForKey:key];
    });
    
    return memCachedImage;
}

- (UIImage *)memCachedImageForURL:(NSURL *)url size:(CGSize)size
{
    if ([[url absoluteString] length] == 0) return nil;
    
    NSString *imageCacheKey = LRMemCacheKey(url, size);
    
    return [self memCachedImageForKey:imageCacheKey];
}

- (UIImage *)diskCachedImageForKey:(NSString *)key
{
    if ([key length] == 0) return nil;
    
    NSString *filePath = LRFilePathForCacheKey(key, self.cacheName);
    
    UIImage *image = nil;
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:filePath])
    {
        __attribute__((objc_precise_lifetime)) UIImage *imageFromFile = [UIImage imageWithContentsOfFile:filePath];
        
        image = [UIImage imageWithCGImage:imageFromFile.CGImage
                                    scale:[[UIScreen mainScreen] scale]
                              orientation:UIImageOrientationUp];
    }
    
    return image;
    
}

- (UIImage *)diskCachedImageForURL:(NSURL *)url size:(CGSize)size
{
    if ([[url absoluteString] length] == 0) return nil;
    
    NSString *imageCacheKey = LRDiskCacheKey(url, size, self.diskCacheKeysDictionary);
    
    return [self diskCachedImageForKey:imageCacheKey];
}

- (void)diskCachedImageForKey:(NSString *)key
              completionBlock:(void (^)(UIImage *image))completionBlock
{
    dispatch_async(self.ioQueue, ^{
        
        UIImage *diskCachedImage = [self diskCachedImageForKey:key];
        
        if (completionBlock)
        {
            completionBlock([diskCachedImage decompressImage]);
        }
    });
}

- (void)diskCachedImageForURL:(NSURL *)url
                         size:(CGSize)size
              completionBlock:(void (^)(UIImage *image))completionBlock
{
    if ([[url absoluteString] length] == 0)
    {
        completionBlock(nil);
        return;
    };
    
    [self diskCachedImageForKey:LRDiskCacheKey(url, size, self.diskCacheKeysDictionary)
                completionBlock:completionBlock];
}

- (void)cacheImage:(UIImage *)image
       memCacheKey:(NSString *)memCacheKey
      diskCacheKey:(NSString *)diskCacheKey
cacheStorageOptions:(LRCacheStorageOptions)cacheStorageOptions
{
    [self memCacheImage:image key:memCacheKey cacheStorageOptions:cacheStorageOptions];
    
    if (cacheStorageOptions & LRCacheStorageOptionsDiskCache)
    {
        [self diskCache:image key:diskCacheKey];
    }
}

- (void)cacheImage:(UIImage *)image
           withURL:(NSURL *)url
              size:(CGSize)size
cacheStorageOptions:(LRCacheStorageOptions)cacheStorageOptions
{
    if (!image || !url) return;
    
    [self cacheImage:image
         memCacheKey:LRMemCacheKey(url, size)
        diskCacheKey:LRDiskCacheKey(url, size, self.diskCacheKeysDictionary)
 cacheStorageOptions:cacheStorageOptions];
}

- (void)memCacheImage:(UIImage *)image
                  key:(NSString *)key
  cacheStorageOptions:(LRCacheStorageOptions)cacheStorageOptions
{
    if (!image || !key) return;
    
    BOOL shouldSaveInNSDictionary = cacheStorageOptions & LRCacheStorageOptionsNSDictionary;
    BOOL shouldSaveInNSCache = cacheStorageOptions & LRCacheStorageOptionsNSCache;
    
    if (shouldSaveInNSDictionary && shouldSaveInNSCache)
    {
        NSAssert(NO, @"You probably don't want to save in both mem caches.");
    }
    
    if (shouldSaveInNSDictionary)
    {
        dispatch_sync(self.syncQueue, ^{
            self.imagesDictionary[key] = image;
        });
    }
    else if (shouldSaveInNSCache)
    {
        [self.imagesCache setObject:image
                             forKey:key
                               cost:image.size.width * image.size.height * image.scale];
    }
}

- (void)diskCache:(UIImage *)image key:(NSString *)key
{
    if (!image || !key) return;
    
    dispatch_async(self.ioQueue, ^{
        
        NSFileManager *fileManager = [NSFileManager defaultManager];
        NSString *imageCacheDirectoryPath = LRPathToImageCacheDirectory(self.cacheName);
        
        if (![fileManager fileExistsAtPath:imageCacheDirectoryPath])
        {
            NSError *error = nil;
            
            if (![fileManager createDirectoryAtPath:imageCacheDirectoryPath
                        withIntermediateDirectories:YES
                                         attributes:nil
                                              error:&error])
            {
                LRImageManagerLog(@"Error creating cache directory at path: %@ | error: %@", imageCacheDirectoryPath, [error localizedDescription]);
            }
            else
            {
                LRImageManagerLog(@"Cache directory successfully created at path: %@", imageCacheDirectoryPath);
            }
        }
        
        NSString *filePath = LRFilePathForCacheKey(key, self.cacheName);
        
        if (![fileManager fileExistsAtPath:filePath])
        {
            NSData *data = UIImageJPEGRepresentation(image, 1.0f);
            
            if (![fileManager createFileAtPath:filePath
                                      contents:data
                                    attributes:nil])
            {
                LRImageManagerLog(@"Error caching image at path: %@", filePath);
            }
            else
            {
                LRImageManagerLog(@"Image successfully cached at path: %@", filePath);
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

- (void)clearMemCacheForKey:(NSString *)key
{
    dispatch_sync(self.syncQueue, ^{
        [self.imagesDictionary removeObjectForKey:key];
    });
    
    // Not necessary, SO should've done the work.
    [self.imagesCache removeObjectForKey:key];
}

- (void)clearDiskCache
{
    dispatch_async(self.ioQueue, ^{
        
        NSFileManager *fileManager = [NSFileManager defaultManager];
        NSString *directoryPath = LRPathToImageCacheDirectory(self.cacheName);
        
        NSError *error = nil;
        
        if (![fileManager removeItemAtPath:directoryPath error:&error])
        {
            LRImageManagerLog(@"Error deleting cache directory at path: %@ | error: %@", directoryPath, [error localizedDescription]);
        }
        else
        {
            LRImageManagerLog(@"Cache directory removed successfully");
        }
    });
}

- (void)clearDiskCacheForKey:(NSString *)key
{
    dispatch_async(self.ioQueue, ^{
        
        NSFileManager *fileManager = [NSFileManager defaultManager];
        NSString *filePath = LRFilePathForCacheKey(key, self.cacheName);
        
        NSError *error = nil;
        
        if (![fileManager removeItemAtPath:filePath error:&error])
        {
            LRImageManagerLog(@"Error deleting cache file at path: %@ | error: %@", filePath, [error localizedDescription]);
        }
        else
        {
            LRImageManagerLog(@"Cache file removed successfully at path: %@", filePath);
        }
    });
}

- (void)cleanDisk
{
    if (LRCacheDirectorySize(self.cacheName) <= self.maxDirectorySize) return;
    
    dispatch_async(self.ioQueue, ^{
        
        NSDirectoryEnumerator *fileEnumerator = [[NSFileManager defaultManager] enumeratorAtPath:LRPathToImageCacheDirectory(self.cacheName)];
        
        NSFileManager *fileManager = [NSFileManager defaultManager];
        
        NSDate *now = [NSDate date];
        
        for (NSString *fileName in fileEnumerator)
        {
            NSString *filePath = [LRPathToImageCacheDirectory(self.cacheName) stringByAppendingPathComponent:fileName];
            NSDictionary *fileAttributes = [fileManager attributesOfItemAtPath:filePath error:nil];
            
            if ([now timeIntervalSinceDate:[fileAttributes fileModificationDate]] > self.maxTimeInCache)
            {
                NSError *error = nil;
                
                if (![fileManager removeItemAtPath:filePath error:&error])
                {
                    LRImageManagerLog(@"Error deleting file item at path: %@ | error: %@", filePath, [error localizedDescription]);
                }
                else
                {
                    LRImageManagerLog(@"File item removed successfully at path: %@", filePath);
                }
            }
        }
        
        // Still bigger? let's clear it all (TODO: LRU or similar, not so harsh)
        if (LRCacheDirectorySize(self.cacheName) > self.maxDirectorySize)
        {
            [self clearDiskCache];
        }
    });
}

NS_INLINE NSString *LRPathToImageCacheDirectory(NSString *name)
{
    static NSString *pathToImageCache = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSArray *cachesDirectories = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
        pathToImageCache = [[cachesDirectories firstObject] stringByAppendingPathComponent:name];
    });
    
    return pathToImageCache;
}

NS_INLINE NSString *LRFilePathForCacheKey(NSString *cacheKey, NSString *cacheName)
{
    return [LRPathToImageCacheDirectory(cacheName) stringByAppendingPathComponent:cacheKey];
}

NS_INLINE NSString *LRMD5(NSString *str)
{
    const char *cStr = [str UTF8String];
    unsigned char result[16];
    CC_MD5(cStr, (CC_LONG)strlen(cStr), result);
    return [NSString stringWithFormat:
            @"%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X",
            result[0], result[1], result[2], result[3],
            result[4], result[5], result[6], result[7],
            result[8], result[9], result[10], result[11],
            result[12], result[13], result[14], result[15]
            ];
}

NS_INLINE unsigned long long LRCacheDirectorySize(NSString *cacheName)
{
    unsigned long long size = 0;
    
    NSDirectoryEnumerator *fileEnumerator = [[NSFileManager defaultManager] enumeratorAtPath:LRPathToImageCacheDirectory(cacheName)];
    
    for (NSString *fileName in fileEnumerator)
    {
        NSString *filePath = [LRPathToImageCacheDirectory(cacheName) stringByAppendingPathComponent:fileName];
        NSDictionary *fileAttributes = [[NSFileManager defaultManager] attributesOfItemAtPath:filePath error:nil];
        size += [fileAttributes fileSize];
    }
    
    return size;
}

NS_INLINE NSString *LRMemCacheKey(NSURL *url, CGSize size)
{
    if (!url) return nil;
    
    return [NSString stringWithFormat:@"%@-%d-%d", [url absoluteString], (NSUInteger)size.width, (NSUInteger)size.height];
}

NS_INLINE NSString *LRDiskCacheKey(NSURL *url, CGSize size, NSMutableDictionary *cacheKeysMap)
{
    if (!url) return nil;
    
    NSString *memCacheKey = LRMemCacheKey(url, size);
    NSString *cacheKey = cacheKeysMap[memCacheKey];
    
    if (!cacheKey)
    {
        cacheKeysMap[memCacheKey] = cacheKey = LRMD5([[url absoluteString] stringByAppendingString:NSStringFromCGSize(size)]);
    }
    
    return cacheKey;
}

- (NSTimeInterval)maxTimeInCache
{
    return _maxTimeInCache ?: (_maxTimeInCache = kDefaultMaxTimeInCache);
}

- (unsigned long long)maxDirectorySize
{
    return _maxDirectorySize ?: (_maxDirectorySize = kDefaultMaxCacheDirectorySize);
}

- (LRCacheStorageOptions)cacheStorageOptions
{
    return _cacheStorageOptions ?: (_cacheStorageOptions = kDefaultCacheStorageOptions);
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
