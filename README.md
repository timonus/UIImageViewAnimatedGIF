# UIImageView+AnimatedGIF

Apple [quietly introduced](https://twitter.com/timonus/status/1146265545102241792) an API for playing animated GIFs and APNGs to the ImageIO framework in iOS 13. This project provides a high-level wrapper around that API that allows you to set animated images on `UIImageView`s.

## Installation

Add the UIImageView+AnimatedGIF.h and UIImageView+AnimatedGIF.m source files to your project.

## Usage

Animated images are represented using the `TJAnimatedImage` object, you can create a `TJAnimatedImage` using using data or a file URL as input.

This library adds a category on `UIImageView` that gives it an `animatedImage` property, setting this to an instance of `TJAnimatedImage` will play the animated image, setting it to `nil` will stop playback.

```objc
UIImageView *imageView = /* an image view */;

// Play animated image from NSData
NSData *animatedImageData = /* animated image data */;
TJAnimatedImage *animatedImage1 = [TJAnimatedImage animatedImageWithData:animatedImageData];
imageView.animatedImage = animatedImage1;

// Play animated image from a file URL
NSURL *animatedImageFileURL = /* animated image file URL */;
TJAnimatedImage *animatedImage2 = [TJAnimatedImage animatedImageWithURL:animatedImageFileURL];
imageView.animatedImage = animatedImage2;

// Stop playback
imageView.animatedImage = nil;
```

You can also use the `TJAnimatedImageView` class to ensure `image` and `animatedImage` are mutually exclusive, explained in the next section.

## Caveats

### `animatedImage`/`image` exclusivity

One caveat with the `UIImageView` category provided here is that setting `image` externally will not stop playback. For example

```objc
imageView.animatedImage = /* an animated image */;
imageView.image = /* a still image */;
// Problem: imageView will continue displaying animatedImage.
```

One workaround for this is to manually `nil` out `animatedImage` before setting `image`.

```objc
imageView.animatedImage = /* an animated image */;
imageView.animatedImage = nil;
imageView.image = /* a still image */;
// imageView will correctly display the image.
```

Another workaround is to use the `TJAnimatedImageView` subclass of `UIImageView`. `TJAnimatedImageView` enforces that setting `image` and `animatedImage` are mutually exclusive.

```objc
TJAnimatedImageView *animatedImageView = [TJAnimatedImageView new];
animatedImageView.animatedImage = /* an animated image */;
animatedImageView.image = /* a still image */;
// imageView will correctly display the image, animatedImage will be nilled out when image is set.
```

### Other caveats

- On iOS versions prior to 13 using this library just sets still images on image views. There is no animated fallback behavior. If you're looking for a library that supports older iOS versions I suggest [FLAnimatedImage](https://github.com/Flipboard/FLAnimatedImage).
- You must build with Xcode 11+ in order for this to build.