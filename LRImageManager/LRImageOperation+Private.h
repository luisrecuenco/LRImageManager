//
//  LRImageOperation+Private.h
//  iShows
//
//  Created by Luis Recuenco on 19/05/13.
//  Copyright (c) 2013 Luis Recuenco. All rights reserved.
//

#import "LRImageOperation.h"

@interface LRImageOperation (Private)

// Inputs
@property (nonatomic, strong, readonly) NSURL *url;
@property (nonatomic, assign, readonly) CGSize size;
@property (nonatomic, assign, readonly) BOOL diskCache;
@property (nonatomic, assign, readonly) LRCacheStorageOptions storageOptions;
@property (nonatomic, strong, readonly) NSMutableArray *completionHandlers;

// Outputs
@property (nonatomic, strong, readonly) UIImage *image;
@property (nonatomic, strong, readonly) NSError *error;

@end
