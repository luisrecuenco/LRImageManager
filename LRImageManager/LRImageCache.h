// LRImageCache.h
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

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>


extern NSString * LRImageCacheDidStartLoadingImageNotification;
extern NSString * LRImageCacheDidStopLoadingImageNotification;


typedef NS_OPTIONS(NSUInteger, LRCacheStorageOptions)
{
    LRCacheStorageOptionsNSDictionary = 1 << 0,
    LRCacheStorageOptionsNSCache = 1 << 1,
};

@interface LRImageCache : NSObject

/** Cache time limit. */
@property (nonatomic, assign) NSTimeInterval maxTimeInCache;

/** Cache size limit */
@property (nonatomic, assign) unsigned long long maxDirectorySize;

/** Default cache storage option */
@property (nonatomic, assign) LRCacheStorageOptions defaultCacheStorageOption;

/** Avoids disk caching */
@property (nonatomic, assign) BOOL skipDiskCache;

+ (LRImageCache *)sharedImageCache;

- (UIImage *)memCachedImageForKey:(NSString *)key;

- (UIImage *)diskCachedImageForKey:(NSString *)key;

/**
 Async disk cache image retrieval.
 */
- (void)diskCachedImageForKey:(NSString *)key
              completionBlock:(void (^)(UIImage *image))completionBlock;

- (void)cacheImage:(UIImage *)image
           withKey:(NSString *)key
         diskCache:(BOOL)diskCache
    storageOptinos:(LRCacheStorageOptions)storageOptions;

- (void)clearMemCache;

- (void)clearMemCacheForKey:(NSString *)key;

- (void)clearDiskCache;

- (void)clearDiskCacheForKey:(NSString *)key;

- (void)cleanDisk;

@end

@interface LRImageCache (URLAndSize)

- (UIImage *)memCachedImageForURL:(NSURL *)url size:(CGSize)size;

- (UIImage *)diskCachedImageForURL:(NSURL *)url size:(CGSize)size;

/**
 Async disk cache image retrieval.
 */
- (void)diskCachedImageForURL:(NSURL *)url
                         size:(CGSize)size
              completionBlock:(void (^)(UIImage *image))completionBlock;

- (void)cacheImage:(UIImage *)image
           withURL:(NSURL *)url
              size:(CGSize)size
         diskCache:(BOOL)diskCache
    storageOptions:(LRCacheStorageOptions)storageOptions;

@end

NSString *LRCacheKeyForImage(NSURL *url, CGSize size);
