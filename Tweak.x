#import <UIKit/UIKit.h>
#import <SafariServices/SafariServices.h>

#define COLOR_BACKGROUND [UIColor colorWithRed:0.12 green:0.16 blue:0.61 alpha:1.0]
#define RANDSTRING  [[NSProcessInfo processInfo] globallyUniqueString]
#define RANDINT (arc4random() % 9) + 1

static NSString *kCustomID;
static NSString *kClientID;
static UIAlertController *alertWithText;

static void howtoUse(UIViewController *vc) {
    NSString *url = @"https://cydia.ichitaso.com/depiction/apollopatcher.html";
    SFSafariViewController *safari = [[SFSafariViewController alloc] initWithURL:[NSURL URLWithString:url]];
    [vc presentViewController:safari animated:YES completion:nil];
}

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
// reddit client id
- (id)clientIdentifier {
    if (kCustomID) {
        return kCustomID;
    }
    return %orig;
}
%end

%hook RDKClient
// Randomize User-Agent
- (id)userAgent {
    return [NSString stringWithFormat:@"iOS: com.%@.%@ v%d.%d.%d (by /u/%@)", RANDSTRING, RANDSTRING, RANDINT, RANDINT, RANDINT, RANDSTRING];
}
%end

@interface NSURLSession (Private)
- (BOOL)isJSONResponse:(NSURLResponse *)response;
- (void)useDummyDataWithCompletionHandler:(void (^)(NSData *, NSURLResponse *, NSError *))completionHandler;
@end

