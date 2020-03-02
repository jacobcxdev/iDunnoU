//
//  Tweak.x
//  iDunnoU
//
//  Created by Jacob Clayden on 08/02/2020.
//  Copyright © 2020 JacobCXDev. All rights reserved.
//

#import <UIKit/UIKit.h>

// NSUserDefaults Interfaces

@interface NSUserDefaults (FBSpNOsor)
- (NSNumber *)objectForKey:(NSString *)key inDomain:(NSString *)domain;
- (void)setObject:(id)value forKey:(NSString *)key inDomain:(NSString *)domain;
@end

// Messages Interfaces

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

// Static Variables

static bool showKnownArray = true;
static UIButton *button;
static UIBarButtonItem *bbi;

// Messages Hooks

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
				[button setImage:[UIImage systemImageNamed:@"person.crop.circle"] forState:UIControlStateNormal];
				[button setImage:[UIImage systemImageNamed:@"questionmark.circle"] forState:UIControlStateSelected];
				[button addTarget:self action:@selector(toggleShowKnownArray) forControlEvents:UIControlEventTouchUpInside];
				button.backgroundColor = [UIColor secondarySystemFillColor];
				button.frame = CGRectMake(0, 0, 30, 30);
				button.layer.cornerRadius = 15;
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

// Constructor

%ctor {
	NSMutableDictionary *settings = [[NSMutableDictionary alloc] initWithContentsOfFile:@"/var/mobile/Library/Preferences/com.jacobcxdev.idunnou.plist"];
	bool enabled = [settings objectForKey:@"enabled"] ? [[settings objectForKey:@"enabled"] boolValue] : true;
	if (!enabled) return;
	%init();
	
	NSLog(@"iDunnoU loaded");
}
