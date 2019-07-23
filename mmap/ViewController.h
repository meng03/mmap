//
//  ViewController.h
//  mmap
//
//  Created by 孟冰川 on 2019/7/19.
//  Copyright © 2019 孟冰川. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ViewController : UIViewController

@property(nonatomic,assign) size_t offset;
@property(nonatomic,assign) void *ptr;
@property(nonatomic,assign) size_t mmapSize;
@property(nonatomic,assign) int fd;

@end

