//
//  Tweak.x
//  iDunnoU
//
//  Created by Jacob Clayden on 08/02/2020.
//  Copyright © 2020 JacobCXDev. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <LocalAuthentication/LocalAuthentication.h>
#import "iDUBadgeButton.h"
#import "iDUNotificationCentre.h"

// Messages Interfaces

@interface CNContact : NSObject
- (NSArray *)handles;
@end

@interface CKEntity : NSObject
- (CNContact *)cnContact;
@end

@interface CKConversation : NSObject
- (void)blacklist;
- (BOOL)isBlacklisted;
- (BOOL)isWhitelisted;
- (BOOL)isKnownSender;
- (CKEntity *)recipient;
- (void)removeFromBlacklist;
- (void)removeFromWhitelist;
- (NSString *)uniqueIdentifier;
- (unsigned long long)unreadCount;
- (void)whitelist;
@end

@interface CKConversationList : NSObject
- (NSMutableArray *)conversations;
@end

@interface CKConversationListCell : UITableViewCell
- (CKConversation *)conversation;
@end

@interface CKConversationListController : UITableViewController<UITableViewDelegate, UITableViewDataSource>
- (void)_chatUnreadCountDidChange:(NSNotification *)notification;
- (void)_toggleShowUnknownArray;
- (CKConversationList *)conversationList;
- (void)toggleShowUnknownArray;
- (void)updateConversationList;
@end

@interface CNContactToggleBlockCallerAction : NSObject
- (BOOL)isBlocked;
- (void)block;
- (void)unblock;
- (instancetype)initWithContact:(CNContact *)contact;
@end

@interface SMSApplication : UIApplication<UIApplicationDelegate>
- (void)applicationWillTerminate;
- (NSInteger)applicationIconBadgeNumber;
- (void)setApplicationBadgeString:(id)string;
- (void)setApplicationIconBadgeNumber:(NSInteger)number;
@end

// IMAgent Interfaces

@interface IMDBadgeUtilities : NSObject
- (void)updateBadgeForUnreadCountChangeIfNeeded:(long long)count;
@end

// TCCd Interfaces

@interface TCCDService : NSObject
@property (retain, nonatomic) NSString *name;
- (void)setDefaultAllowedIdentifiersList:(NSArray *)list;
@end

// Static Variables

static NSMutableArray *conversationBlacklist;
static NSString *conversationBlacklistKey = @"conversationBlacklist";
static NSMutableArray *conversationWhitelist;
static NSString *conversationWhitelistKey = @"conversationWhitelist";
static bool shouldHideUnknownUnreadCountFromSBBadge = false;
static NSString *shouldHideUnknownUnreadCountFromSBBadgeKey = @"shouldHideUnknownUnreadCountFromSBBadge";
static bool shouldHideButtonBadge = false;
static NSString *shouldHideButtonBadgeKey = @"shouldHideButtonBadge";
static bool shouldSecureUnknownList = false;
static NSString *shouldSecureUnknownListKey = @"shouldSecureUnknownList";
static bool showUnknownArray = false;
static NSString *showUnknownArrayKey = @"showUnknownArray";
static NSUInteger knownUnreadCount = 0;
static NSString *knownUnreadCountKey = @"knownUnreadCount";
static NSUInteger unknownUnreadCount = 0;
static NSString *unknownUnreadCountKey = @"unknownUnreadCount";
static NSString *updateNotificationName = @"com.jacobcxdev.idunnou.update";
static NSString *updateRequestNotificationName = @"com.jacobcxdev.idunnou.update.request";
static NSString *updateiCloudNotificationName = @"com.jacobcxdev.idunnou.updateiCloud";
static NSString *updateiCloudPersistNotificationName = @"com.jacobcxdev.idunnou.updateiCloud.persist";
static NSString *updateiCloudRestoreNotificationName = @"com.jacobcxdev.idunnou.updateiCloud.restore";
static iDUNotificationCentre *notificationCentre;
static NSUserDefaults *userDefaults;
static IMDBadgeUtilities *imdbu;
static iDUBadgeButton *button;
static UIBarButtonItem *bbi;

