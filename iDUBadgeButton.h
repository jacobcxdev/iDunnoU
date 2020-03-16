#import <UIKit/UIKit.h>

@interface iDUBadgeButton : UIButton {
	    UILabel *_badgeLabel;
}
@property (nonatomic) NSUInteger badgeCount;
- (void)updateBadge;
@end