%hook NSURLSession
// Imgur Upload
- (NSURLSessionUploadTask*)uploadTaskWithRequest:(NSURLRequest*)request fromData:(NSData*)bodyData completionHandler:(void (^)(NSData*, NSURLResponse*, NSError*))completionHandler {
    NSString *urlString = [[request URL] absoluteString];
    NSString *oldPrefix = @"https://imgur-apiv3.p.rapidapi.com/3/image";
    NSString *newPrefix = @"https://api.imgur.com/3/image?client_id=";

    if ([urlString isEqualToString:oldPrefix] && kClientID) {
        NSString *newUrlString = [newPrefix stringByAppendingString:kClientID];
        NSMutableURLRequest *modifiedRequest = [request mutableCopy];
        [modifiedRequest setURL:[NSURL URLWithString:newUrlString]];
        return %orig(modifiedRequest,bodyData,completionHandler);
    }
    return %orig();
}
// Imgur Delete
- (NSURLSessionDataTask*)dataTaskWithRequest:(NSURLRequest*)request completionHandler:(void (^)(NSData*, NSURLResponse*, NSError*))completionHandler {
    NSString *urlString = [[request URL] absoluteString];
    NSString *oldPrefix = @"https://imgur-apiv3.p.rapidapi.com/3/image/";
    NSString *newPrefix = @"https://api.imgur.com/3/image/";

    if ([urlString hasPrefix:oldPrefix]) {
        NSString *suffix = [urlString substringFromIndex:oldPrefix.length];
        NSString *newUrlString = [newPrefix stringByAppendingString:suffix];
        NSMutableURLRequest *modifiedRequest = [request mutableCopy];
        [modifiedRequest setURL:[NSURL URLWithString:newUrlString]];
        return %orig(modifiedRequest,completionHandler);
    }
    return %orig();
}
// Fix Imgur loading issue
static NSString *imageID;
- (NSURLSessionDataTask *)dataTaskWithURL:(NSURL *)url completionHandler:(void (^)(NSData *, NSURLResponse *, NSError *))completionHandler {
    //NSLog(@"ApolloPatcher:dataTaskWithURL:%@", url.absoluteString);
    imageID = [url.lastPathComponent stringByDeletingPathExtension];
    // Remove unwanted messages on app startup
    if ([url.absoluteString containsString:@"https://apollogur.download/api/apollonouncement"] ||
        [url.absoluteString containsString:@"https://apollogur.download/api/easter_sale"] ||
        [url.absoluteString containsString:@"https://apollogur.download/api/html_codes"] ||
        [url.absoluteString containsString:@"https://apollogur.download/api/refund_screen_config"]) {
        return nil;
    } else if ([url.absoluteString containsString:@"https://apollogur.download/api/image/"]) {
        NSString *modifiedURLString = [NSString stringWithFormat:@"https://api.imgur.com/3/image/%@.json?client_id=%@", imageID, kClientID];
        NSURL *modifiedURL = [NSURL URLWithString:modifiedURLString];
        // Access the modified URL to get the actual data
        NSURLSessionDataTask *dataTask = [self dataTaskWithURL:modifiedURL completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
            if (error || ![self isJSONResponse:response]) {
                // If an error occurs or the response is not a JSON response, dummy data is used
                [self useDummyDataWithCompletionHandler:completionHandler];
            } else {
                // If normal data is returned, the callback is executed
                completionHandler(data, response, error);
            }
        }];

        [dataTask resume];
        return dataTask;
    } else if ([url.absoluteString containsString:@"https://apollogur.download/api/album/"]) {
        NSString *modifiedURLString = [NSString stringWithFormat:@"https://api.imgur.com/3/album/%@.json?client_id=%@", imageID, kClientID];
        NSURL *modifiedURL = [NSURL URLWithString:modifiedURLString];
        return %orig(modifiedURL, completionHandler);
    }
    return %orig;
}
%new
- (BOOL)isJSONResponse:(NSURLResponse *)response {
    if ([response isKindOfClass:[NSHTTPURLResponse class]]) {
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
        NSString *contentType = httpResponse.allHeaderFields[@"Content-Type"];
        if (contentType && [contentType rangeOfString:@"application/json" options:NSCaseInsensitiveSearch].location != NSNotFound) {
            return YES;
        }
    }
    return NO;
}
%new
- (void)useDummyDataWithCompletionHandler:(void (^)(NSData *, NSURLResponse *, NSError *))completionHandler {
    // Create dummy data
    NSDictionary *dummyData = @{
        @"data": @{
            @"id": @"example_id",
            @"title": @"Example Image",
            @"description": @"This is an example image",
            @"datetime": @(1234567890),
            @"type": @"image/gif",
            @"animated": @(YES),
            @"width": @(640),
            @"height": @(480),
            @"size": @(1024),
            @"views": @(100),
            @"bandwidth": @(512),
            @"vote": @(0),
            @"favorite": @(NO),
            @"nsfw": @(NO),
            @"section": @"example",
            @"account_url": @"example_user",
            @"account_id": @"example_account_id",
            @"is_ad": @(NO),
            @"in_most_viral": @(NO),
            @"has_sound": @(NO),
            @"tags": @[@"example", @"image"],
            @"ad_type": @"image",
            @"ad_url": @"https://example.com",
            @"edited": @(0),
            @"in_gallery": @(NO),
            @"deletehash": @"abc123deletehash",
            @"name": @"example_image",
            @"link": [NSString stringWithFormat:@"https://i.imgur.com/%@.gif", imageID],
            @"success": @(YES)
        }
    };

    NSError *error;
    NSData *dummyDataJSON = [NSJSONSerialization dataWithJSONObject:dummyData options:0 error:&error];

    if (error) {
        NSLog(@"JSON conversion error for dummy data: %@", error);
        return;
    }

    NSHTTPURLResponse *response = [[NSHTTPURLResponse alloc] initWithURL:[NSURL URLWithString:@"https://apollogur.download/api/image/"] statusCode:200 HTTPVersion:@"HTTP/1.1" headerFields:@{@"Content-Type": @"application/json"}];

    completionHandler(dummyDataJSON, response, nil);
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
        [self performSelector:@selector(saveText1:) withObject:nil];
    }];

    UIAlertAction *action2 = [UIAlertAction actionWithTitle:@"Set ImgUrClientID" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
        [self performSelector:@selector(saveText2:) withObject:nil];
    }];

    UIAlertAction *action3 = [UIAlertAction actionWithTitle:@"Reset" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"Custom_ID"];
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"IMGUR_ID"];
        [[UIApplication sharedApplication] closeAppAnimatedExit];
    }];

    UIAlertAction *action4 = [UIAlertAction actionWithTitle:@"How to Use" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        howtoUse(self);
    }];

    UIAlertAction *action5 = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {}];

    // add the actions to the alert
    [alertWithText addAction:action1];
    [alertWithText addAction:action2];
    [alertWithText addAction:action3];
    [alertWithText addAction:action4];
    [alertWithText addAction:action5];

    // Establish the weak self reference
    __weak typeof(self) weakSelf = self;

    [alertWithText addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {

        [textField setClearButtonMode:UITextFieldViewModeAlways];
        textField.returnKeyType = UIReturnKeyDone;
        textField.keyboardType = UIKeyboardTypeNumbersAndPunctuation;
        [textField setDelegate:weakSelf];
        textField.placeholder = [NSString stringWithFormat:@"ClientID:%@",kCustomID];

    }];

    [alertWithText addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {

        [textField setClearButtonMode:UITextFieldViewModeAlways];
        textField.returnKeyType = UIReturnKeyDone;
        textField.keyboardType = UIKeyboardTypeNumbersAndPunctuation;
        [textField setDelegate:weakSelf];
        textField.placeholder = [NSString stringWithFormat:@"ImgurID:%@",kClientID];

    }];

    [self presentViewController:alertWithText animated:YES completion:nil];
}

%new
- (void)saveText1:(UITextField *)textField {
    textField = alertWithText.textFields.firstObject;
    NSString *textValue = textField.text;
    if ([textValue length] > 0) {
        [[NSUserDefaults standardUserDefaults] setObject:textValue forKey:@"Custom_ID"];
        [[UIApplication sharedApplication] closeAppAnimatedExit];
    }
}

%new
- (void)saveText2:(UITextField *)textField {
    textField = alertWithText.textFields.lastObject;
    NSString *textValue = textField.text;
    if ([textValue length] > 0) {
        [[NSUserDefaults standardUserDefaults] setObject:textValue forKey:@"IMGUR_ID"];
        [[UIApplication sharedApplication] closeAppAnimatedExit];
    }
}
%end
%end

%ctor {
    @autoreleasepool {
        kCustomID = (id)[[[NSUserDefaults standardUserDefaults] objectForKey:@"Custom_ID"] ?: nil copy];
        kClientID = (id)[[[NSUserDefaults standardUserDefaults] objectForKey:@"IMGUR_ID"] ?: @"8b15a972041abb1" copy];
        // Suppress wallpaper popup
        [[NSUserDefaults standardUserDefaults] setObject:[NSDate dateWithTimeIntervalSinceNow:60*60*24*90] forKey:@"WallpaperPromptMostRecent2"];

        %init(CustomID);

        %init(SettingsViewController, ApolloSettingsViewController = objc_getClass("Apollo.SettingsViewController"));
    }
}
