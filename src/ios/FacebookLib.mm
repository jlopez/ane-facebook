//
//  ChartbootLib.mm
//  ChartbootLib
//
//  Created by Jesus Lopez on 05/07/2012
//  Copyright (c) 2012 JLA. All rights reserved.
//
#import "FBConnect.h"
#import "NativeLibrary.h"

static NSString *const FBAccessTokenKey = @"FBAccessTokenKey";
static NSString *const FBExpirationDateKey = @"FBExpirationDateKey";
static NSString *const FBAutoLoginPermissionsKey = @"FBAutoLoginPermissionsKey";

static NSString *const FBAppIdKey = @"FBAppID";
static NSString *const FBPermissionsKey = @"FBPermissions";

static NSString *const FBLoginEvent = @"LOGIN";
static NSString *const FBLoginCancelledEvent = @"LOGIN_CANCELLED";
static NSString *const FBLoginFailedEvent = @"LOGIN_FAILED";
static NSString *const FBLogoutEvent = @"LOGOUT";
static NSString *const FBAccessTokenExtendedEvent = @"ACCESS_TOKEN_EXTENDED";
static NSString *const FBSessionInvalidatedEvent = @"SESSION_INVALIDATED";


@interface FacebookLib : NativeLibrary<FBSessionDelegate, FBRequestDelegate, FBDialogDelegate> {
@private
  Facebook *facebook;
}

@property (nonatomic, readonly) NSString *applicationId;
@property (nonatomic, assign) BOOL shouldOpenDialogURLInExternalBrowser;

@end

@implementation FacebookLib

FN_BEGIN(FacebookLib)
  FN(applicationId, applicationId)
  FN(accessToken, accessToken)
  FN(expirationDate, expirationDate)
  FN(isFrictionlessRequestsEnabled, isFrictionlessRequestsEnabled)
  FN(login, loginWithPermissions:)
  FN(logout, logout)
  FN(extendAccessToken, extendAccessToken)
  FN(extendAccessTokenIfNeeded, extendAccessTokenIfNeeded)
  FN(shouldExtendAccessToken, shouldExtendAccessToken)
  FN(isSessionValid, isSessionValid)
  FN(enableFrictionlessRequests, enableFrictionlessRequests)
  FN(reloadFrictionlessRecipientCache, reloadFrictionlessRecipientCache)
  FN(isFrictionlessEnabledForRecipient, isFrictionlessEnabledForRecipient:)
  FN(isFrictionlessEnabledForRecipients, isFrictionlessEnabledForRecipients:)
  FN(showDialog, dialog:params:paramsProperties:)
  FN(shouldOpenDialogURLInExternalBrowser, shouldOpenDialogURLInExternalBrowser)
  FN(setShouldOpenDialogURLInExternalBrowser, setShouldOpenDialogURLInExternalBrowser:)
FN_END

@synthesize applicationId;
@synthesize shouldOpenDialogURLInExternalBrowser;

- (id)init {
  if (self = [super init]) {
    shouldOpenDialogURLInExternalBrowser = YES;
  }
  return self;
}

- (void)dealloc {
  [facebook release];
  [super dealloc];
}

- (void)updateToken:(NSString *)accessToken expiresAt:(NSDate *)expirationDate {
  NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
  [defaults setObject:accessToken forKey:FBAccessTokenKey];
  [defaults setObject:expirationDate forKey:FBExpirationDateKey];
  [defaults synchronize];
}

- (void)removeToken {
  NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
  if ([defaults objectForKey:FBAccessTokenKey]) {
    [defaults removeObjectForKey:FBAccessTokenKey];
    [defaults removeObjectForKey:FBExpirationDateKey];
    [defaults synchronize];
  }
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
  NSBundle *bundle = [NSBundle mainBundle];
  applicationId = [bundle objectForInfoDictionaryKey:FBAppIdKey];
  NSAssert(applicationId, @"Missing FBAppID");
  facebook = [[Facebook alloc] initWithAppId:applicationId andDelegate:self];

  NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
  id accessToken = [defaults objectForKey:FBAccessTokenKey];
  id expirationDate = [defaults objectForKey:FBExpirationDateKey];
  if (accessToken && expirationDate) {
    facebook.accessToken = accessToken;
    facebook.expirationDate = expirationDate;
  }

  NSString *loginPermissions = [bundle objectForInfoDictionaryKey:FBPermissionsKey];
  if (loginPermissions) {
    NSString *oldPermissions = [defaults objectForKey:FBAutoLoginPermissionsKey];
    if (![facebook isSessionValid] || ![oldPermissions isEqualToString:loginPermissions]) {
      [self loginWithPermissions:loginPermissions];
      [defaults setObject:loginPermissions forKey:FBAutoLoginPermissionsKey];
      [defaults synchronize];
    }
  }

  return YES;
}

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation {
  return [facebook handleOpenURL:url];
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
  [facebook extendAccessTokenIfNeeded];
}

