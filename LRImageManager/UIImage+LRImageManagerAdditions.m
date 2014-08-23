// UIImage+LRImageManagerAdditions.m
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

#import "UIImage+LRImageManagerAdditions.h"

@implementation UIImage (LRImageManagerAdditions)

- (instancetype)croppedImage:(CGRect)bounds
{
    CGRect croppingRect = CGRectIntegral(CGRectMake(bounds.origin.x * self.scale,
                                                    bounds.origin.y * self.scale,
                                                    bounds.size.width * self.scale,
                                                    bounds.size.height * self.scale));
    
    CGImageRef imageRef = CGImageCreateWithImageInRect(self.CGImage, croppingRect);
    
    UIImage *croppedImage = [UIImage imageWithCGImage:imageRef
                                                scale:self.scale
                                          orientation:self.imageOrientation];
    CGImageRelease(imageRef);
    
    return croppedImage;
}

- (instancetype)resizedImageWithContentMode:(UIViewContentMode)contentMode
                                     bounds:(CGSize)bounds
{
    CGFloat horizontalRatio = bounds.width / self.size.width;
    CGFloat verticalRatio = bounds.height / self.size.height;
    CGFloat ratio = 0;
    
    if (contentMode == UIViewContentModeScaleAspectFill)
    {
        ratio = MAX(horizontalRatio, verticalRatio);
    }
    else if (contentMode == UIViewContentModeScaleAspectFit)
    {
        ratio = MIN(horizontalRatio, verticalRatio);
    }
    else
    {
        NSAssert(NO, @"Unsupported content mode");
    }
    
    CGSize newSize = {self.size.width * ratio, self.size.height * ratio};
    
    return [self resizedImage:newSize];
}

- (instancetype)resizedImage:(CGSize)newSize
{
    CGRect newRect = CGRectIntegral(CGRectMake(0, 0, newSize.width, newSize.height));
    UIGraphicsBeginImageContextWithOptions(newRect.size, NO, 0.0f);
    [self drawInRect:newRect];
    UIImage *resizedImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return resizedImage;
}

- (instancetype)decompressImage
{
    CGImageRef imageRef = self.CGImage;
    CGSize imageSize = CGSizeMake(CGImageGetWidth(imageRef), CGImageGetHeight(imageRef));
    CGRect imageRect = (CGRect){.origin = CGPointZero, .size = imageSize};
    
    CGBitmapInfo bitmapInfo = CGImageGetBitmapInfo(imageRef);
    CGColorSpaceRef colorSpace = CGImageGetColorSpace(imageRef);
    
    // CGBitmapContextCreate doesn't support kCGImageAlphaNone with RGB.
    // https://developer.apple.com/library/mac/#qa/qa1037/_index.html
    if ((bitmapInfo & kCGBitmapAlphaInfoMask) == kCGImageAlphaNone &&
        CGColorSpaceGetNumberOfComponents(colorSpace) == 3)
    {
        bitmapInfo &= ~kCGBitmapAlphaInfoMask;
        bitmapInfo |= kCGImageAlphaNoneSkipFirst;
    }
    
    CGContextRef context = CGBitmapContextCreate(NULL,
                                                 lroundf(imageSize.width),
                                                 lroundf(imageSize.height),
                                                 CGImageGetBitsPerComponent(imageRef),
                                                 0,
                                                 colorSpace,
                                                 bitmapInfo);
    
    if (!context) return self;
    
    CGContextDrawImage(context, imageRect, imageRef);
    CGImageRef decompressedImageRef = CGBitmapContextCreateImage(context);
    CGContextRelease(context);
    
    UIImage *decompressedImage = [UIImage imageWithCGImage:decompressedImageRef
                                                     scale:self.scale
                                               orientation:self.imageOrientation];
    CGImageRelease(decompressedImageRef);
    
    return decompressedImage;
}

@end