static void updateBadgeCount() {
	button.badgeCount = shouldHideButtonBadge ? 0 : showUnknownArray ? knownUnreadCount : unknownUnreadCount;
}

static void persistDefaultsState() {
	if (!userDefaults) return;
	userDefaults = [NSUserDefaults standardUserDefaults];
	[userDefaults setBool:showUnknownArray forKey:showUnknownArrayKey];
	[userDefaults setInteger:knownUnreadCount forKey:knownUnreadCountKey];
	[userDefaults setInteger:unknownUnreadCount forKey:unknownUnreadCountKey];
	[userDefaults setObject:conversationBlacklist forKey:conversationBlacklistKey];
	[userDefaults setObject:conversationWhitelist forKey:conversationWhitelistKey];
}

static void persistiCloudState() {
	if (!userDefaults) return;
	NSUbiquitousKeyValueStore *store = [NSUbiquitousKeyValueStore defaultStore];
	[store setArray:[userDefaults arrayForKey:conversationBlacklistKey] forKey:conversationBlacklistKey];
	[store setArray:[userDefaults arrayForKey:conversationWhitelistKey] forKey:conversationWhitelistKey];
	HBLogDebug(@"conversationBlacklistKey iCloud %@", [store arrayForKey:conversationBlacklistKey]);
	HBLogDebug(@"conversationBlacklistKey %@", conversationBlacklist);
	HBLogDebug(@"conversationWhitelistKey iCloud %@", [store arrayForKey:conversationWhitelistKey]);
	HBLogDebug(@"conversationWhitelistKey %@", conversationWhitelist);
	HBLogDebug(@"Synchronize %@", [store synchronize] ? @"true" : @"false");
}

static void restoreDefaultsState() {
	if (!userDefaults) return;
	showUnknownArray = shouldSecureUnknownList ? false : [userDefaults boolForKey:showUnknownArrayKey];
	knownUnreadCount = [userDefaults integerForKey:knownUnreadCountKey];
	unknownUnreadCount = [userDefaults integerForKey:unknownUnreadCountKey];
	conversationBlacklist = [userDefaults arrayForKey:conversationBlacklistKey] ? [[userDefaults arrayForKey:conversationBlacklistKey] mutableCopy] : [[NSMutableArray alloc] init];
	conversationWhitelist = [userDefaults arrayForKey:conversationWhitelistKey] ? [[userDefaults arrayForKey:conversationWhitelistKey] mutableCopy] : [[NSMutableArray alloc] init];
}

static void restoreiCloudState() {
	HBLogDebug(@"restoreiCloudState called, userDefaults = %@", userDefaults);
	if (!userDefaults) return;
	NSUbiquitousKeyValueStore *store = [NSUbiquitousKeyValueStore defaultStore];
	HBLogDebug(@"Synchronize %@", [store synchronize] ? @"true" : @"false");
	conversationBlacklist = [store arrayForKey:conversationBlacklistKey] ? [[store arrayForKey:conversationBlacklistKey] mutableCopy] : [[NSMutableArray alloc] init];
	conversationWhitelist = [store arrayForKey:conversationWhitelistKey] ? [[store arrayForKey:conversationWhitelistKey] mutableCopy] : [[NSMutableArray alloc] init];
	HBLogDebug(@"conversationBlacklistKey iCloud %@", [store arrayForKey:conversationBlacklistKey]);
	HBLogDebug(@"conversationBlacklistKey %@", conversationBlacklist);
	HBLogDebug(@"conversationWhitelistKey iCloud %@", [store arrayForKey:conversationWhitelistKey]);
	HBLogDebug(@"conversationWhitelistKey %@", conversationWhitelist);
}

// Messages Hooks

