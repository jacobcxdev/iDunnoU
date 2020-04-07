#import "iDURootListController.h"

@implementation iDURootListController
- (instancetype)init {
    [iDUPackageInfo retrieveControl];
    return [super init];
}
- (NSArray *)specifiers {
    if (!_specifiers) _specifiers = [self loadSpecifiersFromPlistName:@"Root" target:self];
    return _specifiers;
}
- (id)readPreferenceValue:(PSSpecifier*)specifier {
    NSString *path = [NSString stringWithFormat:@"/User/Library/Preferences/%@.plist", specifier.properties[@"defaults"]];
    NSMutableDictionary *plist = [[NSMutableDictionary alloc] initWithContentsOfFile:path];
	return (plist[specifier.properties[@"key"]]) ?: specifier.properties[@"default"];
}
- (void)setPreferenceValue:(id)value specifier:(PSSpecifier*)specifier {
    NSString *path = [NSString stringWithFormat:@"/User/Library/Preferences/%@.plist", specifier.properties[@"defaults"]];
    NSMutableDictionary *plist = [[NSMutableDictionary alloc] initWithContentsOfFile:path];
	plist[specifier.properties[@"key"]] = value;
	[plist writeToFile:path atomically:true];
	CFStringRef notificationName = (__bridge CFStringRef)specifier.properties[@"PostNotification"];
	if (notificationName)
		CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), notificationName, NULL, NULL, true);
}
- (void)viewDidLoad {
    [super viewDidLoad];
    UIBarButtonItem *button = [[UIBarButtonItem alloc] initWithTitle:@"Respring" style:UIBarButtonItemStylePlain target:self action:@selector(killall)];
    self.navigationItem.rightBarButtonItem = button;
}
- (void)killall {
    NSTask *killallIMAgent = [[NSTask alloc] init];
    [killallIMAgent setLaunchPath:@"/usr/bin/killall"];
    [killallIMAgent setArguments:@[@"-9", @"imagent"]];
    [killallIMAgent launch];
    NSTask *killallTCCd = [[NSTask alloc] init];
    [killallTCCd setLaunchPath:@"/usr/bin/killall"];
    [killallTCCd setArguments:@[@"-9", @"tccd"]];
    [killallTCCd launch];
    NSTask *killallSpringBoard = [[NSTask alloc] init];
    [killallSpringBoard setLaunchPath:@"/usr/bin/killall"];
    [killallSpringBoard setArguments:@[@"-9", @"SpringBoard"]];
    [killallSpringBoard launch];
}
@end
