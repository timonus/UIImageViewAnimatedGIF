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

@property (nonatomic, assign, readwrite) CGSize size;

@end

@implementation TJAnimatedImage

- (instancetype)init
{
    if (self = [super init]) {
        _size = CGSizeZero;
    }
    return self;
}

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

- (CGSize)size
{
    if (CGSizeEqualToSize(_size, CGSizeZero)) {
        CGImageSourceRef imageSource = nil;
        if (_data) {
            imageSource = CGImageSourceCreateWithData((__bridge CFDataRef)_data, nil);
        } else if (_url) {
            imageSource = CGImageSourceCreateWithURL((__bridge CFURLRef)_url, nil);
        }
        if (imageSource) {
            if (CGImageSourceGetCount(imageSource) > 0) {
                NSDictionary *const properties = (__bridge_transfer NSDictionary *)CGImageSourceCopyPropertiesAtIndex(imageSource, 0, nil);
                const CGFloat width = [properties[(__bridge NSString *)kCGImagePropertyPixelWidth] doubleValue];
                const CGFloat height = [properties[(__bridge NSString *)kCGImagePropertyPixelHeight] doubleValue];
                _size = CGSizeMake(width, height);
            }
            CFRelease(imageSource);
        }
    }
    return _size;
}

@end

static const char *kUIImageViewAnimatedGIFAnimatedImageKey = "kUIImageViewAnimatedGIFAnimatedImageKey";
static const char *kUIImageViewAnimatedGIFFrameKey = "kUIImageViewAnimatedGIFFrameKey";

@interface UIImageView ()

@property (nonatomic, assign, setter=_tj_setFrame:) size_t _tj_frame;

@end

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
    self._tj_frame = 0;
    
    if (@available(iOS 13.0, *)) {
        [self _tj_setImageAnimated:nil];
        [self _tj_tryBeginPlaybackWithAnimatedImage:animatedImage];
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

- (size_t)_tj_frame
{
    return [objc_getAssociatedObject(self, kUIImageViewAnimatedGIFFrameKey) unsignedIntValue];
}

- (void)_tj_setFrame:(size_t)_tj_frame
{
    objc_setAssociatedObject(self, kUIImageViewAnimatedGIFFrameKey, @(_tj_frame), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (void)_tj_tryBeginPlaybackWithAnimatedImage:(TJAnimatedImage *const)animatedImage
{
    if (@available(iOS 13.0, *)) {
        if ([self _tj_isPlaybackEligible]) {
            __weak typeof(self) weakSelf = self;
            void (^updateBlock)(size_t, CGImageRef, bool *) = ^(size_t index, CGImageRef  _Nonnull image, bool * _Nonnull stop) {
                __strong typeof(weakSelf) strongSelf = weakSelf;
                if (strongSelf && [strongSelf.animatedImage isEqual:animatedImage]) {
                    if ([self _tj_isPlaybackEligible]) {
                        strongSelf._tj_frame = index;
                        UIImage *const loadedImage = [UIImage imageWithCGImage:image];
                        [strongSelf _tj_setImageAnimated:loadedImage];
                        animatedImage.size = loadedImage.size;
                    } else {
                        *stop = true;
                    }
                } else {
                    *stop = true;
                }
            };
            NSDictionary *const options = @{(__bridge NSString *)kCGImageAnimationStartIndex: @(self._tj_frame)};
            if (animatedImage.data) {
                CGAnimateImageDataWithBlock((__bridge CFDataRef)animatedImage.data, (__bridge CFDictionaryRef)options, updateBlock);
            } else if (animatedImage.url) {
                CGAnimateImageAtURLWithBlock((__bridge CFURLRef)animatedImage.url, (__bridge CFDictionaryRef)options, updateBlock);
            }
        }
    }
}

- (BOOL)_tj_isPlaybackEligible
{
    return YES;
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

- (void)setAnimatedImage:(TJAnimatedImage *)animatedImage
{
    [super setAnimatedImage:animatedImage];
    
    if (animatedImage) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_tj_applicationWillEnterForeground:) name:UIApplicationWillEnterForegroundNotification object:nil];
    }
}

- (void)setHidden:(BOOL)hidden
{
    TJAnimatedImage *animatedImage;
    const BOOL shouldResume = self.isHidden && !hidden && (animatedImage = self.animatedImage);
    
    [super setHidden:hidden];
    
    if (shouldResume) {
        [self _tj_tryBeginPlaybackWithAnimatedImage:animatedImage];
    }
}

- (void)_tj_setImageAnimated:(UIImage *const)image
{
    [super setImage:image];
}

- (BOOL)_tj_isPlaybackEligible
{
    return self.window && !self.isHidden && [[UIApplication sharedApplication] applicationState] != UIApplicationStateBackground;
}

- (void)willMoveToWindow:(UIWindow *)newWindow
{
    if (!self.window && newWindow) {
        [self _tj_tryBeginPlaybackWithAnimatedImage:self.animatedImage];
    }
}

- (void)_tj_applicationWillEnterForeground:(NSNotification *const)notification
{
    [self _tj_tryBeginPlaybackWithAnimatedImage:self.animatedImage];
}

@end