%group Messages
%hook CKConversation
%new
- (void)blacklist {
	[conversationBlacklist addObject:[self uniqueIdentifier]];
}
%new
- (void)removeFromBlacklist {
	[conversationBlacklist removeObject:[self uniqueIdentifier]];
}
%new
- (BOOL)isBlacklisted {
	return [conversationBlacklist indexOfObject:[self uniqueIdentifier]] != NSNotFound;
}
%new
- (void)whitelist {
	[conversationWhitelist addObject:[self uniqueIdentifier]];
}
%new
- (void)removeFromWhitelist {
	[conversationWhitelist removeObject:[self uniqueIdentifier]];
}
%new
- (BOOL)isWhitelisted {
	return [conversationWhitelist indexOfObject:[self uniqueIdentifier]] != NSNotFound;
}
%end

%hook CKConversationList
- (NSMutableArray *)conversations {
	NSMutableArray *orig = %orig;
	NSMutableArray *knownArray = [[NSMutableArray alloc] init];
	NSMutableArray *unknownArray = [[NSMutableArray alloc] init];
	knownUnreadCount = 0;
	unknownUnreadCount = 0;
	for (CKConversation *conversation in orig) {
		if (([conversation isKnownSender] && ![conversation isBlacklisted]) || (![conversation isKnownSender] && [conversation isWhitelisted])) {
			[knownArray addObject:conversation];
			knownUnreadCount += [conversation unreadCount];
		} else {
			[unknownArray addObject:conversation];
			unknownUnreadCount += [conversation unreadCount];
		}
	}
	updateBadgeCount();
	[notificationCentre postNotificationUsingPostHandlerWithName:updateNotificationName];
	return showUnknownArray ? unknownArray : knownArray;
}
%end

%hook CKConversationListController
- (void)_chatUnreadCountDidChange:(NSNotification *)notification {
	[[self conversationList] conversations];
	return %orig;
}
- (void)viewDidLayoutSubviews {
	if (!self.navigationItem.leftBarButtonItem) {
		if (!bbi) {
			if (!button) {
				button = [iDUBadgeButton buttonWithType:UIButtonTypeCustom];
				[button setImage:[UIImage systemImageNamed:@"questionmark.circle"] forState:UIControlStateNormal];
				[button setImage:[UIImage systemImageNamed:@"person.crop.circle"] forState:UIControlStateSelected];
				[button addTarget:self action:@selector(toggleShowUnknownArray) forControlEvents:UIControlEventTouchUpInside];
				button.backgroundColor = [UIColor secondarySystemFillColor];
				button.frame = CGRectMake(0, 0, 30, 30);
				button.layer.cornerRadius = 15;
			}
			bbi = [[UIBarButtonItem alloc] initWithCustomView:button];
		}
		self.navigationItem.leftBarButtonItem = bbi;
	}
	updateBadgeCount();
	return %orig;
}
%new
- (UISwipeActionsConfiguration *)tableView:(UITableView *)tableView leadingSwipeActionsConfigurationForRowAtIndexPath:(NSIndexPath *)indexPath {
	CKConversationListCell *cell = (CKConversationListCell *)[self tableView:tableView cellForRowAtIndexPath:indexPath];
	CKConversation *conversation = [cell conversation];
	CKEntity *recipient = [conversation recipient];
	UIContextualAction *blacklistAction = [UIContextualAction contextualActionWithStyle:UIContextualActionStyleDestructive title:([conversation isKnownSender] && [conversation isBlacklisted]) || (![conversation isKnownSender] && ![conversation isWhitelisted]) ? @"Unhide" : @"Hide" handler:^(UIContextualAction * _Nonnull action, __kindof UIView * _Nonnull sourceView, void (^ _Nonnull completionHandler)(BOOL)) {
		if ([conversation isKnownSender]) {
			if ([conversation isBlacklisted]) [conversation removeFromBlacklist];
			else [conversation blacklist];
		} else {
			if ([conversation isWhitelisted]) [conversation removeFromWhitelist];
			else [conversation whitelist];
		}
		[self updateConversationList];
		persistDefaultsState();
		[notificationCentre postNotificationWithName:updateiCloudPersistNotificationName];
		completionHandler(true);
	}];
	blacklistAction.backgroundColor = [conversation isBlacklisted] || (![conversation isKnownSender] && ![conversation isWhitelisted]) ? [UIColor systemTealColor] : [UIColor systemBlueColor];
	NSMutableArray *actions = [[NSMutableArray alloc] init];
	[actions addObject:blacklistAction];
	if (recipient && [[recipient cnContact] handles].count != 0) {
		CNContactToggleBlockCallerAction *cnBlockAction = [[%c(CNContactToggleBlockCallerAction) alloc] initWithContact:[recipient cnContact]];
		UIContextualAction *blockAction = [UIContextualAction contextualActionWithStyle:UIContextualActionStyleNormal title:[cnBlockAction isBlocked] ? @"Unblock" : @"Block" handler:^(UIContextualAction * _Nonnull action, __kindof UIView * _Nonnull sourceView, void (^ _Nonnull completionHandler)(BOOL)) {
			if ([cnBlockAction isBlocked]) [cnBlockAction unblock];
			else [cnBlockAction block];
			completionHandler(true);
		}];
		blockAction.backgroundColor = [cnBlockAction isBlocked] ? [UIColor systemPurpleColor] : [UIColor systemOrangeColor];
		[actions addObject:blockAction];
	}
	return [UISwipeActionsConfiguration configurationWithActions:actions];
}
%new
- (void)toggleShowUnknownArray {
	if (shouldSecureUnknownList && !showUnknownArray) {
		LAContext *context = [[LAContext alloc] init];
		NSError *error = nil;
		if ([context canEvaluatePolicy:LAPolicyDeviceOwnerAuthentication error:&error])
			[context evaluatePolicy:LAPolicyDeviceOwnerAuthentication localizedReason:@"iDunnoU" reply:^(BOOL success, NSError *error) {
				if (success) dispatch_async(dispatch_get_main_queue(), ^{
					[self _toggleShowUnknownArray];
				});
			}];
	} else [self _toggleShowUnknownArray];
}
%new
- (void)_toggleShowUnknownArray {
	showUnknownArray = !showUnknownArray;
	if (button) button.selected = showUnknownArray;
	[self updateConversationList];
	persistDefaultsState();
}
%end