- (void)fbDidLogin {
  [self updateToken:facebook.accessToken expiresAt:facebook.expirationDate];
  [self sendEventWithCode:FBLoginEvent level:@"SESSION"];
}

- (void)fbDidNotLogin:(BOOL)cancelled {
  if (cancelled)
    [self sendEventWithCode:FBLoginCancelledEvent level:@"SESSION"];
  else
    [self sendEventWithCode:FBLoginFailedEvent level:@"SESSION"];
}

- (void)fbDidExtendToken:(NSString *)accessToken expiresAt:(NSDate *)expiresAt {
  [self updateToken:accessToken expiresAt:expiresAt];
  [self sendEventWithCode:FBAccessTokenExtendedEvent level:@"SESSION"];
}

- (void)fbDidLogout {
  [self removeToken];
  [self sendEventWithCode:FBLogoutEvent level:@"SESSION"];
}

- (void)fbSessionInvalidated {
  [self removeToken];
  [self sendEventWithCode:FBSessionInvalidatedEvent level:@"SESSION"];
}

- (NSString *)accessToken {
  return facebook.accessToken;
}

- (NSDate *)expirationDate {
  return facebook.expirationDate;
}

- (void)loginWithPermissions:(NSString *)permissions {
  NSArray *permArray = [permissions length] ? [permissions componentsSeparatedByString:@","] : nil;
  [facebook authorize:permArray];
}

- (void)logout {
  [facebook logout];
}

- (BOOL)isFrictionlessRequestsEnabled {
  return [facebook isFrictionlessRequestsEnabled];
}

- (void)extendAccessToken {
  [facebook extendAccessToken];
}

- (void)extendAccessTokenIfNeeded {
  [facebook extendAccessTokenIfNeeded];
}

- (BOOL)shouldExtendAccessToken {
  return [facebook shouldExtendAccessToken];
}

- (BOOL)isSessionValid {
  return [facebook isSessionValid];
}

- (void)enableFrictionlessRequests {
  [facebook enableFrictionlessRequests];
}

- (void)reloadFrictionlessRecipientCache {
  [facebook reloadFrictionlessRecipientCache];
}

- (BOOL)isFrictionlessEnabledForRecipient:(NSString *)fbid {
  return [facebook isFrictionlessEnabledForRecipient:fbid];
}

- (BOOL)isFrictionlessEnabledForRecipients:(NSArray *)fbids {
  return [facebook isFrictionlessEnabledForRecipients:fbids];
}

- (void)requestWithMethodName:(NSString *)methodName params:(ASObject *)params paramsProperties:(NSArray *)paramsProperties httpMethod:(NSString *)httpMethod {
  [facebook requestWithMethodName:methodName andParams:[params dictionaryWithProperties:paramsProperties, nil] andHttpMethod:httpMethod andDelegate:self];
}

- (void)requestWithGraphPath:(NSString *)graphPath params:(ASObject *)params paramsProperties:(NSArray *)paramsProperties httpMethod:(NSString *)httpMethod {
  [facebook requestWithGraphPath:graphPath andParams:[params dictionaryWithProperties:paramsProperties, nil] andHttpMethod:httpMethod andDelegate:self];
}

- (void)dialog:(NSString *)action params:(ASObject *)params paramsProperties:(NSArray *)paramsProperties {
  ANELog(@"Conversion: [%@]", [params dictionaryWithProperties:paramsProperties, nil]);
  [facebook dialog:action andParams:[params dictionaryWithProperties:paramsProperties, nil] andDelegate:self];
}

/**
 * Called just before the request is sent to the server.
 */
- (void)requestLoading:(FBRequest *)request {
  ANELog(@"%s: %@", __PRETTY_FUNCTION__, request);
}

