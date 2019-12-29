//
//  ViewController.m
//  UIImageViewAnimatedGIFTestBed
//
//  Created by Tim Johnsen on 12/28/19.
//  Copyright © 2019 Tim Johnsen. All rights reserved.
//

#import "ViewController.h"

#import "UIImageView+AnimatedGIF.h"

@interface ViewController () <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, strong) NSMutableDictionary<NSString *, TJAnimatedImage *> *animatedImagesForFilenames;

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    UITableView *const tableView = [[UITableView alloc] initWithFrame:self.view.bounds];
    tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    tableView.dataSource = self;
    tableView.delegate = self;
    tableView.contentInset = UIEdgeInsetsZero;
    tableView.separatorInset = UIEdgeInsetsMake(0.0, FLT_EPSILON, 0.0, 0.0);
    tableView.layoutMargins = UIEdgeInsetsZero;
    tableView.preservesSuperviewLayoutMargins = NO;
    [self.view addSubview:tableView];
    
    self.animatedImagesForFilenames = [NSMutableDictionary new];
}

+ (NSArray<NSString *> *)imageFilenames
{
    return @[@"earth",
             @"elmo",
             @"hack",
             @"meme"];
}

- (TJAnimatedImage *)animatedImageForFilename:(NSString *const)filename
{
    TJAnimatedImage *image = self.animatedImagesForFilenames[filename];
    if (!image) {
        image = [TJAnimatedImage animatedImageWithURL:[[NSBundle mainBundle] URLForResource:filename withExtension:@"gif"]];
        self.animatedImagesForFilenames[filename] = image;
    }
    return image;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [[[self class] imageFilenames] count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *const kIdentifier = @"cell";
    static const NSInteger kImageViewTag = 555;
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kIdentifier];
    UIImageView *imageView;
    if (cell) {
        imageView = [cell.contentView viewWithTag:kImageViewTag];
    } else {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:kIdentifier];
        imageView = [[UIImageView alloc] initWithFrame:cell.contentView.bounds];
        imageView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        imageView.tag = kImageViewTag;
        [cell.contentView addSubview:imageView];
    }
    imageView.animatedImage = [self animatedImageForFilename:[[[self class] imageFilenames] objectAtIndex:indexPath.row]];
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *const filename = [[[self class] imageFilenames] objectAtIndex:indexPath.row];
    TJAnimatedImage *const image = [self animatedImageForFilename:filename];
    const CGFloat aspectRatio = image.size.height / image.size.width;
    const CGFloat height = aspectRatio * self.view.bounds.size.width;
    return height;
}

@end
