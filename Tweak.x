#import <UIKit/UIKit.h>

@interface CKConversation : NSObject
- (BOOL)isKnownSender;
@end

@interface CKConversationList : NSObject
- (NSMutableArray *)conversations;
@end

@interface CKConversationListController : UITableViewController
- (void)toggleHidden;
- (void)updateConversationList;
@end

static bool showKnownArray = true;
static UIButton *button;
static UIBarButtonItem *bbi;

%hook CKConversationList
- (NSMutableArray *)conversations {
	NSMutableArray *orig = %orig;
	NSMutableArray *knownArray = [[NSMutableArray alloc] init];
	NSMutableArray *unknownArray = [[NSMutableArray alloc] init];
	for (CKConversation *conversation in orig) {
		if ([conversation isKnownSender]) {
			[knownArray addObject:conversation];
		} else {
			[unknownArray addObject:conversation];
		}
	}
	return showKnownArray ? knownArray : unknownArray;
}
%end

%hook CKConversationListController
- (void)viewDidLayoutSubviews {
	if (!self.navigationItem.leftBarButtonItem) {
		if (!bbi) {
			if (!button) {
				button = [UIButton buttonWithType:UIButtonTypeCustom];
				[button setImage:[UIImage systemImageNamed:@"bubble.left.fill"] forState:UIControlStateNormal];
				[button setImage:[UIImage systemImageNamed:@"text.bubble.fill"] forState:UIControlStateSelected];
				[button addTarget:self action:@selector(toggleShowKnownArray) forControlEvents:UIControlEventTouchUpInside];
			}
			bbi = [[UIBarButtonItem alloc] initWithCustomView:button];
		}
		self.navigationItem.leftBarButtonItem = bbi;
	}
}
%new
- (void)toggleShowKnownArray {
	showKnownArray = !showKnownArray;
	if (button) button.selected = !showKnownArray;
	[self updateConversationList];
}
%end