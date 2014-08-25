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
    CGFloat horizontalRatio = bounds.width / self.size.width;
    CGFloat verticalRatio = bounds.height / self.size.height;
    CGFloat ratio = 1.0f;
    
    if (contentMode == UIViewContentModeScaleAspectFill)
    {
        ratio = MAX(horizontalRatio, verticalRatio);
    }
    else if (contentMode == UIViewContentModeScaleAspectFit)
    {
        ratio = MIN(horizontalRatio, verticalRatio);
    }
    
    CGSize newSize = {self.size.width * ratio, self.size.height * ratio};
    
    return [self lr_resizedImage:newSize];
}

- (instancetype)lr_resizedImage:(CGSize)newSize
{
    CGRect newRect = CGRectIntegral(CGRectMake(0, 0, newSize.width, newSize.height));
    UIGraphicsBeginImageContextWithOptions(newRect.size, ![self lr_hasAlpha], 0.0f);
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
                                                     scale:self.scale
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
