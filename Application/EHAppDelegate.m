#import "EHAppDelegate.h"
#import "../HUD/EHHomeViewController.h"

@implementation EHAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    (void)application;
    (void)launchOptions;

    self.window = [[UIWindow alloc] initWithFrame:UIScreen.mainScreen.bounds];
    self.window.rootViewController = [EHHomeViewController new];
    [self.window makeKeyAndVisible];
    return YES;
}

@end
