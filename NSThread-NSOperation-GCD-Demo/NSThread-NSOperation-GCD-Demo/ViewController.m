//
//  ViewController.m
//  NSThread-NSOperation-GCD-Demo
//
//  Created by vincentMac on 16/3/4.
//  Copyright © 2016年 vincentMac. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()

@property (nonatomic, strong)NSThread *thread;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
}
#pragma mark - NSThread
/*
 
 
 */
- (IBAction)NSThreadStart:(id)sender {
    self.thread = [[NSThread alloc] initWithTarget:self selector:@selector(doSomeThings) object:nil];
    self.thread.name = @"threadOne";
    [self.thread start];
}

- (IBAction)NSThreadCancel:(id)sender{
    self.view.backgroundColor = [UIColor cyanColor];
    [self.thread cancel];
}
- (void)doSomeThings{
    NSLog(@"thread doSomeThing");
    int i = 10;
    while (i--) {
        if ([self.thread isCancelled]) {
            //The current thread to exit
            [NSThread exit];
        }
        sleep(1);
        NSLog(@"i---->>%d",i);
    }
    NSLog(@"The current thread to exit");
}
#pragma mark - NSOperation
- (IBAction)NSOperationStart:(id)sender {
    /*
     NSOperation--抽象类，不能直接使用，需要使用其子类
     NSInvocationOperation
     NSBlockOperation
     */
    NSInvocationOperation *invocation = [[NSInvocationOperation alloc] initWithTarget:self selector:@selector(doSomeThings2) object:nil];
//    [invocation start];  直接启动，子线程是同步的，将其添加到队列里子线程为异步
    NSBlockOperation *blockOperation = [NSBlockOperation blockOperationWithBlock:^{
        int i = 3;
        while (i--) {
            [NSThread sleepForTimeInterval:1.0];
        }
        //UI操作需要回到主线程操作
        [self performSelectorOnMainThread:@selector(doSomeThings4) withObject:nil waitUntilDone:NO];//waitUntilDone  参数YES 为同步 NO为异步
    }];
    //建立依赖关系（决定队列里的任务执行优先级） 依赖关系需要在将任务添加到队列前建立
    [blockOperation addDependency:invocation];  //invocation 优先级高于  blockOperation
    NSOperationQueue *queue = [NSOperationQueue new];
    //将任务添加到队列
    [queue addOperation:blockOperation];
    [queue addOperation:invocation];
    //设置最大并发数
    queue.maxConcurrentOperationCount = 5;
    self.view.backgroundColor = [UIColor redColor];
}
- (void)doSomeThings2{
    int i = 3;
    while (i--) {
        [NSThread sleepForTimeInterval:1.0];
    }
    [self performSelectorOnMainThread:@selector(doSomeThings3) withObject:nil waitUntilDone:NO];
}

- (void)doSomeThings3{
    self.view.backgroundColor = [UIColor greenColor];
}

- (void)doSomeThings4{
    self.view.backgroundColor = [UIColor blueColor];
}

#pragma mark - GCD
/*
 任务：1.同步 不会阻塞线程
 2.异步 会阻塞线程
 队列：1.串行 任务按顺序执行
 2.并行 任务同时执行
 */
//手动创建队列  负责一些耗时操作
/*
 参数1：队列名字
 参数2：DISPATCH_QUEUE_CONCURRENT 并行    null 串行
 */
//    dispatch_queue_t newQueue = dispatch_queue_create("com.dispatch.queue", DISPATCH_QUEUE_CONCURRENT);

//主队列       负责UI操作（任务刷新UI的操作都应回到主队列去操作）
//    dispatch_queue_t mainQueue = dispatch_get_main_queue();

//全局队列
/*
 参数1 优先级
 参数2 保留参数，填0
 #define DISPATCH_QUEUE_PRIORITY_HIGH 2                 高优先级
 #define DISPATCH_QUEUE_PRIORITY_DEFAULT 0              默认优先级
 #define DISPATCH_QUEUE_PRIORITY_LOW (-2)               低优先级
 #define DISPATCH_QUEUE_PRIORITY_BACKGROUND INT16_MIN   最低优先级
 */
//    dispatch_queue_t globalQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);


- (IBAction)GCDStart:(id)sender {
//    [self appluGCD];
//    [self groupGCD];
//    [self asyncGCD];
    [self syncGCD];
 }
/*
 a.高效执行
 b.无序
 */
- (void)appluGCD{
    dispatch_queue_t globalQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_apply(1000, globalQueue, ^(size_t index) {
        NSLog(@"index---->> %ld",index);
        NSLog(@"结束高效执行");
    });
}

/*
    任务组：谁抢到资源谁就会执行
 */
- (void)groupGCD{
    dispatch_group_t group = dispatch_group_create();
    dispatch_queue_t queue = dispatch_queue_create("com.dispatch.queue", DISPATCH_QUEUE_CONCURRENT);
    //task1
    dispatch_group_async(group,queue, ^{
        int i = 3;
        NSLog(@"task-->>1-->>start");
        while (i--) {
            [NSThread sleepForTimeInterval:1.0];
        }
        NSLog(@"task-->>1-->>finished");
    });
    //task2
    dispatch_group_async(group,queue, ^{
        int i = 3;
        NSLog(@"task-->>2-->>start");
        while (i--) {
            [NSThread sleepForTimeInterval:1.0];
        }
        NSLog(@"task-->>2-->>finished");
    });
    //组里面的任务都完成
    dispatch_group_notify(group, queue, ^{
       dispatch_async(dispatch_get_main_queue(), ^{
           self.view.backgroundColor = [UIColor lightTextColor];
       });
    });
}
//异步任务
- (void)asyncGCD{
    NSLog(@"async begin");
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        int i = 3;
        NSLog(@"task start");
        while (i--) {
            [NSThread sleepForTimeInterval:1.0];
            NSLog(@"async-->>i-->>%d",i);
        }
        NSLog(@"task finished");
    });
    dispatch_async(dispatch_get_main_queue(), ^{
        self.view.backgroundColor = [UIColor yellowColor];
    });
    NSLog(@"async finished");
}
//同步任务 一般不用
- (void)syncGCD{
    NSLog(@"sync start");
    dispatch_sync(dispatch_queue_create("com.dispatch.queue", DISPATCH_QUEUE_CONCURRENT), ^{
        int i = 3;
        NSLog(@"task start");
        while (i--) {
            NSLog(@"sync-->i-->>%d",i);
            [NSThread sleepForTimeInterval:1.0];
        }
        NSLog(@"task finished");
    });
    dispatch_async(dispatch_get_main_queue(), ^{
        self.view.backgroundColor = [UIColor purpleColor];
    });
    NSLog(@"sync finished");
}
@end
