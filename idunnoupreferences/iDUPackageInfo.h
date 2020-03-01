#import <Foundation/Foundation.h>
#import <NSTask.h>

@interface iDUPackageInfo : NSObject
@property (class, strong, nonatomic) NSMutableDictionary *control;
+ (void)setControlFromBundleID:(NSString *)bundleID;
+ (void)retrieveControl;
@end
