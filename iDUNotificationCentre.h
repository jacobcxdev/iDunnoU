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
- (void)observeNotificationsWithName:(NSString *)name from:(NSNotificationCenter *)nsNotificationCenter;
- (void)observeNotificationsWithName:(NSString *)name object:(id)object from:(NSNotificationCenter *)nsNotificationCenter;
- (void)postNotificationUsingPostHandlerWithName:(NSString *)name to:(NSNotificationCenter *)nsNotificationCenter;
- (void)postNotificationWithName:(NSString *)name to:(NSNotificationCenter *)nsNotificationCenter;
- (void)postNotificationWithName:(NSString *)name userInfo:(NSDictionary *)userInfo to:(NSNotificationCenter *)nsNotificationCenter;
- (void)receiveNotification:(NSNotification *)notification;
- (void)stopObservingNotificationsFrom:(NSNotificationCenter *)nsNotificationCenter;
- (void)stopObservingNotificationsWithName:(NSString *)name from:(NSNotificationCenter *)nsNotificationCenter;
@end