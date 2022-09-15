//
//  UIImageView+AnimatedGIF.h
//  UIImageViewAnimatedGIF
//
//  Created by Tim Johnsen on 12/26/19.
//  Copyright © 2019 Tim Johnsen. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface TJAnimatedImage : NSObject

+ (instancetype)animatedImageWithData:(nullable NSData *const)data;
+ (instancetype)animatedImageWithURL:(nullable NSURL *const)url;

/// Mutually exclusive with @c url.
@property (nonatomic, nullable, readonly) NSData *data;
/// Mutually exclusive with @c data.
@property (nonatomic, nullable, readonly) NSURL *url;

@property (nonatomic, readonly) CGSize size;

@end

@interface UIImageView (AnimatedGIF)

/// Makes it so that setting @c image will implicitly unset @c animatedImage without the need for @c TJAnimatedImageView.
/// Note: Swizzles out @c -setImage: internally.
+ (void)tj_configureStillImageAnimatedImageMutualExclusivity;

/// Allows for playback of animated GIFs from data or URL inputs.
/// Prior to iOS 13 usage of this method will set a still image instead of an animated one.
@property (nonatomic, nullable) TJAnimatedImage *animatedImage;

@end

@interface TJAnimatedImageView : UIImageView

/// Similar to UIImageView+AnimatedGIF except that @c image and @c animatedImage are mutually exclusive.
/// Setting @c image will unset @c animatedImage, which is not the case when using a plain @c UIImageView.

@end

NS_ASSUME_NONNULL_END
