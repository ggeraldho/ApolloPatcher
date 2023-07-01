#import <UIKit/UIKit.h>

#define COLOR_BACKGROUND [UIColor colorWithRed:0.12 green:0.16 blue:0.61 alpha:1.0]

static NSString *kCustomID;
static NSString *accessToken;
static UIAlertController *alertWithText;

@interface UIApplication (Private)
- (void)suspend;
- (void)terminateWithSuccess;
@end

@interface UIApplication (AnimatedExitToSpringBoard)
- (void)closeAppAnimatedExit;
@end

@implementation UIApplication (AnimatedExitToSpringBoard)
- (void)closeAppAnimatedExit {
    BOOL multitaskingSupported = NO;
    if ([[UIDevice currentDevice] respondsToSelector:@selector(isMultitaskingSupported)]) {
        multitaskingSupported = [UIDevice currentDevice].multitaskingSupported;
    }
    if ([self respondsToSelector:@selector(suspend)]) {
        if (multitaskingSupported) {
            [self beginBackgroundTaskWithExpirationHandler:^{}];
            [self performSelector:@selector(exit) withObject:nil afterDelay:0.4];
        }
        [self suspend];
    } else {
        [self exit];
    }
}

- (void)exit {
    if ([self respondsToSelector:@selector(terminateWithSuccess)]) {
        [self terminateWithSuccess];
    } else {
        exit(0);
    }
}
@end

%group CustomID
%hook RDKOAuthCredential
- (id)clientIdentifier {
    if (kCustomID) {
        return kCustomID;
    }
    return %orig;
}
- (id)accessToken {
    accessToken = %orig;
    return accessToken;
}
%end
%end

%group SettingsViewController
%hook ApolloSettingsViewController
- (CGFloat)tableView:(UITableView*)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    UIButton *settingsButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [settingsButton addTarget:self action:@selector(settingsButtonPushed) forControlEvents:UIControlEventTouchUpInside];
    [settingsButton setTitle:@"CustomAPI" forState:UIControlStateNormal];
    settingsButton.backgroundColor = COLOR_BACKGROUND;
    settingsButton.frame = CGRectMake(0, 0, tableView.frame.size.width, 44);
    tableView.tableFooterView = settingsButton;

    return %orig;
}
%new
- (void)settingsButtonPushed {
    // create an alert controller
    alertWithText = [UIAlertController alertControllerWithTitle:@"Settings"
                                                        message:nil
                                                 preferredStyle:UIAlertControllerStyleAlert];

    UIAlertAction *action1 = [UIAlertAction actionWithTitle:@"Set RedditClientID" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
        [self performSelector:@selector(saveText:) withObject:nil];
    }];

    UIAlertAction *action2 = [UIAlertAction actionWithTitle:@"Reset" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"Custom_ID"];
        [[UIApplication sharedApplication] closeAppAnimatedExit];
    }];

    UIAlertAction *action3 = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {}];

    // add the actions to the alert
    [alertWithText addAction:action1];
    [alertWithText addAction:action2];
    [alertWithText addAction:action3];

    // Establish the weak self reference
    __weak typeof(self) weakSelf = self;

    [alertWithText addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {

        [textField setClearButtonMode:UITextFieldViewModeAlways];
        textField.returnKeyType = UIReturnKeyDone;
        textField.keyboardType = UIKeyboardTypeNumbersAndPunctuation;
        [textField setDelegate:weakSelf];
        textField.placeholder = [NSString stringWithFormat:@"ClientID:%@",kCustomID];

    }];

    [self presentViewController:alertWithText animated:YES completion:nil];
}

%new
- (void)saveText:(UITextField *)textField {
    textField = alertWithText.textFields.lastObject;
    NSString *textValue = textField.text;
    if ([textValue length] > 0) {
        [[NSUserDefaults standardUserDefaults] setObject:textValue forKey:@"Custom_ID"];
        [[UIApplication sharedApplication] closeAppAnimatedExit];
    }
}
%end
%end

%ctor {
    @autoreleasepool {
        kCustomID = (id)[[[NSUserDefaults standardUserDefaults] objectForKey:@"Custom_ID"] ?: nil copy];

        %init(CustomID);

        %init(SettingsViewController, ApolloSettingsViewController = objc_getClass("Apollo.SettingsViewController"));
    }
}
