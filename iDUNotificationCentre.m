#import "iDUNotificationCentre.h"

@implementation iDUNotificationCentre
+ (instancetype)centre {
    return [[iDUNotificationCentre alloc] init];
}
+ (instancetype)centreWithPostHandler:(NSDictionary * (^)(NSString *))postHandler receivedHandler:(void (^)(NSNotification *))receivedHandler {
    return [[iDUNotificationCentre alloc] initWithPostHandler:postHandler receivedHandler:receivedHandler];
}
- (instancetype)initWithPostHandler:(NSDictionary * (^)(NSString *))postHandler receivedHandler:(void (^)(NSNotification *))receivedHandler {
    self = [super init];
    self.postHandler = postHandler;
    self.receivedHandler = receivedHandler;
    return self;
}
- (void)observeNotificationsWithName:(NSString *)name from:(NSNotificationCenter *)nsNotificationCenter {
    [self observeNotificationsWithName:name object:nil from:nsNotificationCenter];
}
- (void)observeNotificationsWithName:(NSString *)name object:(id)object from:(NSNotificationCenter *)nsNotificationCenter {
    [nsNotificationCenter addObserver:self selector:@selector(receiveNotification:) name:name object:object];
}
- (void)postNotificationUsingPostHandlerWithName:(NSString *)name to:(NSNotificationCenter *)nsNotificationCenter {
    NSDictionary *userInfo = _postHandler(name);
    if (userInfo) [self postNotificationWithName:name userInfo:userInfo to:nsNotificationCenter];
    else [self postNotificationWithName:name to:nsNotificationCenter];
}
- (void)postNotificationWithName:(NSString *)name to:(NSNotificationCenter *)nsNotificationCenter {
    if ([nsNotificationCenter isKindOfClass:[NSDistributedNotificationCenter class]])
        [(NSDistributedNotificationCenter *)nsNotificationCenter postNotificationName:name object:nil userInfo:nil deliverImmediately:true];
    else [nsNotificationCenter postNotificationName:name object:nil];
}
- (void)postNotificationWithName:(NSString *)name userInfo:(NSDictionary *)userInfo to:(NSNotificationCenter *)nsNotificationCenter {
    if ([nsNotificationCenter isKindOfClass:[NSDistributedNotificationCenter class]])
        [(NSDistributedNotificationCenter *)nsNotificationCenter postNotificationName:name object:nil userInfo:userInfo deliverImmediately:true];
    else [nsNotificationCenter postNotificationName:name object:nil userInfo:userInfo];
}
- (void)receiveNotification:(NSNotification *)notification {
    _receivedHandler(notification);
}
- (void)stopObservingNotificationsFrom:(NSNotificationCenter *)nsNotificationCenter {
    [nsNotificationCenter removeObserver:self];
}
- (void)stopObservingNotificationsWithName:(NSString *)name from:(NSNotificationCenter *)nsNotificationCenter {
    [nsNotificationCenter removeObserver:self name:name object:nil];
}
@end