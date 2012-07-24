//
//  FacebookLib.mm
//  FacebookLib
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
static NSString *const FBLoginCanceledEvent = @"LOGIN_CANCELED";
static NSString *const FBLoginFailedEvent = @"LOGIN_FAILED";
static NSString *const FBLogoutEvent = @"LOGOUT";
static NSString *const FBAccessTokenExtendedEvent = @"ACCESS_TOKEN_EXTENDED";
static NSString *const FBSessionInvalidatedEvent = @"SESSION_INVALIDATED";


@interface FacebookLib : NativeLibrary<FBSessionDelegate, FBRequestDelegate, FBDialogDelegate> {
@private
  Facebook *facebook;
  NSMutableDictionary *pendingRequests;
}

@property (nonatomic, readonly) NSString *applicationId;

@end

@interface JLRequestWrapper : NSObject<FBRequestDelegate> {
@private
}

@property (nonatomic, readonly) NSString *uuid;
@property (nonatomic, assign) FBRequest *request;
@property (nonatomic, assign) FacebookLib *lib;

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
  FN(showDialog, dialog:params:)
  FN(graph, requestWithGraphPath:params:httpMethod:)
FN_END

@synthesize applicationId;

- (id)init {
  if (self = [super init]) {
    pendingRequests = [NSMutableDictionary new];
  }
  return self;
}

- (void)dealloc {
  [pendingRequests release];
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
      NSArray *permArray = [loginPermissions length] ? [loginPermissions componentsSeparatedByString:@","] : nil;
      [self loginWithPermissions:permArray];
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

- (void)fbDidNotLogin:(BOOL)canceled {
  if (canceled)
    [self sendEventWithCode:FBLoginCanceledEvent level:@"SESSION"];
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

- (void)loginWithPermissions:(NSArray *)permissions {
  [facebook authorize:permissions];
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

NSMutableDictionary *sanitizeParams(NSMutableDictionary *params) {
  if (!params)
    return [NSMutableDictionary dictionary];
  for (NSString *key in params) {
    id val = [params objectForKey:key];
    if (![val isKindOfClass:[NSString class]])
      [params setObject:[val description] forKey:key];
  }
  return params;
}

- (void)requestWithMethodName:(NSString *)methodName params:(NSMutableDictionary *)params httpMethod:(NSString *)httpMethod {
  params = sanitizeParams(params);
  [facebook requestWithMethodName:methodName andParams:params andHttpMethod:httpMethod andDelegate:self];
}

- (NSString *)requestWithGraphPath:(NSString *)graphPath params:(NSMutableDictionary *)params httpMethod:(NSString *)httpMethod {
  params = sanitizeParams(params);
  if (!httpMethod)
    httpMethod = @"GET";
  JLRequestWrapper *wrapper = [JLRequestWrapper new];
  [pendingRequests setObject:wrapper forKey:wrapper.uuid];
  wrapper.lib = self;
  wrapper.request = [facebook requestWithGraphPath:graphPath andParams:params andHttpMethod:httpMethod andDelegate:wrapper];
  return wrapper.uuid;
}

- (void)dialog:(NSString *)action params:(NSMutableDictionary *)params {
  params = sanitizeParams(params);
  [facebook dialog:action andParams:params andDelegate:self];
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
 * Called when dialog failed to load due to an error.
 */
- (void)dialog:(FBDialog*)dialog didFailWithError:(NSError *)error {
  ANELog(@"%s: %@ %@", __PRETTY_FUNCTION__, dialog, error);
  [self executeOnActionScriptThread:^{
    [self callMethodNamed:@"dialogDidFailWithError" withArgument:error];
  }];
}

@end

@implementation JLRequestWrapper

@synthesize uuid;
@synthesize request;
@synthesize lib;

- (id)init {
  if (self = [super init]) {
    CFUUIDRef uuidRef = CFUUIDCreate(NULL);
    uuid = (id)CFUUIDCreateString(NULL, uuidRef);
    CFRelease(uuidRef);
  }
  return self;
}

- (void)dealloc {
  [uuid release];
  [super dealloc];
}

/**
 * Called just before the request is sent to the server.
 */
- (void)requestLoading:(FBRequest *)request_ {
  ANELog(@"%s: %@", __PRETTY_FUNCTION__, request_);
}

/**
 * Called when the Facebook API request has returned a response.
 *
 * This callback gives you access to the raw response. It's called before
 * (void)request:(FBRequest *)request didLoad:(id)result,
 * which is passed the parsed response object.
 */
- (void)request:(FBRequest *)request_ didReceiveResponse:(NSURLResponse *)response {
  ANELog(@"%s: %@ %@", __PRETTY_FUNCTION__, request_, response);
}

/**
 * Called when an error prevents the request from completing successfully.
 */
- (void)request:(FBRequest *)request_ didFailWithError:(NSError *)error {
  ANELog(@"%s: %@ %@", __PRETTY_FUNCTION__, request_, error);
  [lib executeOnActionScriptThread:^{
    [lib callMethodNamed:@"requestDidFailWithError" withArguments:[NSArray arrayWithObjects:uuid, error, nil]];
  }];
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
- (void)request:(FBRequest *)request_ didLoad:(id)result {
  ANELog(@"%s: %@ %@", __PRETTY_FUNCTION__, request_, result);
  [lib executeOnActionScriptThread:^{
    [lib callMethodNamed:@"requestDidLoad" withArguments:[NSArray arrayWithObjects:uuid, result, nil]];
  }];
}

/**
 * Called when a request returns a response.
 *
 * The result object is the raw response from the server of type NSData
 */
- (void)request:(FBRequest *)request_ didLoadRawResponse:(NSData *)data {
  ANELog(@"%s: %@ NSData (%d bytes)", __PRETTY_FUNCTION__, request_, [data length]);
}

@end
