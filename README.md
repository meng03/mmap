# mmap
探索mmap的使用

## 使用步骤
* 创建文件或者指定文件
* 打开文件
* 调整文件大小（非必须步骤）
* mmap内存映射
* 拷贝内容到映射区
* 扩容 （看需要）
* munmap结束映射
* 关闭文件

### 创建或者打开文件没什么可说的，指定路径，创建文件。

### 打开文件使用open函数，返回文件句柄
````Objective-C
_fd = open([url UTF8String], O_RDWR,S_IRWXU);
if (_fd < 0) {
    NSLog(@"fail to open file:%@",url);
    return;
}
````
### 获取文件大小
````Objective-C
size_t fileSize = 0;
struct stat st = {};
if (fstat(_fd, &st) != -1) {
     fileSize = (size_t) st.st_size;
}
````
### 调整文件大小。如果设置的比文件小，则会截取文件。
````Objective-C
//代表将文件中多大的部分对应到内存。以字节为单位，不足一内存页按一内存页处理
//向上取整，找到pagesize的整倍数
size_t pageSize = getpagesize();
if (fileSize == 0 || fileSize/pageSize != 0) {
    _mmapSize = (fileSize/pageSize + 1) * pageSize;
    if (ftruncate(_fd, _mmapSize) != 0) {
        return;
    }
}else {
    _mmapSize = pageSize;
}
````
### 文件内存映射
````Objective-C
void *start = NULL; //由系统选定地址
off_t offset = 0;//offset为文件映射的偏移量，通常设置为0，代表从文件最前方开始对应，offset必须是分页大小的整数倍。可以简单理解为被映射对象内容的起点。
_ptr = (char *) mmap(start, _mmapSize, PROT_READ | PROT_WRITE, MAP_SHARED, _fd, offset);
if (_ptr == MAP_FAILED) {
    NSLog(@"mmap失败,%s",strerror(errno));
    //EBADF 参数fd 不是有效的文件描述词
    //EACCES 存取权限有误。如果是MAP_PRIVATE 情况下文件必须可读，使用MAP_SHARED则要有PROT_WRITE以及该文件要能写入。
    //EINVAL 参数start、length 或offset有一个不合法。
    //EAGAIN 文件被锁住，或是有太多内存被锁住。
    //ENOMEM 内存不足。
    return;
}
````
函数原型为`void *mmap(void *start,size_t length,int prot,int flags,int fd,off_t offsize);`
参数介绍：
* **start** 传入一个期望的映射起始地址。同常传入null，由系统寻找合适的内存区域，并将地址返回。
* **length** 传入映射的长度
* **port** 映射区域的操作属性，有如下四种类型，这里我们使用读写属性。
````Objective-C
#define	PROT_NONE	0x00	/* [MC2] no permissions */
#define	PROT_READ	0x01	/* [MC2] pages can be read */
#define	PROT_WRITE	0x02	/* [MC2] pages can be written */
#define	PROT_EXEC	0x04	/* [MC2] pages can be executed */
````
* **flag** 会影响映射区域的各种特性，可以看下定义，类型比较多
* **fd** 打开的文件句柄
* **offset** 为文件映射的偏移量，通常设置为0，代表从文件最前方开始对应

### 扩容需要三个步骤，使用ftruncate扩容文件，munmap结束映射，使用新的大小，重新映射。比如如下方法，是一个添加数据的方法，内存不够会扩容后继续添加
````Objective-C
- (void)appendData: (NSData *)data {
    if ((_offset + data.length) > _mmapSize) {
        off_t newSize = _mmapSize + getpagesize();
        if (ftruncate(_fd, newSize) != 0) {
            NSLog(@"fail to truncate [%zu] to size %lld, %s", _mmapSize, newSize, strerror(errno));
            return;
        }
        if (munmap(_ptr, _mmapSize) != 0) {
            NSLog(@"fail to munmap, %s", strerror(errno));
            return;
        }
        _mmapSize = newSize;
        _ptr = (char *) mmap(NULL, _mmapSize, PROT_READ | PROT_WRITE, MAP_SHARED, _fd, 0);
        if (_ptr == MAP_FAILED) {
            NSLog(@"mmap失败,%s",strerror(errno));
            return;
        }
    }
    memcpy(_ptr + _offset, data.bytes, data.length);
    _offset = _offset + data.length;
}
````



