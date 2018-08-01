//
//  ViewController.m
//  ThreadKeepAlive
//
//  Created by 王辉平 on 2018/7/21.
//  Copyright © 2018年 王辉平. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()

@end

void oberserveActivityFun (CFRunLoopObserverRef observer, CFRunLoopActivity activity, void *info)
{
    switch (activity) {
        case kCFRunLoopEntry:
            NSLog(@"runloop --kCFRunLoopEntry--mode=%@",CFRunLoopCopyCurrentMode(CFRunLoopGetMain()));
            break;
        case kCFRunLoopBeforeWaiting:
//            NSLog(@"runloop --kCFRunLoopBeforeWaiting--mode=%@",CFRunLoopCopyCurrentMode(CFRunLoopGetMain()));
//              NSLog(@"modes=%@",CFRunLoopCopyAllModes(CFRunLoopGetMain()));
            break;
        case kCFRunLoopExit:
            NSLog(@"runloop --kCFRunLoopExit--mode=%@",CFRunLoopCopyCurrentMode(CFRunLoopGetMain()));
            break;
        default:
            break;
    }
}
@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    CFRunLoopObserverContext context = {0};
    //对主线程runLoop做观察监听  进入和退出
    CFRunLoopObserverRef observer = CFRunLoopObserverCreate(kCFAllocatorDefault, kCFRunLoopEntry|kCFRunLoopExit|kCFRunLoopBeforeWaiting, YES, 0, oberserveActivityFun, &context);
    CFRunLoopAddObserver(CFRunLoopGetMain(), observer, kCFRunLoopCommonModes);
    CFRelease(observer);

    //第二种方式
//    CFRunLoopObserverCreateWithHandler(kCFAllocatorDefault, kCFRunLoopEntry|kCFRunLoopExit|kCFRunLoopBeforeWaiting, YES, 0, ^(CFRunLoopObserverRef observer, CFRunLoopActivity activity) {
//        switch (activity) {
//            case kCFRunLoopEntry:
//                NSLog(@"runloop --kCFRunLoopEntry--mode=%@",CFRunLoopCopyCurrentMode(CFRunLoopGetMain()));
//                break;
//            case kCFRunLoopBeforeWaiting:
//                NSLog(@"runloop --kCFRunLoopBeforeWaiting--mode=%@",CFRunLoopCopyCurrentMode(CFRunLoopGetMain()));
//                break;
//            case kCFRunLoopExit:
//                NSLog(@"runloop --kCFRunLoopExit--mode=%@",CFRunLoopCopyCurrentMode(CFRunLoopGetMain()));
//                break;
//            default:
//                break;
//        }
//    });
}

@end
