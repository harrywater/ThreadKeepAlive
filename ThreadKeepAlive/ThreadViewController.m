//
//  ThreadViewController.m
//  ThreadKeepAlive
//
//  Created by 王辉平 on 2018/7/22.
//  Copyright © 2018年 王辉平. All rights reserved.
//

#import "ThreadViewController.h"
#import "HPThread.h"

@interface ThreadViewController ()
@property(nonatomic,strong)HPThread* thread;
@end

@implementation ThreadViewController
//函数
void observerLoopActivity (CFRunLoopObserverRef observer, CFRunLoopActivity activity, void *info)
{
    switch (activity) {
        case kCFRunLoopEntry:
            NSLog(@"runLoop-kCFRunLoopEntry");
            break;
        case kCFRunLoopExit:
            NSLog(@"runLoop-kCFRunLoopExit");
            break;
        default:
            break;
    }
}
- (void)viewDidLoad {
    [super viewDidLoad];
    
    
    self.thread = [[HPThread alloc]initWithBlock:^{
        
        //创建观察者监听runLoop
        CFRunLoopRef loopf = CFRunLoopGetCurrent();
        CFRunLoopObserverRef loopObserverf = CFRunLoopObserverCreate(kCFAllocatorDefault, kCFRunLoopEntry|kCFRunLoopExit, YES, 0, observerLoopActivity, NULL);
        CFRunLoopAddObserver(loopf, loopObserverf, kCFRunLoopDefaultMode);
        
        //构造一个常住线程 使其生命跟VC同步
        //1、创建runLoop
        NSRunLoop* loop = [NSRunLoop currentRunLoop];
        //2、新增事件源加入
        /*问题及答案：1,为什么不加事件源直接run是不会开启的，原因是在源码中
        CFRunLoopModeRef currentMode = __CFRunLoopFindMode(rl, modeName, false);
        //如果没有添加事件源 currentMode=NULL  这个是NULL。
         
        if (NULL == currentMode || __CFRunLoopModeIsEmpty(rl, currentMode, rl->_currentMode)) {
            Boolean did = false;
            if (currentMode) __CFRunLoopModeUnlock(currentMode);
            __CFRunLoopUnlock(rl);
            return did ? kCFRunLoopRunHandledSource : kCFRunLoopRunFinished;
        }
         
         2,为什么没有添加事件源时，__CFRunLoopFindMode返回的是NULL呢，原因是在CFRunLoopAddSource函数中的下面代码。如果没有Mode回去创建一个Mode
             CFRunLoopModeRef rlm = __CFRunLoopFindMode(rl, modeName, true);
        */
        [loop addPort:[NSPort port] forMode:NSDefaultRunLoopMode];
        //3、启动runLoop
        [loop runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]];
//        [loop run];
        
        //打印底层调用Run的结果CFRunLoopRunResult
        /*
         
         typedef CF_ENUM(SInt32, CFRunLoopRunResult) {
         kCFRunLoopRunFinished = 1,
         kCFRunLoopRunStopped = 2,
         kCFRunLoopRunTimedOut = 3,
         kCFRunLoopRunHandledSource = 4
         };
         
         */
//      SInt32 resultIndex = CFRunLoopRunInMode(kCFRunLoopDefaultMode, MAXFLOAT, YES);
//      NSLog(@"resIndex==%d",resultIndex);
        
        /*
         [loop run];用这个run启动loop是停止不了的。VC退出后线程也死不了。
         是由于开启了一个无限循环,无限执行runMode:beforeDate:，也就是类似whlie(1){runMode:beforeDate:}.
         官方文档：
          otherwise, it runs the receiver in the NSDefaultRunLoopMode by repeatedly invoking runMode:beforeDate:. In other words, this method effectively begins an infinite loop that processes data from the run loop’s input sources and timers.
         
         源码：一个while循环
         void CFRunLoopRun(void) {
           int32_t result;
        do {
            result = CFRunLoopRunSpecific(CFRunLoopGetCurrent(), kCFRunLoopDefaultMode, 1.0e10, false);
            CHECK_FOR_FORK();
        } while (kCFRunLoopRunStopped != result && kCFRunLoopRunFinished != result);
    }
                   
         **/
        NSLog(@"current thread = %@",[NSThread currentThread]);
        NSLog(@"thread end");
    }];
    
    [self.thread start];
}
- (IBAction)stopThreadLoop:(id)sender {
    
    [self performSelector:@selector(stop) onThread:self.thread withObject:nil waitUntilDone:NO];
    
}
- (void)stop
{
    NSLog(@"停止thread loop");
    //RunLoop的停止操作，在UIKit中没有相应的方法函数
    //需要调用CFoundation层的函数
    //1、获取当前线程Run loop
    CFRunLoopRef loop = CFRunLoopGetCurrent();
    //2、停止当前loop
    CFRunLoopStop(loop);
    
}
- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    NSLog(@"点击--开始");
    [self performSelector:@selector(threadTask) onThread:self.thread withObject:nil waitUntilDone:NO];
    
}
- (void)threadTask
{
    NSLog(@"threadTask---在干活啦");
}
- (void)dealloc {
    self.thread = nil;
    NSLog(@"ThreadViewController---delloc");
}

@end


