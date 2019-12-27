//
//  UIImageView+AnimatedGIF.m
//  UIImageViewAnimatedGIF
//
//  Created by Tim Johnsen on 12/26/19.
//  Copyright © 2019 Tim Johnsen. All rights reserved.
//

#import "UIImageView+AnimatedGIF.h"

#import <ImageIO/CGImageAnimation.h>
#import <objc/runtime.h>

@interface TJAnimatedImage ()

@property (nonatomic, strong, nullable, readwrite) NSData *data;
@property (nonatomic, strong, nullable, readwrite) NSURL *url;

@end

@implementation TJAnimatedImage

+ (instancetype)animatedImageWithData:(nullable NSData *const)data
{
    TJAnimatedImage *const animatedImage = [[TJAnimatedImage alloc] init];
    animatedImage.data = data;
    return animatedImage;
}

+ (instancetype)animatedImageWithURL:(nullable NSURL *const)url
{
    TJAnimatedImage *const animatedImage = [[TJAnimatedImage alloc] init];
    animatedImage.url = url;
    return animatedImage;
}

- (NSUInteger)hash
{
    return [self.data hash] + [self.url hash];
}

- (BOOL)isEqual:(id)object
{
    if ([object isKindOfClass:[TJAnimatedImage class]]) {
        return ((self.data == [(TJAnimatedImage *)object data] || [self.data isEqual:[(TJAnimatedImage *)object data]]) &&
                (self.url == [(TJAnimatedImage *)object url] || [self.url isEqual:[(TJAnimatedImage *)object url]]));
        
    }
    return NO;
}

@end

static const char *kUIImageViewAnimatedGIFAnimatedImageKey = "kUIImageViewAnimatedGIFAnimatedImageKey";

@implementation UIImageView (AnimatedGIF)

- (void)_tj_setImageAnimated:(UIImage *const)image
{
    [self setImage:image];
}

- (void)setAnimatedImage:(TJAnimatedImage *const)animatedImage
{
    if (self.animatedImage == animatedImage || [self.animatedImage isEqual:animatedImage]) {
        return;
    }
    
    objc_setAssociatedObject(self, kUIImageViewAnimatedGIFAnimatedImageKey, animatedImage, OBJC_ASSOCIATION_RETAIN);
    
    if (@available(iOS 13.0, *)) {
        __weak typeof(self) weakSelf = self;
        void (^updateBlock)(size_t, CGImageRef, bool *) = ^(size_t index, CGImageRef  _Nonnull image, bool * _Nonnull stop) {
            __strong typeof(weakSelf) strongSelf = weakSelf;
            if (strongSelf && [strongSelf.animatedImage isEqual:animatedImage]) {
                [strongSelf _tj_setImageAnimated:[UIImage imageWithCGImage:image]];
            } else {
                *stop = true;
            }
        };
        
        [self _tj_setImageAnimated:nil];
        
        if (animatedImage.data) {
            CGAnimateImageDataWithBlock((__bridge CFDataRef)animatedImage.data, nil, updateBlock);
        } else if (animatedImage.url) {
            CGAnimateImageAtURLWithBlock((__bridge CFURLRef)animatedImage.url, nil, updateBlock);
        }
    } else {
        if (animatedImage.data) {
            [self _tj_setImageAnimated:[UIImage imageWithData:animatedImage.data]];
        } else if (animatedImage.url && [animatedImage.url isFileURL]) {
            [self _tj_setImageAnimated:[UIImage imageWithContentsOfFile:animatedImage.url.path]];
        } else {
            [self _tj_setImageAnimated:nil];
        }
    }
}

- (TJAnimatedImage *)animatedImage
{
    return objc_getAssociatedObject(self, kUIImageViewAnimatedGIFAnimatedImageKey);
}

@end

@implementation TJAnimatedImageView

- (void)setImage:(UIImage *)image
{
    self.animatedImage = nil;
    [super setImage:image];
}

- (void)_tj_setImageAnimated:(UIImage *const)image
{
    [super setImage:image];
}

@end
