#import "iDULinkCell.h"

@interface iDUGitHubCell : iDULinkCell {
    NSString *_remote;
}
+ (NSURL *)gitHubURLForRemote:(NSString *)remote;
@end