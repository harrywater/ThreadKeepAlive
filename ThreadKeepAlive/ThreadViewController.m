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
@property(nonatomic,assign)BOOL isStopRunLoop;
@end

void (^block1)(void) = ^{
    
    NSLog(@"处理--block1");
};


@implementation ThreadViewController
//函数
void observerLoopActivity (CFRunLoopObserverRef observer, CFRunLoopActivity activity, void *info)
{
    switch (activity) {
        case kCFRunLoopEntry:
            NSLog(@"runLoop-kCFRunLoopEntry");
            break;
        case kCFRunLoopBeforeWaiting:
//            NSLog(@"runloop-kCFRunLoopBeforeWaiting-mode=%@",CFRunLoopCopyCurrentMode(CFRunLoopGetMain()));
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
  
//    __weak typeof(self) weakSelf = self;
    self.thread = [[HPThread alloc]initWithBlock:^{
        
        //创建观察者监听runLoop
        CFRunLoopObserverContext context = {0};
        CFRunLoopRef loopf = CFRunLoopGetCurrent();
        CFRunLoopObserverRef loopObserverf = CFRunLoopObserverCreate(kCFAllocatorDefault, kCFRunLoopEntry|kCFRunLoopExit, YES, 0, observerLoopActivity, &context);
        CFRunLoopAddObserver(loopf, loopObserverf, kCFRunLoopDefaultMode);
        CFRelease(loopObserverf);
        
        //构造一个常住线程 使其生命跟VC同步
        //1、创建runLoop
        NSRunLoop* loop = [NSRunLoop currentRunLoop];
        //2、新增事件源加入
        /*问题及答案：
         1,为什么不加事件源直接run是不会开启的，原因是在源码中
        CFRunLoopModeRef currentMode = __CFRunLoopFindMode(rl, modeName, false);
        //如果没有添加事件源 currentMode=NULL  这个是NULL。
         2,为什么没有添加事件源时，__CFRunLoopFindMode返回的是NULL呢，原因是在CFRunLoopAddSource函数中的下面代码。如果没有Mode回去创建一个Mode
             CFRunLoopModeRef rlm = __CFRunLoopFindMode(rl, modeName, true);
        */
        [loop addPort:[NSPort port] forMode:NSDefaultRunLoopMode];
        
        //3、启动
    //runLoop runMode:beforeDate:只能运行一次loop 处理完sources后runLoop会退出，因此需要加一个while判断保证循环不死
        /*
        while (!weakSelf.isStopRunLoop) {
            //4、有一个问题，最后一次在dealloc中停掉，还是会进来，这时weakSelf是nil所以条件YES再次kCFRunLoopEntry，没有达到停止目的  注意不能再这个block里面strong = weakSelf,否则也会导致强引用出现
            [loop runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]];
        }*/
        
        //解决思路：weakSelf判断是否为空
//        while (weakSelf&&!weakSelf.isStopRunLoop) {
//            //4、有一个问题，最后一次在dealloc中停掉，还是会进来，这时weakSelf是nil所以条件YES再次kCFRunLoopEntry，没有达到停止目的  注意不能再这个block里面strong = weakSelf,否则也会导致强引用出现
//            [loop runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]];
//        }

        /*
         [loop run];用这个run启动loop是停止不了的。VC退出后线程也死不了。
         是由于开启了一个无限循环,无限执行runMode:beforeDate:，也就是类似whlie(1){runMode:beforeDate:}.
         官方文档：
          otherwise, it runs the receiver in the NSDefaultRunLoopMode by repeatedly invoking runMode:beforeDate:. In other words, this method effectively begins an infinite loop that processes data from the run loop’s input sources and timers.
         **/
        
        //CF 创建loop运行
        CFRunLoopSourceContext sourceContext  ={0};//需要初始化
        CFRunLoopSourceRef source = CFRunLoopSourceCreate(kCFAllocatorDefault, 0, &sourceContext);
        CFRunLoopAddSource(loopf, source, kCFRunLoopDefaultMode);
        CFRunLoopRun();
//        CFRunLoopRunInMode(kCFRunLoopDefaultMode, 1.0e10, false);//或者用这个
        
//        NSRunLoop* lop = [NSRunLoop currentRunLoop];
//        [lop run];//无效循环run 不可取
        
        CFRelease(source);
        
        
        NSLog(@"thread =%@----end挂了",[NSThread currentThread]);
    }];
    
    [self.thread start];
}
- (IBAction)stopThreadLoop:(id)sender {
    
    if(!self.thread) return;
    [self performSelector:@selector(stop) onThread:self.thread withObject:nil waitUntilDone:NO];
    
}
- (void)autoStopThreadLoop
{
    if(!self.thread) return;
    //注意：waitUntilDone:NO 会出问题。因为主线程不等thread执行完performSelector的task就会继续往下走代码流程，导致delloc执行完，从而销毁了self及其中的isStopRunLoop属性。如果waitUntilDone:NO就会出现坏内存访问，crash。
    //解决方法：waitUntilDone:YES  等待thread处理完threadTask 后再走下面的代码流程("继续走下面的代码---AAA")这样就保障了还是处于delloc方法中，没有执行完，从而self及其属性值都还没有被销毁。
    [self performSelector:@selector(stop) onThread:self.thread withObject:nil waitUntilDone:YES];
}
- (void)stop
{
    NSLog(@"停止thread loop");
    self.isStopRunLoop = YES;
    //RunLoop的停止操作，在UIKit中没有相应的方法函数
    //需要调用CFoundation层的函数
    //1、获取当前线程Run loop
    CFRunLoopRef loop = CFRunLoopGetCurrent();
    //2、停止当前loop
    CFRunLoopStop(loop);
    //3、清空指针
    self.thread = nil;
}
- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    NSLog(@"点击--开始");
    [self performSelector:@selector(threadTask) onThread:self.thread withObject:nil waitUntilDone:NO];
    NSLog(@"继续走下面的代码---AAA");
}
- (void)threadTask
{
    NSLog(@"threadTask---在干活啦");

}
- (void)dealloc {

    [self autoStopThreadLoop];//使用这个需要注意销毁时效问题 容易出现坏内存访问crash
    NSLog(@"ThreadViewController---delloc");
}

@end


