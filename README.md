## LRImageManager

LRImageManager is a full-featured Objective-C image library. 

It supports: 

* Extremely efficient asynchronous image downloading using NSOperation and NSURLConnection.
* Image request cancellation and auto retry.
* Two memory cache types via NSCache and NSDictionary.
* Asynchronous disk cache using GCD (with automatic cache storage cleanup based on directory maximum size or time).
* UIImage category for image resizing, cropping and decompressing.
* Images with the same URL and size are guaranteed to be downloaded only once.
* UIImageView category for easy asynchronous image download (possibility to have a subtle fade animation when setting the image). 

## Install

1. **Using CocoaPods**

  Add LRImageManager to your Podfile:

  ```
  platform :ios, "5.0"
  pod 'LRImageManager' 
  ```

  Run the following command:
  
  ```
  pod install
  ```

2. **Static Library**

    Clone the project or add it as a submodule. Drag *LRImageManager.xcodeproj* to your project, add it as a target dependency and link *libLRImageManager.a*. 
    Then, you can simply do:
    
    ```
    #import <LRImageManager/Class.h>
    ```
	
3. **Manually**

  Clone the project or add it as a submodule. Drag the whole LRImageManager folder to your project.

## Usage

To download an image, you only have to use the following method from LRImageManager:

```objective-c
- (void)imageFromURL:(NSURL *)url 
                size:(CGSize)size 
      storageOptions:(LRCacheStorageOptions)storageOptions 
   completionHandler:(LRImageCompletionHandler)completionHandler;
```

Just specify the URL to download from and the size you want the image to be resized to (normally, the UIImageView container size). In case of not needing to resize, you can always use CGSizeZero. 

The resulting image will be downloaded from the given URL, resized to the specified size, decompressed and, depending on the storageOptions parameter, saved in memory (NSCache or NSDictionary) and disk.

LRCacheStorageOptions is defined as follows in LRImageCache.h.

```objective-c
typedef NS_OPTIONS(NSUInteger, LRCacheStorageOptions)
{
    LRCacheStorageOptionsNSDictionary = 1 << 0,
    LRCacheStorageOptionsNSCache = 1 << 1,
    LRCacheStorageOptionsOnlyMemory = 1 << 2,
};
```

The option to save it in a NSDictionary instead of NSCache is very handy for the cases when you can't afford some images to be flushed from memory (of course they will be gone in case of memory warnings).

LRImageCompletionHandler contains the downloaded image and an error if any issue arises.

```objective-c
typedef void (^LRImageCompletionHandler)(UIImage *image, NSError *error);
```

You can always cancel a specific request or every ongoing request:

```objective-c
- (void)cancelImageRequestFromURL:(NSURL *)url 
                             size:(CGSize)size;

- (void)cancelAllRequests;
```

Image cache is handled automatically by LRImageManager. In case you still want to use it for your own purposes, you can easily save and restore images:

```objective-c
- (UIImage *)memCachedImageForKey:(NSString *)key;

- (UIImage *)memCachedImageForURL:(NSURL *)url size:(CGSize)size;

- (void)diskCachedImageForKey:(NSString *)key 
 	          completionBlock:(void (^)(UIImage *image))completionBlock;

- (void)diskCachedImageForURL:(NSURL *)url 
		                 size:(CGSize)size 
	          completionBlock:(void (^)(UIImage *image))completionBlock;

- (void)cacheImage:(UIImage *)image 
	       withKey:(NSString *)key 
    storageOptinos:(LRCacheStorageOptions)storageOptions;

- (void)cacheImage:(UIImage *)image 
           withURL:(NSURL *)url 
              size:(CGSize)size 
    storageOptions:(LRCacheStorageOptions)storageOptions;
```

To easily download an image and assign it to a UIImageView container, there's a handy category UIImageView+LRNetworking for that very purpose.
Just set the URL, placeholder, size, storageOptions and animationOptions and you are good to go. There's also a method to cancel the current image request for that UIImageView.

```objective-c
- (void)setImageWithURL:(NSURL *)url 
       placeholderImage:(UIImage *)placeholderImage 
                   size:(CGSize)size 
         storageOptions:(LRCacheStorageOptions)storageOptions 
       animationOptions:(LRImageViewAnimationOptions)animationOptions;

- (void)cancelImageOperation;
```

You can even choose to have a subtle fade animation when setting the image:

```objective-c
typedef NS_OPTIONS(NSUInteger, LRImageViewAnimationOptions)
{
    LRImageViewAnimationOptionFade = 1 << 0,
    LRImageViewAnimationOptionNone = 1 << 1,
};
```

This category is the only one using LRImagePresenter class. Each UIImageView has a presenter object which is the one responsible for setting the resulting image in the container and using the LRImageManager class for downloading purposes.

## Requirements

LRImageManager requires both iOS 5.0 and ARC.

You can still use LRImageManager in your non-arc project. Just set -fobjc-arc compiler flag in every source file.

## Example

The best example for this library is a fully-featured TV Show Tracker app developed as the example of the [LRTVDBAPIClient](https://github.com/luisrecuenco/LRTVDBAPIClient).

## Contact

LRImageManager was created by Luis Recuenco: [@luisrecuenco](https://twitter.com/luisrecuenco).

## Contributing

If you want to contribute to the project just follow this steps:

1. Fork the repository.
2. Clone your fork to your local machine.
3. Create your feature branch.
4. Commit your changes, push to your fork and submit a pull request.

## License

LRImageManager is available under the MIT license. See the [LICENSE file](https://github.com/luisrecuenco/LRImageManager/blob/master/LICENSE) for more info.

