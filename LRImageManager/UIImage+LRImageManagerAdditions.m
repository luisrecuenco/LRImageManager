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

- (instancetype)lr_resizedImageWithContentMode:(UIViewContentMode)contentMode bounds:(CGSize)bounds
{
    CGFloat scaleRatio = [[UIScreen mainScreen] scale] / self.scale;
    CGFloat horizontalRatio = bounds.width * scaleRatio / self.size.width;
    CGFloat verticalRatio = bounds.height * scaleRatio / self.size.height;
    CGFloat ratio = 1.0f;
    
    if (contentMode == UIViewContentModeScaleAspectFit)
    {
        ratio = MIN(horizontalRatio, verticalRatio);
    }
    else
    {
        ratio = MAX(horizontalRatio, verticalRatio);
    }
    
    if (ratio == 1) return self;
    
    return [self lr_resizedImage:(CGSize){self.size.width * ratio, self.size.height * ratio}];
}

- (instancetype)lr_resizedImage:(CGSize)newSize
{
    CGRect newRect = CGRectIntegral((CGRect){.origin = CGPointZero, .size = newSize});
    UIGraphicsBeginImageContextWithOptions(newRect.size, ![self lr_hasAlpha], self.scale);
    [self drawInRect:newRect];
    UIImage *resizedImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return resizedImage;
}

- (instancetype)lr_decompressImage
{
    CGImageRef imageRef = self.CGImage;
    CGSize imageSize = CGSizeMake(CGImageGetWidth(imageRef), CGImageGetHeight(imageRef));
    CGRect imageRect = (CGRect){.origin = CGPointZero, .size = imageSize};
    
    CGBitmapInfo bitmapInfo = CGImageGetBitmapInfo(imageRef);
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    
    uint32_t alpha = (bitmapInfo & kCGBitmapAlphaInfoMask);
    if (alpha == kCGImageAlphaNone)
    {
        bitmapInfo &= ~kCGBitmapAlphaInfoMask;
        bitmapInfo |= kCGImageAlphaNoneSkipFirst;
    }
    else if (alpha != kCGImageAlphaNoneSkipFirst & alpha != kCGImageAlphaNoneSkipLast)
    {
        bitmapInfo &= ~kCGBitmapAlphaInfoMask;
        bitmapInfo |= kCGImageAlphaPremultipliedFirst;
    }
    
    CGContextRef context = CGBitmapContextCreate(NULL, imageSize.width, imageSize.height, CGImageGetBitsPerComponent(imageRef), 0, colorSpace, bitmapInfo);
    
    CGColorSpaceRelease(colorSpace);
    
    if (!context) return self;
    
    UIGraphicsPushContext(context);
    CGContextTranslateCTM(context, 0, imageSize.height);
    CGContextScaleCTM(context, 1.0, -1.0);
    [self drawInRect:imageRect];
    UIGraphicsPopContext();
    
    CGImageRef decompressedImageRef = CGBitmapContextCreateImage(context);
    CGContextRelease(context);
    
    UIImage *decompressedImage = [UIImage imageWithCGImage:decompressedImageRef
                                                     scale:[UIScreen mainScreen].scale
                                               orientation:self.imageOrientation];
    
    CGImageRelease(decompressedImageRef);
    
    return decompressedImage;
}

- (BOOL)lr_hasAlpha
{
    CGImageAlphaInfo alpha = CGImageGetAlphaInfo(self.CGImage);
    return (alpha == kCGImageAlphaFirst ||
            alpha == kCGImageAlphaLast ||
            alpha == kCGImageAlphaPremultipliedFirst ||
            alpha == kCGImageAlphaPremultipliedLast);
}

@end