%hook SMSApplication
- (void)applicationWillTerminate {
	persistDefaultsState();
	[notificationCentre postNotificationWithName:updateiCloudPersistNotificationName];
	return %orig;
}
%end
%end

// IMAgent Hooks

%group IMAgent
%hook IMDBadgeUtilities
- (instancetype)init {
	id orig = %orig;
	imdbu = orig;
	return orig;
}
- (void)updateBadgeForUnreadCountChangeIfNeeded:(long long)count {
	return shouldHideUnknownUnreadCountFromSBBadge ? %orig(knownUnreadCount) : %orig;
}
%end
%end

// TCCd Hooks

%group TCCd
%hook TCCDService
- (void)setDefaultAllowedIdentifiersList:(NSArray *)list {
	if ([self.name isEqual:@"kTCCServiceFaceID"]) {
		NSMutableArray *mutableList = [list mutableCopy];
		[mutableList addObject:@"com.apple.MobileSMS"];
		return %orig(mutableList);
	}
	return %orig;
}
%end
%end

// Constructor

%ctor {
	NSLog(@"Hello from iDunnoU");

	if ([[NSBundle mainBundle].bundleIdentifier isEqual:@"com.apple.tccd"]) %init(TCCd);
	else {
		NSMutableDictionary *settings = [[NSMutableDictionary alloc] initWithContentsOfFile:@"/var/mobile/Library/Preferences/com.jacobcxdev.idunnou.plist"];
		if (settings) {
			bool enabled = [settings objectForKey:@"enabled"] ? [[settings objectForKey:@"enabled"] boolValue] : true;
			if (!enabled) return;
			shouldHideUnknownUnreadCountFromSBBadge = [settings objectForKey:shouldHideUnknownUnreadCountFromSBBadgeKey] && [[settings objectForKey:shouldHideUnknownUnreadCountFromSBBadgeKey] boolValue];
			shouldHideButtonBadge = [settings objectForKey:shouldHideButtonBadgeKey] && [[settings objectForKey:shouldHideButtonBadgeKey] boolValue];
			shouldSecureUnknownList = [settings objectForKey:shouldSecureUnknownListKey] && [[settings objectForKey:shouldSecureUnknownListKey] boolValue];
		}

		notificationCentre = [iDUNotificationCentre centre];
		NSString *mainBundleID = [NSBundle mainBundle].bundleIdentifier;
		if ([mainBundleID isEqualToString:@"com.apple.MobileSMS"]) {
			userDefaults = [NSUserDefaults standardUserDefaults];
			notificationCentre.postHandler = ^NSDictionary *(NSString *name) {
				if ([name isEqualToString:updateNotificationName]) {
					return @{
						shouldHideUnknownUnreadCountFromSBBadgeKey: @(shouldHideUnknownUnreadCountFromSBBadge),
						showUnknownArrayKey: @(showUnknownArray),
						knownUnreadCountKey: @(knownUnreadCount),
						unknownUnreadCountKey: @(unknownUnreadCount)
					};
				} else if ([name isEqualToString:updateiCloudNotificationName]) restoreDefaultsState();
				return nil;
			};
			notificationCentre.receivedHandler = ^(NSNotification *notification) {
				if ([notification.name isEqualToString:updateRequestNotificationName]) {
					[notificationCentre postNotificationUsingPostHandlerWithName:updateNotificationName];
				}
			};
			[notificationCentre observeNotificationsWithName:updateRequestNotificationName];
			[notificationCentre observeNotificationsWithName:updateiCloudNotificationName];
			[notificationCentre postNotificationWithName:updateiCloudRestoreNotificationName];
			%init(Messages);
		} else if ([mainBundleID isEqualToString:@"com.apple.imagent"]) {
			userDefaults = [[NSUserDefaults alloc] initWithSuiteName:@"com.apple.MobileSMS"];
			notificationCentre.receivedHandler = ^(NSNotification *notification) {
				if ([notification.name isEqualToString:updateNotificationName]) {
					shouldHideUnknownUnreadCountFromSBBadge = [notification.userInfo objectForKey:shouldHideUnknownUnreadCountFromSBBadgeKey] && [[notification.userInfo objectForKey:shouldHideUnknownUnreadCountFromSBBadgeKey] boolValue];
					showUnknownArray = [notification.userInfo objectForKey:showUnknownArrayKey] && [[notification.userInfo objectForKey:showUnknownArrayKey] boolValue];
					knownUnreadCount = [notification.userInfo objectForKey:knownUnreadCountKey] ? [[notification.userInfo objectForKey:knownUnreadCountKey] intValue] : [userDefaults integerForKey:knownUnreadCountKey];
					unknownUnreadCount = [notification.userInfo objectForKey:unknownUnreadCountKey] ? [[notification.userInfo objectForKey:unknownUnreadCountKey] intValue] : [userDefaults integerForKey:unknownUnreadCountKey];
					if (imdbu) [imdbu updateBadgeForUnreadCountChangeIfNeeded:knownUnreadCount + unknownUnreadCount];
				} else if ([notification.name isEqualToString:updateiCloudPersistNotificationName]) {
					restoreDefaultsState();
					persistiCloudState();
				} else if ([notification.name isEqualToString:updateiCloudRestoreNotificationName]) {
					restoreiCloudState();
					persistDefaultsState();
				}
			};
			[notificationCentre observeNotificationsWithName:updateiCloudPersistNotificationName];
			[notificationCentre observeNotificationsWithName:updateiCloudRestoreNotificationName];
			[notificationCentre observeNotificationsWithName:updateNotificationName];
			[notificationCentre postNotificationWithName:updateRequestNotificationName];
			%init(IMAgent);
		} else return;

		restoreDefaultsState();
	}

	NSLog(@"iDunnoU loaded");
}