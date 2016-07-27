//
//  UIButton+LRNetworking.h
//  Youla
//
//  Created by Develop Allgoritm on 17/05/16.
//  Copyright © 2016 allgoritm. All rights reserved.
//

#import "LRImageManager.h"
#import "UIView+LRNetworking.h"

@interface UIButton (LRNetworking)

- (void)lr_setImageWithURL:(NSURL *)url
                     state:(UIControlState)state
          placeholderImage:(UIImage *)placeholderImage;


- (void)lr_removePlaceholder;

@end
