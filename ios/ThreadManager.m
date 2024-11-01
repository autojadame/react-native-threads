#import "ThreadManager.h"
#import "ThreadsDevSettings.h"
#include <stdlib.h>

@implementation ThreadManager
{
  bool hasListeners;
}

@synthesize bridge = _bridge;

NSMutableDictionary *threads;
int nextThreadId = 1;
NSString *const THREAD_TERMINATED = @"ThreadIsTerminated";
NSString *const THREAD_MESSAGE = @"Thread";

- (NSArray<NSString *> *)supportedEvents
{
  return @[THREAD_TERMINATED, THREAD_MESSAGE];
}

-(void)startObserving {
    hasListeners = YES;
}

-(void)stopObserving {
    hasListeners = NO;
}

-(void) checkAndSendEvent:(NSString*)name body:(id)body
{
    if (hasListeners) {
      [self sendEventWithName:name body:body];
    }
}

RCT_EXPORT_MODULE();


RCT_REMAP_METHOD(startThread,
                 name: (NSString *)name
                 resolver:(RCTPromiseResolveBlock)resolve
                 rejecter:(RCTPromiseRejectBlock)reject)
{
  if (threads == nil) {
    threads = [[NSMutableDictionary alloc] init];
  }

  int threadId = nextThreadId++;

  NSString *jsFileSlug = [name containsString:@"./"]
    ? [name stringByReplacingOccurrencesOfString:@"./" withString:@""]
    : name;

  // Bundled JavaScript is placed within the resources directory.
  NSURL *bundledThreadURL = [[NSBundle mainBundle] URLForResource:[NSString stringWithFormat:@"%@", [jsFileSlug lastPathComponent]] withExtension:@"jsbundle"];

  // Check whether we can read bundle JS the resources directory. If
  // the file is not found, error will be non-nil.
  NSError *error = nil;
  NSURL *threadURL = [bundledThreadURL checkResourceIsReachableAndReturnError:&error]
    ? bundledThreadURL
    : [[RCTBundleURLProvider sharedSettings] jsBundleURLForBundleRoot:name];

  #ifndef DEBUG
    // For non-debug builds, we enforce that the bundle JS must
    // be available in the resources dir by terminating before
    // falling back to loading via Metro.
    if (error) {
      reject(
        [NSString stringWithFormat:@"%ld", (long)error.code],
        [NSString stringWithFormat:@"Unable to resolve thread bundle: %@", error.localizedDescription],
        error
      );
      return;
    }
  #endif
  NSLog(@"starting Thread %@", [threadURL absoluteString]);

  RCTBridgeModuleListProvider threadModuleProvider = ^NSArray<id<RCTBridgeModule>> *{
    ThreadsDevSettings *devSettings = [[ThreadsDevSettings alloc] init];
    return @[devSettings];
  };


  RCTBridge *threadBridge = [[RCTBridge alloc] initWithBundleURL:threadURL
                                            moduleProvider:threadModuleProvider
                                             launchOptions:nil];

  ThreadSelfManager *threadSelf = [threadBridge moduleForName:@"ThreadSelfManager"];
  [threadSelf setThreadId:threadId];
  [threadSelf setWorkerManager:self];
  [threadSelf setThreadMessage:THREAD_MESSAGE];


  [threads setObject:threadBridge forKey:[NSNumber numberWithInt:threadId]];
  resolve([NSNumber numberWithInt:threadId]);
}

RCT_EXPORT_METHOD(stopThread:(int)threadId)
{
  if (threads == nil) {
    NSLog(@"Empty list of threads. abort stopping thread with id %i", threadId);
    [self checkAndSendEvent:THREAD_TERMINATED body:@{@"threadId": [NSString stringWithFormat:@"%i",threadId]}];
    return;
  }

  RCTBridge *threadBridge = threads[[NSNumber numberWithInt:threadId]];
  if (threadBridge == nil) {
    NSLog(@"Thread is NIl. abort stopping thread with id %i", threadId);
    [self checkAndSendEvent:THREAD_TERMINATED body:@{@"threadId": [NSString stringWithFormat:@"%i",threadId]}];
    return;
  }

  [threadBridge invalidate];
  [threads removeObjectForKey:[NSNumber numberWithInt:threadId]];
}

RCT_EXPORT_METHOD(postThreadMessage: (int)threadId message:(NSString *)message)
{
  if (threads == nil) {
    NSLog(@"Empty list of threads. abort posting to thread with id %i", threadId);
    [self checkAndSendEvent:THREAD_TERMINATED body:@{@"threadId": [NSString stringWithFormat:@"%i",threadId]}];
    return;
  }

  RCTBridge *threadBridge = threads[[NSNumber numberWithInt:threadId]];
  if (threadBridge == nil) {
    NSLog(@"Thread is NIl. abort posting to thread with id %i", threadId);
    [self checkAndSendEvent:THREAD_TERMINATED body:@{@"threadId": [NSString stringWithFormat:@"%i",threadId]}];
    return;
  }

  [threadBridge.eventDispatcher sendAppEventWithName:@"ThreadMessage"
                                               body:message];
}

- (void)invalidate {
  if (threads == nil) {
    return;
  }

  for (NSNumber *threadId in threads) {
    RCTBridge *threadBridge = threads[threadId];
    [threadBridge invalidate];
  }

  [threads removeAllObjects];
  threads = nil;
}

@end
