// LRImageOperation.h
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

extern NSString *const LRImageOperationErrorDomain;

/**
 This class is not meant to be used directly. Use LRImageManager instead.
 */
@interface LRImageOperation : NSOperation

@property (nonatomic, assign) BOOL autoRetry;
@property (nonatomic, assign) BOOL allowUntrustedHTTPSConnections;

- (instancetype)initWithURL:(NSURL *)url
                       size:(CGSize)size
                 imageCache:(id<LRImageCache>)imageCache
        cacheStorageOptions:(LRCacheStorageOptions)cacheStorageOptions
                contentMode:(UIViewContentMode)contentMode
           imageURLModifier:(LRImageURLModifierBlock)imageURLModifier
        postProcessingBlock:(LRImagePostProcessingBlock)postProcessingBlock
          completionHandler:(LRImageCompletionHandler)completionHandler;

- (void)addCompletionHandler:(LRImageCompletionHandler)completionHandler;

@end