/**
 * Called when the Facebook API request has returned a response.
 *
 * This callback gives you access to the raw response. It's called before
 * (void)request:(FBRequest *)request didLoad:(id)result,
 * which is passed the parsed response object.
 */
- (void)request:(FBRequest *)request didReceiveResponse:(NSURLResponse *)response {
  ANELog(@"%s: %@ %@", __PRETTY_FUNCTION__, request, response);
}

/**
 * Called when an error prevents the request from completing successfully.
 */
- (void)request:(FBRequest *)request didFailWithError:(NSError *)error {
  ANELog(@"%s: %@ %@", __PRETTY_FUNCTION__, request, error);
}

/**
 * Called when a request returns and its response has been parsed into
 * an object.
 *
 * The resulting object may be a dictionary, an array or a string, depending
 * on the format of the API response. If you need access to the raw response,
 * use:
 *
 * (void)request:(FBRequest *)request
 *      didReceiveResponse:(NSURLResponse *)response
 */
- (void)request:(FBRequest *)request didLoad:(id)result {
  ANELog(@"%s: %@ %@", __PRETTY_FUNCTION__, request, result);
}

/**
 * Called when a request returns a response.
 *
 * The result object is the raw response from the server of type NSData
 */
- (void)request:(FBRequest *)request didLoadRawResponse:(NSData *)data {
  ANELog(@"%s: %@ NSData (%d bytes)", __PRETTY_FUNCTION__, request, [data length]);
}

/**
 * Called when the dialog succeeds and is about to be dismissed.
 */
- (void)dialogDidComplete:(FBDialog *)dialog {
  ANELog(@"%s: %@", __PRETTY_FUNCTION__, dialog);
  [self executeOnActionScriptThread:^{
    [self callMethodNamed:@"dialogDidComplete"];
  }];
}

/**
 * Called when the dialog succeeds with a returning url.
 */
- (void)dialogCompleteWithUrl:(NSURL *)url {
  ANELog(@"%s: %@", __PRETTY_FUNCTION__, url);
  [self executeOnActionScriptThread:^{
    [self callMethodNamed:@"dialogDidComplete" withArgument:[url absoluteString]];
  }];
}

/**
 * Called when the dialog get canceled by the user.
 */
- (void)dialogDidNotCompleteWithUrl:(NSURL *)url {
  ANELog(@"%s: %@", __PRETTY_FUNCTION__, url);
  [self executeOnActionScriptThread:^{
    [self callMethodNamed:@"dialogDidNotComplete" withArgument:[url absoluteString]];
  }];
}

/**
 * Called when the dialog is cancelled and is about to be dismissed.
 */
- (void)dialogDidNotComplete:(FBDialog *)dialog {
  ANELog(@"%s: %@", __PRETTY_FUNCTION__, dialog);
  [self executeOnActionScriptThread:^{
    [self callMethodNamed:@"dialogDidNotComplete"];
  }];
}

/**
 * Called when dialog failed to load due to an error.
 */
- (void)dialog:(FBDialog*)dialog didFailWithError:(NSError *)error {
  ANELog(@"%s: %@ %@", __PRETTY_FUNCTION__, dialog, error);
  [self executeOnActionScriptThread:^{
    [self callMethodNamed:@"dialogDidFailWithError" withArgument:error];
  }];
}

/**
 * Asks if a link touched by a user should be opened in an external browser.
 *
 * If a user touches a link, the default behavior is to open the link in the Safari browser,
 * which will cause your app to quit.  You may want to prevent this from happening, open the link
 * in your own internal browser, or perhaps warn the user that they are about to leave your app.
 * If so, implement this method on your delegate and return NO.  If you warn the user, you
 * should hold onto the URL and once you have received their acknowledgement open the URL yourself
 * using [[UIApplication sharedApplication] openURL:].
 */
- (BOOL)dialog:(FBDialog*)dialog shouldOpenURLInExternalBrowser:(NSURL *)url {
  ANELog(@"%s: %@ %@", __PRETTY_FUNCTION__, dialog, url);
  if (shouldOpenDialogURLInExternalBrowser)
    return YES;
  [self executeOnActionScriptThread:^{
    [self callMethodNamed:@"dialogOpenUrl" withArgument:[url absoluteURL]];
  }];
  return NO;
}

@end
