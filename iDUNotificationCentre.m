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
- (void)observeNotificationsWithName:(NSString *)name {
    [self observeNotificationsWithName:name object:nil];
}
- (void)observeNotificationsWithName:(NSString *)name object:(id)object {
    [[NSDistributedNotificationCenter defaultCenter] addObserver:self selector:@selector(receiveNotification:) name:name object:object];
}
- (void)postNotificationUsingPostHandlerWithName:(NSString *)name {
    NSDictionary *userInfo = _postHandler(name);
    if (userInfo) [self postNotificationWithName:name userInfo:userInfo];
    else [self postNotificationWithName:name];
}
- (void)postNotificationWithName:(NSString *)name {
    [[NSDistributedNotificationCenter defaultCenter] postNotificationName:name object:nil userInfo:nil deliverImmediately:true];
}
- (void)postNotificationWithName:(NSString *)name userInfo:(NSDictionary *)userInfo {
    [[NSDistributedNotificationCenter defaultCenter] postNotificationName:name object:nil userInfo:userInfo deliverImmediately:true];
}
- (void)receiveNotification:(NSNotification *)notification {
    _receivedHandler(notification);
}
- (void)stopObservingNotifications {
    [[NSDistributedNotificationCenter defaultCenter] removeObserver:self];
}
- (void)stopObservingNotificationsWithName:(NSString *)name {
    [[NSDistributedNotificationCenter defaultCenter] removeObserver:self name:name object:nil];
}
@end