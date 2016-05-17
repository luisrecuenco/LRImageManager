//
//  UIButton+LRNetworking.m
//  Youla
//
//  Created by Develop Allgoritm on 17/05/16.
//  Copyright © 2016 allgoritm. All rights reserved.
//

#import "UIButton+LRNetworking.h"

@implementation UIButton (LRNetworking)
- (void)lr_setImageWithURL:(NSURL *)url
                     state:(UIControlState)state
          placeholderImage:(UIImage *)placeholderImage {
    [[LRImageManager sharedManager] downloadImageForButton:self
                                                     state:state
                                          placeholderImage:placeholderImage
                                         activityIndicator:self.lr_activityIndicator
                                                  imageURL:url
                                                      size:self.frame.size
                                       cacheStorageOptions:[LRImageManager sharedManager].imageCache.cacheStorageOptions
                                       postProcessingBlock:self.lr_postProcessingBlock
                                         completionHandler:self.lr_completionHandler];
}
@end
