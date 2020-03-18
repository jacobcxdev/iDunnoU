#import "iDULinkCell.h"

@interface iDUTwitterCell : iDULinkCell {
    NSString *_username;
}
+ (NSURL *)twitterURLForUsername:(NSString *)username;
@end
