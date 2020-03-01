#include "iDURootListController.h"

@implementation iDURootListController
- (instancetype)init {
	[iDUPackageInfo retrieveControl];
	return [super init];
}
- (NSArray *)specifiers {
	if (!_specifiers) _specifiers = [self loadSpecifiersFromPlistName:@"Root" target:self];
	return _specifiers;
}
- (void)viewDidLoad {
	[super viewDidLoad];
	UIBarButtonItem *button = [[UIBarButtonItem alloc] initWithTitle:@"Kill Messages" style:UIBarButtonItemStylePlain target:self action:@selector(killallMobileSMS)];
	self.navigationItem.rightBarButtonItem = button;
}
- (void)killallMobileSMS {
	NSTask *killall = [[NSTask alloc] init];
	[killall setLaunchPath:@"/usr/bin/killall"];
	[killall setArguments:@[@"-9", @"MobileSMS"]];
	[killall launch];
}
@end
