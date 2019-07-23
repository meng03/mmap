//
//  ViewController.m
//  mmap
//
//  Created by 孟冰川 on 2019/7/19.
//  Copyright © 2019 孟冰川. All rights reserved.
//

#import "ViewController.h"
#import <sys/mman.h>
#import <sys/stat.h>

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    NSString *path = [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex:0] stringByAppendingString:@"/test.txt"];
    NSLog(@"%@",path);
    [self testmmap:path];
}

- (void)testmmap: (NSString*)url{
    //打开文件，拿到文件句柄
    int fd = open([url UTF8String], O_RDWR,S_IRWXU);
    if (fd < 0) {
        NSLog(@"fail to open file:%@",url);
        return;
    }
    //获取文件大小
    size_t fileSize = 0;
    struct stat st = {};
    if (fstat(fd, &st) != -1) {
         fileSize = (size_t) st.st_size;
    }
    //代表将文件中多大的部分对应到内存。以字节为单位，不足一内存页按一内存页处理
    //向上取整，找到pagesize的整倍数
    size_t pageSize = getpagesize();
    size_t requiredSize = 0;
    if (fileSize == 0 || fileSize/pageSize != 0) {
        requiredSize = (fileSize/pageSize + 1) * pageSize;
        if (ftruncate(fd, requiredSize) != 0) {
            return;
        }
    }else {
        requiredSize = pageSize;
    }
    void *start = NULL; //由系统选定地址
    off_t offset = 0;//offset为文件映射的偏移量，通常设置为0，代表从文件最前方开始对应，offset必须是分页大小的整数倍。可以简单理解为被映射对象内容的起点。
    void *ptr = (char *) mmap(start, requiredSize, PROT_READ | PROT_WRITE, MAP_SHARED, fd, offset);
    if (ptr == MAP_FAILED) {
        NSLog(@"mmap失败,%s",strerror(errno));
        //EBADF 参数fd 不是有效的文件描述词
        //EACCES 存取权限有误。如果是MAP_PRIVATE 情况下文件必须可读，使用MAP_SHARED则要有PROT_WRITE以及该文件要能写入。
        //EINVAL 参数start、length 或offset有一个不合法。
        //EAGAIN 文件被锁住，或是有太多内存被锁住。
        //ENOMEM 内存不足。
        return;
    }
    NSString *str = @"12";
    NSData *data = [str dataUsingEncoding:NSASCIIStringEncoding];
    memcpy(ptr, data.bytes, data.length);
    munmap(ptr, data.length);
    close(fd);
}

@end
