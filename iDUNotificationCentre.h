#import <Foundation/Foundation.h>

@interface NSDistributedNotificationCenter : NSNotificationCenter
+ (instancetype)defaultCenter;
- (void)postNotificationName:(NSString *)name object:(NSString *)object userInfo:(NSDictionary *)userInfo deliverImmediately:(BOOL)deliverImmediately;
@end

@interface iDUNotificationCentre : NSObject
@property (nonatomic, copy) NSDictionary *(^postHandler)(NSString *);
@property (nonatomic, copy) void (^receivedHandler)(NSNotification *);
+ (instancetype)centre;
+ (instancetype)centreWithPostHandler:(NSDictionary * (^)(NSString *))postHandler receivedHandler:(void (^)(NSNotification *))receivedHandler;
- (instancetype)initWithPostHandler:(NSDictionary * (^)(NSString *))postHandler receivedHandler:(void (^)(NSNotification *))receivedHandler;
- (void)observeNotificationsWithName:(NSString *)name;
- (void)postNotificationUsingPostHandlerWithName:(NSString *)name;
- (void)postNotificationWithName:(NSString *)name;
- (void)postNotificationWithName:(NSString *)name userInfo:(NSDictionary *)userInfo;
- (void)receiveNotification:(NSNotification *)notification;
- (void)stopObservingNotifications;
- (void)stopObservingNotificationsWithName:(NSString *)name;
@end